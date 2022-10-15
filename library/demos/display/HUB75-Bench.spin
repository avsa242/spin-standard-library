{
    --------------------------------------------
    Filename: HUB75-Bench.spin
    Description: HUB75-specific setup for graphics benchmark
    Author: Jesse Burt
    Copyright (c) 2022
    Started: Feb 19, 2022
    Updated: Feb 19, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    WIDTH       = 64
    HEIGHT      = 32

{ HUB75 configuration }
    RGB_BASEPIN = 0
    ADDR_BASEPIN= 6
    CLKPIN      = 10
    LATPIN      = 11
    BLPIN       = 12
' --

    BPP         = disp#BYTESPERPX
    BYTESPERLN  = WIDTH * BPP
    BUFFSZ      = (WIDTH * HEIGHT)

OBJ

    cfg     : "boardcfg.flip"
    disp    : "display.led.hub75"

VAR

#ifndef GFX_DIRECT
    byte _framebuff[BUFFSZ]                     ' display buffer
#else
    byte _framebuff                             ' dummy VAR for GFX_DIRECT
#endif

PUB Main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if disp.startx(RGB_BASEPIN, ADDR_BASEPIN, BLPIN, CLKPIN, LATPIN, WIDTH, HEIGHT, @_framebuff)
        ser.printf1(string("%s driver started"), @_drv_name)
        disp.fontspacing(1, 0)
        disp.fontscale(1)
        disp.fontsize(fnt#WIDTH, fnt#HEIGHT)
        disp.fontaddress(fnt.baseaddr{})
    else
        ser.printf1(string("%s driver failed to start - halting"), @_drv_name)
        repeat


    benchmark{}                                      ' start demo

{ benchmark routines (common to all display types) included here }
#include "GFXBench-common.spinh"

DAT
    _drv_name   byte    "HUB75", 0

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
