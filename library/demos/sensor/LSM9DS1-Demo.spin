{
    --------------------------------------------
    Filename: LSM9DS1-Demo.spin
    Author: Jesse Burt
    Description: Demo of the LSM9DS1 driver
    Copyright (c) 2020
    Started Aug 12, 2017
    Updated Aug 9, 2020
    See end of file for terms of use.
    --------------------------------------------
}
' Uncomment one of the following to choose which interface the LSM9DS1 is connected to
'#define LSM9DS1_I2C    NOT IMPLEMENTED YET
'#define LSM9DS1_SPI    NOT IMPLEMENTED YET
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    SCL_PIN     = 1
    SDIO_PIN    = 2
    CS_AG_PIN   = 3
    CS_M_PIN    = 0
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    io      : "io"
    time    : "time"
    int     : "string.integer"
    imu     : "sensor.imu.9dof.lsm9ds1.3wspi"

VAR

    long _overruns

PUB Main | dispmode, axo, ayo, azo, gxo, gyo, gzo

    Setup
    imu.AccelScale(2)                                       ' 2, 4, 8, 16 (g's)
    imu.AccelAxisEnabled(%111)                              ' 0 or 1 for each bit (%xyz)

    imu.GyroScale(250)                                      ' 245, 500, 2000
    imu.GyroAxisEnabled(%111)                               ' 0 or 1 for each bit (%xyz)
    imu.GyroBias(0, 0, 0, imu#W)                            ' x, y, z: 0..65535, rw = 1 (write)

    imu.MagScale(4)                                         ' 4, 8, 12, 16
    imu.MagDataRate(80_000)

    ser.HideCursor
    dispmode := 0

    gxo := gyo := gzo := 0
    axo := ayo := azo := 0
    ser.position(0, 3)                                      ' Read back the settings from above
    ser.printf(string("AccelScale: %d\n"), imu.AccelScale(-2), 0, 0, 0, 0, 0)

    imu.AccelBias(@axo, @ayo, @azo, imu#R)                       ' lsm9ds1 Accel has some factory trim accel offsets
    ser.printf(string("AccelBias: %d(x), %d(y), %d(z)\n"), axo, ayo, azo, 0, 0, 0)

    ser.printf(string("GyroScale: %d\n"), imu.GyroScale(-2), 0, 0, 0, 0, 0)
    imu.GyroBias(@gxo, @gyo, @gzo, imu#R)
    ser.printf(string("GyroBias: %d(x), %d(y), %d(z)\n"), gxo, gyo, gzo, 0, 0, 0)

    ser.printf(string("MagScale: %d\n"), imu.MagScale(-2), 0, 0, 0, 0, 0)

    ser.newline

    repeat
        case ser.RxCheck
            "q", "Q":                                       ' Quit the demo
                ser.Position(0, 15)
                ser.str(string("Halting"))
                imu.Stop
                time.msleep(5)
                quit
            "c", "C":                                       ' Perform calibration
                Calibrate
            "r", "R":                                       ' Change display mode: raw/calculated
                ser.Position(0, 10)
                repeat 2
                    ser.clearline{}
                    ser.Newline
                dispmode ^= 1

        ser.Position (0, 10)
        case dispmode
            0:
                AccelRaw
                GyroRaw
                MagRaw
            1:
                AccelCalc
                GyroCalc
                MagCalc

        ser.position (0, 15)
        ser.str(string("Interrupt: "))
        ser.bin(imu.Interrupt, 8)

    ser.ShowCursor
    FlashLED(LED, 100)

PUB AccelCalc | ax, ay, az

    repeat until imu.AccelDataReady
    imu.AccelG (@ax, @ay, @az)
    ser.str(string("Accel micro-g: "))
    ser.Str (int.DecPadded (ax, 10))
    ser.Str (int.DecPadded (ay, 10))
    ser.Str (int.DecPadded (az, 10))
    ser.clearline{}
    ser.Newline

PUB AccelRaw | ax, ay, az

    repeat until imu.AccelDataReady
    imu.AccelData (@ax, @ay, @az)
    ser.str(string("Accel raw: "))
    ser.Str (int.DecPadded (ax, 7))
    ser.Str (int.DecPadded (ay, 7))
    ser.Str (int.DecPadded (az, 7))
    ser.clearline{}
    ser.Newline

PUB GyroCalc | gx, gy, gz

    repeat until imu.GyroDataReady
    imu.GyroDPS (@gx, @gy, @gz)
    ser.str(string("Gyro micro DPS:  "))
    ser.Str (int.DecPadded (gx, 11))
    ser.Str (int.DecPadded (gy, 11))
    ser.Str (int.DecPadded (gz, 11))
    ser.clearline{}
    ser.newline

PUB GyroRaw | gx, gy, gz

    repeat until imu.GyroDataReady
    imu.GyroData (@gx, @gy, @gz)
    ser.str(string("Gyro raw:  "))
    ser.Str (int.DecPadded (gx, 7))
    ser.Str (int.DecPadded (gy, 7))
    ser.Str (int.DecPadded (gz, 7))
    ser.clearline{}
    ser.newline

PUB MagCalc | mx, my, mz

    repeat until imu.MagDataReady
    imu.MagGauss (@mx, @my, @mz)
    ser.str(string("Mag nano T:   "))
    ser.Str (int.DecPadded (mx, 10))
    ser.Str (int.DecPadded (my, 10))
    ser.Str (int.DecPadded (mz, 10))
    ser.clearline{}
    ser.newline

PUB MagRaw | mx, my, mz

    repeat until imu.MagDataReady
    imu.MagData (@mx, @my, @mz)
    ser.str(string("Mag raw:  "))
    ser.Str (int.DecPadded (mx, 7))
    ser.Str (int.DecPadded (my, 7))
    ser.Str (int.DecPadded (mz, 7))
    ser.clearline{}
    ser.newline

PUB Calibrate

    ser.Position (0, 14)
    ser.str(string("Calibrating..."))
    imu.CalibrateXLG
    imu.CalibrateMag (10)
    ser.Position (0, 14)
    ser.str(string("              "))

PUB Setup

    repeat until ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.Clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))

    if imu.Start (SCL_PIN, SDIO_PIN, CS_AG_PIN, CS_M_PIN)
        ser.str(string("LSM9DS1 driver started", ser#CR, ser#LF))
    else
        ser.str(string("LSM9DS1 driver failed to start- halting", ser#CR, ser#LF))
        FlashLED(LED, 500)

        imu.Stop
        time.msleep(5)
        FlashLED(LED, 500)

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
