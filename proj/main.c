/** -----------------------------------------------------------------------------------------------------------------------------------
 *
 *      RADPC
 *
 *
 *      A SIMPLE SOFTWARE DEMO TO BLINK THE RADPC HDYRA `STATUS` LED.
 *
------------------------------------------------------------------------------------------------------------------------------------ */


//--------------------------------------------------------------------------------------------------------------------------------------
//  LIBRARIES
//--------------------------------------------------------------------------------------------------------------------------------------

// Include the RadPC Library
#include "radpc.h"
#include "hwa.h"
#include "aes.h"

// Include standard C libraries
#include <stdint.h>
#include <stdlib.h>


//--------------------------------------------------------------------------------------------------------------------------------------
//  GLOBAL VARIABLES
//--------------------------------------------------------------------------------------------------------------------------------------

int del_val = 1000;                                     // Delay Value




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

        HWA_CTRL = AES_IDLE;

        int state = 0; 
        // 0 is idle
        // 1 is read in plaintext/ciphertext
        // 2 is print the output and go back to idle

        // Infinite loop
        while(1) {

                switch (state){
                        case 0: 
                                {
                                rpc_printf(0, "type 'e' for encryption or 'd' for decryption\n\r");
                                while (state == 0)
                                {
                                        if(UART_00_RX_STAT & BIT_0){
                                                char c = UART_00_RX_BUFF;
                                                if(c == 'e'){
                                                        rpc_printf(0, "Provide Value to encrypt(128 bit Hex): ");
                                                        state = 1;
                                                        HWA_CTRL = AES_ENCRYPT;
                                                }else if(c == 'd'){
                                                        rpc_printf(0, "Provide Value to decrypt(128 bit Hex): ");
                                                        state = 1;
                                                        HWA_CTRL = AES_DECRYPT;
                                                }else{
                                                        //do nothing
                                                }
                                        }
                                }
                                break;
                        }
                        case 1:
                                {
                                uint32_t blk[4] = {0,0,0,0};
                                int n = 0;

                                while(n < 32){
                                        if(UART_00_RX_STAT & BIT_0){
                                                char c = UART_00_RX_BUFF;
                                                int v;

                                                if(c >= '0' && c <= '9'){
                                                        v = c - '0';
                                                }else if(c >= 'a' && c <= 'f'){
                                                        v = c - 'a' + 10;
                                                }else if(c >= 'A' && c <= 'F'){
                                                        v = c - 'A' + 10;
                                                }else{
                                                        continue;
                                                }

                                                blk[n / 8] = (blk[n/8] << 4) | v;
                                                n++;
                                        }
                                }

                                HWA_WRITE_00 = blk[0];
                                HWA_WRITE_01 = blk[1];
                                HWA_WRITE_02 = blk[2];
                                HWA_WRITE_03 = blk[3];

                                HWA_WRITE_07 = AES_IN_VALID;
                                state = 2;
                                break;
                        }
                        case 2:
                                {
                                while(state == 2){
                                        if (HWA_READ_07 & AES_OUT_VALID) {
                                                rpc_printf(0, "\r\n0x%08x 0x%08x 0x%08x 0x%08x\r\n", HWA_READ_00, HWA_READ_01, HWA_READ_02, HWA_READ_03);
                                                state = 0;
                                                HWA_CTRL = AES_IDLE;
                                                HWA_CTRL = 0;
                                        }                      
                                }
                        break;
                        }
                                
                }




                /*
                uint32_t pt[4] =  {0xF3EED1BD, 0xB5D2A03C, 0x64B5A7E, 0x3DB181F8};
                
                HWA_WRITE_00 = pt[0];
                HWA_WRITE_01 = pt[1];
                HWA_WRITE_02 = pt[2];
                HWA_WRITE_03 = pt[3];

                HWA_WRITE_07 = AES_IN_VALID;

                // Toggle heartbeat LED
                GPIO_02_OUT ^= BIT_0;

                // Delay before resuming loop
                delay( del_val );

                if (HWA_READ_07 & AES_OUT_VALID) {
                        rpc_printf(0, "0x%x 0x%x 0x%x 0x%x\r\n", HWA_READ_00, HWA_READ_01, HWA_READ_02, HWA_READ_03);
                }

                if(UART_00_RX_STAT & BIT_0){
                        char c = UART_00_RX_BUFF;

                        if(c == 'e') {
                                HWA_CTRL = AES_ENCRYPT;
                        }else if(c == 'd'){
                                HWA_CTRL = AES_DECRYPT;
                        }else{
                                HWA_CTRL = AES_IDLE;
                        }
                }

                */
                
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
