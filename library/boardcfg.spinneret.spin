{
    --------------------------------------------
    Filename: boardcfg.spinneret.spin
    Author: Jesse Burt
    Description: Board configuration file for Spinneret
        Parallax #32203
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
    { Wiznet W5100 LAN }
    DATA0       = 0
    DATA1       = 1
    DATA2       = 2
    DATA3       = 3
    DATA4       = 4
    DATA5       = 5
    DATA6       = 6
    DATA7       = 7
    ADDR0       = 8
    ADDR1       = 9
    _WR         = 10
    _RD         = 11
    _CS         = 12
    _INT        = 13
    E_RST       = 14
    SEN         = 15
    DAT0        = 16
    DAT1        = 17
    DAT2        = 18
    DAT3        = 19
    CMD         = 20
    SIO         = 22
    LED         = 23
    AUX0        = 24
    AUX1        = 25
    AUX2        = 26
    AUX3        = 27

    { micro-SD socket - SPI }
    SD_MISO     = 16
    SD_DAT1     = 17
    SD_DAT2     = 18
    SD_CS       = 19
    SD_MOSI     = 20
    SD_CLK      = 21

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
