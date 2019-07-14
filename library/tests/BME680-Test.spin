{
    --------------------------------------------
    Filename: BME680-Test.spin
    Author: Jesse Burt
    Description: Test object for the BME680 driver
    Copyright (c) 2019
    Started May 26, 2019
    Updated May 26, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1
    COL_REG     = 0
    COL_SET     = 20
    COL_READ    = 40
    COL_PF      = 58

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    bme     : "sensor.environ.bme680.i2c"

VAR

    long _fails, _expanded
    byte _ser_cog, _bme_cog, _row

PUB Main

    Setup
    _row := 2

    Test_GAS_WAIT_0 (1)
    Test_OSRS_T (1)
    Test_OSRS_P (1)
    Test_OSRS_H (1)
    Stop
    Flash (LED, 100)

PUB Test_GAS_WAIT_0(reps) | tmp, read, mult

'    _expanded := TRUE
    _row++
    repeat reps
        repeat mult from 0 to 3
            repeat tmp from 0 to 63
                bme.GasWaitTime (0, lookupz(mult: 1, 4, 16, 64), tmp)
                read := bme.GasWaitTime (0, 1, -2)
                Message (string("GAS_WAIT_0"), tmp*lookupz(mult: 1, 4, 16, 64), read)

PUB Test_OSRS_T(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 5
            bme.TemperatureOS (lookupz(tmp: 0, 1, 2, 4, 8, 16))
            read := bme.TemperatureOS (-2)
            Message (string("OSRS_T"), lookupz(tmp: 0, 1, 2, 4, 8, 16), read)

PUB Test_OSRS_P(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 5
            bme.PressureOS (lookupz(tmp: 0, 1, 2, 4, 8, 16))
            read := bme.PressureOS (-2)
            Message (string("OSRS_P"), lookupz(tmp: 0, 1, 2, 4, 8, 16), read)

PUB Test_OSRS_H(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 5
            bme.HumidityOS (lookupz(tmp: 0, 1, 2, 4, 8, 16))
            read := bme.HumidityOS (-2)
            Message (string("OSRS_H"), lookupz(tmp: 0, 1, 2, 4, 8, 16), read)

PUB Message(field, arg1, arg2)

    case _expanded
        TRUE:
            ser.PositionX (COL_REG)
            ser.Str (field)

            ser.PositionX (COL_SET)
            ser.Str (string("SET: "))
            ser.Dec (arg1)
            ser.Chars (32, 3)

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
            ser.Chars (32, 3)

            ser.Position (COL_READ, _row)
            ser.Str (string("READ: "))
            ser.Dec (arg2)
            ser.Chars (32, 3)

            ser.Position (COL_PF, _row)
            PassFail (arg1 == arg2)
            ser.NewLine
        OTHER:
            ser.Str (string("DEADBEEF"))

PUB PassFail(num)

    case num
        0:
            ser.Str (string("FAIL"))
            ser.Position (40, 0)
            ser.Dec (_fails++)
        -1: ser.Str (string("PASS"))
        OTHER: ser.Str (string("???"))

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _bme_cog := bme.Start
        ser.Str(string("BME680 driver started", ser#NL))
    else
        ser.Str(string("BME680 driver failed to start - halting", ser#NL))
        Stop
        Flash (LED, 500)


PUB Stop

    time.MSleep (5)
    ser.Stop
    bme.Stop

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
