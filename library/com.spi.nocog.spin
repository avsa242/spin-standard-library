{
    --------------------------------------------
    Filename: com.spi.nocog.spin
    Author: Jesse Burt
    Description: SPI engine (SPIN-based)
        (based on SPI_Spin.spin, originally by
        Beau Schwabe)
    Started 2009
    Updated May 25, 2022
    See end of file for terms of use.
    --------------------------------------------
}
{{
************************************************
* Propeller SPI Engine  ... Spin Version  v1.0 *
* Author: Beau Schwabe                         *
* Copyright (c) 2009 Parallax                  *
* See end of file for terms of use.            *
************************************************

Revision History:
         V1.0   - original program

}}
CON

    #0, MSBPRE, LSBPRE, MSBPOST, LSBPOST                ' Used for ShiftIn{}
'       =0      =1      =2       =3
'
' MSBPRE   - Most Significant Bit first ; data is valid before the clock
' LSBPRE   - Least Significant Bit first ; data is valid before the clock
' MSBPOST  - Most Significant Bit first ; data is valid after the clock
' LSBPOST  - Least Significant Bit first ; data is valid after the clock


    #4, LSBFIRST, MSBFIRST                              ' Used for ShiftOut{}
'       =4        =5
'
' LSBFIRST - Least Significant Bit first ; data is valid after the clock
' MSBFIRST - Most Significant Bit first ; data is valid after the clock


VAR

    long _SCK, _MOSI, _MISO, _spi_mode, _cpol
    long _sck_delay

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
'       1: CPOL 0, CPHA 1
'           SCK idles low
'           MISO shifted in on falling clock pulse
'           MOSI shifted out on rising clock pulse
'       2: CPOL 1, CPHA 0
'           SCK idles high
'           MISO shifted in on falling clock pulse
'           MOSI shifted out on rising clock pulse
'       3: CPOL 1, CPHA 1
'           SCK idles high
'           MISO shifted in on rising clock pulse
'           MOSI shifted out on falling clock pulse
'   NOTE: CS must be handled by the parent object
    longmove(@_SCK, @SCK, 4)                      ' Copy pins

    mode(SPI_MODE)

    dira[SCK] := 1
    outa[MOSI] := 0
    dira[MOSI] := 1

    if MISO <> -1                               ' MISO optional
        dira[MISO] := 0

    return cogid{}+1                            ' return current cog id

PUB DeInit
' Deinitialize
'   Float I/O pins and clear out hub vars
    dira[_SCK] := 0
    dira[_MOSI] := 0
    dira[_MISO] := 0
    longfill(@_SCK, 0, 6)

PUB Mode(mode_nr): curr_mode
' Set SPI mode
'   Valid values: 0..3 (default: 0)
'   Any other value returns the current setting
    case mode_nr
        0, 1:
            _cpol := 0
        2, 3:
            _cpol := 1
        other:
            return _spi_mode

    _spi_mode := mode_nr
    outa[_SCK] := _cpol

PUB RdBlock_LSBF(ptr_buff, nr_bytes) | SCK, MOSI, MISO, b_num, tmp
' Read block of data from SPI bus, least-significant byte first
    longmove(@SCK, @_SCK, 4)                    ' copy pins from hub
    dira[MISO] := 0                             ' ensure MISO is an input
    tmp := 0
    case _spi_mode
        0, 2:
            repeat b_num from 0 to nr_bytes-1   ' byte loop
                repeat 8                        ' bit loop
                    tmp := tmp << 1 | ina[MISO] ' sample bit
                    !outa[SCK]                  ' clock
                    !outa[SCK]
                byte[ptr_buff][b_num] := tmp    ' copy working byte
        1, 3:
            repeat b_num from 0 to nr_bytes-1   ' byte loop
                repeat 8                        ' bit loop
                    !outa[SCK]                  ' clock
                    tmp := tmp << 1 | ina[MISO] ' sample bit
                    !outa[SCK]
                byte[ptr_buff][b_num] := tmp    ' copy working byte

PUB RdBlock_MSBF(ptr_buff, nr_bytes) | SCK, MOSI, MISO, b_num, tmp
' Read block of data from SPI bus, most-significant byte first
    longmove(@SCK, @_SCK, 4)                    ' copy pins from hub
    dira[MISO] := 0                             ' ensure MISO is an input
    tmp := 0
    case _spi_mode
        0, 2:
            repeat b_num from nr_bytes-1 to 0   ' byte loop
                repeat 8                        ' bit loop
                    tmp := (tmp << 1) | ina[MISO]   ' sample bit
                    !outa[SCK]                  ' clock
                    !outa[SCK]
                byte[ptr_buff][b_num] := tmp    ' copy working byte
        1, 3:
            repeat b_num from nr_bytes-1 to 0   ' byte loop
                repeat 8                        ' bit loop
                    !outa[SCK]                  ' clock
                    tmp := (tmp << 1) | ina[MISO]   ' sample bit
                    !outa[SCK]
                byte[ptr_buff][b_num] := tmp    ' copy working byte

PUB Rd_Byte{}: spi2byte
' Read byte from SPI bus
    rdblock_lsbf(@spi2byte, 1)

PUB RdLong_LSBF{}: spi2long
' Read long from SPI bus, least-significant byte first
    rdblock_lsbf(@spi2long, 4)

PUB RdLong_MSBF{}: spi2long
' Read long from SPI bus, least-significant byte first
    rdblock_msbf(@spi2long, 4)

