{
    --------------------------------------------
    Filename: MLX90614-Demo.spin
    Author: Jesse Burt
    Description: Demo for the MLX90614 driver
    Copyright (c) 2019
    Started Mar 17, 2019
    Updated Mar 19, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    mlx     : "sensor.temperature.mlx90614.i2c"
    math    : "tiny.math.float"
    fs      : "string.float"

VAR

    byte _ser_cog

PUB Main

    Setup
    fs.SetPrecision (5)

    ser.Position (0, 3)
    ser.Str (string("Sensor ID: "))
    ser.Hex (mlx.ID, 8)

    repeat
        ser.Position (0, 5)
        ReadIR(1)
        ser.Position (0, 6)
        ReadTa
        time.MSleep (100)

PUB ReadIR(ch) | tmp

    tmp := math.FFloat (mlx.ObjTemp (ch, mlx#C))
    tmp := math.FDiv (tmp, 100.0)
    ser.Str (string("IR: "))
    ser.Str (fs.FloatToString (tmp))

PUB ReadTa | tmp

    tmp := math.FFloat (mlx.AmbientTemp (mlx#C))
    tmp := math.FDiv (tmp, 100.0)
    ser.Str (string("Ta: "))
    ser.Str (fs.FloatToString (tmp))

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if mlx.Start
        ser.Str (string("MLX90614 driver started", ser#NL))    
    else
        ser.Str (string("MLX90614 driver failed to start - halting", ser#NL))
        mlx.Stop
        time.MSleep (500)
        ser.Stop
        repeat

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
