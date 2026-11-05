/** -----------------------------------------------------------------------------------------------------------------------------------
 *
 *      RADPC AES Co-porcessor demo
 * 
 *      Author: Aiden Christy
 * 
 *      Last Edit Date: 11/5/2026
 *
 *
 *      Simple c code to demonstrate AES encryption and decryption via UART_00
 *
------------------------------------------------------------------------------------------------------------------------------------ */


//--------------------------------------------------------------------------------------------------------------------------------------
//  LIBRARIES
//--------------------------------------------------------------------------------------------------------------------------------------

// Include the RadPC Library
#include "radpc.h"
#include "hwa.h"
#include "aes.h" //AES specfic library

// Include standard C libraries
#include <stdint.h>
#include <stdlib.h>


//--------------------------------------------------------------------------------------------------------------------------------------
//  GLOBAL VARIABLES
//--------------------------------------------------------------------------------------------------------------------------------------

int del_val = 1000;                                     // Delay Value



//--------------------------------------------------------------------------------------------------------------------------------------
// Known plaintext and its output from the current key (as of 11/5)
//11111111111111111111111111111111

//7dbd4ea52dca829edd928cbccc348685


//--------------------------------------------------------------------------------------------------------------------------------------
//  MAIN
//--------------------------------------------------------------------------------------------------------------------------------------

int main(){

        // Set UART_00 baud rate to 115200
        UART_00_CLK_CTRL = 0x0116;

        // Enable UART
        UART_00_EN = BIT_0;

        // Set Port B function to UART 00
        PFC_PORT_B |= (BIT_1 + BIT_0);

        // Set GPIO 00 direction
        GPIO_00_DIR = 0xFFFFFFFF;

        // Clear GPIO 00
        GPIO_00_OUT = 0x00000000;

        // Set Port A function to GPIO 00/UART 00 and Port B function to GPIO 01
        PFC_PORT_A = 0x00000000;

        // Set Port C function to GPIO 02
        PFC_PORT_C &= ~BIT_0;

        // Set GPIO 02 direction (Output)
        GPIO_02_DIR |= BIT_0;

        // Turn off heartbeat LED
        GPIO_02_OUT &= ~BIT_0;

        PFC_PORT_A = 0xFFFFFFF;


        
        // before starting sleep to wait for key expansion
        delay(1000);

        //Start the AES core in idle mode
        HWA_CTRL = AES_IDLE;

        // array to hold input from rpc_fgets
        char line[80];

        // 'state machine' controlling variable
        int state = 0; 
        // 0 is idle
        // 1 is read in plaintext/ciphertext
        // 2 is print the output and go back to idle

        // Infinite loop
        while(1) {
                
                // State Logic
                switch (state){
                        // get code mode from user via uart
                        case 0: 
                                {
                                // RPC UART print and get function
                                rpc_printf(0, "\r\ntype 'e' for encryption or 'd' for decryption: ");
                                rpc_fgets(0, line, sizeof(line));

                                // Check to see if the line typed in by user contains a 'e' or 'd' as the first letter
                                if (line[0] == 'e') {
                                        HWA_CTRL = AES_ENCRYPT; // Set the core to encryption mode
                                        rpc_printf(0, "\r\nProvide value to encrypt (128 bit hex): ");
                                        state = 1; // Move onto next state
                                } else if (line[0] == 'd') {
                                        HWA_CTRL = AES_DECRYPT; // set the core to decryption mode
                                        rpc_printf(0, "\r\nProvide value to decrypt (128 bit hex): ");
                                        state = 1; // move onto next state
                                }
                        break;
                        }

                        // get plain/ciphertext from user via uart
                        case 1:
                                {
                                uint32_t blk[4] = {0,0,0,0}; // variable to hold full text
                                int n = 0; // variable to make sure the data line is big enough
                                int i;

                                rpc_fgets(0, line, sizeof(line)); // grab the text from uart

                                for (i = 0; line[i] != '\0' && n < 32; i++) { // iterate through the first 32 values of the input text and make sure it is long enough (\0 is the value at the end of inputs or the null value)
                                        char c = line[i];
                                        int v;
                                
                                        if(c >= '0' && c <= '9'){ // check if the input is a number and push it to placeholder var
                                                v = c - '0';
                                        }else if(c >= 'a' && c <= 'f'){ // check if the input is a hex number and push its value to the var
                                                v = c - 'a' + 10;
                                        }else if(c >= 'A' && c <= 'F'){ // check if the input is a capital hex number and push its value to the var
                                                v = c - 'A' + 10;
                                        }else continue;
                                                                
                                        blk[n / 8] = (blk[n / 8] << 4) | v; // put the current var in the next spot of blk, not gonna lie this assignment came from claude, it makes sense but it did not come from my brain
                                        n++; // increment value of the input line
                                }
                        
                                if (n < 32) { // check to see if the input line was too short
                                        rpc_printf(0, "\r\nNeed 32 hex digits, got %d\r\n", n);
                                        HWA_CTRL = AES_IDLE;
                                        state = 0;
                                        break;
                                }

                                // push the values to the hwa through the internal registers
                                HWA_WRITE_00 = blk[0];
                                HWA_WRITE_01 = blk[1];
                                HWA_WRITE_02 = blk[2];
                                HWA_WRITE_03 = blk[3];

                                // turn on the in valid signal so the hwa starts an encryption
                                HWA_WRITE_07 = AES_IN_VALID;
                                
                                //move to next state
                                state = 2;
                                break;
                        }
                        case 2:
                                {
                                // wait for aes_out to pulse high
                                while(state == 2){
                                        if (HWA_READ_07 & AES_OUT_VALID) {
                                                // print the output value
                                                rpc_printf(0, "\r\n0x%x%x%x%x\r\n", HWA_READ_00, HWA_READ_01, HWA_READ_02, HWA_READ_03);
                                                
                                                // move back to idle state
                                                state = 0;

                                                //turn off AES conversion
                                                HWA_CTRL = AES_IDLE;

                                                // turn off in valid signal
                                                HWA_CTRL = 0;
                                        }                      
                                }
                        break;
                        }
                                
                }
                
        };

        // Return no error
        return 0;

}

//--------------------------------------------------------------------------------------------------------------------------------------
//  INTERRUPTS
//--------------------------------------------------------------------------------------------------------------------------------------

// Function to handle interrupts
void interrupt() {

        // Do Nothing
        // (Interrupts are currently disabled)

}

//--------------------------------------------------------------------------------------------------------------------------------------
//  END OF CODE