PUB RdWord_LSBF{}: spi2word
' Read word from SPI bus, least-significant byte first
    rdblock_lsbf(@spi2word, 2)

PUB RdWord_MSBF{}: spi2word
' Read word from SPI bus, least-significant byte first
    rdblock_msbf(@spi2word, 2)

PUB WrBlock_LSBF(ptr_buff, nr_bytes) | SCK, MOSI, MISO, b_num, tmp
' Write block of data to SPI bus from ptr_buff, least-significant byte first
    longmove(@SCK, @_SCK, 4)                ' copy pins from hub
    dira[MOSI] := 1                         ' ensure MOSI is an output
    case _spi_mode
        0, 2:
            repeat b_num from 0 to nr_bytes-1       ' byte loop
                tmp := (byte[ptr_buff][b_num] << 24)' align byte with MSBit of long
                repeat 8                            ' bit loop
                    outa[MOSI] := (tmp <-= 1) & 1   ' next bit into pos and isolate it
                    !outa[SCK]                      ' clock
                    !outa[SCK]
        1, 3:
            repeat b_num from 0 to nr_bytes-1       ' byte loop
                tmp := (byte[ptr_buff][b_num] << 24)' align byte with MSBit of long
                repeat 8                            ' bit loop
                    outa[MOSI] := (tmp <-= 1) & 1   ' next bit into pos and isolate it
                    !outa[SCK]                      ' clock
                    !outa[SCK]


PUB WrBlock_MSBF(ptr_buff, nr_bytes) | SCK, MOSI, MISO, b_num, tmp
' Write block of data to SPI bus from ptr_buff, most-significant byte first
    longmove(@SCK, @_SCK, 4)                ' copy pins from hub
    dira[MOSI] := 1                         ' ensure MOSI is an output
    case _spi_mode
        0, 2:
            repeat b_num from nr_bytes-1 to 0       ' byte loop
                tmp := (byte[ptr_buff][b_num] << 24)' align byte with MSBit of long
                repeat 8                            ' bit loop
                    outa[MOSI] := (tmp <-= 1) & 1   ' next bit into pos and isolate it
                    !outa[SCK]                      ' clock
                    !outa[SCK]
        1, 3:
            repeat b_num from nr_bytes-1 to 0       ' byte loop
                tmp := (byte[ptr_buff][b_num] << 24)' align byte with MSBit of long
                repeat 8                            ' bit loop
                    !outa[SCK]                      ' clock
                    !outa[SCK]
                    outa[MOSI] := (tmp <-= 1) & 1   ' next bit into pos and isolate it

PUB Wr_Byte(byte2spi)
' Write byte to SPI bus
    wrblock_lsbf(@byte2spi, 1)

PUB WrLong_LSBF(long2spi)
' Write long to SPI bus, least-significant byte first
    wrblock_lsbf(@long2spi, 4)

PUB WrLong_MSBF(long2spi)
' Write long to SPI bus, most-significant byte first
    wrblock_msbf(@long2spi, 4)

PUB WrWord_LSBF(word2spi)
' Write word to SPI bus, least-significant byte first
    wrblock_lsbf(@word2spi, 2)

PUB WrWord_MSBF(word2spi)
' Write word to SPI bus, most-significant byte first
    wrblock_msbf(@word2spi, 2)

'-- Legacy methods below

PUB Start(SCK_DELAY, CPOL)

    _cpol := CPOL
    _sck_delay := ((clkfreq / 100000 * SCK_DELAY) - 4296) #> 381

PUB ShiftOut(mosi, sck, bitorder, nr_bits, val)

    dira[mosi] := 1                                     ' make data pin output
    outa[sck] := _cpol                                  ' initial clock state
    dira[sck] := 1                                      ' make clock pin output

    if bitorder == LSBFIRST
        val <-= 1                                       ' pre-align lsb
        repeat nr_bits
            outa[mosi] := (val ->= 1) & 1               ' output data bit
            postclock(sck)

    if bitorder == MSBFIRST
        val <<= (32 - nr_bits)                          ' pre-align msb
        repeat nr_bits
            outa[mosi] := (val <-= 1) & 1               ' output data bit
            postclock(sck)

PUB ShiftIn(miso, sck, bitorder, nr_bits): val

    dira[miso] := 0                                     ' make dpin input
    outa[sck] := _cpol                                  ' initial clock state
    dira[sck] := 1                                      ' make cpin output

    val := 0                                            ' clear output

    if bitorder == MSBPRE
        repeat nr_bits
            val := (val << 1) | ina[miso]
            postclock(sck)

    if bitorder == LSBPRE
        repeat (nr_bits + 1)
            val := (val >> 1) | (ina[miso] << 31)
            postclock(sck)
        val >>= (32 - nr_bits)

    if bitorder == MSBPOST
        repeat nr_bits
            preclock(sck)
            val := (val << 1) | ina[miso]

    if bitorder == LSBPOST
        repeat (nr_bits + 1)
            preclock(sck)
            val := (val >> 1) | (ina[miso] << 31)
        val >>= (32 - nr_bits)

    return val

PRI PostClock(sck)

    waitcnt(cnt+_sck_delay)
    !outa[sck]
    waitcnt(cnt+_sck_delay)
    !outa[sck]

PRI PreClock(sck)

    !outa[sck]
    waitcnt(cnt+_sck_delay)
    !outa[sck]
    waitcnt(cnt+_sck_delay)


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
