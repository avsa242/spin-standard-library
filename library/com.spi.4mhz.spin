{
----------------------------------------------------------------------------------------------------
    Filename:       com.spi.4mhz.spin
    Description:    PASM SPI engine (~4MHz)
        (no chip-select handling)
        @80MHz Fsys:
            Write speed: 4.16MHz actual - exact timings vary:
                (16% duty - 0.04uS H : 0.2uS L) 240ns
                (23% duty - 0.06uS H : 0.2uS L) 260ns
            Read speed: 4.16MHz actual (41% duty - 0.1uS H : 0.14uS L) 240
    Author:         Jesse Burt
    Started:        Apr 9, 2022
    Updated:        Dec 22, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------

    NOTE: This is based on excerpts of nRF24L01P.spin,
        originally by Mark Tillotson.
}

CON

    ' PASM engine states
    CMD_IDLE        = 0                         ' default state (waiting for command)
    CMD_RDBLK_LSBF  = 1 << 16                   ' block read, LSByte-first (byte[ptr+0..n])
    CMD_WRBLK_LSBF  = 2 << 16                   ' block write, LSByte-first (byte[ptr+n..0])


VAR

    long _command
    byte _cog


PUB null()
' This is not a top-level object


PUB init(SCK, MOSI, MISO, SPI_MODE): status
' Initialize SPI engine using custom pins
'   SCK:    SPI/serial clock pin, 0..31
'   MOSI:   SPI master-out slave-in pin, 0..31
'   MISO:   SPI master-in slave-out pin, 0..31
'       NOTE: Specify the same pin for MOSI and MISO to use 3-wire SPI
'   SPI_MODE: 0..3
'       0: CPOL 0, CPHA 0
'           SCK idles low
'           MISO shifted in on rising clock pulse
'           MOSI shifted out on falling clock pulse
'       1: CPOL 0, CPHA 1   XXX NOT YET SUPPORTED
'           SCK idles low
'           MISO shifted in on falling clock pulse
'           MOSI shifted out on rising clock pulse
'       2: CPOL 1, CPHA 0   XXX NOT YET SUPPORTED
'           SCK idles high
'           MISO shifted in on falling clock pulse
'           MOSI shifted out on rising clock pulse
'       3: CPOL 1, CPHA 1   XXX NOT YET SUPPORTED
'           SCK idles high
'           MISO shifted in on rising clock pulse
'           MOSI shifted out on falling clock pulse
'   NOTE: CS must be handled by the parent object
    _command.byte[0] := SCK
    _command.byte[1] := MOSI
    _command.byte[2] := MISO
    _command.byte[3] := SPI_MODE
    status := _cog := cognew (@entry, @_command) + 1


PUB deinit()
' Deinitialize
'   Float I/O pins, clear out hub vars, and stop the PASM engine
    if ( _cog )
        cogstop(_cog - 1)
        _cog := 0
    _command := 0


PUB rdblock_lsbf(ptr_buff, nr_bytes)
' Read block of data from SPI bus, least-significant byte first
    _command := CMD_RDBLK_LSBF + @ptr_buff
    repeat while _command


PUB rdblock_msbf(ptr_buff, nr_bytes) | i
' Read block of data from SPI bus, most-significant byte first
    repeat i from nr_bytes-1 to 0
        rdblock_lsbf(ptr_buff+i, 1)


PUB wrblock_lsbf(ptr_buff, nr_bytes)
' Write block of data to SPI bus from ptr_buff, least-significant byte first
    _command := CMD_WRBLK_LSBF + @ptr_buff
    repeat while _command


PUB wrblock_msbf(ptr_buff, nr_bytes) | i
' Write block of data to SPI bus from ptr_buff, most-significant byte first
    repeat i from nr_bytes-1 to 0
        wrblock_lsbf(ptr_buff+i, 1)


#include "com.spi.common.spinh"                 ' R/W methods common to all SPI engines


DAT

                org
entry
                rdlong  p_parms, par
                mov     t0,         p_parms
                and     t0,         #$1f
                mov     _sck,       #1
                shl     _sck,       t0
                mov     t0,         p_parms
                shr     t0,         #8
                and     t0,         #$1f
                mov     _mosi,      #1
                shl     _mosi,      t0
                mov     t0,         p_parms
                shr     t0,         #16
                and     t0,         #$1f
                mov     _miso,      #1
                shl     _miso,      t0
                andn    outa,       _sck        ' init SCK low
                or      dira,       _sck        '   and output
                jmp     #cmd_exit


cmd_wait
' Wait for command issued to engine
                rdlong  p_parms,    par wz      ' wait for command
    if_z        jmp     #cmd_wait

                mov     t1,         p_parms     ' copy params from hub
                rdlong  p_buff,     t1          ' pointer to user data to R/W
                add     t1,         #4
                rdlong  ctr,        t1          ' nr_bytes to R/W
                add     t1,         #4
                mov     t0,         p_parms     ' validate command
                shr     t0,         #16 wz
    if_z        jmp     #cmd_exit
                shl     t0,         #1
                add     t0,         #:cmd_table-2
                jmp     t0

:cmd_table      call    #rd_blk_lsbf            ' read block, LSByte-first
                jmp     #cmd_exit
                call    #wr_blk_lsbf            ' write block, LSByte-first
                jmp     #cmd_exit


cmd_exit        wrlong  _zero,      par         ' signal to hub cmd is complete
                jmp     #cmd_wait


rd_blk_lsbf
' Read multiple bytes
'   p_buff: pointer to buffer in hub
'   ctr: number of bytes to read
                andn    dira,       _miso       ' MISO: input
:byteloop
                call    #rd8_bits               ' shift in bits
                wrbyte  data,       p_buff      ' write byte to hub
                add     p_buff,     #1          ' advance to next byte
                djnz    ctr,        #:byteloop  ' loop if more bytes left
rd_blk_lsbf_ret ret


wr_blk_lsbf
' Write multiple bytes
'   p_buff: pointer to buffer in hub
'   ctr: number of bytes to write
                or      dira,       _mosi       ' MOSI: output
:byteloop
                rdbyte  data,       p_buff      ' read byte from hub and
                call    #wr8_bits               '   shift it out
                add     p_buff,     #1          ' advance to next byte
                djnz    ctr,        #:byteloop  ' loop if more bytes left
                andn    dira,       _mosi       ' release MOSI
wr_blk_lsbf_ret ret


rd8_bits
' Read 8 bits from MISO
                mov     bits,       #8
:bitloop
                rcl     data,       #1  wc      ' rotate carry into data
                xor     outa,       _sck        ' clock in the next bit
                test    _miso,      ina wc
                xor     outa,       _sck
                djnz    bits,       #:bitloop   ' loop if more bits left
                rcl     data,       #1          ' shift last MISO bit into data
                and     data,       #$FF
rd8_bits_ret    ret


wr8_bits
' Write 8 bits to MOSI
                mov     bits,       #8
                shl     data,       #24         ' left align byte in long
:bitloop
                rcl     data,       #1  wc      ' rotate out MSBit into carry
                muxc    outa,       _mosi       ' set MOSI state to MSB
                xor     outa,       _sck        ' clock out bit
                xor     outa,       _sck
                djnz    bits,       #:bitloop   ' loop if more bits left
wr8_bits_ret    ret


_zero           long    0                       ' Zero

' SPI I/O pins
_sck            long    0
_mosi           long    0
_miso           long    0

' Uninitialized data
t0              res     1
t1              res     1

bits            res     1
p_parms         res     1
data            res     1
p_buff          res     1
ctr             res     1


DAT
{
Copyright 2024 Jesse Burt

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

