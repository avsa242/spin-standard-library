{
    --------------------------------------------
    Filename: SGP30-Demo.spin
    Author: Jesse Burt
    Description: Demo of the SGP30 driver
    Copyright (c) 2021
    Started Nov 20, 2020
    Updated Jan 30, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 24
    I2C_SDA     = 25
    I2C_HZ      = 400_000                       ' 400_000 max
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    iaq     : "sensor.iaq.sgp30.i2c"
    int     : "string.integer"

VAR

    byte _sn[6]
    byte _tmp[6]

PUB Main{} | i, tmp

    setup{}
    iaq.reset{}                                 ' reset first for reliability

    bytefill(@_sn, 0, 6)
    iaq.serialnum(@_sn)

    ser.str(string("SN: "))
    repeat i from 0 to 5
        ser.hex(_sn[i], 2)

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
    if iaq.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.strln(string("SGP30 driver started"))
    else
        ser.strln(string("SGP30 driver failed to start - halting"))
        repeat

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
