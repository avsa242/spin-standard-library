{
---------------------------------------------------------------------------------------------------
    Filename:       LSM9DS1-Demo.spin
    Description:    LSM9DS1 driver demo
    Author:         Jesse Burt
    Started:        Aug 12, 2017
    Updated:        Jan 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    Build-time symbols supported by driver:
        -DLSM9DS1_SPI
        -DLSM9DS1_SPI_BC
        -DLSM9DS1_I2C (default if none specified)
        -DLSM9DS1_I2C_BC
}

' uncomment the two lines below to use SPI
#define LSM9DS1_SPI
#pragma exportdef(LSM9DS1_SPI)

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


OBJ

    cfg:    "boardcfg.flip"

    { to use 3-wire SPI, set MOSI and MISO to the same pin }
    sensor: "sensor.imu.9dof.lsm9ds1" | {I2C}SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=0, ...
                                        {SPI}CS_AG=2, CS_M=3, SCK=0, MOSI=1, MISO=1
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"LSM9DS1 driver started")
    else
        ser.strln(@"LSM9DS1 driver failed to start - halting")
        repeat

    sensor.preset_active()

    repeat
        ser.pos_xy(0, 3)
        show_accel_data()
        show_gyro_data()
        show_mag_data()
        if ( ser.rx_check() == "c" )
            cal_accel()
            cal_gyro()
            cal_mag()

#include "acceldemo.common.spinh"
#include "gyrodemo.common.spinh"
#include "magdemo.common.spinh"

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

