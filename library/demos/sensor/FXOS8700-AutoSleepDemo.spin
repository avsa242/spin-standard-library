{
    --------------------------------------------
    Filename: FXOS8700-AutoSleepDemo.spin
    Author: Jesse Burt
    Description: Demo of the FXOS8700 driver
        Auto-sleep functionality
    Copyright (c) 2021
    Started Nov 6, 2021
    Updated Nov 8, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = 27'cfg#LED2
    SER_BAUD    = 115_200

' I2C configuration
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000                       ' max is 400_000
    ADDR_BITS   = %11                           ' %00..%11 ($1E, 1D, 1C, 1F)

    RES_PIN     = -1                            ' reset optional: -1 to disable
    INT1        = 24                            ' FXOS8700 INT1 pin
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    accel   : "sensor.imu.6dof.fxos8700"
    core    : "core.con.mma8452q"

VAR

    long _isr_stack[50]                         ' stack for ISR core
    long _intflag                               ' interrupt flag

PUB Main{} | intsource, temp, sysmod

    setup{}
    accel.preset_active{}                       ' default settings, but enable
                                                ' sensor power, and set
                                                ' scale factors
    accel.intactivestate(accel#LOW)
    accel.acceldatarate(100)                    ' 100Hz ODR when active
    accel.autosleep(true)                       ' enable auto-sleep
    accel.accelsleeppwrmode(accel#LOPWR)        ' lo-power mode when sleeping
    accel.accelpowermode(accel#HIGHRES)         ' high-res mode when awake
    accel.transaxisenabled(%011)                ' transient detection on X, Y
    accel.transthresh(0_252000)                 ' set thresh to 0.252g (0..8g)
    accel.transcount(1)                         ' reset counter
    accel.inacttime(5_120)                      ' inactivity timeout ~5sec
    accel.inactint(accel#WAKE_TRANS)            ' wake on transient accel
    accel.intmask(accel#INT_AUTOSLPWAKE | accel#INT_TRANS)
    accel.introuting(accel#INT_AUTOSLPWAKE | accel#INT_TRANS)
    accel.autosleepdatarate(6)                  ' 6Hz ODR when sleeping
    dira[LED] := 1

    ' The demo continuously displays the current accelerometer data.
    ' When the sensor goes to sleep after approx. 5 seconds, the change
    '   in data rate is visible as a slowed update of the display.
    ' To wake the sensor, shake it along the X and/or Y axes
    '   by at least 0.252g's.
    ' When the sensor is awake, the LED should be on.
    ' When the sensor goes to sleep, it should turn off.
    repeat
        ser.position(0, 3)
        accelcalc{}                             ' show accel data
        if _intflag                             ' interrupt triggered
            intsource := accel.interrupt{}
            if (intsource & accel#INT_TRANS)    ' transient acceleration event
                temp := accel.transinterrupt{}  ' clear the trans. interrupt
            if (intsource & accel#INT_AUTOSLPWAKE)
                sysmod := accel.sysmode{}
                if (sysmod & accel#SLEEP)       ' op. mode is sleep,
                    outa[LED] := 0              '   so turn LED off
                elseif (sysmod & accel#ACTIVE)  ' else active,
                    outa[LED] := 1              '   turn it on

        if ser.rxcheck{} == "c"                 ' press the 'c' key in the demo
            calibrate{}                         ' to calibrate sensor offsets

PUB AccelCalc{} | ax, ay, az

    repeat until accel.acceldataready{}         ' wait for new sensor data set
    accel.accelg(@ax, @ay, @az)                 ' read calculated sensor data
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
    accel.calibrateaccel{}
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
    dira[INT1] := 0                             ' INT1 as input
    repeat
        waitpne(|< INT1, |< INT1, 0)            ' wait for INT1 (active low)
        _intflag := 1                           '   set flag
        waitpeq(|< INT1, |< INT1, 0)            ' now wait for it to clear
        _intflag := 0                           '   clear flag

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if accel.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS, RES_PIN)
        ser.strln(string("FXOS8700 driver started (I2C)"))
    else
        ser.strln(string("FXOS8700 driver failed to start - halting"))
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

