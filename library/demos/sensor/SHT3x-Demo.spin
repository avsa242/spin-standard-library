{
    --------------------------------------------
    Filename: SHT3x-Demo.spin
    Author: Jesse Burt
    Description: Demo of the SHT3x driver
    Copyright (c) 2020
    Started Mar 10, 2018
    Updated Aug 9, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_RX          = 31
    SER_TX          = 30
    SER_BAUD        = 115_200

' I2C
    SCL_PIN         = 28
    SDA_PIN         = 29
    ADDR_BIT        = 0                                     ' Can be 0, or 1 for a second device on the bus
    I2C_HZ          = 1_000_000                             ' Max: 1_000_000
' --

' Temperature scale
    C               = 0
    F               = 1

' Measurement repeatbility (on-sensor averaging)
    LOW             = sht3x#LOW                             ' Least averaging / no filtering
    MED             = sht3x#MED
    HIGH            = sht3x#HIGH                            ' Most averaging, more stable readings

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    sht3x   : "sensor.temp_rh.sht3x.i2c"
    int     : "string.integer"
    time    : "time"
    io      : "io"

PUB Main{} | temp, rh

    setup{}

    sht3x.heaterenabled(FALSE)                              ' Enable/Disable built-in heater
    sht3x.repeatability (LOW)                               ' Measurement repeatability (on-chip averaging)
    sht3x.tempscale(C)                                      ' Temperature scale

    repeat
        ser.position(0, 3)

        ser.str(string("Previous temperature: "))
        decimaldot(sht3x.lasttemperature{}, 100)
        ser.newline{}

        ser.str(string("Current temperature: "))
        decimaldot(sht3x.temperature{}, 100)
        ser.newline{}

        ser.str(string("Previous humidity: "))
        decimaldot(sht3x.lasthumidity{}, 100)
        ser.newline{}

        ser.str(string("Relative humidity: "))
        decimaldot(sht3x.humidity{}, 100)
        ser.newline{}

        time.msleep (1000)

PRI DecimalDot(scaled, divisor) | whole[4], part[4], places, tmp
' Display a fixed-point scaled up number in decimal-dot notation - scale it back down by divisor
'   e.g., Decimal (314159, 100000) would display 3.14159 on the terminal
'   scaled: Fixed-point scaled up number
'   divisor: Divide scaled-up number by this amount
    whole := scaled / divisor
    tmp := divisor
    places := 0

    repeat
        tmp /= 10
        places++
    until tmp == 1
    part := int.deczeroed(||(scaled // divisor), places)

    ser.dec (whole)
    ser.char (".")
    ser.str (part)
    ser.clearline{}

PUB Setup{}

    repeat until ser.startrxtx (SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#CR, ser#LF))

    if sht3x.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BIT)
        ser.printf(string("SHT3x driver (S/N %x) started\n"), sht3x.serialnum{}, 0, 0, 0, 0, 0)
    else
        ser.str(string("SHT3x driver failed to start - halting"))
        flashled(LED, 500)

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
