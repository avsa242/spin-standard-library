{
    --------------------------------------------
    Filename: com.spi.bitbang.spin
    Author: Jesse Burt
    Description: PASM SPI driver (~4MHz)
        @80MHz Fsys:
            Write speed: 4.16MHz actual - exact timings vary:
                (16% duty - 0.04uS H : 0.2uS L) 240ns
                (23% duty - 0.06uS H : 0.2uS L) 260ns
            Read speed: 4.16MHz actual (41% duty - 0.1uS H : 0.14uS L) 240
    Started Jul 19, 2011
    Updated Oct 16, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on excerpts of nRF24L01P.spin,
        originally by Mark Tillotson.
}

CON

    CMD_RESERVED    = 0             'This is the default state - means ASM is waiting for command
    CMD_READ        = 1 << 16
    CMD_WRITE       = 2 << 16
    CMD_DESELECT    = 3 << 16
    CMD_LAST        = 17 << 16      'Place holder for last command

VAR

    long _des_after
    long _command
    byte _cog

PUB Null{}
' This is not a top-level object

PUB Init(CS, SCK, MOSI, MISO, SPI_MODE): status
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
    CSmask := |< CS
    SCKmask := |< SCK
    MOSImask := |< MOSI
    MISOmask := |< MISO

    status := _cog := cognew (@entry, @_command) + 1

PUB DeInit{}
' Deinitialize
'   Float I/O pins, clear out hub vars, and stop the PASM engine
    if _cog
        cogstop(_cog - 1)
        longfill(@CSmask, 0, 5)
        _cog := 0
    _command := 0

PUB DeselectAfter(state)
' Deselect (raise CS) after a read or write transaction
'   NOTE: Transitional method for temporary compatibility with interface to PASM engine
    _des_after := (state <> 0)

PUB RdBlock_LSBF(ptr_buff, nr_bytes) | tmp
' Read block of data from SPI bus, least-significant byte first
    tmp := _des_after
    _command := CMD_READ + @ptr_buff
    repeat while _command

PUB RdBlock_MSBF(ptr_buff, nr_bytes) | tmp  'XXX non-functional, for now
' Read block of data from SPI bus, most-significant byte first
    repeat tmp from nr_bytes-1 to 0
        rdblock_lsbf(ptr_buff+tmp, 1)

PUB WrBlock_LSBF(ptr_buff, nr_bytes) | dsel_after
' Write block of data to SPI bus from ptr_buff, least-significant byte first
    dsel_after := ||(_des_after)
    _command := CMD_WRITE + @ptr_buff
    repeat while _command

PUB WrBlock_MSBF(ptr_buff, nr_bytes) | tmp  'XXX non-functional, for now
' Write block of data to SPI bus from ptr_buff, most-significant byte first
    repeat tmp from nr_bytes-1 to 0
        wrblock_lsbf(ptr_buff+tmp, 1)

PUB XDeselect
' Explicitly deselect/raise CS
'   For exceptional/corner cases where CS was left low after a prior Read() or Write()
'       that had no logical way to deselect because e.g., the decision to deselect was
'       based on the result of a Read()
    _command := CMD_DESELECT
    repeat while _command

#include "com.spi-common.spinh"                 ' R/W methods common to all SPI engines

DAT

                org
entry
                mov     outa,       CSmask      ' set I/O pins' initial state
                mov     dira,       CSmask
                or      dira,       SCKmask
                or      dira,       MOSImask

Cmd_Loop        rdlong  ptr_params, par wz      ' wait for command
    if_z        jmp     #cmd_loop

                mov     t1,         ptr_params  ' copy params from hub
                rdlong  ptrbuff,    t1          ' pointer to user data to R/W
                add     t1,         #4
                rdlong  count,      t1          ' nr_bytes to R/W
                add     t1,         #4
                rdlong  deselect,   t1          ' should deslect after?
                add     t1,         #4
                mov     t0,         ptr_params   ' validate command
                shr     t0,         #16 wz
                cmp     t0,         #(CMD_LAST>>16)+1   wc
    if_z_or_nc  jmp     #:cmd_exit
                shl     t0,         #1
                add     t0,         #:cmd_table-2
                jmp     t0

:cmd_table      call    #readbytes
                jmp     #:cmd_exit
                call    #writebytes
                jmp     #:cmd_exit
                call    #expl_desel
                jmp     #:cmd_exit
                call    #LastCMD
                jmp     #:cmd_exit
:cmd_tableEnd
:cmd_exit       test    deselect,   #1  wc      ' end of cmd; deselect chip?
    if_c        or      outa,       CSmask
                wrlong  _zero,      par         ' signal to hub cmd is complete
                jmp     #cmd_loop
LastCMD
LastCMD_ret     ret

ReadBytes
' Read multiple bytes
'   ptrbuff: pointer to buffer in hub
'   count: number of bytes to read
                andn    outa,       CSmask      ' select chip
:readloop       mov     spibyte,    #0
                call    #spiread                ' shift in bits
                wrbyte  spibyte,    ptrbuff     ' write byte to hub
                add     ptrbuff,    #1           ' advance to next location
                djnz    count,      #:readloop  ' loop if more bytes left
ReadBytes_ret   ret

WriteBytes
' Write multiple bytes
'   ptrbuff: pointer to buffer in hub
'   count: number of bytes to write
                andn    outa,       CSmask      ' select chip
:writeloop      rdbyte  spibyte,    ptrbuff     ' read byte from hub and
                call    #spiwrite               '   shift it out
                add     ptrbuff,    #1          ' advance to next byte
                djnz    count,      #:writeloop ' loop if more bytes left
WriteBytes_ret  ret

SPIRead
' Read 8 bits from MISO
                mov     bits,       #8
:rdbitloop      rcl     spibyte,    #1  wc      ' rotate carry into spibyte
                or      outa,       SCKmask     ' clock in the next bit
                test    MISOmask,   ina wc
                andn    outa,       SCKmask
                djnz    bits,       #:rdbitloop ' loop if more bits left
                rcl     spibyte,    #1          ' shift last MISO bit into spibyte
                and     spibyte,    #$FF
SPIRead_ret     ret

SPIWrite
' Write 8 bits to MOSI
                mov     bits,       #8
                shl     spibyte,    #24         ' left align byte in long
:wrbitloop      rcl     spibyte,    #1  wc      ' rotate out MSBit into carry
                muxc    outa,       MOSImask    ' set MOSI state to MSB
                or      outa,       SCKmask     ' clock out bit
                andn    outa,       SCKmask
                djnz    bits,       #:wrbitloop ' loop if more bits left
SPIWrite_ret    ret

expl_desel      or      outa,       CSmask      ' Raise CS manually
expl_desel_ret  ret

_zero           long      0                     ' Zero

CSmask          long    0-0
SCKmask         long    0-0
MOSImask        long    0-0
MISOmask        long    0-0

t0              res     1
t1              res     1

bits            res     1
deselect        res     1
param_a         res     1
param_b         res     1
param_c         res     1
ptr_params      res     1
spibyte         res     1
ptrbuff         res     1
command_addr    res     1
count           res     1

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

