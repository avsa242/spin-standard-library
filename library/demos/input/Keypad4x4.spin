{
    --------------------------------------------
    Filename: Keypad4x4.spin
    Author: Beau Schwabe
    Modified by: Jesse Burt
    Description: Demo of the 4x4 Keypad driver
    Started 2007
    Updated Apr 27, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on 4x4 keypad Reader DEMO.spin,
    originally by Beau Schwabe
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

' -- User-modifiable constants
    VGA_BASEPIN = cfg#VGA
' --

OBJ

    cfg     : "core.con.boardcfg.demoboard"
    text    : "display.vga.text"
    kp      : "input.keypad.4x4"

VAR

    word  _keypad

PUB Start{}

    text.start(VGA_BASEPIN)
    text.str(string(13, "4x4 Keypad Demo..."))
    text.str(string($A, 1, $B, 7))
    text.str(string(13, "RAW keypad value 'word'"))

    text.str(string($A, 1, $B, 13))
    text.str(string(13, "Note: Try pressing multiple keys"))

    repeat
        _keypad := kp.readkeypad{}              ' read the 4x4 keypad

        text.str(string($A, 5, $B, 2))
        text.bin(_keypad >> 0, 4)               ' Display 1st row
        text.str(string($A, 5, $B, 3))
        text.bin(_keypad >> 4, 4)               ' Display 2nd row
        text.str(string($A, 5, $B, 4))
        text.bin(_keypad >> 8, 4)               ' Display 3rd row
        text.str(string($A, 5, $B, 5))
        text.bin(_keypad >> 12, 4)              ' Display 4th row
        text.str(string($A, 5, $B, 9))
        text.bin(_keypad, 16)                   ' Display raw keypad value

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
