{
    --------------------------------------------
    Filename: boardcfg.ptp.spin
    Author: Jesse Burt
    Description: Board configuration file for Propeller Touchscreen Platform
        PTP 3.5" (Ray Allen/Rayman)
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
    { micro-SD socket - SPI }
    SD_DO         = 0
    SD_CLK        = 1
    SD_DI         = 2
    SD_CS         = 3

    { sound }
    SOUND         = 10
    SOUND_L       = 10
    SOUND_R       = 11

    { LCD and touchscreen }
    LCD_RESET     = 12
    LCD_LSDI      = 13
    LCD_LCLK      = 14
    LCD_LCS       = 15
    LCD_VSYNC     = 16
    LCD_HSYNC     = 17
    LCD_B0        = 18
    LCD_B1        = 19
    LCD_G0        = 20
    LCD_G1        = 21
    LCD_R0        = 22
    LCD_R1        = 23
    LCD_DE        = 24
    LCD_PCLK      = 25
    LCD_BL        = 26
    TS_IRQ        = 27

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

