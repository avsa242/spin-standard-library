{
    --------------------------------------------
    Filename: HTU21D-Demo.spin
    Author: Jesse Burt
    Description: HTU21D driver demo
        * Temp/RH data output
    Copyright (c) 2022
    Started Jun 16, 2021
    Updated Jul 16, 2022
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DHTU21D_I2C (default if none specified)
        -DHTU21D_I2C_BC
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    { I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
' --

OBJ

    cfg:    "boardcfg.flip"
    sensr:  "sensor.temp_rh.htu21d"
    ser:    "com.serial.terminal.ansi"
    time:   "time"

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(10)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if (sensr.startx(SCL_PIN, SDA_PIN, I2C_FREQ))
        ser.strln(string("HTU21D driver started"))
    else
        ser.strln(string("HTU21D driver failed to start - halting"))
        repeat

    sensr.tempscale(sensr#C)
    demo{}

#include "temp_rhdemo.common.spinh"             ' code common to all temp/RH demos

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

