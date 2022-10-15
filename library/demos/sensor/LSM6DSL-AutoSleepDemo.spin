{
    --------------------------------------------
    Filename: LSM6DSL-AutoSleepDemo.spin
    Author: Jesse Burt
    Description: Demo of the LSM6DSL driver
        Auto-sleep functionality
    Copyright (c) 2022
    Started Dec 27, 2021
    Updated Jul 9, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED1        = cfg#LED1
    SER_BAUD    = 115_200

    { I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000                       ' max is 400_000
    ADDR_BITS   = 0                             ' 0, 1

    { SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2
    MISO_PIN    = 3

    INT_PIN     = 24                            ' LSM6DSL INT_PIN pin
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    imu     : "sensor.imu.6dof.lsm6dsl"
    core    : "core.con.lsm6dsl"

VAR

    long _isr_stack[50]                         ' stack for ISR core
    long _intflag                               ' interrupt flag

PUB Main{} | intsource, temp, sysmod

    setup{}
    imu.preset_active{}                         ' default settings, but enable
                                                ' sensor power, and set
                                                ' scale factors

    imu.acceldatarate(208)
    imu.accelscale(2)
    imu.gyrodatarate(104)
    imu.gyroscale(250)

    imu.inacttime(5_000)                        ' inactivity timeout ~5sec
    imu.inactthresh(0_250000)
    imu.accelsleeppwrmode(imu#LOPWR_GSLEEP)
    imu.int1mask(imu#INACTIVE)

    dira[LED1] := 1

    ' The demo continuously displays the current accelerometer data.
    ' When the sensor goes to sleep after approx. 5 seconds, the change
    '   in data rate is visible as a slowed update of the display.
    ' To wake the sensor, shake it along the X and/or Y axes
    '   by at least 0.250g's.
    ' When the sensor is awake, the LED1 should be on.
    ' When the sensor goes to sleep, it should turn off.
    repeat
        ser.position(0, 3)
        accelcalc{}                             ' show accel data
        intsource := imu.intinactivity{}
        if _intflag                             ' interrupt triggered
            intsource := imu.intinactivity{}
            if intsource                        ' (in)activity event
                outa[LED1] := 0
            else
                outa[LED1] := 1
        else
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

PUB Calibrate{}

    ser.position(0, 5)
    ser.str(string("Calibrating..."))
    imu.calibrateaccel{}
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

PRI ISR{}
' Interrupt service routine
    dira[INT_PIN] := 0                          ' INT_PIN as input
    repeat
        waitpne(|< INT_PIN, |< INT_PIN, 0)      ' wait for INT_PIN (active low)
        _intflag := 1                           '   set flag
        waitpeq(|< INT_PIN, |< INT_PIN, 0)      ' now wait for it to clear
        _intflag := 0                           '   clear flag

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
#ifdef LSM6DSL_SPI
    if imu.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("LSM6DSL driver started (SPI)"))
#else
    if imu.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS)
        ser.strln(string("LSM6DSL driver started (I2C)"))
#endif
    else
        ser.strln(string("LSM6DSL driver failed to start - halting"))
        repeat

    cognew(isr, @_isr_stack)                    ' start ISR in another core

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

