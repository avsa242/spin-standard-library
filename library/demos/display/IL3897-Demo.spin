{
    --------------------------------------------
    Filename: IL3897-Demo.spin
    Author: Jesse Burt
    Description: IL3897-specific setup for E-Ink/E-Paper graphics demo
    Copyright (c) 2023
    Started: Feb 21, 2021
    Updated: Jan 2, 2024
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
' --

OBJ

    cfg:    "boardcfg.flip"
    epaper: "display.epaper.il3897" | WIDTH=122, HEIGHT=250, ...
                                        CS=16, SCK=17, MOSI=18, DC=19, RST=20, BUSY=21


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

    epaper.preset_2p13_bw{}

    demo{}                                      ' start demo
    repeat

{ demo routines (common to all display types) included here }
#include "EInkDemo-common.spinh"

DAT
    _drv_name   byte    "IL3897 (SPI)", 0

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

