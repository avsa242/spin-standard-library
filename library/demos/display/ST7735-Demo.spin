{
    --------------------------------------------
    Filename: ST7735-Demo.spin
    Description: ST7735-specific setup for graphics demo
    Author: Jesse Burt
    Copyright (c) 2023
    Started: Feb 17, 2022
    Updated: Jul 24, 2023
    See end of file for terms of use.
    --------------------------------------------

    Build options available:
        -DST7789 - build for ST7789 displays; if not defined, ST7735 will be chosen)
    NOTE: Due to memory constraints on the P1, buffered displays are not supported for this driver
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
' --

OBJ

    cfg:    "boardcfg.flip"
    disp:   "display.lcd.st7735" | WIDTH=128, HEIGHT=128, CS=0, DC=1, RST=2, MOSI=3, SCK=4

PUB main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ( disp.start() )
        ser.printf1(string("%s driver started"), @_drv_name)
        disp.font_spacing(1, 0)
        disp.font_scl(1, 1)
        disp.font_sz(fnt#WIDTH, fnt#HEIGHT)
        disp.font_addr(fnt.ptr{})
    else
        ser.printf1(string("%s driver failed to start - halting"), @_drv_name)
        repeat


    { Presets for ST7735R }
'    disp.preset_adafruit_1p44_128x128_land_up{}
'    disp.preset_adafruit_1p44_128x128_land_down{}
'    disp.preset_adafruit_1p44_128x128_port_up{}
'    disp.preset_adafruit_1p44_128x128_port_down{}

    { Presets for ST7789VW }
    disp.preset_adafruit_1p3_240x240_land_up{}
'    disp.preset_adafruit_1p3_240x240_land_down{}
'    disp.preset_adafruit_1p3_240x240_port_up{}
'    disp.preset_adafruit_1p3_240x240_port_down{}


    _time := 5_000                              ' time each demo runs (ms)

    demo{}                                      ' start demo

{ demo routines (common to all display types) included here }
#include "GFXDemo-common.spinh"

DAT
#ifdef ST7789
    _drv_name   byte    "ST7789 (SPI)", 0
#else
    _drv_name   byte    "ST7735 (SPI)", 0
#endif

CON

    WIDTH   = disp.WIDTH
    HEIGHT  = disp.HEIGHT

DAT
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
