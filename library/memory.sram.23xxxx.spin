{
    --------------------------------------------
    Filename: memory.sram.23xxxx.spin
    Author: Jesse Burt
    Description: Driver for 23xxxx series SPI SRAM
    Copyright (c) 2023
    Started May 20, 2019
    Updated Jul 13, 2023
    See end of file for terms of use.
    --------------------------------------------
}

#include "memory.common.spinh"

CON

    { R/W operation modes }
    ONEBYTE     = %00
    SEQ         = %01
    PAGE        = %10

    ERASE_CELL  = $00

    { default I/O settings; these can be overridden in the parent object }
    CS          = 0
    SCK         = 1
    MOSI        = 2
    MISO        = 2

VAR

    long _CS

OBJ

    spi:    "com.spi.20mhz"                     ' PASM SPI engine
    core:   "core.con.23xxxx"                   ' hw-specific constants
    time:   "time"                              ' basic timekeeping functions

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start the driver using default I/O settings
    return startx(CS, SCK, MOSI, MISO)

PUB startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): status
' Start the driver using custom I/O settings
    if ( lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and ...
        lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31) )
        if ( status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE) )
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            time.msleep(1)
            return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
'   Stop running cog(s), set used I/O pins to float, clear memory
    spi.deinit{}
    dira[_CS] := 0                              ' relinquish control over CS
    _CS := 0

PUB defaults{}
' Factory default settings
    opmode(SEQ)

PUB opmode(mode): curr_mode
' Set read/write operation mode
'   Valid values:
'       ONEBYTE (%00): Confine access to single address
'      *SEQ (%01): Entire SRAM accessible, no page boundaries
'           (address counter wraps to 00_00_00 after reaching
'           the end of the SRAM)
'       PAGE (%10): Confine access to single page
'           (address counter wraps to start of page address after reaching the
'           end of the page)
'   Any other value polls the chip and returns the current setting
    readreg(core#RDMR, 1, @curr_mode)
    case mode
        ONEBYTE, SEQ, PAGE:
            mode := (mode << core#WR_MODE) & core#WRMR_MASK
        other:
            return (curr_mode >> core#WR_MODE) & core#WR_MODE_BITS

    writereg(core#WRMR, 1, @mode)

PUB page_size{}: psz
' Page size of SRAM
    return 32

PUB reset_io{}
' Reset to SPI mode
    writereg(core#RSTIO, 1, 0)

PUB rd_block_lsbf(ptr_buff, addr, nr_bytes) | cmd_pkt
' Read a block of data from memory starting at addr, LSB-first
    cmd_pkt.byte[0] := core#READ
    cmd_pkt.byte[1] := addr.byte[2] & 1
    cmd_pkt.byte[2] := addr.byte[1]
    cmd_pkt.byte[3] := addr.byte[0]

    outa[_CS] := 0
    spi.wrblock_lsbf(@cmd_pkt, 4)
    spi.rdblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1

PUB rd_block_msbf(ptr_buff, addr, nr_bytes) | cmd_pkt
' Read a block of data from memory starting at addr, MSB-first
    cmd_pkt.byte[0] := core#READ
    cmd_pkt.byte[1] := addr.byte[2] & 1
    cmd_pkt.byte[2] := addr.byte[1]
    cmd_pkt.byte[3] := addr.byte[0]

    outa[_CS] := 0
    spi.wrblock_lsbf(@cmd_pkt, 4)
    spi.rdblock_msbf(ptr_buff, nr_bytes)
    outa[_CS] := 1

PUB wr_block_lsbf(addr, ptr_buff, nr_bytes) | cmd_pkt
' Write a block of data to memory starting at addr, LSB_first
    cmd_pkt.byte[0] := core#WRITE
    cmd_pkt.byte[1] := addr.byte[2] & 1
    cmd_pkt.byte[2] := addr.byte[1]
    cmd_pkt.byte[3] := addr.byte[0]

    outa[_CS] := 0
    spi.wrblock_lsbf(@cmd_pkt, 4)
    spi.wrblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1

PUB wr_block_msbf(addr, ptr_buff, nr_bytes) | cmd_pkt
' Write a block of data to memory starting at addr, MSB-first
    cmd_pkt.byte[0] := core#WRITE
    cmd_pkt.byte[1] := addr.byte[2] & 1
    cmd_pkt.byte[2] := addr.byte[1]
    cmd_pkt.byte[3] := addr.byte[0]

    outa[_CS] := 0
    spi.wrblock_lsbf(@cmd_pkt, 4)
    spi.wrblock_msbf(ptr_buff, nr_bytes)
    outa[_CS] := 1

PRI readreg(reg_nr, nr_bytes, ptr_buff)
' Read nr_bytes from device into ptr_buff
    case reg_nr
        core#RDMR:
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            spi.rdblock_lsbf(ptr_buff, 1)
            outa[_CS] := 1
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to device from ptr_buff
    case reg_nr
        core#WRMR:
            cmd_pkt.byte[0] := reg_nr
            cmd_pkt.byte[1] := byte[ptr_buff][0]
            outa[_CS] := 0
            spi.wrblock_lsbf(@cmd_pkt, 2)
            outa[_CS] := 1
            return
        core#EQIO, core#EDIO, core#RSTIO:
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            outa[_CS] := 1
            return
        other:
            return

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

