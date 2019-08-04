{
    --------------------------------------------
    Filename: BMP280-Demo.spin
    Description: Demonstrates BMP280 Pressure/Temperature sensor driver (I2C)
    Author: Jesse Burt
    Copyright (c) 2019
    Created: Sep 16, 2018
    Updated: Mar 9, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

    DEBUG_LED   = cfg#LED1

    COL_REG     = 0
    COL_SET     = 12
    COL_READ    = 24
    COL_PF      = 40

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal"
    time: "time"
    bmp : "sensor.baro-alt.bmp280.i2c"

VAR

    byte _ser_cog, _bmp_cog
    long ptr_comp_data

PUB Main | i

    Setup
    ser.Clear
    bmp.SoftReset
    bmp.ReadTrim

    ser.Position (0, 0)
    Test_TrimData (1)
    Test_ID (1)
    Test_MeasureMode (1)
    Test_PressRes (1)
    Test_TempRes (1)
    Test_Standby (1)
    flash(cfg#LED1)

PUB Test_ID(reps) | tmp, read

    tmp := bmp#ID_EXPECTED
    repeat reps
        read := bmp.ID
        Message (string("ID"), tmp, read)

PUB Test_MeasureMode(reps) | tmp, read

    repeat reps
        repeat tmp from 0 to 3
            bmp.MeasureMode (tmp)
            read := bmp.MeasureMode (-2)
            Message (string("MeasureMode"), tmp, read)
    bmp.MeasureMode (bmp#MODE_FORCED1)

PUB Test_PressRes(reps) | tmp, read

    repeat reps
        repeat tmp from 0 to 5
            bmp.PressRes (lookupz(tmp: 0, 16..20))
            read := bmp.PressRes (-2)
            Message (string("PressRes"), lookupz(tmp: 0, 16..20), read)

PUB Test_ReadTrim(reps) | tmp, read

    repeat reps
        bmp.ReadTrim

PUB Test_Standby(reps) | tmp, read

    repeat reps
        repeat tmp from 0 to 7
            bmp.Standby (lookupz(tmp: 1, 63, 125, 250, 500, 1000, 2000, 4000))
            read := bmp.Standby (-2)
            Message (string("Standby"), lookupz(tmp: 1, 63, 125, 250, 500, 1000, 2000, 4000), read)

PUB Test_TempRes(reps) | tmp, read

    repeat reps
        repeat tmp from 0 to 5
            bmp.TempRes (lookupz(tmp: 0, 16..20))
            read := bmp.TempRes (-2)
            Message (string("TempRes"), lookupz(tmp: 0, 16..20), read)

PUB Test_TrimData(reps) | i

    repeat i from 0 to 23
        ser.Position (i * 3, 3)
        ser.Hex ($88+i, 2)
        ser.Position (i * 3, 4)
        ser.Hex (byte[ptr_comp_data][i], 2)
        ser.Char (" ")
    ser.NewLine

    repeat i from 1 to 3
        ser.Str (string("dig_T("))
        ser.Dec (i)
        ser.Str (string("): "))
        ser.Hex (bmp.dig_T (i), 4)
        ser.Char ("/")
        ser.Dec (bmp.dig_T (i))
        ser.NewLine
    ser.NewLine

    repeat i from 1 to 9
        ser.Str (string("dig_P("))
        ser.Dec (i)
        ser.Str (string("): "))
        ser.Hex (bmp.dig_P (i), 4)
        ser.Char ("/")
        ser.Dec (bmp.dig_P (i))
        ser.NewLine

PUB Message(field, arg1, arg2)

    ser.PositionX ( COL_REG)
    ser.Str (field)

    ser.PositionX ( COL_SET)
    ser.Str (string("SET: "))
    ser.Dec (arg1)

    ser.PositionX ( COL_READ)
    ser.Str (string("   READ: "))
    ser.Dec (arg2)

    ser.PositionX (COL_PF)
    PassFail (arg1 == arg2)
    ser.NewLine

PUB PassFail(num)

    case num
        0: ser.Str (string("FAIL"))
        -1: ser.Str (string("PASS"))
        OTHER: ser.Str (string("???"))

PUB waitkey

    ser.Str (string("Press any key to continue"))
    ser.CharIn

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))

    ser.Str (string("bmp280 object "))
    if bmp.Start
        ser.Str (string("started", ser#NL))
    else
        ser.Str (string("failed to start"))
        flash(cfg#LED1)
    time.MSleep (10)
    waitkey

PRI flash(led_pin)

    dira[led_pin] := 1
    repeat
        !outa[led_pin]
        time.MSleep (100)

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
