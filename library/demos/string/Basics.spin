{
    --------------------------------------------
    Filename: Basics.spin
    Author: Brett Weir
    Description: String basics (declaration, display)
    Started Jan 5, 2016
    Updated May 1, 2021
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

    byte _str1[32]                              ' declare 32-byte array

PUB Main{}

    term.start(SER_BAUD)
    time.msleep(30)
    term.clear

    ' Create a string with the string() command
    term.strln(string("String!"))

    ' Create a string in a DAT block and use the address.

    term.strln(@_magicstring)

    ' Get the size of a string with strsize()

    term.dec(strsize(@_magicstring))
    term.newline{}

DAT

'   symbol name     align/size    "string", 0-string terminator (mandatory)
    _magicstring    byte    "another string!", 0

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
