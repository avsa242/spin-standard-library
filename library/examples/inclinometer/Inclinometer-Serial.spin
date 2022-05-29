{
    --------------------------------------------
    Filename: Inclinometer-Serial.spin
    Author: Jesse Burt
    Description: Simple inclinometer using an LSM9DS1 IMU
        (serial display)
    Copyright (c) 2022
    Started Jan 29, 2020
    Updated May 29, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    { I2C & SPI configuration }
    CS_M_PIN    = 0                             ' SPI
    CS_AG_PIN   = 1                             ' SPI
    SCL_PIN     = 2                             ' I2C, SPI
    SDA_PIN     = 3                             ' I2C, SPI
    SDO_PIN     = 4                             ' SPI
                                                ' (define same as SDA_PIN for 3-wire SPI)
    I2C_HZ      = 400_000
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi-new"
    time    : "time"
    imu     : "sensor.imu.9dof.lsm9ds1"

PUB Main{} | pitch, roll

    setup{}

    { set the accelerometer to a lower, less noisy data rate }
    imu.preset_active{}
    imu.acceldatarate(59)
    imu.accelhighres(true)
    imu.fifoenabled(false)
    repeat
        repeat until imu.acceldataready{}
        ser.position(0, 3)

        { clamp angles to +/- 90deg }
        pitch := -90_00 #> imu.pitch{} <# 90_00
        roll := -90_00 #> imu.roll{} <# 90_00

        ser.printf2(@("Pitch: %d.%1.1d    \n\r"), pitch/100, ||(pitch//100)/10)
        ser.printf2(@("Roll: %d.%1.1d    \n\r"), roll/100, ||(roll//100)/10)

        { Press 'z' to reset the inclinometer's 'zero'
          Ensure the chip is lying on a flat surface and the package top
          is facing up }
        if (ser.rxcheck{} == "z")
            setzero{}

PRI setZero{}
' Re-set the 'zero' of the inclinometer (set accelerometer bias offsets)
    ser.position(0, 7)
    ser.str(string("Setting zero..."))
    imu.calibrateaccel{}
    ser.positionx(0)
    ser.clearline{}

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef LSM9DS1_SPI
    if imu.startx(CS_AG_PIN, CS_M_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
#else
    if imu.startx(SCL_PIN, SDA_PIN, I2C_HZ)
#endif
        ser.strln(string("LSM9DS1 driver started"))
    else
        ser.strln(string("LSM9DS1 driver failed to start - halting"))
        repeat

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
