{
    --------------------------------------------
    Filename: com.spi.20mhz.spin
    Author: Jesse Burt
    Description: Fast PASM SPI engine (20MHz W, 10MHz R)
        (_no builtin-Chip Select support_)
        @80MHz Fsys:
            Write speed: 20MHz, exact timings vary:
                19.23MHz actual (53% duty - 0.028uS H : 0.024uS L) 52ns
                20.83MHz actual (50% duty - 0.024uS H : 0.024uS L) 48ns
            Read speed: 10MHz:
                9.99MHz actual (52% duty - 0.052uS H : 0.048uS L) 100ns
    Started Jun 30, 2021
    Updated Jun 15, 2023
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on the PASM portion of Timothy D. Swieter's Wiznet W5200 driver
        adapted for use as a general-purpose SPI engine.
}

CON

' PASM engine states
    CMD_IDLE        = 0                         ' waiting for command
    CMD_RDBLK_LSBF  = 1 << 16                   ' read byte(s)
    CMD_RDBLK_MSBF  = 2 << 16
    CMD_WRBLK_LSBF  = 3 << 16                   ' write byte(s)
    CMD_WRBLK_MSBF  = 4 << 16
    CMD_WR8_X       = 5 << 16
    CMD_WR16_X_LSBF = 6 << 16
    CMD_WR16_X_MSBF = 7 << 16

VAR

    long _cog

OBJ

    ctrs : "core.con.counters"                  ' counter setup symb. constants

DAT

' Command setup
    _command    long    0                       ' PASM engine cmd + args

PUB null{}
' This is not a top-level object

PUB init(SCK, MOSI, MISO, SPI_MODE): status
' Initialize SPI engine using custom pins
'   SCK, MOSI, MISO: 0..31 (each unique)
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
    deinit

    _sck_mask := |< SCK
    _mosi_mask := |< MOSI
    _miso_mask := |< MISO

