{
    --------------------------------------------
    Filename: Inclinometer-Serial.spin
    Author: Jesse Burt
    Description: Simple inclinometer using an LSM9DS1 IMU
        (serial display)
    Copyright (c) 2021
    Started Jan 29, 2020
    Updated Jun 1, 2021
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_M_PIN    = 3
    CS_AG_PIN   = 2
    SCL_PIN     = 0
    SDIO_PIN    = 1
' --

    R2D         = 180.0 / PI

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    imu     : "sensor.imu.9dof.lsm9ds1.spi"
    int     : "string.integer"
    math    : "math.float.extended"
    fs      : "string.float"

PUB Main{} | ax, ay, az, dx, dy

    setup

    ' set the accelerometer to a lower, less noisy data rate
    imu.preset_xl_g_m_3wspi{}
    imu.acceldatarate(14)
    imu.accelhighres(true)

    repeat
        imu.acceldata(@ax, @ay, @az)

        ' convert accelerometer data to degrees
        dx := math.fmul(R2D, math.atan2(math.ffloat(ay), math.ffloat(az)))
        dy := math.fmul(R2D, math.atan2(math.ffloat(ax), math.ffloat(az)))

        ' clamp values to within -90.0 to 90.0deg
        if math.fcmp(dx, -90.0) == -1
            dx := -90.0
        if math.fcmp(dx, 90.0) == 1
            dx := 90.0
        if math.fcmp(dy, -90.0) == -1
            dy := -90.0
        if math.fcmp(dy, 90.0) == 1
            dy := 90.0

        ser.position(0, 3)
        setrange(dx)
        ser.printf1(string("Pitch: %s    \n"), fs.floattostring(dx))

        setrange(dy)
        ser.printf1(string("Roll: %s    \n"), fs.floattostring(dy))

        if ser.rxcheck{} == "z"                 ' press 'z' to reset the
            setzero{}                           '   inclinometer's 'zero'

PRI setRange(val)
' Based on the current measurements,
' keep number of fractional digits displayed at 1
'   (total digits 2 or 3 - includes whole)
    if (math.fcmp(val, 9.9) == -1) or (math.fcmp(val, -9.9) == 1)
        fs.setprecision(2)                  ' if -9.9..9.9, 2 digits
    if (math.fcmp(val, 9.9) == 1) or (math.fcmp(val, -9.9) == -1)
        fs.setprecision(3)                  ' if > 9.9 or < -9.9, 3 digits

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

    if imu.startx(CS_AG_PIN, CS_M_PIN, SCL_PIN, SDIO_PIN)
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
