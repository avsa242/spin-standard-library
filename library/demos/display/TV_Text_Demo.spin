{
    --------------------------------------------
    Filename: TV_Text_Demo.spin
    Author: Jesse Burt
    Description: Demo of the 40x13 text composite
        TV driver
        (based on demo originally by Chip Gracey)
    Started 2006
    Updated Sep 8, 2020
    See end of file for terms of use.
    --------------------------------------------
}

''***************************************
''*  TV Text Demo v1.0                  *
''*  Author: Chip Gracey                *
''*  Copyright (c) 2006 Parallax, Inc.  *
''*  See end of file for terms of use.  *
''***************************************

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    TV_BASEPIN  = cfg#VIDEO

' --

OBJ

    cfg     : "core.con.boardcfg.demoboard"
    term    : "display.tv.text"

PUB start | i

    term.start(TV_BASEPIN)
    term.str(string(13, "   TV Text Demo...", 13, 13, $C, 5, " OBJ and VAR require only 2.8KB ", $C, 1))

    repeat 14
        term.char(" ")

    repeat i from $0E to $FF
        term.char(i)

    term.str(string($C, 6, "     Uses internal ROM font     ", $C, 2))

    repeat
        term.position(16, 12)
        term.hex(i++, 8)

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
