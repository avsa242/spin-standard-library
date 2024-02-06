{
---------------------------------------------------------------------------------------------------
    Filename:       LPS25-Demo.spin
    Description:    LPS25 driver demo (pressure, temperature data output)
    Author:         Jesse Burt
    Started:        Jun 22, 2021
    Updated:        Feb 6, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    NOTE: The driver defaults to an I2C connection (PASM-based), if nothing is explicitly specified
        when building.
}

' Uncomment the two lines below to use an SPI-connected device
'#define LPS25_SPI
'#pragma exportdef(LPS25_SPI)

' Uncomment the two lines below to use an SPI-connected device (bytecode/cogless SPI engine)
'   NOTE: LPS25_SPI above must also be uncommented to enable this.
'#define LPS25_SPI_BC
'#pragma exportdef(LPS25_SPI_BC)

' Uncomment the two lines below to use an I2C-connected device (bytecode/cogless I2C engine)
'#define LPS25_I2C_BC
'#pragma exportdef(LPS25_I2C_BC)

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.pressure.lps25" | {I2C} SCL=28, SDA=29, I2C_FREQ=100_000, I2C_ADDR=0, ...
                                        {SPI} CS=16, SCK=17, MOSI=18, MISO=18
    time:   "time"
'   NOTE: If LPS25_SPI is #defined, and MOSI_PIN and MISO_PIN are the same,
'   the driver will attempt to start in 3-wire SPI mode.
'   SCK=SPC, MOSI=SDI, MISO=SDO

PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"LPS25 driver started")
    else
        ser.strln(@"LPS25 driver failed to start - halting")
        repeat

    sensor.preset_active()                       ' set defaults, but enable
                                                '   sensor power
    demo()

#include "pressdemo.common.spinh"               ' code common to all pressure demos


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

