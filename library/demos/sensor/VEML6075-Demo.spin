{
    --------------------------------------------
    Filename: VEML6075-Demo.spin
    Author: Jesse Burt
    Description: Demo of the VEML6075 driver
    Copyright (c) 2019
    Started Aug 18, 2019
    Updated Aug 19, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000

    TEXT_COL    = 0
    DATA_COL    = 9

    UVA_RESP    = 0_001461  '0.001461
    UVB_RESP    = 0_002591  '0.002591

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    veml6075: "sensor.uv.veml6075.i2c"
    int     : "string.integer"

VAR

    long _fails, _expanded
    byte _ser_cog, _row

PUB Main | uva, uvb, vis, ir, i

    Setup
    veml6075.Powered (TRUE)
    veml6075.Dynamic (veml6075#DYNAMIC_NORM)
    veml6075.IntegrationTime (100)
    veml6075.OpMode (veml6075#CONT)


    repeat
        ser.Position (TEXT_COL, 5)
        ser.Str (string("UVI:"))
        ser.Position (DATA_COL, 5)
        ser.Str (string("0.000000"))
        ser.Str(int.DecPadded (UVI, 10))
        ser.NewLine
{
        ser.Position (TEXT_COL, 5)
        ser.Str (string("UVA:"))
        ser.Position (DATA_COL, 5)
        ser.Str(int.DecPadded (UVACalc(veml6075.UVAData), 5))
        ser.NewLine

        ser.Position (TEXT_COL, 6)
        ser.Str (string("UVB:"))
        ser.Position (DATA_COL, 6)
        ser.Str(int.DecPadded (UVBCalc(veml6075.UVBData), 5))
        ser.NewLine
}
    repeat
        uva := veml6075.UVAData
        uvb := veml6075.UVBData
        vis := veml6075.VisibleData
        ir := veml6075.IRData

        ser.Position (TEXT_COL, 5)
        ser.Str (string("UVA:"))
        ser.Position (DATA_COL, 5)
        ser.Str(int.DecPadded (uva, 5))
        ser.NewLine

        ser.Position (TEXT_COL, 6)
        ser.Str (string("UVB:"))
        ser.Position (DATA_COL, 6)
        ser.Str(int.DecPadded (uvb, 5))
        ser.NewLine

        ser.Position (TEXT_COL, 7)
        ser.Str (string("Visible:"))
        ser.Position (DATA_COL, 7)
        ser.Str(int.DecPadded (vis, 5))
        ser.NewLine

        ser.Position (TEXT_COL, 8)
        ser.Str (string("IR:"))
        ser.Position (DATA_COL, 8)
        ser.Str(int.DecPadded (ir, 5))
        time.MSleep (50)
    FlashLED (LED, 100)

PUB UVACalc(uva_raw) | uva, a, b, uvcomp1, uvcomp2

    a := 2_22   '2.22
    b := 1_33   '1.33

    uva := uva_raw
    uvcomp1 := veml6075.VisibleData
    uvcomp2 := veml6075.IRData
    result := uva - (a * uvcomp1) - (b * uvcomp2)

PUB UVBCalc(uvb_raw) | uvb, c, d, uvcomp1, uvcomp2

    c := 2_95   '2.95
    d := 1_74   '1.74

    uvb := uvb_raw
    uvcomp1 := veml6075.VisibleData
    uvcomp2 := veml6075.IRData
    result := uvb - (c * uvcomp1) - (d * uvcomp2)

PUB UVI

    return ((UVACalc(veml6075.UVAData) * UVA_RESP) + (UVBCalc(veml6075.UVBData) * UVB_RESP)) / 2

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if veml6075.Startx (SCL_PIN, SDA_PIN, I2C_HZ)
        ser.Str (string("VEML6075 driver started", ser#CR, ser#LF))
    else
        ser.Str (string("VEML6075 driver failed to start - halting", ser#CR, ser#LF))
        veml6075.Stop
        time.MSleep (500)
        ser.Stop
        FlashLED (LED, 500)

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
