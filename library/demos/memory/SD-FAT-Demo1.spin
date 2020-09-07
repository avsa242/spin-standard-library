{
    --------------------------------------------
    Filename: SD-FAT-Demo1.spin
    Author: Radical Eye Software
    Modified by: Jesse Burt
    Description: FAT16/32 filesystem driver
    Started 2008
    Updated Aug 9, 2020
    See end of file for terms of use.
    --------------------------------------------
}
'    NOTE: This is a derivative of fsrw_speed.spin, written by Radical Eye Software.
'        The original header is preserved below:

'
'   Copyright 2008   Radical Eye Software
'
'   See end of file for terms of use.
'
CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

    LED             = cfg#LED1
    SER_RX          = 31
    SER_TX          = 30
    SER_BAUD        = 115_200

    SD_BASEPIN      = 0

    DIR_ROW         = 4
    ROWS            = 15
    SPEEDTEST_ROW   = DIR_ROW+ROWS+2

OBJ

    cfg     : "core.con.boardcfg.quickstart-hib"
    ser     : "com.serial.terminal.ansi"
    io      : "io"
    time    : "time"
    sdfat   : "filesystem.block.fat"
    u64     : "math.unsigned64"

VAR

    long _sdfat_status
    byte _ser_cog
    byte _tbuf[20]
    byte _bigbuf[8192]

PUB Main

    Setup

    DIR

    SpeedTest

    ser.str(string("Complete - unmounting card..."))
    ifnot result := \sdfat.Unmount
        ser.str(string("unmounted", ser#CR, ser#LF))
    else
        ser.str(string("error #"))
        ser.dec(result)
        FlashLED(LED, 500)

    FlashLED(LED, 100)

PUB DIR | row

    row := DIR_ROW
    ser.position(0, row)
    ser.str(string("DIR:", ser#CR, ser#LF))
    row++
    sdfat.opendir
    repeat while 0 == sdfat.nextfile(@_tbuf)
        ser.str(@_tbuf)
        ser.clearline{}
        ser.str(string(10, 13))
        row++
        if row == DIR_ROW+ROWS-1
            ser.str(string("Press any key for more"))
            ser.charin
            row := DIR_ROW+1
            ser.position(0, row)

PUB SpeedTest | count, nr_bytes, start, elapsed, secs, Bps, scale

    ser.position(0, SPEEDTEST_ROW)
    ser.str(string("Speed test", ser#CR, ser#LF))

    scale := 1_000                                          ' Bytes per second ends up fractional, and introduces a significant rounding error, so scale up math
    count := 256
    nr_bytes := 8192


    ser.str(string("Write "))
    ser.dec(count * nr_bytes)
    ser.str(string(" bytes: "))
    sdfat.popen(string("speed.txt"), "w")                   ' Open speed.txt for writing

    start := cnt                                            ' Timestamp start of speed test
    repeat count
        sdfat.pwrite(@_bigbuf, nr_bytes)                    ' Write nr_bytes from _bigbuf to speed.txt
    elapsed := cnt - start                                  ' Timestamp end of speed test
    sdfat.pclose                                            ' Close the file when done

    secs := u64.MultDiv(elapsed, scale, clkfreq)            ' Use 64-bit math to handle the scaled-up calculations
    Bps := u64.MultDiv((nr_bytes * count), scale, secs)

    ser.dec(elapsed)
    ser.str(string(" cycles ("))
    ser.dec(Bps)
    ser.str(string("Bps)", ser#CR, ser#LF))


    ser.str(string("Read "))                                ' Do the same as above, but read this time
    ser.dec(count * nr_bytes)
    ser.str(string(" bytes: "))
    sdfat.popen(string("speed.txt"), "r")

    start := cnt
    repeat count
        sdfat.pread(@_bigbuf, nr_bytes)
    elapsed := cnt - start
    sdfat.pclose

    secs := u64.MultDiv(elapsed, scale, clkfreq)
    Bps := u64.MultDiv((nr_bytes * count), scale, secs)

    ser.dec(elapsed)
    ser.str(string(" cycles ("))
    ser.dec(Bps)
    ser.str(string("Bps)", ser#CR, ser#LF))

PUB Setup

    if _ser_cog := ser.StartRXTX(SER_RX, SER_TX, 0, SER_BAUD)
        time.MSleep(30)
        ser.clear
        ser.str(string("Serial terminal started", ser#CR, ser#LF))
    ifnot _sdfat_status := \sdfat.mount(SD_BASEPIN)
        ser.str(string("SD driver started. Card mounted.", ser#CR, ser#LF))
    else
        ser.str(string("SD driver failed to start - err#"))
        ser.dec(_sdfat_status)
        ser.str(string(", halting", ser#CR, ser#LF))
        sdfat.Unmount
        time.MSleep(500)
        ser.Stop
        FlashLED(LED, 500)

#include "lib.utility.spin"

{{
'  Permission is hereby granted, free of charge, to any person obtaining
'  a copy of this software and associated documentation files
'  (the "Software"), to deal in the Software without restriction,
'  including without limitation the rights to use, copy, modify, merge,
'  publish, distribute, sublicense, and/or sell copies of the Software,
'  and to permit persons to whom the Software is furnished to do so,
'  subject to the following conditions:
'
'  The above copyright notice and this permission notice shall be included
'  in all copies or substantial portions of the Software.
'
'  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
'  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
'  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
'  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
'  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
'  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
'  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}}
