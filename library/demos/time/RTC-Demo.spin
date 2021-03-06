{
    --------------------------------------------
    Filename: RTC-Demo.spin
    Author: Jesse Burt
    Description: RTC date/time set/display demo
    Copyright (c) 2020
    Started Nov 18, 2020
    Updated Nov 18, 2020
    See end of file for terms of use.
    --------------------------------------------
}

' Uncomment one of the following:
#define PCF8563
'#define DS3231

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000
' --

' Named constants that can be used in place of numerical month, or weekday
    #1, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC
    #1, SUN, MON, TUE, WED, THU, FRI, SAT

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
#ifdef PCF8563
    rtc     : "time.rtc.pcf8563.i2c"
#elseifdef DS3231
    rtc     : "time.rtc.ds3231.i2c"
#else
#error "No RTC defined!"
#endif

PUB Main{} | wkday, month, day, yr

    setup{}

' Uncomment below to set date/time
'                hh, mm, ss, MMM, DD, WKDAY, YY
'    setdatetime(08, 51, 00, NOV, 18, WED, 20)

    repeat
        rtc.pollrtc{}
        wkday := @wkday_name[(rtc.weekday(-2) - 1) * 4] ' Pull strings from
        month := @month_name[(rtc.month(-2) - 1) * 4]   ' DAT table below
        day := int.deczeroed(rtc.day(-2), 2)
        yr := rtc.year(-2)

        ser.position(0, 3)
        ser.str(wkday)
        ser.printf(string(" %s %s 20%d "), day, month, yr, 0, 0, 0)

        ser.str(int.deczeroed(rtc.hours(-2), 2))    ' Discrete statements
        ser.char(":")                               ' due to a bug in
        ser.str(int.deczeroed(rtc.minutes(-2), 2))  ' string.integer
        ser.char(":")
        ser.str(int.deczeroed(rtc.seconds(-2), 2))

PUB SetDateTime(h, m, s, mmm, dd, wkday, yy)

    rtc.hours(h)                                ' 00..23
    rtc.minutes(m)                              ' 00..59
    rtc.seconds(s)                              ' 00..59

    rtc.month(mmm)                              ' 01..12
    rtc.day(dd)                                 ' 01..31
    rtc.weekday(wkday)                          ' 01..07
    rtc.year(yy)                                ' 00..99

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if rtc.startx(I2C_SCL, I2C_SDA, I2C_HZ)
#ifdef PCF8563
        ser.strln(string("PCF8563 driver started"))
    else
        ser.strln(string("PCF8563 driver failed to start - halting"))
#elseifdef DS3231
        ser.strln(string("DS3231 driver started"))
    else
        ser.strln(string("DS3231 driver failed to start - halting"))
#endif
        rtc.stop{}
        time.msleep(50)
        ser.stop{}

DAT
' Tables for mapping numbers to weekday and month names
    wkday_name
            byte    "Sun", 0                    ' 1
            byte    "Mon", 0                    ' 2
            byte    "Tue", 0                    ' 3
            byte    "Wed", 0                    ' 4
            byte    "Thu", 0                    ' 5
            byte    "Fri", 0                    ' 6
            byte    "Sat", 0                    ' 7

    month_name
            byte    "Jan", 0                    ' 1
            byte    "Feb", 0
            byte    "Mar", 0
            byte    "Apr", 0
            byte    "May", 0
            byte    "Jun", 0
            byte    "Jul", 0
            byte    "Aug", 0
            byte    "Sep", 0
            byte    "Oct", 0
            byte    "Nov", 0
            byte    "Dec", 0                    ' 12

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
