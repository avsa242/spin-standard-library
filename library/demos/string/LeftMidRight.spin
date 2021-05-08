{
    --------------------------------------------
    Filename: LeftMidRight.spin
    Author: Brett Weir
    Description: Demo of the Left(), Mid() and Right()
        functions from the string object
    Started Jan 5, 2016
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
    str  : "string"
    time : "time"

VAR

    byte _str1[20]
    byte _strtemp[20]

PUB Main{}

    term.start(SER_BAUD)
    time.msleep(30)
    term.clear{}

    term.str(str.left(@_str1, @dinosaur, 4))
    term.newline{}

    term.str(str.mid(@_str1, @dinosaur, 5, 9))
    term.newline{}

    term.str(str.right(@_str1, @dinosaur, 6))
    term.newline{}

    str.copy(@_str1, str.left(@_strtemp, @dinosaur, 2))
    str.append(@_str1, str.right(@_strtemp, @dinosaur, 6))
    term.str(@_str1)
    term.newline{}

DAT

dinosaur    byte    "dass pineapplesaurus",0

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
