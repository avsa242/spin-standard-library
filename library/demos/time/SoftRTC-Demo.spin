{
    --------------------------------------------
    Filename: SoftRTC-Demo.spin
    Author: Jesse Burt
    Description: Demo of the software RTC
    Started 2009
    Updated Sep 7, 2020
    See end of file for terms of use.
    --------------------------------------------
    NOTE: Based on PropellerRTC_Emulator_DEMO.spin,
        originally written by Beau Schwabe. The
        original header is preserved below
}
' Author: Beau Schwabe
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-definable constants
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    rtc     : "time.rtc.soft"
    ser     : "com.serial.terminal.ansi"
    time    : "time"

VAR

    long  _timestring
    byte  _datestamp[11], _timestamp[11]

PUB Main{}

    setup{}

    rtc.suspend{}                                 ' Suspend rtc while being 

    rtc.year(20)                               ' 00 - 31 ... Valid from 2000 to 2031
    rtc.months(12)                              ' 01 - 12 ... Month
    rtc.days(31)                               ' 01 - 31 ... Date

    rtc.hours(23)                               ' 01 - 12 ... Hour
    rtc.minutes(59)                                ' 00 - 59 ... Minute
    rtc.seconds(55)                                ' 00 - 59 ... Second

    rtc.restart{}                                 ' Start rtc after being 

    repeat
        rtc.parsedatestamp(@_datestamp)
        rtc.parsetimestamp(@_timestamp)

        ser.position(0, 3)
        ser.str(@_datestamp)
        ser.str(string("  "))
        ser.str(@_timestamp)

PUB Setup{}

    repeat until ser.startrxtx(SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if rtc.start(@_timestring)
        ser.str(string("SoftRTC started", ser#CR, ser#LF))
    else
        ser.str(string("SoftRTC failed to start - halting", ser#CR, ser#LF))
        rtc.stop{}
        time.msleep(50)
        ser.stop{}

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
