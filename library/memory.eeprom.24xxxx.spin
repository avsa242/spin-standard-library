{
    --------------------------------------------
    Filename: memory.eeprom.24xxxx.spin
    Author: Jesse Burt
    Description: Driver for 24xxxx series I2C EEPROM
    Copyright (c) 2023
    Started Oct 26, 2019
    Updated Nov 18, 2023
    See end of file for terms of use.
    --------------------------------------------
}

#include "memory.common.spinh"

CON

    SLAVE_WR    = core#SLAVE_ADDR
    SLAVE_RD    = core#SLAVE_ADDR|1

    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000
    DEF_ADDR    = 0
    I2C_MAX_FREQ= core#I2C_MAX_FREQ

    ERASE_CELL  = $FF

    { default I/O settings; these can be overridden in the parent object }
    SCL         = DEF_SCL
    SDA         = DEF_SDA
    I2C_FREQ    = DEF_HZ
    I2C_ADDR    = DEF_ADDR

VAR

    byte _page_size                             ' EE page size, in bytes
    byte _addr_bits

OBJ

#ifdef EE24XXXX_I2C_BC
    i2c:    "com.i2c.nocog"
#else
    i2c:    "com.i2c"                           ' PASM bit-banged I2C engine
#endif
    core:   "core.con.24xxxx"                   ' HW-specific constants
    time:   "time"                              ' timekeeping methods

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ, I2C_ADDR)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom I/O settings
'   SCL_PIN: I2C serial clock
'   SDA_PIN: I2C serial data
'   I2C_HZ: I2C bus speed
'   ADDR_BITS: optional address bits for alternate bus address
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.msleep(1)
            _addr_bits := (ADDR_BITS << 1)
            ee_size(512)                        ' most common P1 EE size
            if ( i2c.present(SLAVE_WR) )        ' check device bus presence
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}
    _page_size := 0

PUB ee_size(size): curr_eesize
' Set EEPROM size, in kilobits
    case size
        1, 2:
            _page_size := 8
        4, 8, 16:
            _page_size := 16
        32, 64:
            _page_size := 32
        128, 256:
            _page_size := 64
        512:
            _page_size := 128
        1024, 2048:
            _page_size := 256
        other:
            return

PUB page_size{}: psz
' Page size of currently set EEPROM size
    return _page_size

PUB rd_block_lsbf(ptr_buff, addr, nr_bytes) | cmd_pkt
' Read a block of memory starting at addr, LSB-first
    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := addr.byte[1]
    cmd_pkt.byte[2] := addr.byte[0]
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 3)

    i2c.start{}
    i2c.write(SLAVE_RD | _addr_bits)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

PUB rd_block_msbf(ptr_buff, addr, nr_bytes) | cmd_pkt
' Read a block of memory starting at addr, MSB-first
    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := addr.byte[1]
    cmd_pkt.byte[2] := addr.byte[0]
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 3)

    i2c.start{}
    i2c.write(SLAVE_RD | _addr_bits)
    i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

PUB wr_block_lsbf(addr, ptr_buff, nr_bytes) | cmd_pkt
' Write a block of memory starting at addr, LSB-first
    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := addr.byte[1]
    cmd_pkt.byte[2] := addr.byte[0]
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 3)
    i2c.wrblock_lsbf(ptr_buff, nr_bytes)
    i2c.stop{}
    time.msleep(core#T_WR)                      ' Wait "Write cycle time"

PUB wr_block_msbf(addr, ptr_buff, nr_bytes) | cmd_pkt
' Write a block of memory starting at addr, MSB-first
    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := addr.byte[1]
    cmd_pkt.byte[2] := addr.byte[0]
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 3)
    i2c.wrblock_msbf(ptr_buff, nr_bytes)
    i2c.stop{}
    time.msleep(core#T_WR)                      ' Wait "Write cycle time"

DAT
{
Copyright 2023 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

