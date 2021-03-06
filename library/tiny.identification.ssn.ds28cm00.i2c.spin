{
    --------------------------------------------
    Filename: tiny.identification.ssn.ds28cm00.i2c.spin
    Author: Jesse Burt
    Description: Driver for the DS28CM00 64-bit I2C Silicon Serial Number
    Copyright (c) 2019
    Started Oct 27, 2019
    Updated Oct 27, 2019
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This driver will start successfully if the Propeller's EEPROM is on
        the chosen I2C bus and will return data from the EEPROM!
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29

    BUS_I2C         = 0
    BUS_SMBUS       = 1

VAR


OBJ

    i2c : "tiny.com.i2c"
    core: "core.con.ds28cm00"
    time: "time"
    crcs: "math.crc"

PUB Null
''This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA)

PUB Startx(SCL_PIN, SDA_PIN): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        i2c.Setupx (SCL_PIN, SDA_PIN)            'I2C Object Started?
        time.MSleep (1)
        if i2c.Present (SLAVE_WR)                       'Response from device?
            return cogid+1

    return FALSE                                            'If we got here, something went wrong

PUB Stop

PUB CM(mode)
' Set bus mode to I2C or SMBus
'   Valid values: BUS_I2C (0) or BUS_SMBUS(1)
'   Any other value polls the chip and returns the current setting
    readReg(core#CTRL_REG, 1, @result)
    case mode
        BUS_I2C, BUS_SMBUS:
        OTHER:
            return

    writeReg(core#CTRL_REG, 1, mode)

PUB CRC
' Read the CRC byte from the chip
' NOTE: The CRC is of the first 56-bits of the ROM (8 bits Device Family Code + 48 bits Serial Number)
    readReg(core#CRC, 1, @result)

PUB CRCValid | tmp[2]
' Test CRC returned from chip for equality with calculated CRC
'   Returns TRUE if CRC is valid, FALSE otherwise
    tmp := 0
    readReg(core#DEV_FAMILY, 7, @tmp)
    return (CRC == crcs.DallasMaximCRC8 (@tmp, 7))

PUB DeviceFamily
' Reads the Device Family Code
'   Returns $70
    readReg(core#DEV_FAMILY, 1, @result)

PUB SN(buff_addr)
' Reads the unique 64-bit serial number into buffer at address buff_addr
' NOTE: This buffer must be 8 bytes in length.
    readReg(core#DEV_FAMILY, 8, buff_addr)

PRI readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp

    case reg
        $00..$08:
        OTHER:
            return

    case nr_bytes
        1..9:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
        OTHER:
            return

    i2c.Start
    i2c.Write(cmd_packet.byte[0])
    i2c.Write(cmd_packet.byte[1])    

    i2c.Start
    i2c.Write (SLAVE_RD)
    repeat tmp from 0 to nr_bytes-1
        byte[buff_addr][tmp] := i2c.Read(tmp == (nr_bytes-1))
    i2c.Stop

PRI writeReg(reg, nr_bytes, val) | cmd_packet, tmp

    case reg
        $08:
        OTHER:
            return

    case val
        0, 1:
        OTHER:
            return

    case nr_bytes
        1:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            cmd_packet.byte[2] := val
        OTHER:
            return

    i2c.Start
    repeat tmp from 0 to 2
        i2c.Write(cmd_packet.byte[tmp])
    i2c.Stop

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
