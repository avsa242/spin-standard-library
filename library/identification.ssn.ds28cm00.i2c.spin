{
    --------------------------------------------
    Filename: identification.ssn.ds28cm00.i2c.spin
    Author: Jesse Burt
    Description: Driver for the DS28CM00 64-bit I2C Silicon Serial Number
    Copyright (c) 2020
    Started Feb 16, 2019
    Updated Jun 24, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 400_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

    BUS_I2C         = 0
    BUS_SMBUS       = 1

VAR


OBJ

    i2c : "com.i2c"
    core: "core.con.ds28cm00"
    time: "time"
    crcs: "math.crc"

PUB Null
''This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                if i2c.present (SLAVE_WR)                       'Response from device?
                    if DeviceID == $70
                        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB CM(mode)
' Set bus mode to I2C or SMBus
'   Valid values: BUS_I2C (0) or BUS_SMBUS(1)
'   Any other value polls the chip and returns the current setting
    readRegX(core#CTRL_REG, 1, @result)
    case mode
        BUS_I2C, BUS_SMBUS:
        OTHER:
            return

    writeRegX(core#CTRL_REG, 1, mode)

PUB CRC
' Read the CRC byte from the chip
' NOTE: The CRC is of the first 56-bits of the ROM (8 bits Device Family Code + 48 bits Serial Number)
    readRegX(core#CRC, 1, @result)

PUB CRCValid | tmp[2]
' Test CRC returned from chip for equality with calculated CRC
'   Returns TRUE if CRC is valid, FALSE otherwise
    tmp := 0
    readRegX(core#DEV_FAMILY, 7, @tmp)
    return (CRC == crcs.DallasMaximCRC8 (@tmp, 7))

PUB DeviceID
' Reads the Device Family Code
'   Returns $70
    readRegX(core#DEV_FAMILY, 1, @result)

PUB SN(buff_addr)
' Reads the unique 64-bit serial number into buffer at address buff_addr
' NOTE: This buffer must be 8 bytes in length.
    readRegX(core#DEV_FAMILY, 8, buff_addr)

PRI readRegX(reg, bytes, dest) | cmd_packet

    case reg
        $00..$08:
        OTHER:
            return

    case bytes
        1..9:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
        OTHER:
            return

    i2c.start
    i2c.wr_block (@cmd_packet, 2)

    i2c.start
    i2c.write (SLAVE_RD)
    i2c.rd_block (dest, bytes, TRUE)
    i2c.stop

PRI writeRegX(reg, bytes, val) | cmd_packet

    case reg
        $08:
        OTHER:
            return

    case val
        0, 1:
        OTHER:
            return

    case bytes
        1:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            cmd_packet.byte[2] := val
        OTHER:
            return

    i2c.start
    i2c.wr_block(@cmd_packet, bytes)
    i2c.stop

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
