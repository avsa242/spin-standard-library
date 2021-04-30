{
    --------------------------------------------
    Filename: RangeSensor-Serial-Demo.spin
    Description: Demo of the ultrasonic/laser
        range sensor driver (serial display)
        * PING))) Parallax #28015
        * LaserPing Parallax #28041
    Author: Chris Savage, Jeff Martin
    Modified by: Jesse Burt
    Created May 8, 2006
    Updated Apr 30, 2021
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

    SER_BAUD    = 115_200
' --

OBJ

    ser     : "com.serial.terminal.ansi"
    ping    : "sensor.range.ultrasonic"
    int     : "string.integer"
    time    : "time"

PUB Main{} | mm, inches

    setup{}
    ser.printf1(string("PING))) Demo\nInches      -\nCentimeters -"), 0)
    repeat
        inches := ping.inches(PING_PIN)
        ser.position(16, 1)
        ser.dec(inches)
        ser.str(string(".0 "))

        mm := ping.millimeters(PING_PIN)
        ser.position(14, 2)
        ser.str(int.decpadded((mm / 10), 3))
        ser.char(".")
        ser.str(int.decpadded((mm // 10), 1))
        time.msleep(100)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}

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
