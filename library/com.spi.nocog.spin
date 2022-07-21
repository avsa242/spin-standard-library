{
    --------------------------------------------
    Filename: com.spi.nocog.spin
    Author: Jesse Burt
    Description: SPI engine (SPIN-based)
        @80MHz Fsys:
            Write speed: 25.641kHz actual (25% duty - 10uS H : 29uS L)
            Read speed: 26.315kHz actual (26% duty - 10uS H : 28uS L)
    Started 2009
    Updated Jul 3, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on SPI_Spin.spin,
        originally by Beau Schwabe
}
VAR

    long _SCK, _MOSI, _MISO
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

    outa[SCK] := _cpol
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

PUB RdBits_LSBF(nr_bits): val | SCK, MOSI, MISO, clk_delay, b
' Read arbitrary number of bits from SPI bus, least-significant bit first
'   nr_bits: 1 to 32
    ifnot (lookdown(nr_bits: 1..32))            ' reject invalid # bits
        return
    longmove(@SCK, @_SCK, 4)
    val := 0
    dira[MISO] := 0
    case _spi_mode
        0, 2:
            repeat b from 0 to (nr_bits-1)
                val |= (ina[MISO] << b)
                !outa[SCK]
                !outa[SCK]
        1, 3:
            repeat b from 0 to (nr_bits-1)
                !outa[SCK]
                val |= (ina[MISO] << b)
                !outa[SCK]

PUB RdBits_MSBF(nr_bits): val | SCK, MOSI, MISO, clk_delay, b
' Read arbitrary number of bits from SPI bus, most-significant bit first
'   nr_bits: 1 to 32
    ifnot (lookdown(nr_bits: 1..32))            ' reject invalid # bits
        return
    longmove(@SCK, @_SCK, 4)
    val := 0
    dira[MISO] := 0
    case _spi_mode
        0, 2:
            repeat b from (nr_bits-1) to 0
                val |= (ina[MISO] << b)
                !outa[SCK]
                !outa[SCK]
        1, 3:
            repeat b from (nr_bits-1) to 0
                !outa[SCK]
                val |= (ina[MISO] << b)
                !outa[SCK]

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

PUB WrBits_LSBF(val, nr_bits) | SCK, MOSI, MISO, clk_delay, b
' Write arbitrary number of bits to SPI bus, least-significant byte first
'   nr_bits: 1 to 32
    ifnot (lookdown(nr_bits: 1..32))            ' reject invalid # bits
        return
    longmove(@SCK, @_SCK, 4)
    outa[MOSI] := 0
    repeat b from 0 to (nr_bits-1)
        outa[MOSI] := (val >> b)
        !outa[SCK]
        !outa[SCK]

PUB WrBits_MSBF(val, nr_bits) | SCK, MOSI, MISO, clk_delay, b
' Write arbitrary number of bits to SPI bus, most-significant byte first
'   nr_bits: 1 to 32
    ifnot (lookdown(nr_bits: 1..32))            ' reject invalid # bits
        return
    longmove(@SCK, @_SCK, 4)
    outa[MOSI] := 0
    repeat b from (nr_bits-1) to 0
        outa[MOSI] := (val >> b)
        !outa[SCK]
        !outa[SCK]

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

#include "com.spi.common.spinh"                 ' R/W methods common to all SPI engines

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

