{
    --------------------------------------------
    Filename: Il3820-Demo.spin
    Description: IL3820-specific setup for E-Ink/E-Paper graphics demo
    Author: Jesse Burt
    Copyright (c) 2023
    Started: Jul 2, 2022
    Updated: Aug 8, 2023
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

OBJ

    cfg:    "boardcfg.flip"
    epaper: "display.epaper.il3820" | WIDTH=128, HEIGHT=296, ...
                                        CS=21, SCK=20, MOSI=19, DC=18, RST=17, BUSY=16

PUB main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ( epaper.start() )
        ser.printf1(string("%s driver started"), @_drv_name)
        epaper.set_font(fnt.ptr(), fnt.setup())
    else
        ser.printf1(string("%s driver failed to start - halting"), @_drv_name)
        repeat

    epaper.preset_2p9_bw{}
    demo{}                                      ' start demo
    repeat

{ demo routines (common to all display types) included here }
#include "EInkDemo-common.spinh"

DAT
    _drv_name   byte    "IL3820 (SPI)", 0

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

