{
    --------------------------------------------
    Filename: com.onewire.spin2
    Description: OneWire Bus engine
    Author: Jesse Burt
    Created July 15, 2006
    Updated Oct 15, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on OneWire.spin,
    originally by Cam Thompson
}

CON

' OneWire PASM engine commands
    OW_SETUP    = (1 << 16)
    OW_RESET    = (2 << 16)
    OW_WRITE    = (3 << 16)
    OW_READ     = (4 << 16)
    OW_SEARCH   = (5 << 16)
    OW_CRC8     = (6 << 16)

' OneWire Bus commands
    SEARCH_ROM  = $F0
    RD_ROM      = $33
    MATCH_ROM   = $55
    SKIP_ROM    = $CC

' Search flags
    CHECK_CRC   = $100

    GOOD        = 0
    PRESENT     = 1

OBJ

    crc : "math.crc"

VAR

    long _cog
    long _command, _cmd_ret

PUB null{}
' This is not a top-level object

PUB init(OW_PIN): status | pin, usec
' Initialize OneWire engine
    deinit{}                                    ' stop an existing instance
    status := _cog := cognew(@getcmd, @_command) + 1

    ' set pin to use for 1-wire interface and calculate usec delay
    if (status)
        pin := OW_PIN
        usec := (clkfreq + 999_999) / 1_000_000
        ow_cmd(OW_SETUP + @pin)

PUB deinit{}
' Deinitialize
    if (_cog)
        cogstop(_cog - 1)
        _cog := 0
    _command := 0

PUB crc8(nr_bytes, ptr_buff): outcrc
' Calculate CRC of nr_bytes of data at ptr_buff
    return ow_cmd(OW_CRC8 + @nr_bytes)

PUB rd_byte{}: ow2byte
' Read a byte from the bus
    return rd_bits(8)

PUB rd_long{}: ow2long
' Read a long from the bus
    return rd_bits(32)

PUB rd_word{}: ow2word
' Read a word from the bus
    return rd_bits(16)

PUB rd_bits(nr_bits): ow2bits
' Read nr_bits from the bus
    return ow_cmd(OW_READ + @nr_bits)

PUB rdblock_lsbf(ptr_buff, nr_bytes) | bytenum
' Read block of bytes from bus, least-significant byte first
    repeat bytenum from 0 to nr_bytes-1
        byte[ptr_buff][bytenum] := rd_bits(8)

PUB rdblock_msbf(ptr_buff, nr_bytes) | bytenum
' Read block of bytes from bus, most-significant byte first
    repeat bytenum from nr_bytes-1 to 0
        byte[ptr_buff][bytenum] := rd_bits(8)

PUB rd_addr(ptr_addr)
' Read 64-bit address from the bus
    rdblock_lsbf(ptr_addr, 8)

PUB reset{}: pres
' Send Reset signal to bus
'   Returns:
'       TRUE (-1): a device is present
'       FALSE (0): no device present, or bus is busy
    return (ow_cmd(OW_RESET) == PRESENT)

PUB search(flags, max_addrs, ptr_addr): nr_devs
' Search bus for devices
'   flags:
'       bits[7..0]: restrict search to family code
'       bits[8]: if set, return only devices with a valid CRC
'   max_addrs: maximum number of 64-bit addresses to find
'   ptr_addr: pointer to buffer for storing found addresses (LSW-first)
'       NOTE: buffer must be a minimum of (max_addrs * 8) bytes
'
'   Returns: number of devices found
    return ow_cmd(OW_SEARCH + @flags)

PUB wr_bits(byte2ow, nr_bits)
' Write nr_bits of byte2ow to bus (LSB-first)
    ow_cmd(OW_WRITE + @byte2ow)

PUB wr_byte(byte2ow)
' Write byte to bus
    wr_bits(byte2ow, 8)

PUB wr_long(long2ow)
' Write long to bus
    wr_bits(long2ow, 32)

