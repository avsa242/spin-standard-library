{
    --------------------------------------------
    Filename: MMA7455-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the MMA7455 driver that
        outputs live data from the chip.
    Copyright (c) 2020
    Started Nov 27, 2019
    Updated Aug 9, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    accel   : "sensor.accel.3dof.mma7455.i2c"
    int     : "string.integer"

VAR

    long _overruns
    byte _ser_cog, _accel_cog

PUB Main | dispmode

    Setup

    accel.OpMode(accel#MEASURE)
    accel.AccelScale(8)
    ser.HideCursor
    dispmode := 0

    repeat
        case ser.RxCheck
            "q", "Q":
                ser.Position(0, 5)
                ser.str(string("Halting"))
                accel.Stop
                time.MSleep(5)
                ser.Stop
                quit
            "c", "C":
                Calibrate
            "r", "R":
                ser.Position(0, 3)
                repeat 2
                    ser.ClearLine{}
                    ser.Newline
                dispmode ^= 1

        ser.Position (0, 3)
        case dispmode
            0: AccelRaw
            1: AccelCalc

    ser.ShowCursor
    FlashLED(LED, 100)

PUB Calibrate

    ser.Position (0, 8)
    ser.Str(string("Calibrating..."))
    accel.Calibrate
    ser.Position (0, 8)
    ser.Str(string("              "))

PUB AccelCalc | ax, ay, az

    repeat until accel.AccelDataReady
    accel.AccelG (@ax, @ay, @az)
    if accel.AccelDataOverrun
        _overruns++
    ser.Str (string("Accel micro-g: "))
    ser.Str (int.DecPadded (ax, 10))
    ser.Str (int.DecPadded (ay, 10))
    ser.Str (int.DecPadded (az, 10))
    ser.Newline
    ser.Str (string("Overruns: "))
    ser.Dec (_overruns)

PUB AccelRaw | ax, ay, az

    repeat until accel.AccelDataReady
    accel.AccelData (@ax, @ay, @az)
    if accel.AccelDataOverrun
        _overruns++
    ser.Str (string("Raw Accel: "))
    ser.Str (int.DecPadded (ax, 7))
    ser.Str (int.DecPadded (ay, 7))
    ser.Str (int.DecPadded (az, 7))
    ser.Newline
    ser.Str (string("Overruns: "))
    ser.Dec (_overruns)

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, %0000, SER_BAUD)
    time.MSleep(20)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#CR, ser#LF))
    if _accel_cog := accel.Startx (SCL_PIN, SDA_PIN, I2C_HZ)
        ser.Str (string("MMA7455 driver started", ser#CR, ser#LF))
    else
        ser.Str (string("MMA7455 driver failed to start - halting", ser#CR, ser#LF))
        accel.Stop
        time.MSleep (5)
        ser.Stop
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
