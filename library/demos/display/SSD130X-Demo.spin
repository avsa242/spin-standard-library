{
    --------------------------------------------
    Filename: SSD130X-Demo.spin
    Description: SSD130X-specific setup for graphics demo
    Author: Jesse Burt
    Copyright (c) 2022
    Started: Feb 16, 2022
    Updated: Nov 1, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    WIDTH       = 128
    HEIGHT      = 64

{ I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    ADDR_BITS   = 0
    SCL_FREQ    = 1_000_000

{ SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2
    DC_PIN      = 3

    RES_PIN     = 4                             ' optional; -1 to disable
' --

    BPP         = disp#BYTESPERPX
    BYTESPERLN  = WIDTH * BPP
    BUFFSZ      = ((WIDTH * HEIGHT) * BPP) / 8

OBJ

    cfg     : "boardcfg.flip"
    disp    : "display.oled.ssd130x"

VAR

    byte _framebuff[BUFFSZ]                     ' display buffer

PUB main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef SSD130X_SPI
    if disp.startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, @_framebuff)
#else
#define SSD130X_I2C
    if disp.startx(SCL_PIN, SDA_PIN, RES_PIN, SCL_FREQ, ADDR_BITS, WIDTH, HEIGHT, @_framebuff)
#endif
        ser.printf1(string("%s driver started"), @_drv_name)
        disp.font_spacing(1, 0)
        disp.font_scl(1)
        disp.font_sz(fnt#WIDTH, fnt#HEIGHT)
        disp.font_addr(fnt.ptr{})
    else
        ser.printf1(string("%s driver failed to start - halting"), @_drv_name)
        repeat

    disp.preset_128x{}
    disp.mirror_h(FALSE)
    disp.mirror_v(FALSE)
    _time := 5_000                              ' time each demo runs (ms)

    demo{}                                      ' start demo

{ demo routines (common to all display types) included here }
#include "GFXDemo-common.spinh"

DAT
#ifdef SSD130X_I2C
    _drv_name   byte    "SSD130X (I2C)", 0
#elseifdef SSD130X_SPI
    _drv_name   byte    "SSD130X (SPI)", 0
#endif

{
Copyright 2022 Jesse Burt

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

