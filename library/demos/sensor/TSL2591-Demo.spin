{
    --------------------------------------------
    Filename: TSL2591-Demo.spin
    Description: Demo of the TSL2591 driver
    Author: Jesse Burt
    Copyright (c) 2022
    Started Nov 23, 2019
    Updated Jul 24, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
' --

    DAT_COL     = 20

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    tsl2591 : "sensor.light.tsl2591"

PUB Main{} | tmp, ir, full

    setup{}

    tsl2591.preset_als{}                        ' set up for ambient light sensing

    repeat
        repeat until tsl2591.dataready{}
        tmp := tsl2591.alsdata{}
        ir := tmp.word[1]
        full := tmp.word[0]                     ' full-spectrum: IR + visible
        ser.position(0, 3)
        ser.printf1(string("IR: %04.4x\n\r"), ir)
        ser.printf1(string("Full: %04.4x"), full)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if tsl2591.startx(SCL_PIN, SDA_PIN, I2C_FREQ)
        ser.strln(string("TSL2591 driver started"))
    else
        ser.strln(string("TSL2591 driver failed to start - halting"))
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

