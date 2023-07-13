{
    --------------------------------------------
    Filename: 24XXXX-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the 24XXXX EEPROM driver
        * Memory hexdump display
    Copyright (c) 2023
    Started May 9, 2020
    Updated Jul 13, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    { memory size }
    PART        = 512                           ' kbits
' --

    MEMSIZE     = (PART / 8) * 1024

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    time:   "time"
    mem:    "memory.eeprom.24xxxx" | SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=0

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if ( mem.start() )
        ser.strln(string("24XXXX driver started"))
    else
        ser.strln(string("24XXXX driver failed to start - halting"))
        repeat

    mem.ee_size(PART)
    demo{}

#include "memdemo.common.spinh"

DAT
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

