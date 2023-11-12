{
    --------------------------------------------
    Filename: AHT20-Demo.spin
    Author: Jesse Burt
    Description: AHT20 driver demo
        * Temp/RH data output
    Copyright (c) 2023
    Started Jun 16, 2021
    Updated Nov 12, 2023
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DAHT20_I2C (default if none specified)
        -DAHT20_I2C_BC
}
' Uncomment to use the bytecode-based I2C engine
#define AHT20_I2C_BC
#pragma exportdef(AHT20_I2C_BC)

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


OBJ

    cfg:    "boardcfg.flip"
    sensor: "sensor.temp_rh.aht20" | SCL=28, SDA=29, I2C_FREQ=400_000
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"

PUB setup{}

    ser.start()
    time.msleep(30)
    ser.clear{}
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"AHT20 driver started")
    else
        ser.strln(@"AHT20 driver failed to start - halting")
        repeat

    sensor.reset{}
    sensor.temp_scale(C)
    demo{}

#include "temp_rhdemo.common.spinh"             ' code common to all temp/RH demos

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

