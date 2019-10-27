{
    --------------------------------------------
    Filename: VEML6075-Test.spin
    Author: Jesse Burt
    Description: Test of the VEML6075 driver
    Copyright (c) 2019
    Started Aug 18, 2019
    Updated Aug 18, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    COL_REG     = 0
    COL_SET     = 25
    COL_READ    = 37
    COL_PF      = 52

    LED         = cfg#LED1

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    uv      : "sensor.uv.veml6075.i2c"

VAR

    long _fails, _expanded
    byte _ser_cog, _row

PUB Main | tmp, i

    Setup
    _row := 1

    SD (1)
    UV_AF (1)
    HD (1)
    UV_IT (1)
    Flash (LED, 100)

PUB SD(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from -1 to 0
            uv.Power (tmp)
            read := uv.Power (-2)
            Message (string("SD"), tmp, read)
    uv.Power (TRUE)

PUB UV_AF(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 1
            uv.MeasureMode (tmp)
            read := uv.MeasureMode (-2)
            Message (string("UV_AF"), tmp, read)

PUB HD(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 1
            uv.Dynamic (tmp)
            read := uv.Dynamic (-2)
            Message (string("HD"), tmp, read)

PUB UV_IT(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 5
            uv.IntegrationTime (lookup(tmp: 50, 100, 200, 400, 800))
            read := uv.IntegrationTime (-2)
            Message (string("UV_IT"), lookup(tmp: 50, 100, 200, 400, 800), read)

PUB Dumpregs | i, tmp

    repeat i from $00 to $0C
        ser.Hex (i, 2)
        ser.Str (string(": "))
        uv.readReg (i, 2, @tmp)
        ser.Hex (tmp, 4)
        ser.NewLine

PUB Message(field, arg1, arg2)

    case _expanded
        TRUE:
            ser.PositionX (COL_REG)
            ser.Str (field)

            ser.PositionX (COL_SET)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

            ser.PositionX (COL_READ)
            ser.Str (string("READ: "))
            ser.Dec (arg2)
            ser.Chars (32, 3)
            ser.PositionX (COL_PF)
            PassFail (arg1 == arg2)
            ser.NewLine

        FALSE:
            ser.Position (COL_REG, _row)
            ser.Str (field)

            ser.Position (COL_SET, _row)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

            ser.Position (COL_READ, _row)
            ser.Str (string("READ: "))
            ser.Dec (arg2)

            ser.Position (COL_PF, _row)
            PassFail (arg1 == arg2)
            ser.NewLine
        OTHER:
            ser.Str (string("DEADBEEF"))

PUB PassFail(num)

    case num
        0:
            ser.Str (string("FAIL"))
            _fails++

        -1:
            ser.Str (string("PASS"))

        OTHER:
            ser.Str (string("???"))

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if uv.Startx (SCL_PIN, SDA_PIN, I2C_HZ)
        ser.Str (string("VEML6075 driver started", ser#NL))
    else
        ser.Str (string("VEML6075 driver failed to start - halting", ser#NL))
        uv.Stop
        time.MSleep (500)
        ser.Stop
        repeat

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
