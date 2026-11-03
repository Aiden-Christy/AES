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
        sleep(2);

        // Infinite loop
        while(1) {

                uint32_t pt[4] =  {0x6bc1bee2, 0x2e409f96, 0xe93d7e11, 0x7393172a};
                
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
                        rpc_printf(0, "0x%x 0x%x 0x%x 0x%x", HWA_READ_00, HWA_READ_01, HWA_READ_02, HWA_READ_03);
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
