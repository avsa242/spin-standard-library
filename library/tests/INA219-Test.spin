{
    --------------------------------------------
    Filename: INA219-Test.spin
    Author: Jesse Burt
    Description: Test of the INA219 driver
    Copyright (c) 2019
    Started Sep 18, 2019
    Updated Sep 22, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

    SCL_PIN         = 28
    SDA_PIN         = 29
    I2C_HZ          = 400_000

    COL_REG         = 0
    COL_SET         = COL_REG+20
    COL_READ        = COL_SET+20
    COL_PF          = COL_READ+18

    LED             = cfg#LED1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    ina219  : "sensor.power.ina219.i2c"
    int     : "string.integer"

VAR

    long _fails, _expanded
    byte _ser_cog, _row

PUB Main

    Setup
    _row := 3
    ser.Position (0, _row)

    PG (1)
    SADC_SAMP (1)
    SADC (1)
    BRNG (1)
    BADC (1)
    Flash (LED, 100)

PUB PG(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 4
            ina219.ShuntVoltageRange (lookup(tmp: 40, 80, 160, 320))
            read := ina219.ShuntVoltageRange (-2)
            Message (string("PG"), lookup(tmp: 40, 80, 160, 320), read)

PUB SADC_SAMP(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 8
            ina219.ShuntSamples (lookup(tmp: 1, 2, 4, 8, 16, 32, 64, 128))
            read := ina219.ShuntSamples (-2)
            Message (string("SADC_SAMP"), lookup(tmp: 1, 2, 4, 8, 16, 32, 64, 128), read)

PUB SADC(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 4
            ina219.ShuntADCRes (lookup(tmp: 9, 10, 11, 12))
            read := ina219.ShuntADCRes (-2)
            Message (string("SADC"), lookup(tmp: 9, 10, 11, 12), read)

PUB BRNG(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 2
            ina219.BusVoltageRange (lookup(tmp: 16, 32))
            read := ina219.BusVoltageRange (-2)
            Message (string("BRNG"), lookup(tmp: 16, 32), read)

PUB BADC(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 4
            ina219.BusADCRes (lookup(tmp: 9, 10, 11, 12))
            read := ina219.BusADCRes (-2)
            Message (string("BADC"), lookup(tmp: 9, 10, 11, 12), read)

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
    if ina219.Startx (SCL_PIN, SDA_PIN, I2C_HZ)
        ser.Str (string("INA219 driver started", ser#NL))
    else
        ser.Str (string("INA219 driver failed to start - halting", ser#NL))
        ina219.Stop
        time.MSleep (500)
        ser.Stop
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
