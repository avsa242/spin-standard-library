{
    --------------------------------------------
    Filename: boardcfg.p8xblade2.spin
    Author: Jesse Burt
    Description: Board configuration file for Cluso's P8XBlade2
    Started Oct 15, 2022
    Updated Oct 15, 2022
    Copyright 2022
    See end of file for terms of use.
    --------------------------------------------
}

#include "p8x32a.common.spinh"

CON
    { --- clock settings --- }
    _clkmode    = xtal1 + pll8x
    _xinfreq    = 12_000_000

    { --- pin definitions --- }
    {  micro-SD socket - SPI }
    SD_DO       = 12
    SD_CLK      = 13
    SD_MISO     = 14
    SD_CS       = 15

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

