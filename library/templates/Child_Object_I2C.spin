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
}i

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR


OBJ

    i2c : "com.i2c"                             ' PASM I2C engine (up to ~800kHz)
'    i2c : "tiny.com.i2c"                        ' SPIN I2C engine (~40kHz)
    core: "core.con.your_i2c_device_here"       ' hw-specific low-level const's
    time: "time"                                ' basic timing functions

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins and 100kHz
    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ                 ' validate pins and bus freq
        if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
            time.msleep(core#TPOR)              ' wait for device startup
            if i2c.present(SLAVE_WR)            ' test device bus presence
                if deviceid{} == core#DEVID_RESP' validate device 
                    return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB Stop{}

    i2c.terminate{}

PUB Defaults{}
' Set factory defaults

PUB DeviceID{}: id
' Read device identification

PUB Reset{}
' Reset the device

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        $00..$FF:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)
            i2c.start{}
            i2c.write(SLAVE_RD)

' choose the block below appropriate to your device
    ' write LSByte to MSByte
            repeat tmp from 0 to nr_bytes-1
                byte[ptr_buff][tmp] := i2c.read(tmp == nr_bytes-1)
            i2c.stop{}
    '

    ' write MSByte to LSByte
            repeat tmp from nr_bytes-1 to 0
                byte[ptr_buff][tmp] := i2c.read(tmp == 0)
            i2c.stop{}
    '
        other:                                  ' invalid reg_nr
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        $00..$FF:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)

' choose the block below appropriate to your device
    ' write LSByte to MSByte
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}
    '

    ' write MSByte to LSByte
            repeat tmp from nr_bytes-1 to 0
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}
    '
        other:
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
