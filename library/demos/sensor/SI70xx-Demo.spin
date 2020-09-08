{
    --------------------------------------------
    Filename: SI70xx-Demo.spin2
    Author: Jesse Burt
    Description: Demo of the SI70xx driver (P2 version)
    Copyright (c) 2020
    Started Aug 9, 2020
    Updated Sep 8, 2020
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
    I2C_HZ          = 400_000                             ' Max: 400_000
' --

' Temperature scale
    C               = 0
    F               = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    int     : "string.integer"
    time    : "time"
    io      : "io"
    si70xx  : "sensor.temp_rh.si70xx.i2c"

VAR

    long _sn[2], _fw_rev[2]

PUB Main{}

    setup{}

    si70xx.heaterenabled(FALSE)                             ' Enable/Disable built-in heater
    si70xx.tempscale(F)                                     ' Temperature scale

    repeat
        ser.position(0, 3)

        ser.str(string("Temperature:       "))
        decimaldot(si70xx.temperature{}, 100)
        ser.newline

        ser.str(string("Relative humidity: "))
        decimaldot(si70xx.humidity{}, 100)

        time.msleep (100)

PRI DecimalDot(scaled, divisor) | whole[4], part[4], places, tmp
' Display a fixed-point scaled up number in decimal-dot notation - scale it back down by divisor
'   e.g., DecimalDot (314159, 100000) would display 3.14159 on the terminal
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

    if si70xx.startx(SCL_PIN, SDA_PIN, I2C_HZ)
        si70xx.serialnum(@_sn)
        case si70xx.firmwarerev{}
            $ff:
                _fw_rev := string("1.0")
            $20:
                _fw_rev := string("2.0")
            other:
                _fw_rev := string("???")
        ser.printf(string("SI70xx driver (SI70%d S/N %x%x, FW rev: %s) started\n"), si70xx.deviceid{}, _sn[1], _sn[0], _fw_rev, 0, 0)
    else
        ser.str(string("SI70xx driver failed to start - halting"))
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
