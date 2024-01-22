{
---------------------------------------------------------------------------------------------------
    Filename:       LCD-Serial-Demo.spin
    Description:    Demo of the HD44780 serial LCD driver
        Works with e.g.:
            Parallax #27977 (2x16), #27979 (4x20)
    Author:         Jesse Burt
    Started:        Apr 29, 2006
    Updated:        Jan 22, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' -- User-defined constants
    LCD_PIN     = 16
    LCD_BAUD    = 19_200                        ' 2400, 9600, 19200 (must match DIP switches)
    LCD_LINES   = 4
' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    disp:   "display.lcd.serial"

PUB main{}

    ser.start()
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    disp.startx(LCD_PIN, LCD_BAUD, LCD_LINES)
    ser.strln(string("HD44780 driver started (Serial)"))

    time.msleep(1_000)
    disp.curs_mode(0)                            ' cursor off
    disp.backlight_ena(1)

    demo{}

#include "alphanum-disp-demo.common.spinh"

DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

