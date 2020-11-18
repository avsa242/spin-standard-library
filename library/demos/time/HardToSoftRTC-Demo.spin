{
    --------------------------------------------
    Filename: HardToSoftRTC-Demo.spin
    Author: Jesse Burt
    Description: Demo that reads a hardware RTC once,
        sets the software RTC by it, and continuously
        displays the date and time from the software RTC
    Started Sep 7, 2020
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

' -- User-definable constants
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    softrtc : "time.rtc.soft"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
#ifdef PCF8563
    hardrtc : "time.rtc.pcf8563.i2c"
#elseifdef DS3231
    hardrtc : "time.rtc.ds3231.i2c"
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
    hyr := hardrtc.year(-2)
    hmo := hardrtc.month(-2)
    hdy := hardrtc.day(-2)
    hwkd := hardrtc.weekday(-2)
    hhr := hardrtc.hours(-2)
    hmin := hardrtc.minutes(-2)
    hsec := hardrtc.seconds(-2)

' Now write it to the Propeller's SoftRTC
#ifdef PCF8563
    ser.str(string("Setting SoftRTC from PCF8563..."))
#elseifdef DS3231
    ser.str(string("Setting SoftRTC from DS3231..."))
#endif
    softrtc.suspend{}
    softrtc.year(hyr)                            ' 00..31 (Valid from 2000 to 2031)
    softrtc.months(hmo)                          ' 01..12
    softrtc.days(hdy)                            ' 01..31
    softrtc.weekday(hwkd)                        ' 01..07

    softrtc.hours(hhr)                           ' 01..12
    softrtc.minutes(hmin)                        ' 00..59
    softrtc.seconds(hsec)                        ' 00..59
    softrtc.resume{}
    ser.str(string("done."))

    repeat
        softrtc.parsedatestamp(@_datestamp)
        softrtc.parsetimestamp(@_timestamp)

        ser.position(0, 7)
        ser.str(string("SoftRTC date & time:", ser#CR, ser#LF))
        ser.str(@_datestamp)
        ser.char(" ")
        ser.str(@weekday[(softrtc.weekday(-2) - 1) * 4])
        ser.str(string("  "))
        ser.str(@_timestamp)

PUB Setup{}

    repeat until ser.startrxtx(SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#CR, ser#LF))

    if softrtc.start(@_timestring)
        ser.str(string("SoftRTC started", ser#CR, ser#LF))
    else
        ser.str(string("SoftRTC failed to start - halting", ser#CR, ser#LF))
        softrtc.stop{}
        time.msleep(50)
        ser.stop{}

    if hardrtc.startx(I2C_SCL, I2C_SDA, I2C_HZ)
#ifdef PCF8563
        ser.strln(string("PCF8563 driver started"))
    else
        ser.strln(string("PCF8563 driver failed to start - halting"))
#elseifdef DS3231
        ser.strln(string("DS3231 driver started"))
    else
        ser.strln(string("DS3231 driver failed to start - halting"))
#endif
        hardrtc.stop{}
        softrtc.stop{}
        time.msleep(50)
        ser.stop{}

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
