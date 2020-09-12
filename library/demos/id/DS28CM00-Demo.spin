{
    --------------------------------------------
    Filename: DS28CM00-Demo.spin
    Author: Jesse Burt
    Description: Demo of the DS28CM00 64-bit ROM ID chip
    Copyright (c) 2020
    Started Oct 27, 2019
    Updated Sep 12, 2020
    See end of file for terms of use.
    --------------------------------------------
    NOTE: If a common EEPROM (e.g. AT24Cxxxx) is on the same I2C bus as the SSN,
        the driver may return data from it instead of the SSN. Make sure the EEPROM is
        somehow disabled or test the SSN using different I/O pins.
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    I2C_SCL     = 24
    I2C_SDA     = 25
    I2C_HZ      = 400_000
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    ssn     : "id.ssn.ds28cm00.i2c"

VAR

    byte _ser_cog
    byte _sn[8]

PUB Main{} | i

    setup{}
    ser.newline{}
    ser.str(string("Device Family: $"))
    ser.hex(ssn.deviceid{}, 2)
    ser.str(string(ser#CR, ser#LF, "Serial Number: $"))
    ssn.sn(@_sn)
    repeat i from 0 to 7
        ser.hex(_sn.byte[i], 2)
    ser.str(string(ser#CR, ser#LF, "CRC: $"))
    ser.hex(ssn.crc{}, 2)
    ser.str(string(", Valid: "))
    case ssn.crcvalid{}
        true: ser.str(string("Yes"))
        false: ser.str(string("No"))

    ser.str(string(ser#CR, ser#LF, "Halting"))
    repeat

PUB Setup{}

    repeat until ser.startrxtx(SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if ssn.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str(string("DS28CM00 driver started", ser#CR, ser#LF))
    else
        ser.str(string("DS28CM00 driver failed to start - halting", ser#CR, ser#LF))
        ssn.stop{}
        time.msleep (5)
        ser.stop{}

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
