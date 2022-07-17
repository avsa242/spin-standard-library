{
    --------------------------------------------
    Filename: FXAS21002-IntDemo.spin
    Author: Jesse Burt
    Description: Demo of the FXAS21002 driver:
        interrupt functionality
    Copyright (c) 2022
    Started Jun 9, 2021
    Updated Jul 9, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

' I2C
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000
    ADDR_BITS   = 1
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    gyro    : "sensor.gyroscope.3dof.fxas21002"

PUB Main{}

    setup{}
    gyro.preset_active{}                        ' default settings, but enable
                                                ' measurements, and set scale
                                                ' factor

'   set threshold in micro-degrees per second. The axes' thresholds can't be
'   independently set - all three are set to the value passed in the X-axis
'   parameter (first param):
    gyro.gyrointthresh(100_000000, 0, 0, 1)
    gyro.gyrointmask(gyro#INT_ZTHS)

    repeat
        ser.position(0, 3)
        gyrocalc{}

        ser.position(0, 4)
        ser.bin(gyro.gyroint{}, 7)              ' show interrupt flags

        if ser.rxcheck{} == "c"                 ' press the 'c' key in the demo
            calibrate{}                         ' to calibrate sensor offsets

PUB GyroCalc{} | gx, gy, gz

    repeat until gyro.gyrodataready{}           ' wait for new sensor data set
    gyro.gyrodps(@gx, @gy, @gz)                 ' read calculated sensor data
    ser.str(string("Gyro (dps):"))
    ser.positionx(DAT_X_COL)
    decimal(gx, 1000000)                        ' data is in micro-dps; display
    ser.positionx(DAT_Y_COL)                    ' it as if it were a float
    decimal(gy, 1000000)
    ser.positionx(DAT_Z_COL)
    decimal(gz, 1000000)
    ser.clearline{}
    ser.newline{}

PUB Calibrate{}

    ser.position(0, 7)
    ser.str(string("Calibrating..."))
    gyro.calibrategyro{}
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

    if gyro.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS)
        ser.strln(string("FXAS21002 driver started (I2C)"))
    else
        ser.strln(string("FXAS21002 driver failed to start - halting"))
        repeat

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

