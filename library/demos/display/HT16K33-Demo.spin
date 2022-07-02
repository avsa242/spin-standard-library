{
    --------------------------------------------
    Filename: HT16K33-Demo.spin
    Description: HT16K33-specific setup for small matrix graphics demo
    Author: Jesse Burt
    Copyright (c) 2022
    Started: Jul 1, 2022
    Updated: Jul 2, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    WIDTH       = 8
    HEIGHT      = 8

{ I2C configuration }
    SCL_PIN     = 14
    SDA_PIN     = 15
    ADDR_BITS   = 0
    I2C_FREQ    = 400_000
' --

    BPP         = disp#BYTESPERPX
    BYTESPERLN  = WIDTH * BPP
    BUFFSZ      = ((WIDTH * HEIGHT) * BPP) / 8

OBJ

    cfg     : "core.con.boardcfg.flip"
    disp    : "display.led.ht16k33"

VAR

    byte _framebuff[BUFFSZ]                     ' display buffer

PUB Main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if disp.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS, WIDTH, HEIGHT, @_framebuff)
        ser.printf1(string("%s driver started"), @_drv_name)
        disp.defaults{}
        disp.fontsize(fnt#WIDTH, fnt#HEIGHT)
        disp.fontaddress(fnt.baseaddr{})
    else
        ser.printf1(string("%s driver failed to start - halting"), @_drv_name)
        repeat

    _time := 5_000                              ' time each demo runs (ms)

    demo{}                                      ' start demo

    repeat

{ demo routines (common to small dot-matrix type displays) included here }
#include "SmallMatrixDemo-common.spinh"

DAT

    _drv_name   byte    "HT16K33 (I2C)", 0

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
