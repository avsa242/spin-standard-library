{
    --------------------------------------------
    Filename: com.spi.bitbang.spin
    Author: Mark Tillotson
    Modified by: Jesse Burt
    Description: PASM SPI driver (~4MHz)
    Started Jul 19, 2011
    Updated May 6, 2020
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is an excerpt of Mark Tillotson's nRF24L01P.spin driver,
        adapted for use as a general-purpose SPI engine.
        The original header is preserved below.

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Driver for Nordic RF module NRF24L01+
//
// Author: Mark Tillotson
// Updated: 2011-07-19
// Designed For: P8X32A
// Version: 0.1 PRELIM
//
// Copyright (c) 2011 Mark Tillotson
// See end of file for terms of use.
//
// Update History:
//
// v0.1 - Preliminary version 2011-07-19
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}

CON

    CMD_RESERVED  = 0             'This is the default state - means ASM is waiting for command
    CMD_READ      = 1 << 16
    CMD_WRITE     = 2 << 16
    CMD_LAST      = 17 << 16      'Place holder for last command

VAR

    long _command
    byte _cog

PUB Start(CS, SCK, MOSI, MISO): okay

    CSmask := |< CS
    SCKmask := |< SCK
    MOSImask := |< MOSI
    MISOmask := |< MISO

    okay := _cog := cognew (@entry, @_command) + 1

PUB Stop

    if _cog
        cogstop(_cog - 1)
        longfill(@CSmask, 0, 5)
        _cog := 0

PUB Read(buff_addr, nr_bytes)
' Read from slave into buff_addr
    _command := CMD_READ + @buff_addr
    repeat while _command

PUB Write(block, buff_addr, nr_bytes, deselect_after)
' Write bytes to slave from buff_addr
'   Valid values:
'       block
'           Non-zero: Block/wait for Write() to complete
'           FALSE (0): Return immediately
'       deslect_after
'           TRUE (-1 or 1): Deselect slave/raise CS after transaction
'           FALSE (0): Leave slave selected/keep CS low after transaction
    deselect_after := (||deselect_after) <# 1
    _command := CMD_WRITE + @buff_addr

    if block
        repeat while _command

DAT

                        org
entry
                        mov     outa,           CSmask
                        mov     dira,           CSmask
                        or      dira,           SCKmask
                        or      dira,           MOSImask

cmd_loop                rdlong  cmdAdrLen,      par                 wz
                if_z    jmp     #cmd_loop

                        mov     t1,             cmdAdrLen
                        rdlong  buff,           t1
                        add     t1,             #4
                        rdlong  count,          t1
                        add     t1,             #4
                        rdlong  deselect,       t1
                        add     t1,             #4
                        mov     t0,             cmdAdrLen
                        shr     t0,             #16                 wz
                        cmp     t0,             #(CMD_LAST>>16)+1   wc
            if_z_or_nc  jmp     #:cmd_exit
                        shl     t0,             #1
                        add     t0,             #:cmd_table-2
                        jmp     t0

:cmd_table              call    #readbytes
                        jmp     #:cmd_exit
                        call    #writebytes
                        jmp     #:cmd_exit
                        call    #LastCMD
                        jmp     #:cmd_exit
:cmd_tableEnd
:cmd_exit               test    deselect,       #1                  wc
            if_c        or      outa,           CSmask
                        wrlong  _zero,          par
                        jmp     #cmd_loop
LastCMD

LastCMD_ret             ret
' SPI command that reads multiple bytes, buff = hub address of buffer, count = length
readbytes               andn    outa,           CSmask
:readloop               mov     spibyte,        #0
                        call    #spiread
                        wrbyte  spibyte,        buff
                        add     buff,           #1
                        djnz    count,          #:readloop
                        or      outa,           CSmask
readbytes_ret           ret

' SPI command that writes multiple bytes, buff = hub address of buffer, count = length
writebytes              andn    outa,           CSmask
:writeloop              rdbyte  spibyte,        buff
                        call    #spiwrite
                        add     buff,           #1
                        djnz    count,          #:writeloop
writebytes_ret          ret

spiread                 mov     n,              #8
:spireadloop            rcl     spibyte,        #1                  wc
                        or      outa,           SCKmask
                        test    MISOmask,       ina                 wc
                        andn    outa,           SCKmask                 ' set SCLK low
                        djnz    n,              #:spireadloop
                        rcl     spibyte,        #1                      ' shift last MISO bit into spibyte
                        and     spibyte,        #$FF
spiread_ret             ret

spiwrite                mov     n,              #8
                        shl     spibyte,        #24
:spiwriteloop           rcl     spibyte,        #1                  wc  ' rotate out MSB into carry, MISO data goes i
                        muxc    outa,           MOSImask                ' put on MOSI pin
                        or      outa,           SCKmask                 ' set SCLK high
                        andn    outa,           SCKmask                 ' set SCLK low
                        djnz    n,              #:spiwriteloop
spiwrite_ret            ret


_zero                   long      0                                     ' Zero

CSmask                  long    0-0
SCKmask                 long    0-0
MOSImask                long    0-0
MISOmask                long    0-0

t0                      res     1
t1                      res     1

n                       res     1
deselect                res     1
param_a                 res     1
param_b                 res     1
param_c                 res     1
cmdAdrLen               res     1
spibyte                 res     1
buff                    res     1
command_addr            res     1
count                   res     1

