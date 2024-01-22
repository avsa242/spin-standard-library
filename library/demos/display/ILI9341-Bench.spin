{
---------------------------------------------------------------------------------------------------
    Filename:       ILI9341-Demo.spin
    Description:    ILI9341-specific setup for benchmark
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
    time:   "time"
    fnt:    "font.5x8"
    disp:   "display.lcd.ili9341" | WIDTH=320, HEIGHT=240, ...
                                    DBASEPIN=0, RST=8, CS=9, DC=10, WRX=11, RDX=12

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

    { uncomment one of the following presets if it applies to your LCD module }
    disp.preset_hiletgo_2p4_320x240_land_up()
'    disp.preset_hiletgo_2p4_320x240_land_down()
'    disp.preset_hiletgo_2p4_240x320_port_up()
'    disp.preset_hiletgo_2p4_240x320_port_down()


    { OR, change these to suit the orientation of your display }
'    disp.rotation(0)                           ' 0, 1
'    disp.mirror_h(false)
'    disp.mirror_v(false)

    benchmark{}                                      ' start demo

{ demo routines (common to all display types) included here }
#include "GFXBench-common.spinh"

DAT
    _drv_name   byte    "ILI9341 (8bit Par.)", 0

CON

    WIDTH   = disp.WIDTH
    HEIGHT  = disp.HEIGHT

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

