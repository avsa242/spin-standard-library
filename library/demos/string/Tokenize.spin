{
    --------------------------------------------
    Filename: Tokenize.spin
    Author: Brett Weir
    Modified by: Jesse Burt
    Description: Demo of the Tokenize() method from
        the string object
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

    word _ptr_token

PUB Main{}

    term.start(SER_BAUD)
    time.msleep(30)
    term.clear{}

    _ptr_token := str.tokenize(@_magicstring)

    repeat while _ptr_token
        term.str(_ptr_token)
        term.newline{}
        _ptr_token := str.tokenize(0)

DAT

_magicstring     byte    "this string needs to be tokenized!", 0

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

