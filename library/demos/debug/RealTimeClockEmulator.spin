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
    rtc     : "time.rtc.emulated"
    ser     : "com.serial.terminal.ansi"
    time    : "time"

VAR

    long  _timestring
    byte  _datestamp[11], _timestamp[11]

PUB Main{}

    setup{}

    rtc.suspend{}                                 ' Suspend rtc while being set

    rtc.setyear(20)                               ' 00 - 31 ... Valid from 2000 to 2031
    rtc.setmonth(12)                              ' 01 - 12 ... Month
    rtc.setdate(31)                               ' 01 - 31 ... Date

    rtc.sethour(23)                               ' 01 - 12 ... Hour
    rtc.setmin(59)                                ' 00 - 59 ... Minute
    rtc.setsec(55)                                ' 00 - 59 ... Second

    rtc.restart{}                                 ' Start rtc after being set

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

