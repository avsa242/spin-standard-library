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

    long _CS

OBJ

' choose an SPI engine below
'    spi : "com.spi"                             ' PASM SPI engine (20MHz W/10R)
'    spi : "com.spi.4w"                          ' PASM SPI engine (up to 1MHz)
'    spi : "com.spi.bitbang"                     ' PASM SPI engine (~4MHz)
'    spi : "tiny.com.spi"                        ' SPIN SPI engine (TBD kHz)
    core: "core.con.your_spi_device_here"       ' hw-specific low-level const's
    io  : "io"                                  ' i/o pin convenience methods
    time: "time"                                ' Basic timing functions

PUB Null{}
' This is not a top-level object

PUB Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): status
' Start using custom IO pins
    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if (status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE))
            time.msleep(core#T_POR)             ' wait for device startup
            _CS := CS_PIN                       ' copy i/o pin to hub var
            io.high(_CS)                        ' make sure CS starts high
            io.output(_CS)

            if deviceid{} == core#DEVID_RESP    ' validate device
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    spi.deinit{}

PUB Defaults{}
' Set factory defaults

PUB DeviceID{}: id
' Read device identification

PUB Reset{}
' Reset the device

PRI readReg(reg_nr, nr_bytes, ptr_buff)
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        $00:
        core#REG_NAME:
            ' Special handling for register REG_NAME
        other:                                  ' invalid reg_nr
            return

    io.low(_CS)
    spi.wr_byte(reg_nr)

' choose the block below appropriate to your device
    ' read LSByte to MSByte
    spi.rdblock_lsbf(ptr_buff, nr_bytes)
    io.high(_CS)
    '

    ' read MSByte to LSByte
    spi.rdblock_msbf(ptr_buff, nr_bytes)
    io.high(_CS)
    '

PRI writeReg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        $00:
        core#REG_NAME:
            ' Special handling for register REG_NAME
        other:
            return

    io.low(_CS)
    spi.wr_byte(reg_nr)

' choose the block below appropriate to your device
    ' write LSByte to MSByte
    spi.wrblock_lsbf(ptr_buff, nr_bytes)
    io.high(_CS)
    '

    ' write MSByte to LSByte
    spi.wrblock_msbf(ptr_buff, nr_bytes)
    io.high(_CS)
    '

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
