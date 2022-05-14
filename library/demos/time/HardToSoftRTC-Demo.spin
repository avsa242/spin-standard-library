{
    --------------------------------------------
    Filename: HardToSoftRTC-Demo.spin
    Author: Jesse Burt
    Description: Demo that reads a hardware RTC once,
        sets the software RTC by it, and continuously
        displays the date and time from the software RTC
    Started Sep 7, 2020
    Updated May 14, 2022
    See end of file for terms of use.
    --------------------------------------------
}
' Uncomment one of the following:
#define PCF8563
'#define DS3231
'#define RV3028

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-definable constants
    SER_BAUD    = 115_200

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    softrtc : "time.rtc.soft"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
#ifdef PCF8563
    hardrtc : "time.rtc.pcf8563"
#elseifdef DS3231
    hardrtc : "time.rtc.ds3231"
#elseifdef RV3028
    hardrtc : "time.rtc.rv3028"
#else
#error "No RTC defined!"
#endif

VAR

    long  _timestring
    byte  _datestamp[11], _timestamp[11]

PUB Main{} | hyr, hmo, hdy, hwkd, hhr, hmin, hsec

    setup{}

' Read in the time from the hardware RTC
    hardrtc.pollrtc{}
    hyr := hardrtc.year{}
    hmo := hardrtc.month{}
    hdy := hardrtc.date{}
    hwkd := hardrtc.weekday{}
    hhr := hardrtc.hours{}
    hmin := hardrtc.minutes{}
    hsec := hardrtc.seconds{}

' Now write it to the Propeller's SoftRTC
#ifdef PCF8563
    ser.str(string("Setting SoftRTC from PCF8563..."))
#elseifdef DS3231
    ser.str(string("Setting SoftRTC from DS3231..."))
#elseifdef RV3028
    ser.str(string("Setting SoftRTC from RV3028..."))
#endif
    softrtc.suspend{}
    softrtc.setyear(hyr)                        ' 00..31 (Valid from 2000 to 2031)
    softrtc.setmonth(hmo)                       ' 01..12
    softrtc.setdate(hdy)                        ' 01..31
    softrtc.setweekday(hwkd)                    ' 01..07

    softrtc.sethours(hhr)                       ' 01..12
    softrtc.setminutes(hmin)                    ' 00..59
    softrtc.setseconds(hsec)                    ' 00..59
    softrtc.resume{}
    ser.str(string("done."))

    repeat
        softrtc.parsedatestamp(@_datestamp)
        softrtc.parsetimestamp(@_timestamp)

        ser.position(0, 7)
        ser.strln(string("SoftRTC date & time:"))
        ser.str(@_datestamp)
        ser.char(" ")
        ser.str(@weekday[(softrtc.weekday{} - 1) * 4])
        ser.str(string("  "))
        ser.str(@_timestamp)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    softrtc.start(@_timestring)
    ser.strln(string("SoftRTC started"))

    if hardrtc.startx(SCL_PIN, SDA_PIN, I2C_HZ)
#ifdef PCF8563
        ser.strln(string("PCF8563 driver started"))
    else
        ser.strln(string("PCF8563 driver failed to start - halting"))
#elseifdef DS3231
        ser.strln(string("DS3231 driver started"))
    else
        ser.strln(string("DS3231 driver failed to start - halting"))
#elseifdef RV3028
        ser.strln(string("RV3028 driver started"))
    else
        ser.strln(string("RV3028 driver failed to start - halting"))
#endif
        repeat

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
