{
---------------------------------------------------------------------------------------------------
    Filename:       SSD130X-Demo.spin
    Description:    SSD130X-specific setup for graphics demo
    Author:         Jesse Burt
    Started:        Feb 16, 2022
    Updated:        Feb 2, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

' Uncomment the below to build for an SSD1309 (if unspecified, the build will target SSD1306)
'#define SSD1309
'#pragma exportdef(SSD1309)

' Uncomment the below to build for an SPI-connected display (SSD1306 or SSD1309; default is I2C)
'#define SSD130X_SPI
'#pragma exportdef(SSD130X_SPI)

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    fnt:    "font.5x8"
    time:   "time"
    disp:   "display.oled.ssd130x" | WIDTH=128, HEIGHT=64, ...
                                    {SPI}   CS=0, DC=1, RST=2, MOSI=3, SCK=4, ...
                                    {I2C}   SCL=28, SDA=29, I2C_FREQ=1_000_000, I2C_ADDR=%0

PUB main()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( disp.start() )
        ser.strln(@"SSD130X driver started")
        disp.char_attrs(disp.TERMINAL)
        disp.set_font(fnt.ptr(), fnt.setup())
    else
        ser.strln(@"SSD130X driver failed to start - halting")
        repeat

    disp.preset_128x()
    disp.mirror_h(FALSE)
    disp.mirror_v(FALSE)
    _time := 5_000                              ' time each demo runs (ms)

    demo()                                      ' start demo

{ demo routines (common to all display types) included here }
#include "GFXDemo-common.spinh"

DAT
    _drv_name   byte    "SSD130X", 0


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