PUB wr_word(word2ow)
' Write word to bus
    wr_bits(word2ow, 16)

PUB wrblock_lsbf(ptr_buff, nr_bytes) | bytenum
' Writeblock of bytes to bus, least-significant byte first
    repeat bytenum from 0 to nr_bytes-1
        wr_bits(byte[ptr_buff][bytenum], 8)

PUB wrblock_msbf(ptr_buff, nr_bytes) | bytenum
' Write block of bytes to bus, least-significant byte first
    repeat bytenum from nr_bytes-1 to 0
        wr_bits(byte[ptr_buff][bytenum], 8)

PUB wr_addr(ptr_addr)
' Write 64-bit address to bus
    wrblock_lsbf(ptr_addr, 8)

PRI ow_cmd(cmd): cmd_ret
' Send command to OneWire PASM engine
    _command := cmd
    repeat while _command                       ' wait until PASM finished
    return _cmd_ret

DAT

                        org

getCmd                  rdlong  t1, par wz              ' wait for command
        if_z            jmp     #getcmd

                        mov     t2, t1                  ' get parameter pointer

                        shr     t1, #16 wz              ' get command
                        max     t1, #(OW_CRC8>>16)      ' make sure valid range
                        add     t1, #:cmdtable-1
                        jmp     t1                      ' jump to command

:cmdTable               jmp     #cmd_setup              ' command dispatch table
                        jmp     #cmd_reset
                        jmp     #cmd_write
                        jmp     #cmd_read
                        jmp     #cmd_search
                        jmp     #cmd_crc8

errorExit               neg     value, #1               ' set return to -1

endCmd                  mov     t1, par                 ' return result
                        add     t1, #4
                        wrlong  value, t1
                        wrlong  zero, par               ' clear command status
                        jmp     #getcmd                 ' wait for next command

'------------------------------------------------------------------------------
' parameters: data pin, ticks per usec
' return:     none
'------------------------------------------------------------------------------

cmd_setup               rdlong  t1, t2                  ' get data pin
                        mov     datamask, #1
                        shl     datamask, t1
                        add     t2, #4                  ' get 1 usec delay period
                        rdlong  dly1usec, t2

                        mov     dly2usec, dly1usec      ' set delay values
                        add     dly2usec, dly1usec
                        mov     dly3usec, dly2usec
                        add     dly3usec, dly1usec
                        mov     dly4usec, dly3usec
                        add     dly4usec, dly1usec
                        sub     dly1usec, #13           ' adjust in-line delay values
                        sub     dly2usec, #13
                        sub     dly3usec, #13
                        jmp     #endcmd

'------------------------------------------------------------------------------
' parameters: none
' return:     0 if no presence, 1 is presence detected
'------------------------------------------------------------------------------

cmd_reset               call    #_reset                 ' send reset and exit
                        jmp     #endcmd

'------------------------------------------------------------------------------
' parameters: value, number of bits
' return:     none
'------------------------------------------------------------------------------

cmd_write               rdlong  value, t2               ' get the data byte
                        add     t2, #4
                        rdlong  bitcnt, t2 wz           ' get bit count
        if_z            mov     bitcnt, #1              ' must be 1 to 32
                        max     bitcnt, #32
                        call    #_write                 ' write bits and exit
                        jmp     #endcmd

'------------------------------------------------------------------------------
' parameters: number of bits
' return:     value
'------------------------------------------------------------------------------

cmd_read                rdlong  bitcnt, t2              ' get bit count
        if_z            mov     bitcnt, #1              ' must be 1 to 32
                        max     bitcnt, #32
                        call    #_read                  ' read bits and exit
                        jmp     #endcmd

'------------------------------------------------------------------------------
' parameters: family, maximum number of addresses, address pointer
' return:     number of addresses
'------------------------------------------------------------------------------

