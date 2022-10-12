{
    --------------------------------------------
    Filename: com.spi.fast.spin
    Author: Jesse Burt
    Description: Fast PASM SPI engine (20MHz W, 10MHz R)
        @80MHz Fsys:
            Write speed: 20MHz, exact timings vary:
                19.23MHz actual (53% duty - 0.028uS H : 0.024uS L) 52ns
                20.83MHz actual (50% duty - 0.024uS H : 0.024uS L) 48ns
            Read speed: 10MHz:
                9.99MHz actual (52% duty - 0.052uS H : 0.048uS L) 100ns
    Started Oct 13, 2012
    Updated Oct 12, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Timothy D. Swieter's Wiznet W5200 driver
        adapted for use as a general-purpose SPI engine.
}

CON

' PASM engine states
    CMD_IDLE        = 0                         ' waiting for command
    CMD_READ        = 1 << 16                   ' read byte(s)
    CMD_WRITE       = 2 << 16                   ' write byte(s)
    CMD_WR8_X       = 3 << 16
    CMD_WR16_X_MSBF = 4 << 16
    CMD_WR16_X_LSBF = 5 << 16
    CMD_LAST        = 17 << 16                  ' Placeholder for last command

VAR

    long _cog, _dsel_after

OBJ

    ctrs : "core.con.counters"                  ' counter setup symb. constants

DAT

' Command setup
    _command    long    0                       ' PASM engine cmd + args

PUB null{}
' This is not a top-level object

PUB init(CS, SCK, MOSI, MISO, SPI_MODE): status
' Initialize SPI engine using custom pins
'   CS, SCK, MOSI, MISO: 0..31 (each unique)
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
    deinit

    _cs_mask := |< CS
    _sck_mask := |< SCK
    _mosi_mask := |< MOSI
    _miso_mask := |< MISO

