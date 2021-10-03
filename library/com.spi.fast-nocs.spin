{
    --------------------------------------------
    Filename: com.spi.fast-nocs.spin
    Author: Jesse Burt
    Description: Fast PASM SPI driver (20MHz W, 10MHz R)
        (_no builtin-Chip Select support_)
    Started Jun 30, 2021
    Updated Oct 3, 2021
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

    long _cog
    long _cpol, _spi_mode

OBJ

    ctrs : "core.con.counters"                  ' counter setup symb. constants

DAT

' Command setup
    _command    long    0                       ' PASM engine cmd + args

PUB Null{}
' This is not a top-level object

PUB Init(SCK, MOSI, MISO, SPI_MODE): status
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

' clear the command buffer - be sure no commands were set before initializing
    _command := 0

' start the PASM engine in a new cog
    status := _cog := cognew(@entry, @_command) + 1

PUB DeInit{}
' Deinitialize
'   Float I/O pins, clear out hub vars, and stop the PASM engine
    if _cog
        cogstop(_cog - 1)
        _cog := 0
    _command := 0

PUB Mode(mode_nr): curr_mode
' Set SPI mode
'   Valid values: 0..3  XXX CURRENTLY ONLY MODE 0 SUPPORTED
'   Any other value returns the current setting
    case mode_nr
        0, 1:
            _cpol := 0
        2, 3:
            _cpol := 1
        other:
            return _spi_mode

    _spi_mode := mode_nr

PUB RdBlock_LSBF(ptr_buff, nr_bytes)
' Read nr_bytes from slave device into ptr_buff
    _command := CMD_READ + @ptr_buff

    repeat while _command

PUB RdBlock_MSBF(ptr_buff, nr_bytes)    'XXX not yet functional
' Read nr_bytes from slave device into ptr_buff
    _command := CMD_READ + @ptr_buff

    repeat while _command

PUB Rd_Byte{}: spi2byte
' Read byte from SPI bus
    rdblock_lsbf(@spi2byte, 1)

PUB RdLong_LSBF{}: spi2long
' Read long from SPI bus, least-significant byte first
    rdblock_lsbf(@spi2long, 4)

PUB RdLong_MSBF{}: spi2long 'XXX non-functional, for now
' Read long from SPI bus, least-significant byte first
    rdblock_msbf(@spi2long, 4)

PUB RdWord_LSBF{}: spi2word
' Read word from SPI bus, least-significant byte first
    rdblock_lsbf(@spi2word, 2)

PUB RdWord_MSBF{}: spi2word 'XXX non-functional, for now
' Read word from SPI bus, least-significant byte first
    rdblock_msbf(@spi2word, 2)

PUB WrBlock_LSBF(ptr_buff, nr_bytes)
' Write nr_bytes from ptr_buff into slave device
'   Valid values:
'       block:
'           Non-zero: Wait for ASM routine to finish before returning
'           0: Return immediately after writing
'       ptr_buff: Pointer to byte(s) of data to be written
'       nr_bytes: Number of bytes to write
    _command := CMD_WRITE + @ptr_buff

    repeat while _command

PUB WrBlock_MSBF(ptr_buff, nr_bytes)    'XXX non-functional, for now
' Write block of data to SPI bus from ptr_buff, most-significant byte first
    _command := CMD_WRITE + @ptr_buff

    repeat while _command

PUB Wr_Byte(byte2spi)
' Write byte to SPI bus
    wrblock_lsbf(@byte2spi, 1)

PUB WrByteX(byte2spi, nr_bytes)
' Write byte2spi repeatedly to SPI bus, nr_bytes times
    _command := CMD_WR8_X + @byte2spi
    repeat while _command

PUB WrLong_LSBF(long2spi)
' Write long to SPI bus, least-significant byte first
    wrblock_lsbf(@long2spi, 4)

PUB WrLong_MSBF(long2spi)   'XXX non-functional, for now
' Write long to SPI bus, most-significant byte first
    wrblock_msbf(@long2spi, 4)

PUB WrWord_LSBF(word2spi)
' Write word to SPI bus, least-significant byte first
    wrblock_lsbf(@word2spi, 2)

PUB WrWordX_MSBF(word2spi, nr_words)
' Repeatedly write word2spi to SPI bus, nr_words times
    _command := CMD_WR16_X_MSBF + @word2spi
    repeat while _command

PUB WrWord_MSBF(word2spi)   'XXX non-functional, for now
' Write word to SPI bus, most-significant byte first
    wrblock_msbf(@word2spi, 2)

DAT
                org
entry
                ' Set the initial state of the I/O
                ' (unless listed here, the output is initialized as off/low)
                or        dira, _sck_mask       ' set as outputs
                or        dira, _mosi_mask      '

                mov       frqb, #0              ' init ctrb
                mov       ctrb, ctrbmode        '   (used by MOSI)

CmdWait
' Wait for command issued to engine
                rdlong    ptr_params, par wz    ' command passed to engine?
    if_z        jmp       #cmdwait              ' if not, loop until there is

                mov       t0, ptr_params        ' get command/address
                rdlong    param_a, t0           ' get parameters
                add       t0, #4                '
                rdlong    param_b, t0           '

                mov       cmd, ptr_params       ' get command/address
                shr       cmd, #16 wz           ' command
                cmp       cmd, #(CMD_LAST>>16)+1 wc' command valid?
    if_z_or_nc  jmp       #:cmdexit             ' no; exit loop
                shl       cmd, #1               '(1: 2), (2: 4), (3: 8), (4: 16)
                add       cmd, #:cmdtable-2     ' add in the "call" address
                jmp       cmd                   ' Jump to the command

:CmdTable
' Command table
                call      #readspi              ' read a byte
                jmp       #:cmdexit
                call      #writespi             ' write a byte
                jmp       #:cmdexit
                call      #wr8_x                ' write a byte repeatedly
                jmp       #:cmdexit
                call      #wr16_x_msbf          ' write a word repeatedly
                jmp       #:cmdexit
                call      #lastcmd              ' placeholder for last command
                jmp       #:cmdexit
:CmdTableEnd

:CmdExit
' Clear command status and wait for new command
                wrlong    _zero, par            ' clear the command status
                jmp       #cmdwait              ' wait for next command


readSPI
' Read/shift in data from SPI bus
                mov       ptr_hub, param_a      ' get hub read buff. pointer
                mov       ctr, param_b          ' get nr. bytes to read
                call      #readmulti            ' read byte(s)

readSPI_ret     ret                             ' complete


writeSPI
' Write/shift out data to SPI bus
                mov       ptr_hub, param_a      ' Move the data byte into a variable for processing
                mov       ctr, param_b          ' number of bytes
                call      #writemulti           ' write byte(s)

writeSPI_ret    ret                             ' complete


LastCMD
LastCMD_ret     ret                             ' complete

wr8_x
' Write the same byte to the SPI bus many times
                mov       data, param_a         ' get byte and how many to
                mov       ctr, param_b          '   write from hubram
:byteloop       call      #write8_spi           ' write it
                djnz      ctr, #:byteloop       ' loop if more bytes to write
wr8_x_ret       ret

wr16_x_lsbf
' Write the same word (LSByte first) to the SPI bus many times
'   param_a: pointer to word to write
'   param_b: number of times to write
                mov       data, param_a         ' get word and how many to
                mov       ctr, param_b          '   write from hubram
:wordloop       call      #write8_spi           ' write LSB
                ror       data, #8              ' put the MSB into position,
                call      #write8_spi           '   and write
                djnz      ctr, #:wordloop       ' loop if more words to write
wr16_x_lsbf_ret ret

wr16_x_msbf
' Write the same word (MSByte first) to the SPI bus many times
'   param_a: pointer to word to write
'   param_b: number of times to write
                mov       data, param_a         ' get word and how many to
                mov       ctr, param_b          '   write from hubram
:wordloop       ror       data, #8              ' put the MSByte into position
                call      #write8_spi           '   and write it
                rol       data, #8              ' put things back, so the LSB
                call      #write8_spi           '   is in position, and write
                djnz      ctr, #:wordloop       ' loop if more words to write
wr16_x_msbf_ret ret

WriteMulti
' Write multiple bytes
:byteloop
                rdbyte    data, ptr_hub         ' read the byte from hubram
                call      #write8_spi            ' write one byte

                add       ptr_hub, #1           ' next (byte) hubram address
                djnz      ctr, #:byteloop          ' loop if more bytes to write
WriteMulti_ret  ret                             ' complete


ReadMulti
' Read multiple bytes
:byteloop
                call      #rspi_data            ' Read one data byte
                and       data, _bytemask       ' Ensure there is only a byte
                wrbyte    data, ptr_hub         ' Write the byte to hubram

                add       ptr_hub, #1           ' next (byte) hubram address
                djnz      ctr, #:byteloop          ' loop if more bytes to read
ReadMulti_ret   ret                             ' complete


write8_spi
' Low-level write routine
'   Shift out PHSB bit 31 to MOSI
' Counter A: SCK
' Counter B: MOSI
                andn      outa, _sck_mask       ' clock off, SCK low
                mov       phsb, #0
                mov       phsb, data            ' load PHSB with data

                shl       phsb, #24             ' left-justify it
                mov       frqa, frq20           ' set write frequency
                mov       phsa, phs20           ' phase of data/clock
                mov       ctra, ctramode        ' start clocking
                rol       phsb, #1              ' rotate each bit into
                rol       phsb, #1              '   position...
                rol       phsb, #1
                rol       phsb, #1
                rol       phsb, #1
                rol       phsb, #1
                rol       phsb, #1
                mov       ctra, #0              ' turn off clocking
write8_spi_ret  ret                             ' complete


rSPI_Data
' Low-level read routine
'   Shift in bits from MISO (unrolled loop)
' Counter A: SCK
                mov       frqa, frq10           ' set read frequency
                mov       phsa, phs10           ' phase of data/clock
                nop
                mov       ctra, ctramode        ' start clocking
                test      _MISO_mask, ina wc    ' shift in each bit
                rcl       data, #1
                test      _MISO_mask, ina wc
                rcl       data, #1
                test      _MISO_mask, ina wc
                rcl       data, #1
                test      _MISO_mask, ina wc
                rcl       data, #1
                test      _MISO_mask, ina wc
                rcl       data, #1
                test      _MISO_mask, ina wc
                rcl       data, #1
                test      _MISO_mask, ina wc
                rcl       data, #1
                test      _MISO_mask, ina wc
                mov       ctra, #0              ' disable clocking to avoid
                rcl       data, #1              '   odd behavior
rSPI_Data_ret   ret                             ' complete


' Initialized data
_zero           long      0                     ' zero
_bytemask       long      $FF                   ' byte mask

' Pin/mask definitions are initianlized in SPIN and program/memory modified
'   here before the COG is started
_sck_mask       long      0-0                   ' Serial Clock
_mosi_mask      long      0-0                   ' Master out slave in - output
_miso_mask      long      0-0                   ' Master in slave out - input

' NOTE: Data that is initialized in SPIN and program/memory modified here
'   before COG is started
ctramode        long      0-0                   ' counter A: SCK
ctrbmode        long      0-0                   ' counter B: MOSI

frq20           long      $4000_0000            ' counter A & B: frqa (write)
                                                '   (CLKFREQ / 4)
phs20           long      $5000_0000            ' counter A & B: phsa (write)
                                                '  (set relationship of MOSI
                                                '   to SCK)

frq10           long      $2000_0000            ' counter A: frqa (read)
phs10           long      $6000_0000            ' counter A: phsa (read)

ctr             long      0                     ' R/W byte loop counter
' Data defined in constant section, but needed in the ASM for program operation

' Uninitialized data - temporary variables
cmd             res 1
t0              res 1

' Parameters read from commands passed into the ASM routine
ptr_params      res 1                           ' address, cmd, data length
param_a         res 1                           ' parameter A
param_b         res 1                           ' parameter B

data            res 1                           ' byte read from/written to SPI
ptr_hub         res 1                           ' pointer to read/write buffer

                fit 496                         ' compiler: PASM and variables
                                                '   fit in a single cog?

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

