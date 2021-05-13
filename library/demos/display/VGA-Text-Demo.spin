{
    --------------------------------------------
    Filename: VGA-Text-Demo.spin
    Author: Chip Gracey
    Modified by: Jesse Burt
    Description: Demo of the 32x15 text VGA driver
    Started 2006
    Updated May 13, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

' -- User-modifiable constants
    VGA_BASEPIN = cfg#VGA

' --

OBJ

    cfg     : "core.con.boardcfg.demoboard"
    text    : "display.vga.text"

PUB Start | i

    text.start(VGA_BASEPIN)
    text.str(string(13,"   VGA Text Demo...", 13, 13, $C, 5, " OBJ and VAR require only 2.6KB ", $C, 1))
    repeat 14
        text.char(" ")
    repeat i from $0E to $FF
        text.char(i)
    text.str(string($C, 6, "     Uses internal ROM font     ", $C, 2))
    repeat
        text.str(string($A, 12, $B, 14))
        text.hex(i++, 8)

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

