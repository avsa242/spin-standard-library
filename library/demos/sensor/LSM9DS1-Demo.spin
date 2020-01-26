{
    --------------------------------------------
    Filename: LSM9DS1-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the LSM9DS1 driver that
        outputs live data from the chip.
    Copyright (c) 2020
    Started Aug 12, 2017
    Updated Jan 12, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    SCL_PIN     = 1
    SDIO_PIN    = 2
    CS_AG_PIN   = 4
    CS_M_PIN    = 5
    INT_AG_PIN  = 6
    INT_M_PIN   = 8

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    imu     : "sensor.imu.9dof.lsm9ds1.3wspi"
    int     : "string.integer"

VAR

    byte _ser_cog, _imu_cog

PUB Main

    Setup

    imu.MagDataRate(80_000)
    ser.HideCursor

    repeat
        ser.Position (0, 3)
        AccelCalc
        ser.Position (0, 4)
        GyroCalc
        ser.Position (0, 5)
        MagCalc
        ser.Position (0, 6)
        TempRaw

        time.MSleep (10)

{
    repeat
        ser.Position (0, 3)
        AccelRaw
        ser.Position (0, 4)
        GyroRaw
        ser.Position (0, 5)
        MagRaw
        ser.Position (0, 6)
        TempRaw

        time.MSleep (10)
}

        case ser.RxCheck
            27:
                quit
            "c", "C":
                Calibrate

    ser.ShowCursor
    FlashLED(LED, 100)

PUB Calibrate

    ser.Position (0, 8)
    ser.Str(string("Calibrating..."))
    imu.CalibrateXLG
    imu.CalibrateMag (10)
    ser.Position (0, 8)
    ser.Str(string("              "))

PUB AccelCalc | ax, ay, az

    repeat until imu.AccelDataReady
    imu.AccelG (@ax, @ay, @az)
    ser.Str (string("Accel: "))
    ser.Str (int.DecPadded (ax, 10))
    ser.Str (int.DecPadded (ay, 10))
    ser.Str (int.DecPadded (az, 10))

PUB GyroCalc | gx, gy, gz

    repeat until imu.GyroDataReady
    imu.GyroDPS (@gx, @gy, @gz)
    ser.Str (string("Gyro:  "))
    ser.Str (int.DecPadded (gx, 10))
    ser.Str (int.DecPadded (gy, 10))
    ser.Str (int.DecPadded (gz, 10))

PUB MagCalc | mx, my, mz

    repeat until imu.MagDataReady
    imu.MagGauss (@mx, @my, @mz)
    ser.Str (string("Mag:   "))
    ser.Str (int.DecPadded (mx, 10))
    ser.Str (int.DecPadded (my, 10))
    ser.Str (int.DecPadded (mz, 10))

PUB AccelRaw | ax, ay, az

    repeat until imu.AccelDataReady
    imu.AccelData (@ax, @ay, @az)
    ser.Str (string("Accel: "))
    ser.Str (int.DecPadded (ax, 7))
    ser.Str (int.DecPadded (ay, 7))
    ser.Str (int.DecPadded (az, 7))

PUB GyroRaw | gx, gy, gz

    repeat until imu.GyroDataReady
    imu.GyroData (@gx, @gy, @gz)
    ser.Str (string("Gyro:  "))
    ser.Str (int.DecPadded (gx, 7))
    ser.Str (int.DecPadded (gy, 7))
    ser.Str (int.DecPadded (gz, 7))

PUB MagRaw | mx, my, mz

    repeat until imu.MagDataReady
    imu.MagData (@mx, @my, @mz)
    ser.Str (string("Mag:  "))
    ser.Str (int.DecPadded (mx, 7))
    ser.Str (int.DecPadded (my, 7))
    ser.Str (int.DecPadded (mz, 7))

PUB TempRaw

    ser.Str (string("Temperature: "))
    ser.Str (int.DecPadded (imu.Temperature, 7))

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, %0000, SER_BAUD)
    time.MSleep(20)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#CR, ser#LF))
    if _imu_cog := imu.Start (SCL_PIN, SDIO_PIN, CS_AG_PIN, CS_M_PIN, INT_AG_PIN, INT_M_PIN)
        ser.Str (string("LSM9DS1 driver started", ser#CR, ser#LF))
    else
        ser.Str (string("LSM9DS1 driver failed to start - halting", ser#CR, ser#LF))
        imu.Stop
        time.MSleep (5)
        ser.Stop
        FlashLED(LED, 500)

PRI waitkey(message)

    ser.Str (message)
    ser.CharIn

#include "lib.utility.spin"

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
