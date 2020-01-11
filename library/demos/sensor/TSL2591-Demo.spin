{
    --------------------------------------------
    Filename: TSL2591-Demo.spin
    Description: Demo for the TSL2591 driver
    Author: Jesse Burt
    Copyright (c) 2020
    Started Nov 23, 2019
    Updated Jan 10, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000

    GA          = 1             ' Glass attenuation factor
    DF          = 408 '53       ' Device factor

    COL         = 26            ' Column to display measurements
    PADDING     = 6

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    int     : "string.integer"
    time    : "time"
    io      : "io"
    tsl2591 : "sensor.lux.tsl2591.i2c"

VAR

    byte _ser_cog, _tsl2591_cog

PUB Main | atime_ms, againx, Lux1, cpl, ch0, ch1, scale

    Setup

    tsl2591.Gain (1)                                                ' Gain factor (x): 1, 25, 428, 9876
    tsl2591.IntegrationTime (100)                                   ' ADC Integration Time (ms): 100, 200, 300, 400, 500, 600

    scale := 1_000
    ATIME_ms := tsl2591.IntegrationTime(-2)
    AGAINx:= tsl2591.Gain(-2)
    CPL := ((ATIME_ms * AGAINx) * scale) / (GA * DF)

    ser.Position (0, 4)
    ser.str(string("Integration time: "))
    ser.dec(ATIME_ms)
    ser.newline

    ser.str(string("Gain: "))
    ser.dec(AGAINx)
    ser.newline

    ser.str(string("Glass attenuation: "))
    ser.dec(GA)
    ser.newline

    ser.str(string("Device Factor: "))
    ser.dec(DF)
    ser.newline

    ser.str(string("Counts per Lux: "))
    ser.dec(CPL)
    ser.newline

    repeat
        repeat until tsl2591.DataReady
        tsl2591.Measure (tsl2591#BOTH)
        ch0 := tsl2591.LastFull * scale
        ch1 := tsl2591.LastIR * scale
        Lux1 := ((ch0 - ch1) * ((1 * scale) - (ch1 / ch0))) / CPL   ' XXX Unverified
        ser.Position (0, 10)
        ser.str(string("CH0: "))
        ser.str(int.DecPadded (ch0 / scale, PADDING))
        ser.newline
        ser.str(string("CH1: "))
        ser.str(int.DecPadded (ch1 / scale, PADDING))
        ser.newline
        ser.str(string("(CH0 - CH1): "))
        ser.str(int.DecPadded ((ch0 - ch1), PADDING))
        ser.newline

        ser.str(string("1 - (CH0 - CH1): "))
        ser.str(int.DecPadded ((1 * scale) - (ch1 / ch0), PADDING))
        ser.newline
        ser.str(string("Lux: "))
        Frac (Lux1, scale)

PUB Frac(scaled, divisor) | whole, part, places, tmp
' Display a scaled up number in its natural form (#.###...) - scale it back down by divisor
    whole := scaled / divisor
    tmp := divisor
    places := 0

    repeat
        tmp /= 10
        places++
    until tmp == 1
    part := int.DecZeroed(||(scaled // divisor), places)
    ser.dec(whole)
    ser.char(".")
    ser.str(part)
    ser.char(" ")

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(100)
    ser.Clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if _tsl2591_cog := tsl2591.Startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str(string("TSL2591 driver started", ser#CR, ser#LF))
    else
        ser.str(string("TSL2591 driver failed to start - halting", ser#CR, ser#LF))
        time.MSleep (1)
        tsl2591.Stop
        FlashLED (LED, 500)
    tsl2591.Reset
    tsl2591.Powered (TRUE)
    tsl2591.SensorEnabled (TRUE)

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
