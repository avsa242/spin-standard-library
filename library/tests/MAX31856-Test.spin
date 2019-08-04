{
    --------------------------------------------
    Filename: MAX31856-Test.spin
    Description: Test for the MAX31856 driver
    Author: Jesse Burt
    Copyright (c) 2019
    Created Sep 30, 2018
    Updated Jun 11, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    CS          = 0
    SDI         = 1
    SDO         = 2
    SCK         = 3

    LED         = cfg#LED1

    COL_REG     = 0
    COL_SET     = 12
    COL_READ    = 24
    COL_PF      = 40

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    tc      : "sensor.thermocouple.max31856.spi"
    math    : "tiny.math.float"
    fs      : "string.float"

VAR

    long _fails, _expanded
    byte _ser_cog, _row

PUB Main

    Setup
    ser.NewLine

    tc.ConversionMode (tc#CMODE_OFF)
    tc.FaultMode (tc#FAULTMODE_COMP)
    tc.ColdJuncSensor (FALSE)
    tc.NotchFilter (50)

    _row := 3
    LTLFT (1)
    LTHFT (1)
    CJLF (1)
    CJHF (1)
    MASK (1)
    TC_TYPE (1)
    CMODE (1)
    OCFAULT (1)
    CJ (1)
    FAULT (1)
    NOTCH5060 (1)

    Flash (cfg#LED1, 100)

PUB LTLFT(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 32767
            tc.ThermocoupleLowFault (tmp)
            read := tc.ThermocoupleLowFault (-2)
            Message (string("LTLFT"), tmp, read)
    tc.ThermocoupleLowFault ($8000)

PUB LTHFT(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 32767
            tc.ThermocoupleHighFault (tmp)
            read := tc.ThermocoupleHighFault (-2)
            Message (string("LTHFT"), tmp, read)
    tc.ThermocoupleHighFault ($7FFF)

PUB CJLF(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 255
            tc.ColdJuncLowFault (tmp)
            read := tc.ColdJuncLowFault (-2)
            Message (string("CJLF"), tmp, read)
    tc.ColdJuncLowFault ($C0)

PUB CJHF(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 255
            tc.ColdJuncHighFault (tmp & $FF)
            read := tc.ColdJuncHighFault (-255)
            Message (string("CJHF"), tmp, read)
    tc.ColdJuncHighFault ($7F)

PUB MASK(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 63
            tc.FaultMask (tmp)
            read := tc.FaultMask (-2)
            Message (string("MASK"), tmp, read)
    tc.FaultMask (%111111)

PUB TC_TYPE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 7
            tc.ThermoCoupleType (tmp)
            read := tc.ThermoCoupleType (-2)
            Message (string("TC_TYPE"), tmp, read)
    tc.ThermoCoupleType (tc#K)

PUB CMODE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 1
            tc.ConversionMode (tmp)
            read := tc.ConversionMode (-2)
            Message (string("CMODE"), tmp, read)
    tc.ConversionMode (FALSE)

PUB OCFAULT(reps) | tmp, read
'        0, 10, 32, 100:
    _row++
    repeat reps
        repeat tmp from 0 to 3
            tc.FaultTestTime (lookupz(tmp: 0, 10, 32, 100))
            read := tc.FaultTestTime (-2)
            Message (string("OCFAULT"), lookupz(tmp: 0, 10, 32, 100), read)
    tc.FaultTestTime (0)

PUB CJ(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            tc.ColdJuncSensor (tmp)
            read := tc.ColdJuncSensor (-2)
            Message (string("CJ"), tmp, read)
    tc.ColdJuncSensor (TRUE)

PUB FAULT(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 1
            tc.FaultMode (tmp)
            read := tc.FaultMode (-2)
            Message (string("FAULT"), tmp, read)
    tc.FaultTestTime (0)

PUB NOTCH5060(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 50 to 60 step 10
            tc.NotchFilter (tmp)
            read := tc.NotchFilter (-2)
            Message (string("NOTCH"), tmp, read)

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
    if tc.start (CS, SDI, SDO, SCK)
        ser.Str(string("MAX31856 driver started", ser#NL))
    else
        ser.Str(string("MAX31856 driver failed to start - halting", ser#NL))
        tc.Stop
        time.MSleep (5)
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
