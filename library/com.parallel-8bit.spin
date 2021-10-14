{
    --------------------------------------------
    Filename: com.parallel-8bit.spin
    Author: Jesse Burt
    Description: 8-bit parallel I/O engine for LCDs
    Copyright (c) 2021
    Started Oct 13, 2021
    Updated Oct 13, 2021
    See end of file for terms of use.
    --------------------------------------------
}
CON

' 8-bit Parallel engine commands
    IDLE        = 0
    CMD         = 1
    DATA        = 2
    BLKDAT      = 3
    REPDAT      = 4

VAR

    long _cog
    long _io_cmd, _ptr_buff, _nr_bytes
    long _DATA, _CS, _DC, _WR, _RD

PUB Null{}
' This is not a top-level object

PUB Init(D_BASEPIN, CS_PIN, DC_PIN, WR_PIN, RD_PIN): status
' Initialize engine
'   D_BASEPIN: first of 8 I/O pin block
'   CS_PIN: CS / CSX (chip select)
'   DC_PIN: DC / DCX / RS (data/command or register select)
'   WR_PIN: WR / WRX (write clock)
'   RD_PIN: RD / RDX (read clock)
    deinit{}                                    ' stop engine, if started
    _DATA := $FF << D_BASEPIN                   ' 8 pins starting at D_BASEPIN
    _CS := |< CS_PIN                            ' create masks for control pins
    _DC := |< DC_PIN
    _WR := |< WR_PIN
    _RD := |< RD_PIN
    _cog := cognew(@entry, @_io_cmd)+1          ' start engine

    return _cog

PUB DeInit{}
' Deinitialize engine
'   Stop running cog and clear variables
    if _cog
        cogstop(_cog-1)
        longfill(@_cog, 0, 8)

PUB WrByte_CMD(c)
' Write command (8-bits)
    _nr_bytes := 1                              ' set data size
    _ptr_buff := c                              ' command byte
    _io_cmd := CMD                              ' signal command to engine
    repeat until (_io_cmd == IDLE)              ' wait for engine to finish

PUB WrByte_DAT(d)
' Write data (8-bits)
    _nr_bytes := 1
    _ptr_buff := d
    _io_cmd := DATA
    repeat until (_io_cmd == IDLE)

PUB WrBlock_DAT(ptr_buff, nr_bytes)
' Write block of data
'   ptr_buff: pointer to buffer of data
'   nr_bytes: number of bytes to write to display
    longmove(@_ptr_buff, @ptr_buff, 2)
    _io_cmd := BLKDAT
    repeat until (_io_cmd == IDLE)

PUB WrWordX_DAT(dw, nr_bytes)
' Repeatedly write word dw, nr_bytes times
    _ptr_buff := dw
    _nr_bytes := nr_bytes
    _io_cmd := REPDAT
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
            mov     ptr_nrbytes, iolink         ' get ptr to spin nr_bytes
            add     ptr_nrbytes, #8
            mov     tmp0, iolink                ' get D7..0 pins mask
            add     tmp0, #12
            rdlong  DATMASK, tmp0
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
            cmp     tmp0, #REPDAT   wz
    if_e    jmp     #wrwordx_data


cmdexit
' End of command, or no/invalid command
            wrlong  clrcmd, iolink              ' signal command is clear
            jmp     #cmdloop


wr_cmd
' Write command
            andn    outa, DC                    ' DC low: command
            rdbyte  cmdbyte, ptrbuff            ' get cmd from hub
            andn    outa, DATMASK               ' D7..0 low
            or      outa, cmdbyte               ' write cmd to D7..D0
            or      outa, WRC                   ' clock out byte
            andn    outa, WRC
            jmp     #cmdexit                    ' return


wr_dat
' Write byte of data
            or      outa, DC                    ' DC high: data
            rdbyte  dbyte, ptrbuff              ' get data from hub
            andn    outa, DATMASK               ' D7..0 low
            or      outa, dbyte                 ' write data to D7..D0
            or      outa, WRC                   ' clock out byte
            andn    outa, WRC
            jmp     #cmdexit                    ' return


wrblk_data
' Write block of data
            or      outa, DC                    ' DC high: data
            rdlong  ptr_data, ptrbuff           ' get pointer to data
            rdlong  bytecnt, ptr_nrbytes        '   and number of bytes
:dbyteloop
            rdbyte  dbyte, ptr_data             ' get next byte of data
            andn    outa, DATMASK               ' D7..0 low
            or      outa, dbyte                 ' write byte to D7..0
            or      outa, WRC                   ' clock out byte
            andn    outa, WRC
            add     ptr_data, #1                ' advance ptr to next byte
            djnz    bytecnt, #:dbyteloop        ' loop if more bytes
            jmp     #cmdexit                    ' return


wrwordx_data
' Repeatedly write the same byte of data
            or      outa, DC                    ' DC high: data
            rdlong  dword, ptrbuff              ' get pointer to word of data
            rdlong  bytecnt, ptr_nrbytes        '   and number of bytes XXX
            mov     hbyte, dword                ' isolate MSB of word
            shr     hbyte, #8
            mov     lbyte, dword                '   and LSB
            and     lbyte, #$FF
:repdloop
            andn    outa, DATMASK               ' D7..0 low
            or      outa, hbyte                 ' write MSB
            or      outa, WRC                   ' clock it out
            andn    outa, WRC
            andn    outa, DATMASK               ' D7..0 low
            or      outa, lbyte                 ' write LSB
            or      outa, WRC                   ' clock it out
            andn    outa, WRC
            djnz    bytecnt, #:repdloop         ' loop if more bytes
            jmp     #cmdexit                    ' return


DATMASK     long    0
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
ptr_nrbytes long    0
bytecnt     long    0
hbyte       long    0
lbyte       long    0

