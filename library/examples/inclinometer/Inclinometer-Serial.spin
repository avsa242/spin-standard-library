{
---------------------------------------------------------------------------------------------------
    Filename:       Inclinometer-Serial.spin2
    Description:    Simple inclinometer using an IMU and the serial terminal
    Author:         Jesse Burt
    Started:        Jan 29, 2020
    Updated:        Jan 27, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    Hardware required:
        * LSM9DS1 9DoF IMU (I2C or SPI)
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


' Uncomment these if the LSM9DS1 is connected using SPI
'#define LSM9DS1_SPI
'#pragma exportdef(LSM9DS1_SPI)

' Uncomment these to use the bytecode (cogless) SPI engine for the LSM9DS1
'#define LSM9DS1_SPI_BC
'#pragma exportdef(LSM9DS1_SPI_BC)


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"
    imu:    "sensor.imu.9dof.lsm9ds1" | {I2C}SCL=28, SDA=29, I2C_FREQ=100_000, I2C_ADDR=0, ...
                                        {SPI}CS_AG=0, CS_M=1, SCK=2, MOSI=3, MISO=4
    ' NOTE: To use SPI, uncomment #define LSM9DS1_SPI above (I2C is used by default)
    ' NOTE: For 3-wire SPI, specify MOSI and MISO as the same pin


PUB main() | pitch, roll

    setup()

    { set the accelerometer to a lower, less noisy data rate }
    imu.preset_active()
    imu.accel_data_rate(59)
    imu.accel_high_res_ena(true)
    imu.fifo_ena(false)
    repeat
        repeat until imu.accel_data_rdy()
        ser.pos_xy(0, 3)

        { clamp angles to +/- 90deg }
        pitch := -90_00 #> imu.pitch() <# 90_00
        roll := -90_00 #> imu.roll() <# 90_00

        ser.printf2(@"Pitch: %d.%1.1d    \n\r", pitch/100, ||(pitch//100)/10)
        ser.printf2(@"Roll: %d.%1.1d    \n\r", roll/100, ||(roll//100)/10)

        { Press 'z' to reset the inclinometer's 'zero'
          Ensure the chip is lying on a flat surface and the package top
          is facing up }
        if ( ser.getchar_noblock() == "z" )
            set_zero()


PRI set_zero()
' Re-set the 'zero' of the inclinometer (set accelerometer bias offsets)
    ser.pos_xy(0, 7)
    ser.puts(@"Setting zero...")
    imu.calibrate_accel()
    ser.pos_x(0)
    ser.clear_line()


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( imu.start() )
        ser.strln(@"LSM9DS1 driver started")
    else
        ser.strln(@"LSM9DS1 driver failed to start - halting")
        repeat


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

