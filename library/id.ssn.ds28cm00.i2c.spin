{
    --------------------------------------------
    Filename: id.ssn.ds28cm00.i2c.spin
    Author: Jesse Burt
    Description: Driver for the DS28CM00
     64-bit I2C Silicon Serial Number
    Copyright (c) 2021
    Started Oct 27, 2019
    Updated Aug 15, 2021
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
    DEF_HZ          = 100_000

    BUS_I2C         = 0
    BUS_SMBUS       = 1

OBJ

#ifdef DS28CM00_PASM
    i2c : "com.i2c"                             ' PASM I2C engine
#elseifdef DS28CM00_SPIN
    i2c : "tiny.com.i2c"                        ' SPIN I2C engine
#else
#error "One of DS28CM00_PASM or DS28CM00_PASM must be defined"
#endif
    core: "core.con.ds28cm00"                   ' HW-specific constants
    time: "time"                                ' timekeeping methods
    crcs: "math.crc"                            ' various CRC routines

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)
            if i2c.present(SLAVE_WR)            ' check device bus presence
                if deviceid{} == core#DEVID_RESP
                    return

    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB CM(mode): curr_mode | cmd_pkt
' Set bus mode to I2C or SMBus
'   Valid values: BUS_I2C (0) or BUS_SMBUS(1)
'   Any other value polls the chip and returns the current setting
    readreg(core#CTRL_REG, 1, @curr_mode)
    case mode
        BUS_I2C, BUS_SMBUS:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := core#CTRL_REG
            cmd_pkt.byte[2] := mode
        other:
            return

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 3)
    i2c.stop{}

PUB CRC{}: crcbyte
' Read the CRC byte from the chip
' NOTE: The CRC is of the first 56-bits of the ROM (8 bits Device Family Code + 48 bits Serial Number)
    readreg(core#CRC, 1, @crcbyte)

PUB CRCValid{}: valid | tmp[2]
' Test CRC returned from chip for equality with calculated CRC
'   Returns TRUE if CRC is valid, FALSE otherwise
    tmp := 0
    readreg(core#DEV_FAMILY, 7, @tmp)
    return (crc{} == crcs.dallasmaximcrc8(@tmp, 7))

PUB DeviceID{}: id
' Reads the Device ID (Family Code)
'   Returns $70
    id := 0
    readreg(core#DEV_FAMILY, 1, @id)

PUB SN(ptr_buff)
' Reads the unique 64-bit serial number into buffer at address ptr_buff
' NOTE: This buffer must be 8 bytes in length.
    readreg(core#DEV_FAMILY, 8, ptr_buff)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the slave device into ptr_buff
    case reg_nr
        core#DEV_FAMILY..core#CTRL_REG:
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)

    i2c.start{}
    i2c.write(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

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
