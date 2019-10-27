{
    --------------------------------------------
    Filename: MB85RC-Test.spin
    Author: Jesse Burt
    Description: Test app for the MB85RCxxx driver
    Copyright (c) 2019
    Started Oct 27, 2019
    Updated Oct 27, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1
    SCL_PIN     = 24
    SDA_PIN     = 25
    I2C_HZ      = 400_000
    ADDR_A2A1A0 = %000                  ' Optional alternate slave address (%000..%111, 0..7)

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    fram    : "memory.fram.mb85rc.i2c"
    time    : "time"

VAR

    byte _ser_cog

PUB Main

    Setup

    ser.Position (0, 3)
    ser.Str (string("Device ID: "))
    ser.Hex (fram.ID, 8)
    ser.NewLine

    ser.Str (string("Density: "))
    ser.Dec (fram.Density)
    ser.NewLine

    ser.Str (string("Manufacturer: "))
    ser.Hex (fram.Manufacturer, 3)
    ser.NewLine

    ser.Str (string("Product ID: "))
    ser.Hex (fram.ProductID, 3)
    ser.NewLine

    Flash (LED, 100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if fram.Startx (SCL_PIN, SDA_PIN, I2C_HZ, ADDR_A2A1A0)
        ser.Str(string("MB85RCxxx driver started", ser#NL))
    else
        ser.Str(string("MB85RCxxx driver failed to start - halting", ser#NL))
        fram.Stop
        time.MSleep (500)
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
