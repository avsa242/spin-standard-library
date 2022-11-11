{
    --------------------------------------------
    Filename: TCS3x7x-Demo.spin
    Author: Jesse Burt
    Description: Demo of the TCS3x7x driver
    Copyright (c) 2022
    Started: Jun 24, 2018
    Updated: Nov 9, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    { I2C configuration }
    I2C_SCL         = 28
    I2C_SDA         = 29
    I2C_FREQ        = 400_000

    { optional white LED }
    LED_ENABLED     = TRUE
    WHITE_LED_PIN   = 25
' --

OBJ

    cfg : "boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    rgb : "sensor.light.tcs3x7x"

PUB main{}

    setup{}
    rgb.preset_active{}                         ' default settings, but enable
                                                '   sensor power
    repeat
        rgb.opmode(rgb#RUN)
        if (LED_ENABLED)                        ' if LED is enabled,
            outa[WHITE_LED_PIN] := 1            '   illuminate the sample
        repeat until rgb.rgbw_data_rdy{}        ' wait for new sensor data
        rgb.opmode(rgb#STDBY)                   ' pause sensor while processing
        if (LED_ENABLED)
            outa[WHITE_LED_PIN] := 0

        rgb.measure{}

        ser.pos_xy(0, 3)
        ser.printf1(string("White: %4.4x\n\r"), rgb.last_white{})
        ser.printf1(string("Red:   %4.4x\n\r"), rgb.last_red{})
        ser.printf1(string("Green: %4.4x\n\r"), rgb.last_green{})
        ser.printf1(string("Blue:  %4.4x\n\r"), rgb.last_blue{})

PUB setup{}

    if (LED_ENABLED)
        outa[WHITE_LED_PIN] := 0                ' turn off the LED, initially
        dira[WHITE_LED_PIN] := 1

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if (rgb.startx(I2C_SCL, I2C_SDA, I2C_FREQ))
        ser.strln(string("TCS3X7X driver started"))
    else
        ser.strln(string("TCS3X7X driver failed to start - halting"))
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

