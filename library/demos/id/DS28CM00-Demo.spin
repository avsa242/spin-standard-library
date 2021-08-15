{
    --------------------------------------------
    Filename: DS28CM00-Demo.spin
    Author: Jesse Burt
    Description: Demo of the DS28CM00 64-bit ROM ID chip
    Copyright (c) 2021
    Started Oct 27, 2019
    Updated Aug 15, 2021
    See end of file for terms of use.
    --------------------------------------------
    NOTE: If a common EEPROM (e.g. AT24Cxxxx) is on the same I2C bus as the SSN,
        the driver may return data from it instead of the SSN. Make sure the EEPROM is
        somehow disabled or test the SSN using different I/O pins.
}
' Uncomment one of the below lines to choose the SPIN or PASM-based I2C engine
#define DS28CM00_PASM
'#define DS28CM00_SPIN

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    I2C_SCL     = 0
    I2C_SDA     = 1
    I2C_HZ      = 400_000
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    ssn     : "id.ssn.ds28cm00.i2c"

VAR

    byte _sn[8]

PUB Main{} | i

    setup{}
    ser.newline{}
    ser.str(string("Device Family: $"))
    ser.hex(ssn.deviceid{}, 2)
    ser.str(string(ser#CR, ser#LF, "Serial Number: $"))
    ssn.sn(@_sn)
    repeat i from 7 to 0
        ser.hex(_sn[i], 2)
    ser.str(string(ser#CR, ser#LF, "CRC: $"))
    ser.hex(ssn.crc{}, 2)
    ser.str(string(", Valid: "))
    case ssn.crcvalid{}
        true: ser.strln(string("Yes"))
        false: ser.strln(string("No"))

    ser.str(string("Halting"))
    repeat

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ssn.startx(I2C_SCL, I2C_SDA, I2C_HZ)
#ifdef DS28CM00_PASM
        ser.strln(string("DS28CM00 driver started (I2C-PASM)"))
#elseifdef DS28CM00_SPIN
        ser.strln(string("DS28CM00 driver started (I2C-SPIN)"))
#endif
    else
        ser.strln(string("DS28CM00 driver failed to start - halting"))
        repeat

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
