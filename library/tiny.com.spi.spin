{
    --------------------------------------------
    Filename: tiny.com.spi.spin
    Author: Jesse Burt
    Description: SPI engine (SPIN-based)
        (based on SPI_Spin.spin, originally by
        Beau Schwabe)
    Started 2009
    Updated Sep 12, 2020
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

    #0, MSBPRE, LSBPRE, MSBPOST, LSBPOST                ' Used for ShiftIn()
'       =0      =1      =2       =3
'
' MSBPRE   - Most Significant Bit first ; data is valid before the clock
' LSBPRE   - Least Significant Bit first ; data is valid before the clock
' MSBPOST  - Most Significant Bit first ; data is valid after the clock
' LSBPOST  - Least Significant Bit first ; data is valid after the clock


    #4, LSBFIRST, MSBFIRST                              ' Used for ShiftOut()
'       =4        =5
'
' LSBFIRST - Least Significant Bit first ; data is valid after the clock
' MSBFIRST - Most Significant Bit first ; data is valid after the clock


VAR

    long _sck_delay, _cpol

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
