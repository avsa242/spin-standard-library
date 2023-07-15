{
    --------------------------------------------
    Filename: SGP30-Demo.spin
    Author: Jesse Burt
    Description: Demo of the SGP30 driver
    Copyright (c) 2023
    Started Nov 20, 2020
    Updated Jul 15, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    time:   "time"
    iaq:    "sensor.iaq.sgp30" | SCL=28, SDA=29, I2C_FREQ=400_000

VAR

    word _sn[3]

PUB main{}

    setup{}

    iaq.reset{}                                 ' reset first for reliability

    iaq.serial_num(@_sn)

    ser.printf3(@"SN: %04.4x%04.4x%04.4x\n\r", _sn[0], _sn[1], _sn[2])

    repeat
        ser.pos_xy(0, 5)
        ser.printf1(string("CO2Eq: %5.5dppm\n\r"), iaq.co2_equiv{})
        ser.printf1(string("TVOC: %5.5dppb"), iaq.tvoc{})
        time.msleep(1000)                       ' 1Hz rate for best performance

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if ( iaq.start{} )
        ser.strln(string("SGP30 driver started"))
    else
        ser.strln(string("SGP30 driver failed to start - halting"))
        repeat

DAT
{
Copyright 2023 Jesse Burt

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

