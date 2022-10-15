{
    --------------------------------------------
    Filename: TSL230-Demo.spin
    Author: Paul Baker
    Modified By: Jesse Burt
    Description: Demo of the TSL230 Light to Frequency
        driver
    Started 2007
    Updated Apr 30, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on tsl230 DEMO.spin, originally
        by Paul Baker (Copyright 2007 Parallax, Inc)
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    TSL_INPIN   = 0
    TSL_CTRLPIN = 1
    TSL_SAMPRATE= 10
    TSL_AUTOSCL = TRUE
' --

OBJ

    cfg     : "boardcfg.flip"
    term    : "com.serial.terminal.ansi"
    lfs     : "sensor.light.tsl230"
    time    : "time"

PUB Main{}

    term.start(SER_BAUD)
    time.msleep(30)
    term.clear{}

    lfs.start(TSL_INPIN, TSL_CTRLPIN, TSL_SAMPRATE, TSL_AUTOSCL)

    repeat
        term.dec(lfs.getsample{})
        term.newline{}
        time.msleep(100)

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

