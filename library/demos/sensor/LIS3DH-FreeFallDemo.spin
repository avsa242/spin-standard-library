{
    --------------------------------------------
    Filename: LIS3DH-FreeFallDemo.spin
    Author: Jesse Burt
    Description: Demo of the LIS3DH driver
        Free-fall detection functionality
    Copyright (c) 2022
    Started Dec 22, 2021
    Updated Jul 9, 2022
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DLIS3DH_SPI
        -DLIS3DH_SPI_BC
        -DLIS3DH_I2C (default if none specified)
        -DLIS3DH_I2C_BC
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
    I2C_FREQ    = 400_000                       ' max is 400_000
    ADDR_BITS   = 0                             ' 0, 1

    { SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1                             ' SCL
    MOSI_PIN    = 2                             ' SDA
    MISO_PIN    = 3                             ' SDO
    INT1        = 24

'   NOTE: If LIS3DH_SPI is #defined, and SDA_PIN and SDO_PIN are the same,
'   the driver will attempt to start in 3-wire SPI mode.
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    accel   : "sensor.accel.3dof.lis3dh"

VAR

    long _isr_stack[50]                         ' stack for ISR core
    long _intflag                               ' interrupt flag

PUB Main{} | intsource

    setup{}
    accel.preset_freefall{}                     ' default settings, but enable
                                                ' sensors, set scale factors,
                                                ' and free-fall parameters

    ser.position(0, 3)
    ser.str(string("Waiting for free-fall condition..."))

    ' When the sensor detects free-fall, a message is displayed and
    '   is cleared after the user presses a key
    ' The preset for free-fall detection sets a free-fall threshold of
    '   0.320g's for a minimum time of 100ms. This can be tuned using
    '   accel.FreeFallThresh() and accel.FreeFallTime():
    accel.freefallthresh(0_320000)              ' 0.315g's
    accel.freefalltime(100_000)                 ' 100_000us/100ms

    repeat
        if _intflag                             ' interrupt triggered?
            intsource := accel.interrupt{}      ' read & clear interrupt flags
            if (intsource & %01_01_01)          ' free-fall event?
                ser.position(0, 4)
                ser.str(string("Sensor in free-fall!"))
                ser.clearline{}
                ser.newline{}
                ser.str(string("Press any key to reset"))
                ser.charin{}
                ser.positionx(0)
                ser.clearline{}
                ser.position(0, 4)
                ser.str(string("Sensor stable"))
                ser.clearline{}
        if ser.rxcheck{} == "c"                 ' press the 'c' key in the demo
            calibrate{}                         ' to calibrate sensor offsets

PUB Calibrate{}
' Calibrate sensor/set bias offsets
    ser.position(0, 7)
    ser.str(string("Calibrating..."))
    accel.calibrateaccel{}
    ser.positionx(0)
    ser.clearline{}

PRI ISR{}
' Interrupt service routine
    dira[INT1] := 0                             ' INT1 as input
    dira[LED1] := 1                             ' LED as output

    repeat
        waitpeq(|< INT1, |< INT1, 0)            ' wait for INT1 (active high)
        outa[LED1] := 1                         ' light LED
        _intflag := 1                           '   set flag

        waitpne(|< INT1, |< INT1, 0)            ' now wait for it to clear
        outa[LED1] := 0                         ' turn off LED
        _intflag := 0                           '   clear flag

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
#ifdef LIS3DH_SPI
    if accel.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("LIS3DH driver started (SPI)"))
#else
    if accel.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS)
        ser.strln(string("LIS3DH driver started (I2C)"))
#endif
    else
        ser.strln(string("LIS3DH driver failed to start - halting"))
        repeat

    cognew(isr{}, @_isr_stack)                  ' start ISR in another core

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

