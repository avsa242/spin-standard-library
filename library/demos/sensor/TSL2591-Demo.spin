{
    --------------------------------------------
    Filename: TSL2591-Demo.spin
    Description: Demo for the TSL2591 driver
    Author: Jesse Burt
    Copyright (c) 2018
    Started Feb 17, 2018
    Updated Jun 11, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1

    GA          = 1             ' Glass attenuation factor
    DF          = 53            ' Device factor

    COL         = 26            ' Column to display measurements
    PADDING     = 6

OBJ

    cfg   : "core.con.boardcfg.flip"
    ser   : "com.serial.terminal"
    int   : "string.integer"
    time  : "time"
    lux   : "sensor.lux.tsl2591.i2c"
    fs    : "string.float"

PUB Main | atime_ms, againx, lux1, cpl, ch0, ch1, scale

    Setup

    lux.Gain (1)                ' 1, 25, 428, 9876
    lux.IntegrationTime (100)   ' 100, 200, 300, 400, 500, 600

    scale := 1
    ATIME_ms := lux.IntegrationTime (-2)
    AGAINx:= lux.Gain (-2)
    CPL := ((ATIME_ms * AGAINx) * scale) / (GA * DF)

    ser.Position (0, 3)
    ser.Str (string("ATIME_ms: "))
    ser.Position (COL, 3)
    ser.Dec (ATIME_ms)
    ser.NewLine

    ser.Str (string("AGAINx: "))
    ser.PositionX (COL)
    ser.Dec (AGAINx)
    ser.NewLine

    ser.Str (string("GA: "))
    ser.PositionX (COL)
    ser.Dec (GA)
    ser.NewLine

    ser.Str (string("DF: "))
    ser.PositionX (COL)
    ser.Dec (DF)
    ser.NewLine

    ser.Str (string("CPL: "))
    ser.PositionX (COL)
    ser.Dec (CPL)
    ser.NewLine

    repeat
        lux.Luminosity (3)
        ch0 := lux.LastFull
        ch1 := lux.LastIR
        Lux1 := (ch0 - (2 * ch1)) / CPL

        ser.Position (0, 9)
        ser.Str (string("CH0: "))
        ser.PositionX (COL-PADDING+1)
        ser.Str (int.DecPadded (ch0, PADDING))
        ser.NewLine

        ser.Str (string("CH1: "))
        ser.PositionX (COL-PADDING+1)
        ser.Str (int.DecPadded (ch1, PADDING))
        ser.NewLine

        ser.Str (string("(CH0 - (2 * CH1)): "))
        ser.PositionX (COL-PADDING+1)
        ser.Str (int.DecPadded (ch0-(2 * ch1), PADDING))
        ser.NewLine

        ser.Str (string("Lux: "))
        ser.PositionX (COL-PADDING+1)
        ser.Str (int.DecPadded (Lux1, PADDING))

PUB Setup

    repeat until ser.Start (115_200)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#NL))
    if lux.Start
        ser.Str (string("TSL2591 object started"))
        lux.Reset
        lux.Power (TRUE)
        lux.Sensor (TRUE)

    else
        ser.Str (string("TSL2591 object failed to start - halting", ser#NL))
        time.MSleep (1)
        lux.Stop
        ser.Stop
        Flash (LED, 500)

PUB Flash(led_pin, delay_ms)

    dira[led_pin] := 1
    repeat
        !outa[led_pin]
        time.MSleep (delay_ms)

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
