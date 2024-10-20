{
---------------------------------------------------------------------------------------------------
    Filename:       HD44780-Demo.spin
    Description:    Demo of the HD44780 LCD driver
    Author:         Jesse Burt
    Started:        Sep 8, 2021
    Updated:        Jan 22, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 100_000                       ' max is 100_000
    ADDR_BITS   = %111                          ' %000 (def) .. %111
' --

OBJ

    cfg :   "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    disp:   "display.lcd-alpha.hd44780"

PUB main{}

    ser.start()
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if disp.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS)
        ser.strln(string("HD44780 driver started (I2C)"))
    else
        ser.strln(string("HD44780 driver failed to start - halting"))
        repeat

    disp.reset{}
    disp.backlight_ena(1)

    demo{}

#include "alphanum-disp-demo.common.spinh"

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
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

