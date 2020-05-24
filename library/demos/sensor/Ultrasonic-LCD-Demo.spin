{
    --------------------------------------------
    Filename: Ultrasonic-LCD-Demo.spin
    Description: Demonstrates functionality of the
     ultrasonic range sensor driver
    Author: Chris Savage, Jeff Martin
    Modified by: Jesse Burt
    Created May 8, 2006
    Updated May 24, 2020
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is a derivative of Ping_Demo.spin,
        originally by Chris Savage, Jeff Martin
        The original header is preserved below
}

''***************************************
''*         Ping))) Demo V1.2           *
''* Author:  Chris Savage & Jeff Martin *
''* Copyright (c) 2006 Parallax, Inc.   *
''* See end of file for terms of use.   *
''* Started: 05-08-2006                 *
''***************************************
''
'' Version 1.2 - Updated March 26, 2008 by Jeff Martin to use updated Debug_LCD.

CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

    PING_PIN    = 0                                         ' I/O Pin For PING)))
    LCD_PIN     = 1                                         ' I/O Pin For term
    LCD_BAUD    = 19_200                                    ' term Baud Rate
    LCD_LINES   = 4                                         ' Parallax 4X20 Serial term (#27979)

OBJ

    term    : "display.lcd.serial"
    ping    : "sensor.range.ultrasonic"
    num     : "string.integer"
    time    : "time"

PUB Main | range

    Setup

    repeat
        term.Position(15, 2)
        range := ping.Inches(PING_PIN)
        term.Dec(range)
        term.Str(string(".0 "))
        term.Position(14, 3)
        range := ping.Millimeters(PING_Pin)
        term.Str(num.DecPadded(range / 10, 3))
        term.Char(".")
        term.Str(num.DecPadded(range // 10, 1))
        time.MSleep(100)

PUB Setup

    term.Start(LCD_PIN, LCD_BAUD, LCD_LINES)                ' Initialize term Object
    term.CursorMode(0)                                       ' Turn Off Cursor
    term.EnableBacklight(true)                              ' Turn On Backlight
    term.Clear
    term.Str(string("PING))) Demo", 13, 13, "Inches      -", 13, "Centimeters -"))

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
