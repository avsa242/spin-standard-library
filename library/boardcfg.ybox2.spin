{
    --------------------------------------------
    Filename: boardcfg.ybox2.spin
    Author: Jesse Burt
    Description: Board configuration file for YBox2
        https://www.adafruit.com/product/95
    Started Oct 15, 2022
    Updated Oct 15, 2022
    Copyright 2022
    See end of file for terms of use.
    --------------------------------------------
}

#include "p8x32a.common.spinh"
#define YBOX2
CON
    { --- clock settings --- }
    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

    { --- pin definitions --- }
    { ENC28J60 Ethernet controller }
    RESET_PIN       = 0
    CS_PIN          = 1
    SCK_PIN         = 2
    MOSI_PIN        = 3
    MISO_PIN        = 4
    WOL_PIN         = 5
    INT_PIN         = 6

    { NOTE: The YBox2 provides no crystal for the ENC28J60,
        so the clock (25MHz) must be generated using one of the Propeller's
        counters, output to I/O pin 7 }
    ENC_OSCPIN      = 7

    { piezo buzzer }
    BUZZER          = 8
    AUDIO           = 8
    AUDIO_L         = 8
    AUDIO_R         = 8
    SOUND           = 8

    { RGB LED (not smart-LED), color order can differ from LED to LED }
    LED1            = 9
    LED2            = 10
    LED3            = 11

    { composite video }
    COMPVIDEO       = 12

    { PNA640XM IR receiver, 38kHz }
    IR_RX           = 15

    { S1: Tactile button }
    SWITCH1         = 16
    BUTTON1         = 16

PUB null
' This is not a top-level object

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

