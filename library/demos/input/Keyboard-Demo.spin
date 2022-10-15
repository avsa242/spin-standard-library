{
    --------------------------------------------
    Filename: Keyboard-Demo.spin
    Author: Chip Gracey
    Modified by: Jesse Burt
    Description: Demo of the PS/2 keyboard input driver
        Displays ASCII value of keypresses on terminal output
        (plus modifier key codes, if applicable)
    Started May 15, 2006
    Updated May 13, 2021
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is based on Keyboard_Demo.spin, originally by
        Chip Gracey
}
' Uncomment the line below to use composite video output
'#define HAS_TV

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

' Composite TV
    TV_BASEPIN  = cfg#VIDEO

' PS/2 keyboard
    KEYB_CLK    = cfg#KEYB_CLK
    KEYB_DATA   = cfg#KEYB_DATA
' --

OBJ

' Uncomment one of the boardcfg objects below for your board,
'   or define the constants above appropriately

    cfg : "boardcfg.demoboard"
'    cfg : "boardcfg.quickstart-hib"
#ifdef HAS_TV
    term: "display.tv.terminal"
#else
    term: "com.serial.terminal.ansi"
#endif
    kb  : "input.keyboard.ps2"
    time: "time"

PUB Start{}

#ifdef HAS_TV
    term.start(TV_BASEPIN)
#else
    term.start(SER_BAUD)
    time.msleep(30)
    term.clear{}
#endif
    term.str(string("Keyboard Demo...", 13, 10))

    kb.start(KEYB_CLK, KEYB_DATA)

    repeat
        term.hex(kb.getkey{}, 3)
        term.char(" ")

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
