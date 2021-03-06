{
    --------------------------------------------
    Filename: 23XXXX-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the 23XXXX driver
    Copyright (c) 2020
    Started May 20, 2019
    Updated Dec 27, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq
    CLK_FREQ    = ((_clkmode - xtal1) >> 6) * _xinfreq
    TICKS_USEC  = CLK_FREQ / 1_000_000

' -- User-modifiable constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    CS_PIN      = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2
    MISO_PIN    = 3

' 64 = 23640, 256 = 23256, 512 = 23512, 1024 = 231024
    PART        = 1024
' --

' Calculations based on PART
    RAMSIZE     = (PART / 8) * 1024
    RAM_END     = RAMSIZE - 1
    PAGESIZE    = 32                            ' Page size is the same for all SRAMs
    LASTPAGE    = (RAMSIZE/PAGESIZE) - 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    sram    : "memory.sram.23xxxx.spi"

VAR

    byte _sram_buff[PAGESIZE]                   ' working buffer for SRAM

PUB Main{} | base_page, start, elapsed

    setup{}
    sram.defaults{}
    bytefill(@_sram_buff, 0, PAGESIZE)          ' clear out buffer
    ser.position(0, 3)
    ser.printf2(string("SRAM size set to %dkbytes (23%d)\n"), RAMSIZE, PART)

    base_page := 0

    repeat
        ' simple speed test
        start := cnt
        sram.readpage(base_page, PAGESIZE, @_sram_buff)
        elapsed := cnt-start

        ser.hexdump(@_sram_buff, base_page << 5, PAGESIZE, 8, 0, 5)
        ser.printf1(string("\nReading done (%dus)\n"), usec(elapsed))

        case ser.charin{}
            "[":                                ' Go back a page in SRAM
                base_page--
                if base_page < 0
                    base_page := 0
            "]":                                ' Go forward a page
                base_page++
                if base_page > LASTPAGE
                    base_page := LASTPAGE
            "e":                                ' Go to the last page
                base_page := LASTPAGE
            "s":                                ' Go to the first page
                base_page := 0
            "w":                                ' Write a test string
                writetest(base_page << 5)       '   to start of current page
            "x":                                ' Erase the current page
                erasepage(base_page)
            "q":                                ' Quit the demo and halt
                ser.strln(string("Halting"))
                stop{}
                quit
            other:

    repeat

PUB ErasePage(base_page) | tmp[8]
' Erase a page of SRAM
    bytefill(@tmp, $00, PAGESIZE)               ' fill temp buffer with zeroes
    sram.writepage(base_page, PAGESIZE, @tmp)   '   and write it to the page

PUB WriteTest(base) | tmp
' Write a test string to the SRAM
    tmp := string("TESTING TESTING 1 2 3")
    sram.writebytes(base, strsize(tmp), tmp)

PRI usec(ticks): usecs
' Convert system clock ticks to microseconds
    return ticks / TICKS_USEC

PUB Setup

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if sram.start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("23XXXX driver started"))
    else
        ser.strln(string("23XXXX driver failed to start - halting"))
        stop{}

PUB Stop{}

    time.msleep(5)
    ser.stop{}
    sram.stop{}

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