cmd_search              rdlong  addrl, t2 wz            ' get family code
                        mov     addrh, #0
        if_nz           mov     lastunknown, #7         ' if non-zero, restrict search
        if_z            mov     lastunknown, #0         ' if zero, search all

                        add     t2, #4                  ' get maximum number of addresses
                        rdlong  datamax, t2
                        max     datamax, #150 wz
        if_z            jmp     #:exit

                        add     t2, #4                  ' get data pointer
                        rdlong  dataptr, t2
                        mov     datacnt, #0             ' clear address count

:nextAddr               call    #_reset                 ' reset the network
                        cmp     value, #0 wz            ' exit if no presence
        if_z            jmp     #:exit
                        mov     searchbit, #1           ' set initial search bit (1 to 64)
                        mov     unknown, #0             ' clear unknown marker
                        mov     addr, addrl             ' get address bits
                        mov     searchmask, #1          ' set search mask

                        mov     value, #SEARCH_ROM      ' send search ROM command
                        call    #_writebyte

:nextBit                mov     bitcnt, #2              ' read two bits
                        call    #_read

                        cmp     value, #%00 wz          ' 00 - device conflict
        if_nz           jmp     #:check10
                        cmp     searchbit, lastunknown wz, wc
        if_z            or      addr, searchmask
        if_z            jmp     #:sendbit
        if_nc           andn    addr, searchmask
        if_nc           mov     unknown, searchbit
        if_nc           jmp     #:sendbit
                        test    addr, searchmask wz
        if_z            mov     unknown, searchbit
                        jmp     #:sendbit

:check10                cmp     value, #%10 wz          ' 10 - all devices have 0 bit
        if_z            andn    addr, searchmask
        if_z            jmp     #:sendbit

:check01                cmp     value, #%01 wz          ' 01 - all devices have 1 bit
        if_z            or      addr, searchmask
        if_z            jmp     #:sendbit

                        jmp     #:exit                  ' 11 - no devices responding

:sendBit                test    addr, searchmask wc     ' send reply bit
                        muxc    value, #1
                        mov     bitcnt, #1
                        call    #_write

                        add     searchbit, #1           ' increment search count
                        rol     searchmask, #1          ' adjust mask
                        cmp     searchbit, #33 wz       ' check for upper 32 bits
        if_z            mov     addrl, addr
        if_z            mov     addr, addrh
                        cmp     searchbit, #65 wz       ' repeat for all 64 bits
        if_nz           jmp     #:nextbit

                        wrlong  addrl, dataptr          ' store address
                        add     dataptr, #4
                        mov     addrh, addr
                        wrlong  addrh, dataptr
                        add     dataptr, #4

                        add     datacnt, #1             ' increment address count
                        cmp     datacnt, datamax wc
                        mov     lastunknown, unknown wz ' update last unknown bit
        if_nz_and_c     jmp     #:nextaddr              ' repeat if more addresses

:exit                   mov     value, datacnt          ' return number of addresses found
                        jmp     #endcmd

'------------------------------------------------------------------------------
' parameters: byte count, address pointer
' return:     crc8
'------------------------------------------------------------------------------

cmd_crc8                rdlong  datacnt, t2             ' get number of bytes
                        add     t2, #4                  ' get data pointer
                        rdlong  dataptr, t2

                        mov     value, #0               ' clear CRC

:nextByte               rdbyte  addr, dataptr           ' get next byte
                        add     dataptr, #1
                        mov     bitcnt, #8

:nextBit                mov     t1, addr                ' x^8 + x^5 + x^4 + 1
                        shr     addr, #1
                        xor     t1, value
                        shr     value, #1
                        shr     t1, #1 wc
        if_c            xor     value, #crc#POLY8_DSMAX
                        djnz    bitcnt, #:nextbit
                        djnz    datacnt, #:nextbyte
                        jmp     #endcmd

'------------------------------------------------------------------------------
' input:  none
' output: value         0 if no presence, 1 is presence detected
'------------------------------------------------------------------------------

