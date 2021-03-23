{
    --------------------------------------------
    Filename: SoftRTC-Demo.spin
    Author: Jesse Burt
    Description: Demo of the software RTC
    Started 2009
    Updated Mar 23, 2021
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

    rtc.suspend{}
    rtc.setyear(20)                             ' 00..31 (Valid from 2000 to 2031)
    rtc.setmonth(12)                            ' 01..12
    rtc.setdate(31)                             ' 01..31
    rtc.setweekday(5)                           ' 01..07

    rtc.sethours(23)                            ' 01..12
    rtc.setminutes(59)                          ' 00..59
    rtc.setseconds(55)                          ' 00..59
    rtc.resume{}

    repeat
        rtc.parsedatestamp(@_datestamp)
        rtc.parsetimestamp(@_timestamp)

        ser.position(0, 3)
        ser.str(@_datestamp)
        ser.char(" ")
        ser.str(@weekday[(rtc.weekday{} - 1) * 4])
        ser.str(string("  "))
        ser.str(@_timestamp)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    rtc.start(@_timestring)
    ser.strln(string("SoftRTC started"))

DAT

    weekday
            byte    "Sun", 0
            byte    "Mon", 0
            byte    "Tue", 0
            byte    "Wed", 0
            byte    "Thu", 0
            byte    "Fri", 0
            byte    "Sat", 0

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
