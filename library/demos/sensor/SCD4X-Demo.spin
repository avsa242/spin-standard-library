{
    --------------------------------------------
    Filename: SCD4X-Demo.spin
    Author: Jesse Burt
    Description: SCD4X driver demo
        * CO2 data output
    Copyright (c) 2023
    Started Aug 6, 2022
    Updated Jul 15, 2023
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DSCD4X_I2C (default if none specified)
        -DSCD4X_I2C_BC
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
' --

OBJ

    cfg: "boardcfg.flip"
    env: "sensor.co2.scd4x" | SCL=28, SDA=29, I2C_FREQ=400_000
    ser: "com.serial.terminal.ansi"
    time: "time"

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(20)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ( env.start() )
        ser.strln(string("SCD4X driver started"))
    else
        ser.strln(string("SCD4X driver failed to start - halting"))
        repeat

    env.preset_active{}

    env.co2_set_alt_comp(0)                     ' your location's altitude above sea level (m)

    demo{}

#include "co2demo.common.spinh"                 ' code common to all CO2 demos

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

