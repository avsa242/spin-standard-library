{
    --------------------------------------------
    Filename: memory.sram.23xxxx.spi.spin
    Author: Jesse Burt
    Description: Driver for 23xxxx series
        SPI SRAM
    Copyright (c) 2020
    Started May 20, 2019
    Updated Jan 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Read/write operation modes
    ONEBYTE     = %00
    SEQ         = %01
    PAGE        = %10

' SPI transaction types
    TRANS_CMD   = 0
    TRANS_DATA  = 1

VAR

    byte _CS, _SCK, _MOSI, _MISO

OBJ

    spi : "com.spi.fast"
    core: "core.con.23xxxx"
    time: "time"
    io  : "io"

PUB Null
'This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): okay

    if okay := spi.Start (CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        time.MSleep (1)
        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.Stop

PUB OpMode(mode) | tmp
' Set read/write operation mode
'   Valid values:
'       ONEBYTE (%00): Single byte R/W access
'       SEQ (%01): Sequential R/W access (crosses page boundaries)
'       PAGE (%10): Single page R/W access
'   Any other value polls the chip and returns the current setting
    readReg (TRANS_CMD, core#RDMR, 1, @tmp)
    case mode
        ONEBYTE, SEQ, PAGE:
            mode := (mode << core#FLD_WR_MODE) & core#WRMR_MASK
        OTHER:
            result := (tmp >> 6) & core#BITS_WR_MODE
            return

    writeReg (TRANS_CMD, core#WRMR, 1, @mode)

PUB ReadByte(sram_addr)
' Read a single byte from SRAM
'   Valid values:
'       sram_addr: 0..$01_FF_FF
'   Any other value is ignored                                                                                   
    OpMode(ONEBYTE)
    readReg(TRANS_DATA, sram_addr, 1, @result)

PUB ReadBytes(sram_addr, nr_bytes, buff_addr)
' Read multiple bytes from SRAM
'   Valid values:
'       sram_addr: 0..$01_FF_FF
'   Any other value is ignored                                                                                   
    readReg(TRANS_DATA, sram_addr, nr_bytes, buff_addr)

PUB ReadPage(sram_page_nr, nr_bytes, buff_addr)
' Read up to 32 bytes from SRAM page
'   Valid values:
'       sram_page_nr: 0..4095
'   Any other value is ignored
    case sram_page_nr
        0..4095:
'            OpMode(PAGE)   ' This can be uncommented for simplicity, but page reads are much slower (~514uS vs ~243uS)
            readReg(TRANS_DATA, sram_page_nr << 5 {*32}, nr_bytes, buff_addr)
            return
        OTHER:
            return FALSE

PUB ResetIO
' Reset to SPI mode
    writeReg(TRANS_CMD, core#RSTIO, 1, 0)

PUB WriteByte(sram_addr, val)
' Write a single byte to SRAM
'   Valid values:
'       sram_addr: 0..$01_FF_FF
'   Any other value is ignored
    OpMode(ONEBYTE)
    val &= $FF
    writeReg(TRANS_DATA, sram_addr, 1, @val)

PUB WriteBytes(sram_addr, nr_bytes, buff_addr)
' Write multiple bytes to SRAM
'   Valid values:
'       sram_addr: 0..$01_FF_FF
'   Any other value is ignored
    OpMode(SEQ)
    writeReg(TRANS_DATA, sram_addr, nr_bytes, buff_addr)

PUB WritePage(sram_page_nr, nr_bytes, buff_addr)
' Write up to 32 bytes to SRAM page
'   Valid values:
'       sram_page_nr: 0..4095
'   Any other value is ignored
    case sram_page_nr
        0..4095:
'            OpMode(PAGE)
            writeReg(TRANS_DATA, sram_page_nr << 5 {*32}, nr_bytes, buff_addr)
            return
        OTHER:
            return FALSE

PRI readReg(trans_type, reg, nr_bytes, buff_addr) | cmd_packet, tmp
' Read nr_bytes from register 'reg' to address 'buff_addr'
    case trans_type
        TRANS_CMD:
            case reg
                core#RDMR:
                    spi.Write (TRUE, @reg, 1, FALSE)
                    result := spi.Read(@result, 1)
                    return

        TRANS_DATA:
            case reg
                0..$01_FF_FF:
                    cmd_packet.byte[0] := core#READ
                    cmd_packet.byte[1] := reg.byte[2]
                    cmd_packet.byte[2] := reg.byte[1]
                    cmd_packet.byte[3] := reg.byte[0]

                    spi.Write(TRUE, @cmd_packet, 4, FALSE)
                    spi.Read(buff_addr, nr_bytes)
                    return
                OTHER:
                    return FALSE
        OTHER:
            return FALSE

PRI writeReg(trans_type, reg, nr_bytes, buff_addr) | cmd_packet, tmp
' Write nr_bytes to register 'reg' stored at buff_addr
    case trans_type
        TRANS_CMD:
            case reg
                core#WRMR:
                    cmd_packet.byte[0] := reg
                    cmd_packet.byte[1] := byte[buff_addr][0]
                    spi.Write(TRUE, @cmd_packet, 2, TRUE)
                    return
                core#EQIO, core#EDIO, core#RSTIO:
                    spi.Write(TRUE, @reg, 1, TRUE)
                    return

                OTHER:
                    return FALSE        
        TRANS_DATA:
            case reg
                0..$01_FF_FF:
                    cmd_packet.byte[0] := core#WRITE
                    cmd_packet.byte[1] := reg.byte[2]
                    cmd_packet.byte[2] := reg.byte[1]
                    cmd_packet.byte[3] := reg.byte[0]

                    spi.Write(TRUE, @cmd_packet, 4, FALSE)
                    spi.Write(TRUE, buff_addr, nr_bytes, TRUE)
                    return
                OTHER:
                    return FALSE
        
        OTHER:
            return FALSE

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
