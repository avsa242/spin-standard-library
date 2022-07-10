{
    --------------------------------------------
    Filename: SGP30-Demo.spin
    Author: Jesse Burt
    Description: Demo of the SGP30 driver
    Copyright (c) 2022
    Started Nov 20, 2020
    Updated Jul 10, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' 400_000 max
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    iaq     : "sensor.iaq.sgp30"
    int     : "string.integer"

VAR

    word _sn[3]
    byte _tmp[6]

PUB Main{} | i, tmp

    setup{}

    iaq.reset{}                                 ' reset first for reliability

    bytefill(@_sn, 0, 6)
    iaq.serialnum(@_sn)

    ser.str(string("SN: "))
    repeat i from 0 to 2
        ser.hex(_sn[i], 4)

    ser.newline

    repeat
        ser.position(0, 5)
        ser.str(string("CO2Eq: "))
        ser.str(int.decpadded(iaq.co2eq, 5))
        ser.str(string("ppm"))
        ser.newline

        ser.str(string("TVOC: "))
        ser.str(int.decpadded(iaq.tvoc, 5))
        ser.str(string("ppb"))
        ser.newline
        time.msleep(1000)                       ' 1Hz rate for best performance

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if iaq.startx(SCL_PIN, SDA_PIN, I2C_FREQ)
        ser.strln(string("SGP30 driver started"))
    else
        ser.strln(string("SGP30 driver failed to start - halting"))
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

