{
    --------------------------------------------
    Filename: LSM303DLHC-Demo.spin
    Author: Jesse Burt
    Description: Demo of the LSM303DLHC driver
    Copyright (c) 2021
    Started Jul 30, 2020
    Updated Jan 28, 2021
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    SCL_PIN     = 4
    SDA_PIN     = 3
    I2C_HZ      = 400_000                       ' max is 400_000
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    imu     : "sensor.imu.6dof.lsm303dlhc.i2c"

PUB Main{}

    setup{}
    imu.preset_active{}                         ' default settings, but enable
                                                ' sensor output and set
                                                ' scale factors
    repeat
        ser.position(0, 3)
        accelcalc{}
        magcalc{}

        if ser.rxcheck{} == "c"                 ' press the 'c' key in the demo
            calibrate{}                         ' to calibrate sensor offsets

PUB AccelCalc{} | ax, ay, az

    repeat until imu.acceldataready{}           ' wait for new sensor data set
    imu.accelg(@ax, @ay, @az)                   ' read calculated sensor data
    ser.str(string("Accel (g):"))
    ser.positionx(DAT_X_COL)
    decimal(ax, 1000000)                        ' data is in micro-g's; display
    ser.positionx(DAT_Y_COL)                    ' it as if it were a float
    decimal(ay, 1000000)
    ser.positionx(DAT_Z_COL)
    decimal(az, 1000000)
    ser.clearline{}
    ser.newline{}

PUB MagCalc{} | mx, my, mz

    repeat until imu.magdataready{}
    imu.maggauss(@mx, @my, @mz)
    ser.str(string("Mag (gauss):"))
    ser.positionx(DAT_X_COL)
    decimal(mx, 1000)
    ser.positionx(DAT_Y_COL)
    decimal(my, 1000)
    ser.positionx(DAT_Z_COL)
    decimal(mz, 1000)
    ser.clearline{}
    ser.newline{}

PUB Calibrate{}

    ser.position(0, 7)
    ser.str(string("Calibrating..."))
    imu.calibrateaccel{}
    imu.calibratemag{}
    ser.positionx(0)
    ser.clearline{}

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp, sign
' Display a scaled up number as a decimal
'   Scale it back down by divisor (e.g., 10, 100, 1000, etc)
    whole := scaled / divisor
    tmp := divisor
    places := 0
    part := 0
    sign := 0
    if scaled < 0
        sign := "-"
    else
        sign := " "

    repeat
        tmp /= 10
        places++
    until tmp == 1
    scaled //= divisor
    part := int.deczeroed(||(scaled), places)

    ser.char(sign)
    ser.dec(||(whole))
    ser.char(".")
    ser.str(part)
    ser.chars(" ", 5)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if imu.startx(SCL_PIN, SDA_PIN, I2C_HZ)
        ser.strln(string("LSM303DLHC driver started"))
    else
        ser.strln(string("LSM303DLHC driver failed to start - halting"))
        imu.stop{}
        time.msleep(5)
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
