{
    --------------------------------------------
    Filename: boardcfg.demoboard.spin
    Author: Jesse Burt
    Description: Board configuration file for Demo board
        Parallax #32100
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
    { microphone }
    MIC_IN      = 8
    MIC_FB      = 9

    { sound }
    SOUND       = 10
    AUDIO       = 10
    SOUND_L     = 10
    AUDIO_L     = 10
    SOUND_R     = 11
    AUDIO_R     = 11

    { composite video }
    VIDEO       = 12

    { VGA video }
    VGA         = 16

    { 8x amber LEDs }
    LED1        = 16
    LED2        = 17
    LED3        = 18
    LED4        = 19
    LED5        = 20
    LED6        = 21
    LED7        = 22
    LED8        = 23

    { PS/2 mouse }
    MOUSE       = 24
    MOUSE_DATA  = 24
    MOUSE_CLK   = 25

    { PS/2 keyboard }
    KEYBOARD    = 26
    KEYB_CLK    = 26
    KEYB_DATA   = 27

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

