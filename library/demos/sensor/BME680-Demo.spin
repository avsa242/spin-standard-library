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

    byte _ser_cog, _bme_cog

PUB Main | a, i

    Setup

'    bme.HumidityOS (1)                                  ' Quick-start settings per BME680 datasheet, s.3.2.1
    bme.TemperatureOS (2)
'    bme.PressureOS (16)
'    bme.GasWaitTime (0, 4, 25)
    bme.ReadCoefficients
    DumpCalTable
{    repeat
        ser.Position (0, 5)
        Hum1
'        Temperature
        time.MSleep (300)
}
    Stop
    Flash (LED, 100)
'7c7580
PUB Temperature | adc, var1, var2, var3, _t_fine

    bme.OpMode (bme#OPMODE_FORCED)
    adc := bme.TempADC
'    adc := 508704
    ser.Str (string("adc: "))
    ser.Dec (adc)
    ser.NewLine

    var1 := (adc >> 3) - (bme.Par_T(1) << 1)
    ser.Str (string("var1: "))
    ser.Dec (var1)
    ser.NewLine

    var2 := (var1 * bme.Par_T(2)) >> 11
    ser.Str (string("var2: "))
    ser.Dec (var2)
    ser.NewLine

    var3 := ((var1 >> 1) * (var1 >> 1)) >> 12
    ser.Str (string("var3: "))
    ser.Dec (var3)
    ser.NewLine

    var3 := ((var3) * (bme.Par_T(3) << 4)) >> 14
    ser.Str (string("var3: "))
    ser.Dec (var3)
    ser.NewLine

    _t_fine := (var2 + var3)
    ser.Str (string("_t_fine: "))
    ser.Dec (_t_fine)
    ser.NewLine

    result := (((_t_fine * 5) + 128) >> 8)
    ser.Str (string("temp: "))
    ser.Dec (result)
    ser.NewLine

PUB Hum1

    bme.OpMode (bme#OPMODE_FORCED)
    ser.Hex (bme.HumidityADC, 8)
    ser.NewLine
'    ser.Dec (bme.Temperature)
'    ser.NewLine
'    ser.Dec (bme.Temp_Fine)

PUB Temp1

    bme.OpMode (bme#OPMODE_FORCED)
    ser.Hex (bme.TempADC, 8)
    ser.NewLine
    ser.Dec (bme.Temperature)
    ser.NewLine
    ser.Dec (bme.Temp_Fine)

PUB DumpCalTable | i

    bme.ReadCoefficients
    ser.Str (string("Temp: "))
    repeat i from 1 to 3
        ser.Dec (bme.Par_T (i))
        ser.Char (" ")
    ser.NewLine

    ser.Str (string("Press: "))
    repeat i from 1 to 10
        ser.Dec (bme.Par_P (i))
        ser.Char (" ")
    ser.NewLine

    ser.Str (string("Hum: "))
    repeat i from 1 to 7
        ser.Dec (bme.Par_H (i))
        ser.Char (" ")
    ser.NewLine

    ser.Str (string("Gas: "))
    repeat i from 1 to 3
        ser.Dec (bme.Par_GH (i))
        ser.Char (" ")

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
