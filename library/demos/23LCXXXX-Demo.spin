{
    --------------------------------------------
    Filename: 23LCXXXX-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the 23LCXXXX driver
    Copyright (c) 2020
    Started May 20, 2019
    Updated Jan 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq
    CLK_FREQ    = ((_clkmode - xtal1) >> 6) * _xinfreq
    TICKS_USEC  = CLK_FREQ / 1_000_000

' User-modifiable constants
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200
    LED         = cfg#LED1
    CS_PIN      = 4
    SCK_PIN     = 2
    MOSI_PIN    = 1
    MISO_PIN    = 0
    PART        = 1024                              ' 64 = 23K640, 256 = 23K256, 512 = 23LC512, 1024 = 23LC1024

' Calculations based on PART
    RAMSIZE     = (PART / 8) * 1024
    RAM_END     = RAMSIZE - 1
    PAGESIZE    = 32                                ' Page size is the same for all Microchip SRAMs
    LASTPAGE    = (RAMSIZE/PAGESIZE) - 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    io      : "io"
    sram    : "memory.sram.23lcxxxx.spi"

VAR

    byte _ser_cog, _sram_cog
    byte _sram_buff[PAGESIZE]

PUB Main | base_page, start, elapsed

    Setup

    ser.position(0, 3)
    ser.str(string("SRAM size set to "))
    ser.dec(RAMSIZE)
    ser.str(string("kbytes (23LC"))
    ser.dec(PART)
    ser.str(string(")", ser#CR, ser#LF))

    base_page := 0
    sram.OpMode(sram#PAGE)                                          ' Set Page access mode

    repeat
        start := cnt                                                '
        sram.ReadPage(base_page, PAGESIZE, @_sram_buff)             ' Simple speed test
        elapsed := cnt-start                                        '
        ser.Hexdump(@_sram_buff, base_page << 5, PAGESIZE, 8, 0, 5)
        ser.Str(string(ser#CR, ser#LF, "Reading done ("))
        ser.Dec(usec(elapsed))
        ser.Str(string("us)", ser#CR, ser#LF))

        case ser.CharIn
            "[":                                                    ' Go back a page in SRAM
                base_page--
                if base_page < 0
                    base_page := 0
            "]":                                                    ' Go forward a page
                base_page++
                if base_page > LASTPAGE
                    base_page := LASTPAGE
            "e":                                                    ' Go to the last page
                base_page := LASTPAGE
            "s":                                                    ' Go to the first page
                base_page := 0
            "w":                                                    ' Write a test string to the current page
                WriteTest(base_page << 5)
            "x":                                                    ' Erase the current page
                ErasePage(base_page)
            "q":                                                    ' Quit the demo and shutdown
                ser.Str(string("Halting", ser#CR, ser#LF))
                Stop
                quit
            OTHER:

    FlashLED(LED, 100)

PUB ErasePage(base_page) | tmp[8]
' Erase a page of SRAM
    bytefill(@tmp, $00, PAGESIZE)
    sram.WritePage(base_page, PAGESIZE, @tmp)

PUB WriteTest(base) | tmp, i
' Write a test string to the SRAM
    tmp := string("TESTING TESTING 1 2 3")
    sram.WriteBytes(base, strsize(tmp), tmp)

PUB usec(ticks)

    return ticks / TICKS_USEC

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(100)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if _sram_cog := sram.Start (CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.Str(string("23LCXXXX driver started", ser#CR, ser#LF))
    else
        ser.Str(string("23LCXXXX driver failed to start - halting", ser#CR, ser#LF))
        Stop
        FlashLED(LED, 500)

PUB Stop

    time.MSleep (5)
    ser.Stop
    sram.Stop

#include "lib.utility.spin"

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
