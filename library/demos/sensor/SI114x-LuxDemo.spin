{
    --------------------------------------------
    Filename: SI114x-LuxDemo.spin
    Author: Jesse Burt
    Description: Demo of the Si114x driver:
        Display illuminance in lux
    Copyright (c) 2022
    Started Jul 4, 2022
    Updated Jul 5, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 1_000_000                     ' max is 3_400_000
' --

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    si      : "sensor.light.si114x"

PUB Main{} | luxsc

    setup{}

    si.preset_als{}

    repeat
        ser.position(0, 3)
        luxsc := si.lux{}
        ser.printf2(@"lux: %6.6d.%01.1d", (luxsc / 10), ||(luxsc // 10))

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if si.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.strln(string("SI114x driver started"))
    else
        ser.strln(string("SI114x driver failed to start - halting"))
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

