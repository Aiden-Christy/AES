#ifndef AES_H
#define AES_H

#include "radpc.h"
#include "hwa.h"

#include <stdarg.h>
#include <stdint.h>


// AES HWA operation modes
#define AES_IDLE        0x00
#define AES_ENCRYPT     0x01
#define AES_DECRYPT     0x02

// AES signals
#define AES_IN_VALID    BIT_0
#define AES_KEY_VALID   BIT_0
#define AES_OUT_VALID   BIT_1

#define AES_TIMEOUT     100000