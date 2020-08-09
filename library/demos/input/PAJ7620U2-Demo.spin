{
    --------------------------------------------
    Filename: PAJ7620U2-Demo.spin
    Author: Jesse Burt
    Description: Demo of the PAJ7620U2 driver
    Copyright (c) 2020
    Started May 21, 2020
    Updated Aug 9, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000

    LED         = cfg#LED1
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    gesture : "input.gesture.paj7620u2.i2c"

VAR

    byte _ser_cog

PUB Main | gest, gestct

    Setup

    gestct := 0

    repeat
        ser.position(0, 4)
        ser.str(string("Gesture: "))
        repeat until gest := gesture.LastGesture
            time.msleep(1)
        ser.str(lookup(gest: string("RIGHT"), string("LEFT"), string("UP"), string("DOWN"), string("FORWARD"), string("BACKWARD"), string("CLOCKWISE"), string("COUNTER-CLOCKWISE"), string("WAVE")))
        ser.clearline{}
        gestct++
        ser.newline
        ser.str(string("("))
        ser.dec(gestct)
        ser.str(string(" total gestures recognized)"))
    FlashLED(LED, 100)

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))

    if gesture.Startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str(string("PAJ7620U2 driver started", ser#CR, ser#LF))
    else
        ser.str(string("PAJ7620U2 driver failed to start - halting", ser#CR, ser#LF))
        gesture.Stop
        time.MSleep(5)
        ser.Stop
        FlashLED(LED, 500)

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
