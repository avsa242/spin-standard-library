{
    --------------------------------------------
    Filename: TCS3x7x-Demo.spin
    Author: Jesse Burt
    Description: Demo of the TCS3x7x driver
    Copyright (c) 2022
    Started: Jun 24, 2018
    Updated: Jan 31, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    I2C_SCL         = 28
    I2C_SDA         = 29
    I2C_FREQ        = 400_000

' I/O Pin connected to the (optional) on-board white LED
    LED_ENABLED     = TRUE
    WHITE_LED_PIN   = 25
' --

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    io  : "io"
    rgb : "sensor.color.tcs3x7x"

PUB Main{}

    setup{}
    rgb.preset_active{}                         ' default settings, but enable
                                                '   sensor power
    repeat
        rgb.opmode(rgb#RUN)
        if LED_ENABLED                          ' if LED is enabled,
            io.high(WHITE_LED_PIN)              '   illuminate the sample
        repeat until rgb.dataready{}            ' wait for new sensor data
        rgb.opmode(rgb#STDBY)                   ' pause sensor while processing
        if LED_ENABLED
            io.low(WHITE_LED_PIN)

        rgb.measure{}

        ser.position(0, 3)
        ser.printf1(string("Clear: %x\n"), rgb.lastclear{})
        ser.printf1(string("Red:   %x\n"), rgb.lastred{})
        ser.printf1(string("Green: %x\n"), rgb.lastgreen{})
        ser.printf1(string("Blue:  %x\n"), rgb.lastblue{})

PUB Setup{}

    if LED_ENABLED
        io.output(WHITE_LED_PIN)                ' turn off the LED, initially
        io.low(WHITE_LED_PIN)

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if rgb.startx(I2C_SCL, I2C_SDA, I2C_FREQ)
        ser.strln(string("TCS3X7X driver started"))
    else
        ser.strln(string("TCS3X7X driver failed to start - halting"))
        repeat

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