_reset                  test    datamask, ina wc        ' make sure bus is
        if_nc           jmp     #_reset_ret             '   free, first
                        andn    outa, datamask          ' set data low
                        or      dira, datamask

                        mov     t1, #480                ' delay 480 usec
                        call    #_dly

                        andn    dira, datamask          ' set data to high Z

                        mov     t1, #72                 ' delay 72 usec
                        call    #_dly

                        test    datamask, ina wc        ' check for presence
        if_c            mov     value, #0
        if_nc           mov     value, #1

                        mov     t1, #480                ' delay 480 usec
                        call    #_dly
_reset_ret              ret

'------------------------------------------------------------------------------
' input:  value         data bits
'         bitCount      number of bits
' output: none
'------------------------------------------------------------------------------

_writeByte              mov     bitcnt, #8              ' write an 8-bit byte

_write                  andn    outa, datamask          ' set data low for 8 usec
                        or      dira, datamask
                        mov     t1, #8
                        call    #_dly

                        ror     value, #1 wc            ' check next bit
        if_c            andn    dira, datamask          ' if 1, set data to high Z

                        mov     t1, #52                 ' hold for 52 usec
                        call    #_dly

                        andn    dira, datamask          ' set data to high Z for 12 usec
                        mov     t1, #12
                        call    #_dly

                        djnz    bitcnt, #_write         ' repeat for all bits
_writeByte_ret
_write_ret              ret

'------------------------------------------------------------------------------
' input:  bitCount      number of bits
' output: value         data bits
'------------------------------------------------------------------------------


_readByte               mov     bitcnt, #8              ' read an 8-bit byte

_read                   mov     shiftcnt, #32           ' get shift count
                        sub     shiftcnt, bitcnt

:read2                  andn    outa, datamask          ' pull low to get
                        or      dira, datamask          '   next bit
                        mov     t1, #4
                        call    #_dly

                        andn    dira, datamask          ' set data to high Z
                        mov     t1, #4                  ' delay 4 usec
                        call    #_dly

                        test    datamask, ina wc        ' read next bit
                        rcr     value, #1

                        mov     t1, #60                 ' delay for 60 usec
                        call    #_dly

                        djnz    bitcnt, #:read2         ' repeat for all bits

                        shr     value, shiftcnt         ' right justify
_readByte_ret
_read_ret               ret

'------------------------------------------------------------------------------
' input:  t1            number of usec to delay (must be multiple of 4)
' output: none
'------------------------------------------------------------------------------


_dly                    shr     t1, #2 wz               ' divide delay count by 4
        if_z            mov     t1, #1                  ' ensure at least one delay
                        mov     t2, dly4usec            ' get initial delay
                        add     t2, cnt
                        sub     t2, #41                 ' adjust for call overhead

:wait                   waitcnt t2, dly4usec            ' wait for 4 usec
                        djnz    t1, #:wait              ' loop while delay count > 0
_dly_ret                ret

'-------------------- constant values -----------------------------------------

Zero                    long    0                       ' constants

'-------------------- local variables -----------------------------------------

t1                      res     1                       ' temporary values
t2                      res     1
bitcnt                  res     1                       ' bit counter
shiftcnt                res     1                       ' shift counter
datamask                res     1                       ' data pin mask
value                   res     1                       ' data value / return value
dataptr                 res     1                       ' data pointer
datacnt                 res     1                       ' data count
datamax                 res     1                       ' maximum data count

searchbit               res     1                       ' current search bit
searchmask              res     1                       ' search mask
unknown                 res     1                       ' current unknown bit
lastunknown             res     1                       ' last unknown search bit
addr                    res     1                       ' current address
addrl                   res     1                       ' lower 32 bits of address
addrh                   res     1                       ' upper 32 bits of address

dly1usec                res     1                       ' 1 usec delay
dly2usec                res     1                       ' 2 usec delay
dly3usec                res     1                       ' 3 usec delay
dly4usec                res     1                       ' 4 usec delay

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

