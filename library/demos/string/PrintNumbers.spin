{
    --------------------------------------------
    Filename: PrintNumbers.spin
    Author: Brett Weir
    Modified by: Jesse Burt
    Description: Demo of the Dec(), DecPadded(), DecZeroed(),
        Hex(), Bin(), HexIndicated(), BinIndicated(), StrToBase()
        functions in the string object
    Started Jan, 2016
    Updated May 8, 2021
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
    num  : "string.integer"
    time : "time"

PUB Main{}

    term.start(SER_BAUD)
    time.msleep(30)
    term.clear{}

    ' decimal
    term.strln(num.dec(34236))

    ' decimal, padded with leading spaces to 10-digit width
    term.strln(num.decpadded(34236, 10))

    ' decimal, padded with leading zeroes to 10-digit width
    term.strln(num.deczeroed(34236, 10))

    ' hexadecimal, padded with leading zeroes to 8-digit width
    term.strln(num.hex(34236, 8))

    ' hexadecimal, padded with leading zeroes to 8-digit width,
    '   with leading radix/base indicator ($)
    term.strln(num.hexindicated(34236, 8))

    ' binary, padded with leading zeroes to 32-digit width
    term.strln(num.bin(34256, 32))

    ' binary, padded with leading zeroes to 32-digit width,
    '   with radix/base indicator (%)
    term.strln(num.binindicated(34256, 32))

    ' string of numbers converted to an integer,
    '   interpreted as base-10 (decimal)
    term.strln(num.strtobase(string("34256"), 10))

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}

