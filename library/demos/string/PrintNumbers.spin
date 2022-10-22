{
    --------------------------------------------
    Filename: PrintNumbers.spin
    Description: Demo of the dec(), decpads(), decpadz(),
        hexs(), bin(), atoib() functions in the string object
    Author: Brett Weir
    Modified by: Jesse Burt
    Started Jan, 2016
    Updated Oct 22, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' -- User-modifiable constants
    SER_BAUD    = 115_200
' --

OBJ

    term : "com.serial.terminal.ansi"
    str  : "string"
    time : "time"

PUB main{} | tmp

    term.start(SER_BAUD)
    time.msleep(30)
    term.clear{}

    ' decimal
    term.strln(str.dec(34236))

    ' decimal, padded with leading spaces to 10-digit width
    term.strln(str.decpads(34236, 10))

    ' decimal, padded with leading zeroes to 10-digit width
    term.strln(str.decpadz(34236, 10))

    ' hexadecimal, padded with leading zeroes to 8-digit width
    term.strln(str.hex(34236, 8))

    ' binary, padded with leading zeroes to 32-digit width
    term.strln(str.bin(34236, 32))

    ' string of numbers converted to an integer,
    '   interpreted as base-10 (decimal)
    term.dec(str.atoib(string("34236"), 10))

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

