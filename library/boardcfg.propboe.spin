{
    --------------------------------------------
    Filename: boardcfg.propboe.spin
    Author: Jesse Burt
    Description: Board configuration file for Propeller Board of Education
        Parallax #32900
    Started Oct 15, 2022
    Updated Jul 3, 2023
    Copyright 2023
    See end of file for terms of use.
    --------------------------------------------
}

#include "p8x32a.common.spinh"

CON
    { --- clock settings --- }
    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

    { --- pin definitions --- }
    { 6x 3-pin servo headers }
    SERVO1      = 14
    SERVO2      = 15
    SERVO3      = 16
    SERVO4      = 17
    SERVO5      = 18
    SERVO6      = 19

    { microphone }
    MIC_IN      = 20
    MIC_FB      = 21

    { micro-sd socket - SPI }
    SD_DO       = 22
    SD_CLK      = 23
    SD_DI       = 24
    SD_CS       = 25
    SD_MISO     = 22
    SD_MOSI     = 24
    SD_CD       = 25

    { sound }
    SOUND       = 26
    SOUND_L     = 26
    SOUND_R     = 27
    AUDIO_L     = SOUND_L
    AUDIO_R     = SOUND_R

    { 2x amber LEDs }
    LED1        = 26
    LED2        = 27

    { DAC }
    DA0         = 26
    DA1         = 27

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

