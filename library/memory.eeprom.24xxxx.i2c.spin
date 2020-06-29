{
    --------------------------------------------
    Filename: memory.eeprom.24xxxx.i2c.spin
    Author: Jesse Burt
    Description: Driver for 24xxxx-series I2C EEPROMs
    Copyright (c) 2019
    Started Oct 26, 2019
    Updated Jun 29, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR


OBJ

    i2c : "com.i2c"
    core: "core.con.24xxxx.spin"
    time: "time"

PUB Null
'This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                if i2c.present (SLAVE_WR)                       'Response from device?
                    return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB ReadByte(ee_addr)
' Read single byte from EEPROM
    readReg(ee_addr, 1, @result)

PUB ReadBytes(ee_addr, nr_bytes, buff_addr)
' Read multiple bytes from EEPROM
    readReg(ee_addr, nr_bytes, buff_addr)

PUB WriteByte(ee_addr, data)
' Write single byte to EEPROM
    writeReg(ee_addr, 1, @data)

PUB WriteBytes(ee_addr, nr_bytes, buff_addr) | tmp
' Write multiple bytes to EEPROM
'   nr_bytes Valid values: 1..64 (page boundary)
    case nr_bytes
        1..64:
            writeReg(ee_addr, nr_bytes, buff_addr)
        OTHER:
            return FALSE

PRI readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Read num_bytes from the slave device into the address stored in buff_addr
    case reg
        $000000..$01FFFF:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg.byte[1]
            cmd_packet.byte[2] := reg.byte[0]
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 3)

            i2c.Start
            i2c.Write (SLAVE_RD)
            i2c.Rd_Block (buff_addr, nr_bytes, TRUE)
            i2c.Stop
        OTHER:
            return

PRI writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Write num_bytes to the slave device from the address stored in buff_addr
    case reg
        $000000..$01FFFF:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg.byte[1]
            cmd_packet.byte[2] := reg.byte[0]
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 3)
            i2c.Wr_Block (buff_addr, nr_bytes)
            i2c.Stop
            time.MSleep (core#T_WR)                         ' Wait "Write cycle time"
        OTHER:
            return


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
