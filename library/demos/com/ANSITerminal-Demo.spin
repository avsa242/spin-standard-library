{
    --------------------------------------------
    Filename: ANSITerminal-Demo.spin
    Description: Demo of the ANSI serial terminal driver
    Author: Jesse Burt
    Copyright (c) 2020
    Created: Jun 18, 2019
    Updated: Jan 11, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.demoboard"
    io          : "io"
    time        : "time"
    int         : "string.integer"


PUB Main | fg, bg, mouse_raw, mouse_btn, mouse_x, mouse_y

    Setup

    ser.CursorPositionReporting(FALSE)
    ser.Str(string("ANSI serial terminal demo", ser#CR, ser#LF))
    ser.Str(string("NOTE: Not all attributes supported by all terminals.", ser#CR, ser#LF))

    ser.Bold(ser#SGR_INTENSITY_BOLD)
    Demo_Text(string("BOLD"))

    ser.Bold(ser#SGR_INTENSITY_FAINT)
    Demo_Text(string("FAINT"))

    ser.Italic
    Demo_Text(string("ITALIC (or INVERSE)"))

    ser.Underline(ser#SGR_UNDERLINE)
    Demo_Text(string("UNDERLINED"))
 
    ser.Underline(ser#SGR_UNDERLINE_DBL)
    Demo_Text(string("DOUBLE UNDERLINED"))

    ser.Blink(ser#SGR_BLINKSLOW)
    Demo_Text(string("SLOW BLINKING"))

    ser.Blink(ser#SGR_BLINKFAST)
    Demo_Text(string("FAST BLINKING"))

    ser.Inverse(ser#SGR_INVERSE)
    Demo_Text(string("INVERSE"))

    ser.Conceal(ser#SGR_CONCEAL)
    Demo_Text(string("CONCEALED"))

    ser.Strikethrough(ser#SGR_STRIKETHRU)
    Demo_Text(string("STRIKETHROUGH"))

    ser.Framed
    Demo_Text(string("FRAMED"))

    ser.Encircle
    Demo_Text(string("ENCIRCLED"))

    ser.Overline
    Demo_Text(string("OVERLINED"))

    repeat bg from 40 to 47
        repeat fg from 30 to 37
            ser.Color(fg, bg)
            ser.Str(string(" COLORED "))
        ser.Newline
    ser.Color(39, 49)

    repeat 5
        ser.MoveUp(1)
        time.Sleep(1)
    repeat 5
        ser.MoveDown(1)
        time.Sleep(1)

    Demo_Text(string("Hide Cursor"))
    ser.HideCursor
    time.Sleep(3)

    Demo_Text(string("Show cursor"))
    ser.ShowCursor
    time.Sleep(3)

    Demo_Text(string("Window scrolling"))
    repeat 5
        ser.ScrollUp(1)
        time.MSleep(500)

    repeat 5
        ser.ScrollDown(1)
        time.MSleep(500)

    ser.Newline
    ser.CursorPositionReporting(TRUE)

    ser.Position(0, 28)
    ser.Str(string("Mouse reporting (hold down a mouse button to update current position):"))

    repeat
        ser.Position(5, 29)
        mouse_raw := ser.MouseCursorPosition
        mouse_btn := mouse_raw.byte[2]
        mouse_y := mouse_raw.byte[1]
        mouse_x := mouse_raw.byte[0]
        ser.Str(string("X: "))
        ser.Str(int.DecPadded(mouse_x, 3))
        ser.Str(string("  Y: "))
        ser.Str(int.DecPadded(mouse_y, 3))
        ser.Str(string("  Button: "))
        ser.Str(int.DecPadded(mouse_btn, 2))

    FlashLED(LED, 100)

PUB Demo_Text(inp_text)

    ser.Str(string("This is "))
    ser.Str(inp_text)
    ser.Newline
    ser.Reset

PUB Setup

    repeat until ser.StartRxTx (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(100)
    ser.Reset
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))

#include "lib.utility.spin"

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
