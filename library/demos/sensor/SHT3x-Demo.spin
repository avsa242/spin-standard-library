{
    --------------------------------------------
    Filename: SHT3x-Demo.spin
    Author: Jesse Burt
    Description: Demo of the SHT3x driver
    Copyright (c) 2019
    Started Mar 10, 2018
    Updated Jun 9, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

    LED             = cfg#LED1
    SCL_PIN         = 28            ' Change these to match your I2C pin configuration
    SDA_PIN         = 29
    I2C_HZ          = 1_000_000     ' SHT3x supports I2C bus speeds up to FM+ (1MHz)
    ADDR_BIT        = 0             ' Optional alternate slave address (set to 1 to use)

    TERM_RX         = 31            ' Change these to suit your terminal settings
    TERM_TX         = 30
    TERM_BAUD       = 115_200

    F               = 0
    C               = 1
    TEMP_SCALE      = C             ' Change this to one of F, or C

    LOW             = sht3x#RPT_LOW
    MED             = sht3x#RPT_MED
    HIGH            = sht3x#RPT_HIGH
    REPEATABILITY   = HIGH          ' Change this to one of LOW, MED, or HIGH

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    sht3x   : "sensor.temp_rh.sht3x.i2c"
    math    : "tiny.math.float"
    fs      : "string.float"

VAR

    byte _ser_cog, _sht3x_cog

PUB Main | rh, t

    Setup
    sht3x.Repeatability (REPEATABILITY)
    sht3x.MeasureRate (4)

    sht3x.AlertTrigHiRH (80)
    sht3x.AlertClearHiRH (79)
    sht3x.AlertTrigLoRH (22)
    sht3x.AlertClearLoRH (20)

    sht3x.AlertTrigHiTemp (60)
    sht3x.AlertClearHiTemp (58)
    sht3x.AlertTrigLoTemp (-9)
    sht3x.AlertClearLoTemp (-10)

    ser.Position (0, 3)
    ser.Str (string("Humidity alert threshold levels: "))
    ser.Dec (sht3x.AlertTrigHiRH (-2))
    ser.Char (" ")
    ser.Dec (sht3x.AlertClearHiRH (-2))
    ser.Char (" ")
    ser.Dec (sht3x.AlertTrigLoRH (-2))
    ser.Char (" ")
    ser.Dec (sht3x.AlertClearLoRH (-2))
    ser.NewLine

    ser.Str (string("Temperature alert threshold levels: "))
    ser.Dec (sht3x.AlertTrigHiTemp (-255))
    ser.Char (" ")
    ser.Dec (sht3x.AlertClearHiTemp (-255))
    ser.Char (" ")
    ser.Dec (sht3x.AlertTrigLoTemp (-255))
    ser.Char (" ")
    ser.Dec (sht3x.AlertClearLoTemp (-255))
    ser.NewLine

    repeat
        sht3x.Measure

        ser.Position (0, 7)
        ser.Str (string("Temperature: "))
        case TEMP_SCALE
            F:
                t := math.FDiv (math.FFloat (sht3x.TemperatureF), 100.0)
                ser.Str (fs.FloatToString (t))
                ser.Str(string("F    "))
            C:
                t := math.FDiv (math.FFloat (sht3x.TemperatureC), 100.0)
                ser.Str (fs.FloatToString (t))
                ser.Str(string("C    "))
            OTHER:
                t := math.FDiv (math.FFloat (sht3x.TemperatureC), 100.0)
                ser.Str (fs.FloatToString (t))
                ser.Str(string("C    "))

        ser.NewLine

        ser.Str (string("Relative humidity: "))
        rh := math.FDiv (math.FFloat (sht3x.Humidity), 100.0)
        ser.Str (fs.FloatToString (rh))
        ser.Str(string("%    "))

        time.MSleep (100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _sht3x_cog := sht3x.Startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BIT)
        ser.Str (string("SHT3x driver (S/N "))
        ser.Hex (sht3x.SerialNum, 8)
        ser.Str (string(") started", ser#NL))
    else
        ser.Str (string("SHT3x driver failed to start - halting"))
        Stop
        Flash(LED, 500)

    sht3x.ClearStatus
    sht3x.Heater (FALSE)
    fs.SetPrecision (5)

PUB Stop

    sht3x.Stop
    time.MSleep (5)
    ser.Stop

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
