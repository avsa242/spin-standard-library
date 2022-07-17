{
    --------------------------------------------
    Filename: LIS3DH-Demo.spin
    Author: Jesse Burt
    Description: LIS3DH driver demo
        * 3DoF data output
    Copyright (c) 2022
    Started Aug 12, 2017
    Updated Jul 13, 2022
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DLIS3DH_SPI
        -DLIS3DH_SPI_BC
        -DLIS3DH_I2C (default if none specified)
        -DLIS3DH_I2C_BC
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    { I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
    ADDR_BITS   = 0                             ' 0, 1

    { SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1                             ' SCL
    MOSI_PIN    = 2                             ' SDA
    MISO_PIN    = 3                             ' SDO
'   NOTE: If LIS3DH_SPI is #defined, and MOSI_PIN and MISO_PIN are the same,
'   the driver will attempt to start in 3-wire SPI mode.' --

OBJ

    cfg: "core.con.boardcfg.flip"
    imu: "sensor.accel.3dof.lis3dh"
    ser: "com.serial.terminal.ansi"
    time: "time"

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(10)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef LIS3DH_SPI
    if (imu.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
#else
    if (imu.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS))
#endif
        ser.strln(string("LIS3DH driver started"))
    else
        ser.strln(string("LIS3DH driver failed to start - halting"))
        repeat

    imu.preset_active{}

    demo{}

#include "imudemo-common.spinh"                 ' code common to all IMU demos

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