' pre-define counter modes for PASM engine
    ctramode := (ctrs#NCO_SINGLEEND | ctrs#VCO_DIV_128) + SCK
    ctrbmode := (ctrs#NCO_SINGLEEND | ctrs#VCO_DIV_128) + MOSI

' clear the command buffer - be sure no commands were set before initializing
    _command := 0

' start the PASM engine in a new cog
    status := _cog := cognew(@entry, @_command) + 1

PUB deinit{}
' Deinitialize
'   Float I/O pins, clear out hub vars, and stop the PASM engine
    if _cog
        cogstop(_cog - 1)
        longfill(@_cs_mask, 0, 4)               ' Clear all masks
        _cog := 0
    _command := 0

PUB desel_after(state)
' Deselect (raise CS) after a read or write transaction
'   NOTE: Transitional method for temporary compatibility with interface to PASM engine
    _dsel_after := (state <> 0)

PUB rdblock_lsbf(ptr_buff, nr_bytes)
' Read nr_bytes from slave device into ptr_buff
    _command := CMD_READ + @ptr_buff
    repeat while _command

PUB rdblock_msbf(ptr_buff, nr_bytes) | i
' Read nr_bytes from slave device into ptr_buff
    repeat i from nr_bytes-1 to 0
        rdblock_lsbf(ptr_buff+i, 1)

PUB wrblock_lsbf(ptr_buff, nr_bytes) | dsel_after
' Write nr_bytes from ptr_buff into slave device
'   Valid values:
'       block:
'           Non-zero: Wait for ASM routine to finish before returning
'           0: Return immediately after writing
'       ptr_buff: Pointer to byte(s) of data to be written
'       nr_bytes: Number of bytes to write
    dsel_after := ||(_dsel_after)
    _command := CMD_WRITE + @ptr_buff
    repeat while _command

PUB wrblock_msbf(ptr_buff, nr_bytes) | i
' Write block of data to SPI bus from ptr_buff, most-significant byte first
    repeat i from nr_bytes-1 to 0
        wrblock_lsbf(ptr_buff+i, 1)

#define HAS_WR_BYTEX
' Normally the common code #included provides this, but this engine has native support
PUB wr_bytex(byte2spi, nr_bytes)
' Write byte2spi repeatedly to SPI bus, nr_bytes times
    _command := CMD_WR8_X + @byte2spi
    repeat while _command

#define HAS_WRWORDX_MSBF
' Normally the common code #included provides this, but this engine has native support
PUB wrwordx_msbf(word2spi, nr_words)
' Repeatedly write word2spi to SPI bus, nr_words times
    _command := CMD_WR16_X_MSBF + @word2spi
    repeat while _command

#include "com.spi.common.spinh"                 ' R/W methods common to all SPI engines

DAT
                org
entry
' Set the initial state of the I/O
' (unless listed here, the output is initialized as off/low)
                mov     outa, _cs_mask          ' CS initialized high

                mov     dira, _cs_mask          '
                or      dira, _sck_mask         ' set as outputs
                or      dira, _mosi_mask        '

                mov     frqb, #0                ' init ctrb
                mov     ctrb, ctrbmode          '   (used by MOSI)

CmdWait
' Wait for command issued to engine
                rdlong  ptr_params, par wz      ' command passed to engine?
    if_z        jmp     #cmdwait                ' if not, loop until there is

                mov     t0, ptr_params          ' get command/address
                rdlong  param_a, t0             ' get parameters
                add     t0, #4                  '
                rdlong  param_b, t0             '
                add     t0, #4                  '
                rdlong  param_c, t0             '

                add     t0, #4                  '
                mov     cmd, ptr_params         ' get command/address
                shr     cmd, #16 wz             ' command
                cmp     cmd, #(CMD_LAST>>16)+1 wc' command valid?
    if_z_or_nc  jmp     #:cmdexit               ' no; exit loop
                shl     cmd, #1
                add     cmd, #:cmdtable-2       ' add in the "call" address
                jmp     cmd                     ' Jump to the command

:CmdTable
' Command table
                call    #readspi                ' read a byte
                jmp     #:cmdexit
                call    #writespi               ' write a byte
                jmp     #:cmdexit
                call    #wr8_x                  ' write a byte repeatedly
                jmp     #:cmdexit
                call    #wr16_x_msbf            ' write a word repeatedly
                jmp     #:cmdexit
                call    #lastcmd                ' placeholder for last command
                jmp     #:cmdexit
:CmdTableEnd

:CmdExit
' Clear command status and wait for new command
                wrlong  _zero, par              ' clear the command status
                jmp     #cmdwait                ' wait for next command


ReadSPI
' Read/shift in data from SPI bus
                mov     ptr_hub, param_a        ' get hub read buff. pointer
                mov     ctr, param_b            ' get nr. bytes to read
                call    #readmulti              ' read byte(s)

ReadSPI_ret     ret                             ' complete


WriteSPI
' Write/shift out data to SPI bus
                mov     ptr_hub, param_a        ' Move the data byte into a variable for processing
                mov     ctr, param_b            ' number of bytes
                mov     deselect, param_c       ' flag: deselect after write
                call    #writemulti             ' write byte(s)

WriteSPI_ret    ret                             ' complete


LastCMD
LastCMD_ret     ret                             ' complete

Wr8_x
' Write the same byte to the SPI bus many times
                mov     data, param_a           ' get byte and how many to
                mov     ctr, param_b            '   write from hubram
:byteloop       call    #write8_spi             ' write it
                djnz    ctr, #:byteloop         ' loop if more bytes to write
Wr8_x_ret       ret

Wr16_x_LSBF
' Write the same word (LSByte first) to the SPI bus many times
'   param_a: pointer to word to write
'   param_b: number of times to write
                mov     data, param_a           ' get word and how many to
                mov     ctr, param_b            '   write from hubram
:wordloop       call    #write8_spi             ' write LSB
                ror     data, #8                ' put the MSB into position,
                call    #write8_spi             '   and write
                djnz    ctr, #:wordloop         ' loop if more words to write
Wr16_x_LSBF_ret ret

Wr16_x_MSBF
' Write the same word (MSByte first) to the SPI bus many times
'   param_a: pointer to word to write
'   param_b: number of times to write
                mov     data, param_a           ' get word and how many to
                mov     ctr, param_b            '   write from hubram
:wordloop       ror     data, #8                ' put the MSByte into position
                call    #write8_spi             '   and write it
                rol     data, #8                ' put things back, so the LSB
                call    #write8_spi             '   is in position, and write
                djnz    ctr, #:wordloop         ' loop if more words to write
Wr16_x_MSBF_ret ret

WriteMulti
' Write multiple bytes
:byteloop
                rdbyte  data, ptr_hub           ' read the byte from hubram
                call    #write8_spi             ' write one byte

                add     ptr_hub, #1             ' next (byte) hubram address
                djnz    ctr, #:byteloop         ' loop if more bytes to write
                test    deselect, #1 wc         ' deselect slave after write?
    if_c        or      outa, _cs_mask          ' if yes, raise CS
WriteMulti_ret  ret                             ' complete


ReadMulti
' Read multiple bytes
:byteloop
                call    #read8_spi              ' Read one data byte
                and     data, _bytemask         ' Ensure there is only a byte
                wrbyte  data, ptr_hub           ' Write the byte to hubram

                add     ptr_hub, #1             ' next (byte) hubram address
                djnz    ctr, #:byteloop         ' loop if more bytes to read
                or      outa, _cs_mask          ' raise CS
ReadMulti_ret   ret                             ' complete


Write8_SPI
' Low-level write routine
'   Shift out PHSB bit 31 to MOSI
' Counter A: SCK
' Counter B: MOSI
                andn    outa, _cs_mask          ' begin transmission
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
Write8_SPI_ret  ret                             ' complete


Read8_SPI
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
Read8_SPI_ret   ret                             ' complete


' Initialized data
_zero           long    0                       ' zero
_bytemask       long    $FF                     ' byte mask

' Pin/mask definitions are initianlized in SPIN and program/memory modified
'   here before the COG is started
_cs_mask        long    0-0                     ' Chip Select
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
param_c         res     1                       ' parameter C

deselect        res     1                       ' flag: raise CS after?
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