' pre-define counter modes for PASM engine
    ctramode := (ctrs#NCO_SINGLEEND | ctrs#VCO_DIV_128) + SCK
    ctrbmode := (ctrs#NCO_SINGLEEND | ctrs#VCO_DIV_128) + MOSI

' start the PASM engine in a new cog
    status := _cog := cognew(@entry, @_command) + 1

PUB deinit{}
' Deinitialize
'   Float I/O pins, clear out hub vars, and stop the PASM engine
    if ( _cog )
        cogstop(_cog - 1)
        longfill(@_sck_mask, 0, 3)              ' Clear all masks
        _cog := 0
    _command := 0

PUB rdblock_lsbf(ptr_buff, nr_bytes)
' Read a block of data from the device, least-significant byte first
'   ptr_buff: pointer to buffer to read into
'   nr_bytes: number of bytes to read
    _command := CMD_RDBLK_LSBF + @ptr_buff
    repeat while _command

PUB rdblock_msbf(ptr_buff, nr_bytes) | i
' Read a block of data from the device, most-significant byte first
'   ptr_buff: pointer to buffer to read into
'   nr_bytes: number of bytes to read
    _command := CMD_RDBLK_MSBF + @ptr_buff
    repeat while _command

PUB wrblock_lsbf(ptr_buff, nr_bytes)
' Write a block of data to the device, least-significant byte first
'   ptr_buff: pointer to data to write
'   nr_bytes: number of bytes to write
    _command := CMD_WRBLK_LSBF + @ptr_buff
    repeat while _command

PUB wrblock_msbf(ptr_buff, nr_bytes)
' Write a block of data to the device, most-significant byte first
'   ptr_buff: pointer to data to write
'   nr_bytes: number of bytes to write
    _command := CMD_WRBLK_MSBF + @ptr_buff
    repeat while _command

#define HAS_WR_BYTEX
' Normally the common code #included provides this, but this engine has native support
PUB wr_bytex(val, rep_nr)
' Write a byte repeatedly to the device
'   val: byte to write
'   rep_nr: number of times to write the byte
    _command := CMD_WR8_X + @val
    repeat while _command

#define HAS_WRWORDX_LSBF
' Normally the common code #included provides this, but this engine has native support
PUB wrwordx_lsbf(val, rep_nr)
' Write a word (least-significant byte first) repeatedly to the device
'   val: word to write
'   rep_nr: number of times to write the word
    _command := CMD_WR16_X_LSBF + @val
    repeat while _command

#define HAS_WRWORDX_MSBF
' Normally the common code #included provides this, but this engine has native support
PUB wrwordx_msbf(val, rep_nr)
' Write a word (most-significant byte first) repeatedly to the device
'   val: word to write
'   rep_nr: number of times to write the word
    _command := CMD_WR16_X_MSBF + @val
    repeat while _command

#include "com.spi.common.spinh"                 ' R/W methods common to all SPI engines

DAT
                org
entry
' Set the initial state of the I/O
' (unless listed here, the output is initialized as off/low)
                or      dira, _sck_mask         ' set as outputs
                or      dira, _mosi_mask        '

                mov     frqb, #0                ' init ctrb
                mov     ctrb, ctrbmode          '   (used by MOSI)

cmd_wait
' Wait for command issued to engine
                rdlong  ptr_params, par wz      ' command passed to engine?
    if_z        jmp     #cmd_wait               ' if not, loop until there is

                mov     t0, ptr_params          ' get command/address
                rdlong  param_a, t0             ' get parameters
                add     t0, #4                  '
                rdlong  param_b, t0             '

                mov     cmd, ptr_params         ' get command/address
                shr     cmd, #16 wz             ' command
    if_z        jmp     #:cmd_exit              ' no; exit loop
                shl     cmd, #1
                add     cmd, #:cmd_tbl-2        ' add in the "call" address
                jmp     cmd                     ' Jump to the command


:cmd_tbl
' Command table
                call    #rd_blk_lsbf            ' read block, LSByte-first
                jmp     #:cmd_exit
                call    #rd_blk_msbf            '   MSByte-first
                jmp     #:cmd_exit
                call    #wr_blk_lsbf            ' write block, LSByte-first
                jmp     #:cmd_exit
                call    #wr_blk_msbf            '   MSByte-first
                jmp     #:cmd_exit
                call    #wr8_x                  ' write a byte repeatedly
                jmp     #:cmd_exit
                call    #wr16_x_lsbf            ' write a word (LSB-first) repeatedly
                jmp     #:cmd_exit
                call    #wr16_x_msbf            ' write a word (MSB-first) repeatedly
                jmp     #:cmd_exit


:cmd_exit
' Clear command status and wait for new command
                wrlong  _zero, par              ' clear the command status
                jmp     #cmd_wait               ' wait for next command


setup_ptr
' Set up pointer-to and length-of data from hub
                mov     ptr_hub, param_a        ' get hub read buff. pointer
                mov     ctr, param_b            ' get nr. bytes to read
setup_ptr_ret   ret                             ' complete


rd_blk_lsbf
' Read a block of data, LSB-first (start at the beginning of the data, working forwards)
                call    #setup_ptr
:byteloop
                call    #rd8_bits               ' Read one data byte
                and     data, _bytemask         ' Ensure there is only a byte
                wrbyte  data, ptr_hub           ' Write the byte to hubram

                add     ptr_hub, #1             ' next (byte) hubram address
                djnz    ctr, #:byteloop         ' loop if more bytes to read
rd_blk_lsbf_ret ret                             ' complete


rd_blk_msbf
' Read a block of data, MSB-first (start at the beginning of the data, working forwards)
                call    #setup_ptr
                add     ptr_hub, ctr
:byteloop
                sub     ptr_hub, #1
                call    #rd8_bits               ' Read one data byte
                and     data, _bytemask         ' Ensure there is only a byte
                wrbyte  data, ptr_hub           ' Write the byte to hubram
                djnz    ctr, #:byteloop         ' loop if more bytes to read
rd_blk_msbf_ret ret                             ' complete


wr8_x
' Write the same byte to the SPI bus many times
                mov     ctr, param_b            ' get setup from hub params
:byteloop       mov     data, param_a
                call    #wr8_bits               ' write it
                djnz    ctr, #:byteloop         ' loop if more bytes to write
wr8_x_ret       ret


wr16_x_lsbf
' Write the same word (LSByte first) to the SPI bus many times
'   param_a: pointer to word to write
'   param_b: number of times to write
                mov     ctr, param_b
:wordloop       mov     data, param_a
                call    #wr8_bits               ' write LSB
                ror     data, #8                ' put the MSB into position,
                call    #wr8_bits               '   and write
                djnz    ctr, #:wordloop         ' loop if more words to write
wr16_x_lsbf_ret ret


wr16_x_msbf
' Write the same word (MSByte first) to the SPI bus many times
'   param_a: pointer to word to write
'   param_b: number of times to write
                mov     ctr, param_b
:wordloop       mov     data, param_a
                ror     data, #8                ' put the MSByte into position
                call    #wr8_bits               '   and write it
                rol     data, #8                ' put things back, so the LSB
                call    #wr8_bits               '   is in position, and write
                djnz    ctr, #:wordloop         ' loop if more words to write
wr16_x_msbf_ret ret


wr_blk_lsbf
' Write a block of data, LSB-first (start at the beginning of the data, working forwards)
                call    #setup_ptr
:byteloop
                rdbyte  data, ptr_hub           ' read the byte from hubram
                call    #wr8_bits               ' write one byte

                add     ptr_hub, #1             ' next (byte) hubram address
                djnz    ctr, #:byteloop         ' loop if more bytes to write
wr_blk_lsbf_ret ret                             ' complete


wr_blk_msbf
' Write a block of data, MSB-first (start at the end of the data, working backwards)
                call    #setup_ptr
                add     ptr_hub, ctr            ' point to the end of the data (MSB-first)
:byteloop
                sub     ptr_hub, #1
                rdbyte  data, ptr_hub           ' read a byte from hubram
                call    #wr8_bits               ' write one byte
                djnz    ctr, #:byteloop         ' loop if more bytes to write
wr_blk_msbf_ret ret


wr8_bits
' Low-level write routine
'   Shift out PHSB bit 31 to MOSI
' Counter A: SCK
' Counter B: MOSI
                andn    outa, _sck_mask         ' clock off, SCK low
                mov     phsb, #0
                mov     phsb, data              ' load PHSB with data

                shl     phsb, #24               ' left-justify it
                mov     frqa, frq20             ' set write frequency
                mov     phsa, phs20             ' phase of data/clock
                mov     ctra, ctramode          ' start clocking
                rol     phsb, #1                ' rotate each bit into
                rol     phsb, #1                '   position...
                rol     phsb, #1
                rol     phsb, #1
                rol     phsb, #1
                rol     phsb, #1
                rol     phsb, #1
                mov     ctra, #0                ' turn off clocking
wr8_bits_ret    ret                             ' complete


rd8_bits
' Low-level read routine
'   Shift in bits from MISO (unrolled loop)
' Counter A: SCK
                mov     frqa, frq10             ' set read frequency
                mov     phsa, phs10             ' phase of data/clock
                nop
                mov     ctra, ctramode          ' start clocking
                test    _MISO_mask, ina wc      ' shift in each bit
                rcl     data, #1
                test    _MISO_mask, ina wc
                rcl     data, #1
                test    _MISO_mask, ina wc
                rcl     data, #1
                test    _MISO_mask, ina wc
                rcl     data, #1
                test    _MISO_mask, ina wc
                rcl     data, #1
                test    _MISO_mask, ina wc
                rcl     data, #1
                test    _MISO_mask, ina wc
                rcl     data, #1
                test    _MISO_mask, ina wc
                mov     ctra, #0                ' disable clocking to avoid
                rcl     data, #1                '   odd behavior
rd8_bits_ret    ret                             ' complete


' Initialized data
_zero           long    0                       ' zero
_bytemask       long    $FF                     ' byte mask

' Pin/mask definitions are initialized in SPIN and program/memory modified
'   here before the COG is started
_sck_mask       long    0-0                     ' Serial Clock
_mosi_mask      long    0-0                     ' Master out slave in - output
_miso_mask      long    0-0                     ' Master in slave out - input

' NOTE: Data that is initialized in SPIN and program/memory modified here
'   before COG is started
ctramode        long    0-0                     ' counter A: SCK
ctrbmode        long    0-0                     ' counter B: MOSI

frq20           long    $4000_0000              ' counter A & B: frqa (write)
                                                '   (CLKFREQ / 4)
phs20           long    $5000_0000              ' counter A & B: phsa (write)
                                                '  (set relationship of MOSI
                                                '   to SCK)

frq10           long    $2000_0000              ' counter A: frqa (read)
phs10           long    $6000_0000              ' counter A: phsa (read)

ctr             long    0                       ' R/W byte loop counter
' Data defined in constant section, but needed in the ASM for program operation

' Uninitialized data - temporary variables
cmd             res     1
t0              res     1

' Parameters read from commands passed into the ASM routine
ptr_params      res     1                       ' address, cmd, data length
param_a         res     1                       ' parameter A
param_b         res     1                       ' parameter B

data            res     1                       ' byte read from/written to SPI
ptr_hub         res     1                       ' pointer to read/write buffer

                fit     496                     ' compiler: PASM and variables
                                                '   fit in a single cog?

DAT
{
Copyright 2022 Jesse Burt

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

