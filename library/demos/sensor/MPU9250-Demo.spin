{
    --------------------------------------------
    Filename: MPU9250-Demo.spin
    Author: Jesse Burt
    Description: MPU9250 driver demo
        * 9DoF data output
    Copyright (c) 2022
    Started Aug 12, 2017
    Updated Nov 26, 2022
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DMPU9250_I2C (default if none specified)
        -DMPU9250_I2C_BC
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    { I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000
    ADDR_BITS   = 0
' --

OBJ

    cfg: "boardcfg.flip"
    sensor: "sensor.imu.9dof.mpu9250"
    ser: "com.serial.terminal.ansi"
    time: "time"

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(10)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if (sensor.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS))
        ser.strln(string("MPU9250 driver started"))
    else
        ser.strln(string("MPU9250 driver failed to start - halting"))
        repeat

    sensor.preset_active{}

    repeat
        ser.pos_xy(0, 3)
        show_accel_data{}
        show_gyro_data{}
        show_mag_data{}
        if (ser.rx_check{} == "c")
            cal_accel{}
            cal_gyro{}
            cal_mag{}

#include "acceldemo.common.spinh"
#include "gyrodemo.common.spinh"
#include "magdemo.common.spinh"

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

