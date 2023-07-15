{
    --------------------------------------------
    Filename: PMSA003I-Demo.spin
    Author: Jesse Burt
    Description: Demo of the PMSA003I driver
    Copyright (c) 2023
    Started Aug 29, 2022
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

    cfg:  "boardcfg.flip"
    ser:  "com.serial.terminal.ansi"
    time: "time"
    iaq:  "sensor.particle.pmsa003i" | SCL=28, SDA=29, I2C_FREQ=100_000

PUB main{}

    setup{}

    repeat
        iaq.measure{}
        ser.pos_xy(0, 3)

        { unicode UTF-8 output (provides 'mu' and 'cubed' characters) }
        ser.printf1(@"PM1.0: %5.5d\302\265g/m\302\263\n\r", iaq.pm1_0{})
        ser.printf1(@"PM2.5: %5.5d\302\265g/m\302\263\n\r", iaq.pm2_5{})
        ser.printf1(@"PM10: %5.5d\302\265g/m\302\263\n\r", iaq.pm10{})

        { non-unicode output }
'        ser.printf1(@"PM1.0: %5.5dug/m^3\n\r", iaq.pm1_0{})
'        ser.printf1(@"PM2.5: %5.5dug/m^3\n\r", iaq.pm2_5{})
'        ser.printf1(@"PM10: %5.5dug/m^3\n\r", iaq.pm10{})

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(20)
    ser.clear{}

    ser.strln(@"Serial terminal started")

    if ( iaq.start() )
        ser.strln(@"PMSA003i driver started")
    else
        ser.strln(@"PMSA003i driver failed to start - halting")
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

