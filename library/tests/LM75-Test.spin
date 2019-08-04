{
    --------------------------------------------
    Filename: LM75-Test.spin
    Author: Jesse Burt
    Description: Simple test for the LM75 driver
    Copyright (c) 2019
    Started May 19, 2019
    Updated May 20, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    temp    : "sensor.temperature.lm75.i2c"
    math    : "tiny.math.float"
    fs      : "string.float"

VAR

    byte _ser_cog, _temp_cog

PUB Main | tmp

    Setup
    repeat
        tmp := temp.Temperature

        ser.Position (0, 3)
        ser.Str (string("Temperature (int, centi-degrees C): "))
        ser.Dec (tmp)

        ser.Position (0, 4)
        ser.Str (string("Temperature (float, degrees C): "))
        tmp := math.FFloat (tmp)
        tmp := math.FDiv (tmp, 10.0)
        ser.Str (fs.FloatToString (tmp))
        ser.Chars (32, 2)
        time.MSleep (300)


PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _temp_cog := temp.Start
        ser.Str(string("LM75 driver started", ser#NL))
    else
        ser.Str(string("LM75 driver failed to start - halting", ser#NL))
        Stop
    fs.SetPrecision (4)

PUB Stop

    time.MSleep (5)
    ser.Stop
    temp.Stop
    Flash (LED, 500)

PUB Flash(pin, delay_ms)

    dira[pin] := 1
    repeat
        !outa[pin]
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
