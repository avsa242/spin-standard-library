{
    --------------------------------------------
    Filename:
    Author:
    Description:
    Copyright (c) 20__
    Started Month Day, Year
    Updated Month Day, Year
    See end of file for terms of use.
    --------------------------------------------
}

CON


VAR

    byte _CS, _MOSI, _MISO, _SCK

OBJ

    spi : "com.spi.4w"                                          'PASM SPI Driver
    core: "core.con.your_spi_device_here"                       'File containing your device's register set
    io  : "io"
    time: "time"                                                'Basic timing functions

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, SCK_DELAY): okay

    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if SCK_DELAY => 1
            if okay := spi.start (SCK_DELAY, core#CPOL)         ' SPI engine started?
                time.MSleep (1)                                 ' Device startup time
                _CS := CS_PIN
                _MOSI := MOSI_PIN
                _MISO := MISO_PIN
                _SCK := SCK_PIN

                io.High(_CS)
                io.Output(_CS)

                if DeviceID == core#DEVID_RESP
                    return okay
    return FALSE                                                ' If we got here, something went wrong

PUB Stop

PUB Defaults
' Set factory defaults

PUB DeviceID
' Read device identification

PUB Reset
' Reset the device

PRI readReg(reg_nr, nr_bytes, buff_addr) | tmp
' Read nr_bytes from register 'reg_nr' to address 'buff_addr'
    case reg_nr
        $00:                                                    ' Validate register number
        core#REG_NAME:
            'Special handling for register REG_NAME
        OTHER:
            return FALSE

    io.Low(_CS)
    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg_nr)

    repeat tmp from 0 to nr_bytes-1
        byte[buff_addr][tmp] := spi.SHIFTIN(_MISO, _SCK, core#MISO_BITORDER, 8)
    io.High(_CS)

PRI writeReg(reg_nr, nr_bytes, buff_addr) | tmp
' Write nr_bytes to register 'reg_nr' stored at buff_addr
    case reg_nr
        $00:                                                    ' Validate register number
        core#REG_NAME:
            'Special handling for register REG_NAME
        OTHER:
            return FALSE

    io.Low(_CS)
    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg_nr)

    repeat tmp from 0 to nr_bytes-1
        spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][tmp])
    io.High(_CS)

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
