{
---------------------------------------------------------------------------------------------------
    Filename:       SSD1331-Demo.spin
    Description:    SSD1331-specific setup for graphics demo
    Author:         Jesse Burt
    Started:        Feb 17, 2022
    Updated:        Jan 22, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    fnt:    "font.5x8"
    time:   "time"
    disp:   "display.oled.ssd1331" | WIDTH=96, HEIGHT=64, CS=0, SCK=1, MOSI=2, DC=3, RST=4

PUB main{}

    ser.start()
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ( disp.start() )
        ser.printf1(string("%s driver started"), @_drv_name)
        disp.set_font(fnt.ptr(), fnt.setup())
        disp.char_attrs(disp.TERMINAL)
    else
        ser.printf1(string("%s driver failed to start - halting"), @_drv_name)
        repeat


    disp.preset_96x64_hi_perf{}
    _time := 5_000                              ' time each demo runs (ms)

    demo{}                                      ' start demo

{ demo routines (common to all display types) included here }
#include "GFXDemo-common.spinh"

DAT
    _drv_name   byte    "SSD1331 (SPI)", 0


DAT
{
Copyright 2024 Jesse Burt

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
