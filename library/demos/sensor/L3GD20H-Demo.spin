{
    --------------------------------------------
    Filename: L3GD20H-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the L3GD20H driver that
        outputs live data from the chip.
    Copyright (c) 2020
    Started Jul 11, 2020
    Updated Aug 9, 2020
    See end of file for terms of use.
    --------------------------------------------
}
'#define L3GD20H_I2C
#define L3GD20H_SPI

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

' I2C
    I2C_SCL     = 17
    I2C_SDA     = 19
    I2C_HZ      = 400_000

' SPI
    CS_PIN      = 16
    SCL_PIN     = 17
    SDO_PIN     = 18
    SDA_PIN     = 19
' --

OBJ

    cfg         : "core.con.boardcfg.flip"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    io          : "io"
    l3gd20h     : "sensor.gyroscope.3dof.l3gd20h.i2cspi"
    int         : "string.integer"

VAR

    long _overruns
    byte _ser_cog, _l3gd20h_cog

PUB Main | dispmode

    Setup

    l3gd20h.gyroopmode(l3gd20h#NORMAL)                      ' POWERDOWN (0), SLEEP (1), NORMAL (2)
    l3gd20h.gyrodatarate(100)                               ' 100, 200, 400, 800
    l3gd20h.gyroaxisenabled(%111)                           ' Bitmask %zyx (0 = disable, 1 = enable)
    l3gd20h.gyroscale(245)                                  ' 245, 500, 2000

    dispmode := 0
    ser.hidecursor

    repeat
        case ser.rxcheck
            "q", "Q":
                ser.showcursor
                ser.position(0, 5)
                ser.str(string("Halting"))
                l3gd20h.stop
                time.msleep(5)
                ser.stop
                quit
            "r", "R":
                ser.position(0, 3)
                repeat 2
                    ser.clearline{}
                    ser.newline
                dispmode ^= 1

        ser.position (0, 3)
        case dispmode
            0:
                gyroraw
                ser.newline
                tempraw
            1:
                gyrocalc
                ser.newline
                tempraw

    flashled(LED, 100)

PUB GyroCalc | gx, gy, gz

    repeat until l3gd20h.gyrodataready
    l3gd20h.gyrodps (@gx, @gy, @gz)
    if l3gd20h.gyrodataoverrun
        _overruns++
    ser.str (string("Gyro micro-DPS:  "))
    ser.str (int.decpadded (gx, 12))
    ser.str (int.decpadded (gy, 12))
    ser.str (int.decpadded (gz, 12))
    ser.newline
    ser.str (string("Overruns: "))
    ser.dec (_overruns)

PUB GyroRaw | gx, gy, gz

    repeat until l3gd20h.gyrodataReady
    l3gd20h.gyrodata (@gx, @gy, @gz)
    if l3gd20h.gyrodataoverrun
        _overruns++
    ser.str (string("Raw Gyro:  "))
    ser.str (int.decpadded (gx, 7))
    ser.str (int.decpadded (gy, 7))
    ser.str (int.decpadded (gz, 7))
    ser.newline
    ser.str (string("Overruns: "))
    ser.dec (_overruns)

PUB TempRaw

    ser.str (string("Temperature: "))
    ser.str (int.decpadded (l3gd20h.temperature, 7))

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, %0000, SER_BAUD)
    time.msleep(30)
    ser.clear
    ser.str (string("Serial terminal started", ser#CR, ser#LF))
#ifdef L3GD20H_SPI
    if _l3gd20h_cog := l3gd20h.Start (CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        l3gd20h.defaults
        ser.str (string("L3GD20H driver started (SPI)", ser#CR, ser#LF))
    else
#elseifdef L3GD20H_I2C
    if _l3gd20h_cog := l3gd20h.Startx (I2C_SCL, I2C_SDA, I2C_HZ)
        l3gd20h.defaults
        ser.str (string("L3GD20H driver started (I2C)", ser#CR, ser#LF))
    else
#endif
        ser.str (string("L3GD20H driver failed to start - halting", ser#CR, ser#LF))
        l3gd20h.stop
        time.msleep (5)
        ser.stop
        flashled(LED, 500)

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
