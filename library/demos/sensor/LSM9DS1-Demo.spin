{
    --------------------------------------------
    Filename: LSM9DS1-Test.spin
    Author: Jesse Burt
    Description: Test harness for LSM9DS1 driver
    Copyright (c) 2019
    Started Aug 12, 2017
    Updated Feb 18, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    SCL_PIN     = 0
    SDIO_PIN    = 1
    CS_AG_PIN   = 2
    CS_M_PIN    = 3
    INT_AG_PIN  = 4
    INT_M_PIN   = 5

    LED         = cfg#LED1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    imu     : "sensor.imu.tri.lsm9ds1"
    int     : "string.integer"

VAR

    byte _ser_cog, _imu_cog

PUB Main

    Setup

    waitkey(string("Press any key to calibrate Accelerometer & Gyroscope...", ser#NL))
    ser.Str (string("Calibrating..."))
    imu.CalibrateAG

    waitkey(string("Press any key to calibrate Magnetometer", ser#NL))
    ser.Str (string("Calibrating..."))
    imu.CalibrateMag (512)

    ser.Clear

    repeat
        ser.Position (0, 0)
        AccelRaw
        ser.Position (0, 1)
        GyroRaw
        ser.Position (0, 2)
        MagRaw
        ser.Position (0, 3)
        TempRaw

        time.MSleep (100)

PUB AccelRaw | ax, ay, az

    imu.ReadAccel (@ax, @ay, @az)
    ser.Str (string("Accel: "))
    ser.Str (int.DecPadded (ax, 7))
    ser.Str (int.DecPadded (ay, 7))
    ser.Str (int.DecPadded (az, 7))

PUB GyroRaw | gx, gy, gz

    imu.ReadGyro (@gx, @gy, @gz)
    ser.Str (string("Gyro:  "))
    ser.Str (int.DecPadded (gx, 7))
    ser.Str (int.DecPadded (gy, 7))
    ser.Str (int.DecPadded (gz, 7))

PUB MagRaw | mx, my, mz

    imu.ReadMag (@mx, @my, @mz)
    ser.Str (string("Mag:  "))
    ser.Str (int.DecPadded (mx, 7))
    ser.Str (int.DecPadded (my, 7))
    ser.Str (int.DecPadded (mz, 7))

PUB TempRaw

    ser.Str (string("Temperature: "))
    ser.Str (int.DecPadded (imu.Temperature, 7))

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#NL))
    if _imu_cog := imu.Start (SCL_PIN, SDIO_PIN, CS_AG_PIN, CS_M_PIN, INT_AG_PIN, INT_M_PIN)
        ser.Str (string("LSM9DS1 driver started", ser#NL))
    else
        ser.Str (string("LSM9DS1 driver failed to start- halting", ser#NL))
        imu.Stop
        time.MSleep (5)
        ser.Stop
        Flash(LED, 500)

PUB waitkey(message)

    ser.Str (message)
    ser.CharIn

PUB Flash(led_pin, delay_ms)

    dira[led_pin] := 1
    repeat
        !outa[led_pin]
        time.MSleep (delay_ms)

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
