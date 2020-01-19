{
    --------------------------------------------
    Filename: INA260-Demo.spin2
    Author: Jesse Burt
    Description: Simple demo of the INA260 driver
    Copyright (c) 2020
    Started Jan 18, 2020
    Updated Jan 18, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    io          : "io"
    time        : "time"
    ina260      : "sensor.power.ina260.i2c"
    int         : "string.integer"

VAR

    long _ser_cog, _ina260_cog

PUB Main

    Setup
    ser.HideCursor

    repeat
        repeat until ina260.ConversionReady
        ser.Position(0, 5)
        ser.str(string("Current: "))
        Frac(ina260.Current)
        ser.str(string("mA   ", ser#CR, ser#LF))

        ser.str(string("Bus Voltage: "))
        Frac(ina260.BusVoltage)
        ser.str(string("mV   ", ser#CR, ser#LF))

        ser.str(string("Power: "))
        Frac(ina260.Power)
        ser.str(string("mW   ", ser#CR, ser#LF))

        if ser.RXCheck == "Q"                       ' Press captial Q to quit the demo
            ser.ShowCursor
            ser.newline
            ser.str(string("Halting"))
            quit

    FlashLED(LED, 100)     ' Signal execution finished

PUB Frac(thousandths) | whole, part

    whole := thousandths / 1000
    part := int.DecZeroed(thousandths // 1000, 2)
    ser.dec(whole)
    ser.char(".")
    ser.str(part)

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if _ina260_cog := ina260.Startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str(string("INA260 driver started", ser#CR, ser#LF))
    else
        ser.str(string("INA260 driver failed to start - halting", ser#CR, ser#LF))
        FlashLED(LED, 500)

#include "lib.utility.spin"

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
