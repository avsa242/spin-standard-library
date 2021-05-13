{
    --------------------------------------------
    Filename: TV-Terminal-Demo.spin
    Author: Chip Gracey
    Description: Demo of the display.tv.terminal object
    Started 2004
    Updated May 13, 2021
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is based on TV_Terminal_Demo.spin, originally
        by Chip Gracey
}

CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' -- User-modifiable constants
    TV_BASEPIN  = 12

' --

OBJ

    term    : "display.tv.terminal"

PUB Start{} | i

    ' start the tv terminal
    term.start(TV_BASEPIN)

    ' print a string
    term.str(@title)

    ' change to green
    term.char(2)

    ' print some small decimal numbers
    repeat i from -6 to 6
        term.dec(i)
        term.char(" ")
    term.newline

    ' print the extreme decimal numbers
    term.dec(posx)
    term.char(term#TB)
    term.dec(negx)
    term.newline

    ' change to red
    term.char(3)

    ' print some hex numbers
    repeat i from -6 to 6
        term.hex(i, 2)
        term.char(" ")
    term.newline

    ' print some binary numbers
    repeat i from 0 to 7
        term.bin(i, 3)
        term.char(" ")


DAT

title   byte    "TV Terminal Demo",13,13,0
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

