{
    --------------------------------------------
    Filename: PAJ7620U2-Demo.spin
    Author: Jesse Burt
    Description: Demo of the PAJ7620U2 driver
    Copyright (c) 2022
    Started May 21, 2020
    Updated Nov 27, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000
' --

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    gesture : "input.gesture.paj7620u2"

PUB main{} | gest, gestct

    setup{}
    gesture.powered(true)

    gestct := 0

    repeat
        ser.pos_xy(0, 4)
        ser.str(string("Gesture: "))

        { wait for gesture to be recognized }
        repeat until gest := gesture.last_gesture{}

        ser.str(lookup(gest: string("RIGHT"), string("LEFT"), string("UP"), string("DOWN"), {
}                            string("FORWARD"), string("BACKWARD"), string("CLOCKWISE"), {
}                            string("COUNTER-CLOCKWISE"), string("WAVE")))
        ser.clear_line{}
        gestct++
        ser.newline{}
        ser.printf1(string("(%d total gestures recognized)"), gestct)

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if gesture.startx(SCL_PIN, SDA_PIN, I2C_FREQ)
        ser.strln(string("PAJ7620U2 driver started"))
    else
        ser.strln(string("PAJ7620U2 driver failed to start - halting"))
        repeat

DAT
{
Copyright 2022 Jesse Burt

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

