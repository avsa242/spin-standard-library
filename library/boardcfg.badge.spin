{
    --------------------------------------------
    Filename: boardcfg.badge.spin
    Author: Jesse Burt
    Description: Board configuration file for Hackable badge
        Parallax #20000, 20100, 20200
    Started Oct 15, 2022
    Updated Oct 15, 2022
    Copyright 2022
    See end of file for terms of use.
    --------------------------------------------
}

#include "p8x32a.common.spinh"

CON

    { --- clock settings --- }
    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

    { --- pin definitions --- }
    { R/C-time }
    RCT_V       = 0

    { RGB leds (non-smart) }
    RGBA        = 1
    RGBB        = 2
    RGBC        = 3
    XYZI        = 4

    { OSH capacitive touch-pad }
    PAD_OSH     = 5

    LEDA        = 6
    LEDB        = 7
    LEDC        = 8

    { sound }
    SOUND       = 9
    SOUND_L     = 9
    SOUND_R     = 10

    { composite video }
    VIDEO       = 12

    { capacitive touch-pads (left side) }
    PADL_1      = 15
    PADL_2      = 16
    PADL_3      = 17

    { OLED }
    OLED_CS     = 18
    OLED_RST    = 19
    OLED_DC     = 20
    OLED_CLK    = 21
    OLED_DAT    = 22

    { IR }
    IR_RX       = 23
    IR_TX       = 24

    { capacitive touch-pads (right side) }
    PADR_1      = 25
    PADR_2      = 26
    PADR_3      = 27

    { TV output modes and channels }
    COMPOSITE   = %0101
    BROADCAST   = %0100

    CH2         = 55_250_000
    CH3         = 61_250_000
    CH4         = 67_250_000

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

