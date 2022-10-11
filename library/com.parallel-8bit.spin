{
    --------------------------------------------
    Filename: com.parallel-8bit.spin
    Author: Jesse Burt
    Description: 8-bit parallel I/O engine for LCDs
    Copyright (c) 2022
    Started Oct 13, 2021
    Updated Oct 11, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

' 8-bit Parallel engine commands
    IDLE        = 0
    CMD         = 1
    DATA        = 2
    BLKDAT      = 3
    BLKWD_MSBF  = 4
    BYTEX       = 5
    WORDX       = 6

VAR

    long _cog
    long _io_cmd, _ptr_buff, _xfer_cnt
    long _DATA, _CS, _DC, _WR, _RD

PUB null{}
' This is not a top-level object

PUB init(D_BASEPIN, CS_PIN, DC_PIN, WR_PIN, RD_PIN): status
' Initialize engine
'   D_BASEPIN: first of 8 I/O pin block
'   CS_PIN: CS / CSX (chip select)
'   DC_PIN: DC / DCX / RS (data/command or register select)
'   WR_PIN: WR / WRX (write clock)
'   RD_PIN: RD / RDX (read clock)
    deinit{}                                    ' stop engine, if started
    _DATA := D_BASEPIN                          ' 8 pins starting at D_BASEPIN
    _CS := |< CS_PIN                            ' create masks for control pins
    _DC := |< DC_PIN
    _WR := |< WR_PIN
    _RD := |< RD_PIN
    _cog := cognew(@entry, @_io_cmd)+1          ' start engine

    return _cog

PUB deinit{}
' Deinitialize engine
'   Stop running cog and clear variables
    if (_cog)
        cogstop(_cog-1)
        longfill(@_cog, 0, 8)

PUB wrbyte_cmd(c)
' Write command (8-bits)
    _xfer_cnt := 1                              ' set data size
    _ptr_buff := c                              ' command byte
    _io_cmd := CMD                              ' signal command to engine
    repeat until (_io_cmd == IDLE)              ' wait for engine to finish

PUB wrbyte_dat(d)
' Write data (8-bits)
    _xfer_cnt := 1
    _ptr_buff := d
    _io_cmd := DATA
    repeat until (_io_cmd == IDLE)

PUB wrblock_dat(ptr_buff, nr_bytes)
' Write block of data
'   ptr_buff: pointer to buffer of data
'   nr_bytes: number of bytes to write to display
    longmove(@_ptr_buff, @ptr_buff, 2)          ' copy params to PASM engine
    _io_cmd := BLKDAT                           '   params
    repeat until (_io_cmd == IDLE)

PUB wrblkword_msbf(ptr_buff, nr_words)
' Write block of words (MSByte-first)
'   ptr_buff: pointer to buffer of data
'   nr_words: number of words to write to display
    longmove(@_ptr_buff, @ptr_buff, 2)
    _io_cmd := BLKWD_MSBF
    repeat until (_io_cmd == IDLE)

PUB wrwordx_dat(dw, nr_words)
' Repeatedly write word dw, nr_words times
    longmove(@_ptr_buff, @dw, 2)
    _io_cmd := WORDX
    repeat until (_io_cmd == IDLE)

DAT

entry
            org     0


initio
' Initialize:
'   * set pointers to calling spin code
'   * set I/O pin directions and states
            mov     iolink, par
            mov     ptrbuff, iolink             ' get spin buffer ptr
            add     ptrbuff, #4
            mov     ptr_xcnt, iolink            ' get ptr to spin nr_bytes
            add     ptr_xcnt, #8
            mov     tmp0, iolink
            add     tmp0, #12
            rdlong  DBASE, tmp0                 ' get data basepin and
            mov     DATMASK, #$FF               '   create mask
            shl     DATMASK, DBASE
            add     tmp0, #4
            rdlong  CS, tmp0
            add     tmp0, #4
            rdlong  DC, tmp0
            add     tmp0, #4
            rdlong  WRC, tmp0
            add     tmp0, #4
            rdlong  RD, tmp0

            or      outa, CS                    ' CS high
            or      dira, CS
            andn    outa, WRC                   ' WRC low
            or      dira, WRC
            or      dira, DATMASK               ' D7..0 output
            or      dira, DC                    ' DC output
            or      outa, RD                    ' RD high
            or      dira, RD
            andn    outa, CS                    ' CS low


cmdloop
' Wait for command
            rdlong  tmp0, par       wz
    if_z    jmp     #cmdloop

            cmp     tmp0, #CMD      wz
    if_e    jmp     #wr_cmd
            cmp     tmp0, #DATA     wz
    if_e    jmp     #wr_dat
            cmp     tmp0, #BLKDAT   wz
    if_e    jmp     #wrblk_data
            cmp     tmp0, #BLKWD_MSBF wz
    if_e    jmp     #wrblkwd_msbf
            cmp     tmp0, #BYTEX   wz
    if_e    jmp     #wrwordx_data
            cmp     tmp0, #WORDX   wz
    if_e    jmp     #wrwordx_data


cmdexit
' End of command, or no/invalid command
            wrlong  clrcmd, iolink              ' signal command is clear
            jmp     #cmdloop


wr_cmd
' Write command
            andn    outa, DC                    ' DC low: command
            rdbyte  cmdbyte, ptrbuff            ' get cmd from hub
            shl     cmdbyte, DBASE
            andn    outa, DATMASK               ' D7..0 low
            or      outa, cmdbyte               ' write cmd to D7..D0
            or      outa, WRC                   ' clock out byte
            andn    outa, WRC
            jmp     #cmdexit                    ' return


wr_dat
' Write byte of data
            or      outa, DC                    ' DC high: data
            rdbyte  dbyte, ptrbuff              ' get data from hub
            shl     dbyte, DBASE
            andn    outa, DATMASK               ' D7..0 low
            or      outa, dbyte                 ' write data to D7..D0
            or      outa, WRC                   ' clock out byte
            andn    outa, WRC
            jmp     #cmdexit                    ' return


wrblk_data
' Write block of bytes
            or      outa, DC                    ' DC high: data
            rdlong  ptr_data, ptrbuff           ' get pointer to data
            rdlong  xcnt, ptr_xcnt              '   and number of bytes
:dbyteloop
            rdbyte  dbyte, ptr_data             ' get next byte of data
            shl     dbyte, DBASE
            andn    outa, DATMASK               ' D7..0 low
            or      outa, dbyte                 ' write byte to D7..0
            or      outa, WRC                   ' clock out byte
            andn    outa, WRC
            add     ptr_data, #1                ' advance ptr to next byte
            djnz    xcnt, #:dbyteloop           ' loop if more bytes
            jmp     #cmdexit                    ' return


wrblkwd_msbf
' Write block of words, MSByte-first
            or      outa, DC                    ' DC high: data
            rdlong  ptr_data, ptrbuff           ' get pointer to data
            rdlong  xcnt, ptr_xcnt              '   and number of words

:dwordloop
            rdword  dword, ptr_data             ' get next word of data
            mov     byte1, dword
            shr     byte1, #8
            shl     byte1, DBASE
            mov     byte0, dword
            and     byte0, #$FF
            shl     byte0, DBASE

            andn    outa, DATMASK               ' D7..0 low
            or      outa, byte1                 ' write MSB
            or      outa, WRC                   ' clock it out
            andn    outa, WRC
            andn    outa, DATMASK               ' D7..0 low
            or      outa, byte0                 ' write LSB
            or      outa, WRC                   ' clock it out
            andn    outa, WRC
            add     ptr_data, #2                ' advance ptr to next word
            djnz    xcnt, #:dwordloop           ' loop if more bytes
            jmp     #cmdexit                    ' return


wrbytex_data
' Repeatedly write the same byte of data, xcnt times
            or      outa, DC                    ' DC high: data
            rdlong  dbyte, ptrbuff              ' get pointer to word of data
            shl     dbyte, DBASE
            rdlong  xcnt, ptr_xcnt              '   and number of words
:repdloop
            andn    outa, DATMASK               ' D7..0 low
            or      outa, dbyte                 ' write MSB
            or      outa, WRC                   ' clock it out
            andn    outa, WRC
            djnz    xcnt, #:repdloop            ' loop if more words
            jmp     #cmdexit                    ' return

wrwordx_data
' Repeatedly write the same word of data, xcnt times
            or      outa, DC                    ' DC high: data
            rdlong  dword, ptrbuff              ' get pointer to word of data
            rdlong  xcnt, ptr_xcnt              '   and number of words
            mov     byte1, dword                ' isolate MSB of word
            shr     byte1, #8
            shl     byte1, DBASE
            mov     byte0, dword                '   and LSB
            and     byte0, #$FF
            shl     byte0, DBASE
:repdloop
            andn    outa, DATMASK               ' D7..0 low
            or      outa, byte1                 ' write MSB
            or      outa, WRC                   ' clock it out
            andn    outa, WRC
            andn    outa, DATMASK               ' D7..0 low
            or      outa, byte0                 ' write LSB
            or      outa, WRC                   ' clock it out
            andn    outa, WRC
            djnz    xcnt, #:repdloop            ' loop if more words
            jmp     #cmdexit                    ' return


DATMASK     long    0
DBASE       long    0
CS          long    0
WRC         long    0
DC          long    0
RD          long    0
iolink      long    0
tmp0        long    0
ptr_data    long    0
dbyte       long    0
dword       long    0
cmdbyte     long    0
clrcmd      long    IDLE
ptrbuff     long    0
ptr_xcnt    long    0
xcnt        long    0
byte1       long    0
byte0       long    0

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

