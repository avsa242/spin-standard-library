{
    --------------------------------------------
    Filename: INA219-Demo.spin
    Author: Jesse Burt
    Description: Demo of the INA219 driver
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

    LED             = cfg#LED1

    MEASUREMENT_COL = 0
    CURR_MEAS_COL   = 20
    MIN_MEAS_COL    = CURR_MEAS_COL + 20
    MAX_MEAS_COL    = MIN_MEAS_COL + 20

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    ina219  : "sensor.power.ina219.i2c"
    int     : "string.integer"

VAR

    byte _ser_cog, _row

PUB Main | vbus, vbus_min, vbus_max, vshunt, vshunt_min, vshunt_max, i, i_min, i_max, p, p_min, p_max, cnf, cnf_init

    Setup
    ina219.Calibration (20480)
    ina219.BusVoltageRange (32)
    ina219.ShuntVoltageRange (320)
    ina219.ShuntADCRes (12)
'    ina219.ShuntSamples (128)
    ina219.BusADCRes (12)

    cnf_init := ina219.ConfigWord
    _row := 5
    ser.Position (MEASUREMENT_COL, _row)
    ser.Str (string("Measurement:"))
    ser.Position (CURR_MEAS_COL, _row)
    ser.Str (string("Current val:"))
    ser.Position (MIN_MEAS_COL, _row)
    ser.Str (string("Min:"))
    ser.Position (MAX_MEAS_COL, _row)
    ser.Str (string("Max:"))

    _row += 2
    vbus_min := ina219.BusVoltage
    vshunt_min := ina219.ShuntVoltage
    i_min := ina219.Current
    p_min := ina219.Power

    repeat
        vbus := ina219.BusVoltage
        vshunt := ina219.ShuntVoltage
        i := ina219.Current
        p := ina219.Power
        cnf := ina219.ConfigWord

        vbus_min := vbus <# vbus_min
        vbus_max := vbus #> vbus_max
        vshunt_min := vshunt_min <# vshunt
        vshunt_max := vshunt #> vshunt_max
        i_min := i_min <# i
        i_max := i #> i_max
        p_min := p_min <# p
        p_max := p #> p_max

        ser.Position (MEASUREMENT_COL, _row)
        ser.Str (string("Bus voltage"))
        ser.Position (CURR_MEAS_COL+3, _row)
        ser.Str (int.DecPadded(vbus, 7))
        ser.Str (string("mV"))
        ser.Position (MIN_MEAS_COL-3, _row)
        ser.Str (int.DecPadded(vbus_min, 7))
        ser.Position (MAX_MEAS_COL-3, _row)
        ser.Str (int.DecPadded(vbus_max, 7))

        _row++
        ser.Position (MEASUREMENT_COL, _row)
        ser.Str (string("Shunt voltage"))
        ser.Position (CURR_MEAS_COL+3, _row)
        ser.Str (int.DecPadded(vshunt, 7))
        ser.Str (string("uV"))
        ser.Position (MIN_MEAS_COL-3, _row)
        ser.Str (int.DecPadded(vshunt_min, 7))
        ser.Position (MAX_MEAS_COL-3, _row)
        ser.Str (int.DecPadded(vshunt_max, 7))

        _row++
        ser.Position (MEASUREMENT_COL, _row)
        ser.Str (string("Current"))
        ser.Position (CURR_MEAS_COL+3, _row)
        ser.Str (int.DecPadded(i, 7))
        ser.Str (string("uA"))
        ser.Position (MIN_MEAS_COL-3, _row)
        ser.Str (int.DecPadded(i_min, 7))
        ser.Position (MAX_MEAS_COL-3, _row)
        ser.Str (int.DecPadded(i_max, 7))

        _row++
        ser.Position (MEASUREMENT_COL, _row)
        ser.Str (string("Power"))
        ser.Position (CURR_MEAS_COL+3, _row)
        ser.Str (int.DecPadded(p, 7))
        ser.Str (string("uW"))
        ser.Position (MIN_MEAS_COL-3, _row)
        ser.Str (int.DecPadded(p_min, 7))
        ser.Position (MAX_MEAS_COL-3, _row)
        ser.Str (int.DecPadded(p_max, 7))

        _row++
        ser.Position (MEASUREMENT_COL, _row)
        ser.Str (string("Config word"))
        ser.Position (CURR_MEAS_COL, _row)
        ser.Bin (cnf, 16)

        _row++
        ser.Position (CURR_MEAS_COL+2, _row)
        ser.Char ("|")
        ser.Position (CURR_MEAS_COL+4, _row)
        ser.Char ("|")
        ser.Position (CURR_MEAS_COL+8, _row)
        ser.Char ("|")
        ser.Position (CURR_MEAS_COL+12, _row)
        ser.Char ("|")
        ser.Position (CURR_MEAS_COL+15, _row)
        ser.Char ("|")

        _row++
        ser.Position (CURR_MEAS_COL, _row)
        ser.Bin (cnf_init, 16)

        _row := 7
        time.MSleep (10)

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
