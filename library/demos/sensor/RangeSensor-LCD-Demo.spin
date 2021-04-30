{
    --------------------------------------------
    Filename: RangeSensor-LCD-Demo.spin
    Description: Demo of the ultrasonic/laser
        range sensor driver
        * PING))) Parallax #28015
        * LaserPing Parallax #28041
    Author: Chris Savage, Jeff Martin
    Modified by: Jesse Burt
    Created May 8, 2006
    Updated May 24, 2020
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Ping_Demo.spin, originally by
        Chris Savage and Jeff Martin (Copyright 2006 Parallax, inc)
}

CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' -- User-modifiable constants
' Ultrasonic or LaserPing
    PING_PIN    = 0

' Serial LCD (Parallax #27977: 2 line, #27979: 4 line)
    LCD_PIN     = 16
    LCD_BAUD    = 19_200                        ' 2400, 9600, 19_200
    LCD_LINES   = 4                             ' 2, 4
' --

OBJ

    lcd     : "display.lcd.serial"
    ping    : "sensor.range.ultrasonic"
    int     : "string.integer"
    time    : "time"

PUB Main{} | mm, inches

    setup{}
    lcd.printf1(string("PING))) Demo\rInches      -\rCentimeters -"), 0)
    if lookdown(LCD_PIN: 0..31)
        repeat
            inches := ping.inches(PING_PIN)
            lcd.position(16, 1)
            lcd.dec(inches)
            lcd.str(string(".0 "))

            mm := ping.millimeters(PING_PIN)
            lcd.position(14, 2)
            lcd.str(int.decpadded((mm / 10), 3))
            lcd.char(".")
            lcd.str(int.decpadded((mm // 10), 1))
            time.msleep(100)

PUB Setup

    lcd.start(LCD_PIN, LCD_BAUD, LCD_LINES)
    lcd.cursormode(0)
    lcd.enablebacklight(true)
    lcd.clear{}

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
