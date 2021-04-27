{
    --------------------------------------------
    Filename: SD-FAT-Demo1.spin
    Author: Radical Eye Software
    Modified by: Jesse Burt
    Description: FAT16/32 filesystem driver
    Started 2008
    Updated Apr 27, 2021
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

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    SD_BASEPIN      = cfg#SD_BASEPIN
' --

    DIR_ROW         = 4
    ROWS            = 15
    SPEEDTEST_ROW   = DIR_ROW+ROWS+2

OBJ

    cfg     : "core.con.boardcfg.activityboard"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    sdfat   : "filesystem.block.fat"
    u64     : "math.unsigned64"

VAR

    long _sdfat_status
    byte _ser_cog
    byte _tbuf[20]
    byte _bigbuf[8192]

PUB Main{}

    setup{}

    dir{}

    speedtest{}

    ser.str(string("Complete - unmounting card..."))
    ifnot result := \sdfat.unmount{}
        ser.strln(string("unmounted"))
    else
        ser.str(string("error #"))
        ser.dec(result)
        repeat

    repeat

PUB DIR{} | row
' Display a directory listing of the SD card
    row := DIR_ROW
    ser.position(0, row)
    ser.strln(string("DIR:"))
    row++
    sdfat.opendir{}
    repeat while 0 == sdfat.nextfile(@_tbuf)
        ser.str(@_tbuf)
        ser.clearline{}
        ser.newline{}
        row++
        if row == DIR_ROW+ROWS-1
            ser.str(string("Press any key for more"))
            ser.charin{}
            row := DIR_ROW+1
            ser.position(0, row)

PUB SpeedTest{} | count, nr_bytes, start, elapsed, secs, bps, scale

    ser.position(0, SPEEDTEST_ROW)
    ser.strln(string("Speed test"))

    scale := 1_000                              ' Bytes per second ends up
                                                ' fractional, and introduces
                                                ' a significant rounding error,
                                                '   so scale up math
    count := 256
    nr_bytes := 8192

    ' write test
    ser.printf1(string("Write %d bytes: "), count * nr_bytes)
    sdfat.popen(string("speed.txt"), "w")       ' open speed.txt for writing

    start := cnt                                ' timestamp start of speed test
    repeat count
        sdfat.pwrite(@_bigbuf, nr_bytes)        ' write nr_bytes from _bigbuf to speed.txt
    elapsed := cnt - start                      ' timestamp end of speed test
    sdfat.pclose{}                              ' close the file when done

    ' use 64-bit math to handle the scaled-up calculations
    secs := u64.multdiv(elapsed, scale, clkfreq)
    bps := u64.multdiv((nr_bytes * count), scale, secs)

    ser.printf2(string("%d cycles (%d Bps)\n"), elapsed, bps)

    ' read test
    ser.printf1(string("Read %d bytes: "), count * nr_bytes)
    sdfat.popen(string("speed.txt"), "r")

    start := cnt
    repeat count
        sdfat.pread(@_bigbuf, nr_bytes)
    elapsed := cnt - start
    sdfat.pclose

    secs := u64.multdiv(elapsed, scale, clkfreq)
    bps := u64.multdiv((nr_bytes * count), scale, secs)

    ser.printf2(string("%d cycles (%d Bps)\n"), elapsed, bps)

PUB Setup{}

    ser.start(SER_BAUD)
        time.msleep(30)
        ser.clear{}
        ser.strln(string("Serial terminal started"))
    ifnot _sdfat_status := \sdfat.mount(SD_BASEPIN)
        ser.strln(string("SD driver started. Card mounted."))
    else
        ser.str(string("SD driver failed to start - err#"))
        ser.dec(_sdfat_status)
        ser.strln(string(", halting"))
        sdfat.unmount{}
        time.msleep(500)
        ser.stop{}
        repeat

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
