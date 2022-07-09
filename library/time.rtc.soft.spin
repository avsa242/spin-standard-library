{
    --------------------------------------------
    Filename: time.rtc.soft.spin
    Author: Jesse Burt
    Description: Soft RTC
    Started 2009
    Updated Mar 23, 2021
    See end of file for terms of use.
    --------------------------------------------
    NOTE: Based on PropellerRTC_Emulator.spin,
        originally written by Beau Schwabe. The
        original header is preserved below
}

{{
************************************************
* Propeller RTC Emulator                  v1.0 *
* Author: Beau Schwabe                         *
* Copyright (c) 2009 Parallax                  *
* See end of file for terms of use.            *
************************************************
}}
CON

' Constants representing months, and day of week
    #1, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC
    #1, SUN, MON, TUE, WED, THU, FRI, SAT

VAR

    long _time_stack[100]
    long _timer, _temp, _clockflag, _timeaddress
    byte _monthdays, _ss, _mm, _hh, _dd, _mo, _yy, _ly, _wkday
    byte _datetimestamp[11]
    byte _cog

PUB Start(timeaddress): okay

    _timeaddress := timeaddress
    if okay := _cog := cognew(cog_RTCLoop(timeaddress), @_time_stack)
        return (_cog++)
    return false

PUB Stop{}

    if _cog
        cogstop(_cog-1)

PUB Date{}: d
' Get current date/day of month
    return _dd

PUB Hours{}: h
' Get current hour
    return _hh

PUB Minutes{}: m
' Get current minute
    return _mm

PUB Month{}: m
' Get current month
    return _mo

PUB PollRTC{}
' Dummy method

PUB Seconds{}: s
' Get current second
    return _ss

PUB SetDate(d)
' Set current date/day of month
'   Valid values: 1..31
'   Any other value is ignored
    case d
        01..31:
            _dd := d
        other:
            return

PUB SetHours(h)
' Set current hour
'   Valid values: 0..23
'   Any other value is ignored
    case h
        00..23:
            _hh := h
        other:
            return

PUB SetMinutes(m)
' Set current minute
'   Valid values: 0..59
'   Any other value is ignored
    case m
        00..59:
            _mm := m
        other:
            return

PUB SetMonth(m)
' Set current month
'   Valid values: 1..12
'   Any other value is ignored
    case m
        01..12:
            _mo := m
        other:
            return

PUB SetSeconds(s)
' Set current second
'   Valid values: 0..59
'   Any other value is ignored
    case s
        00..59:
            _ss := s
        other:
            return

PUB SetWeekDay(w)
' Set day of week
'   Valid values: 1..7
'   Any other value is ignored
    case w
        1..7:
            _wkday := w
        other:
            return

PUB SetYear(y)
' Set 2-digit year
'   Valid values: 0..99
'   Any other value is ignored
    case y
        00..99:
            _yy := y
        other:
            return

PUB Weekday{}
' Get current week day
    return _wkday

PUB Year{}
' Get current year
    return _yy

PUB UnParseTime(timeaddress)

    result := _ly << 31 | _yy << 26 | _mo << 22 | _dd << 17 | _hh << 12 | _mm << 6 | _ss
    longmove(timeaddress, @result, 1)

PUB ParseTime(timeaddress)

    longmove(@_temp, timeaddress, 1)                ' Parse Data
    _ss := _temp & %111111
    _temp := _temp >> 6
    _mm := _temp & %111111
    _temp := _temp >> 6
    _hh := _temp & %11111
    _temp := _temp >> 5
    _dd := _temp & %11111
    _temp := _temp >> 5
    _mo := _temp & %1111
    _temp := _temp >> 4
    _yy := _temp & %11111
    _temp := _temp >> 5
    _ly := _temp & %1

PUB ParseDateStamp(dataaddress)

    _datetimestamp[0] := "2"                        ' Year
    _datetimestamp[1] := "0"                        ' Year
    _datetimestamp[2] := "0" + _yy/10               ' Year
    _datetimestamp[3] := "0" + _yy//10              ' Year
    _datetimestamp[4] := "/"
    _datetimestamp[5] := "0" + _mo/10               ' Month
    _datetimestamp[6] := "0" + _mo//10              ' Month
    _datetimestamp[7] := "/"
    _datetimestamp[8] := "0" + _dd/10               ' Day
    _datetimestamp[9] := "0" + _dd//10              ' Day
    _datetimestamp[10] := 0                         ' String terminator
    bytemove(dataaddress, @_datetimestamp, 11)

PUB ParseTimeStamp(dataaddress)

    _datetimestamp[0] := "0" + _hh/10               ' Hour
    _datetimestamp[1] := "0" + _hh//10              ' Hour
    _datetimestamp[2] := ":"
    _datetimestamp[3] := "0" + _mm/10               ' Minute
    _datetimestamp[4] := "0" + _mm//10              ' Minute
    _datetimestamp[5] := ":"
    _datetimestamp[6] := "0" + _ss/10               ' Second
    _datetimestamp[7] := "0" + _ss//10              ' Second
    _datetimestamp[8] := 0                          ' String terminator
    bytemove(dataaddress, @_datetimestamp, 11)

PRI cog_RTCLoop(timeaddress)
' timeaddress variable allocation:
' Leap   Year    Month   Date     Hours   Minutes   Seconds
' (0-1) (00-31)  (1-12) (1-31)   (1-12)  (00-59)   (00-59)
'   0____00000____0000___00000____00000___000000____000000
    _timer := cnt
    repeat
        waitcnt(_timer += clkfreq)                  ' 1 Second Synchronized Delay

        if _clockflag <> 0                          ' Check for request to suspend clock?
            _clockflag := 2                         ' respond by acknowledging request
            repeat while _clockflag <> 0            ' Wait for the OK to resume clock
            _timer := cnt

        parsetime(timeaddress)

        if ((_yy >> 2) << 2) == _yy                 ' Detect Leap Year
            _ly := 1
        else
            _ly := 0

        case _mo
            FEB:
                _monthdays := 28 + _ly              ' Decode number of days in each month
            APR, JUN, SEP, NOV:
                _monthdays := 30
            JAN, MAR, MAY, JUL, AUG, OCT, DEC:
                _monthdays := 31

        _ss += 1                                    ' Increment Time Calendar

        if _ss > 59                                 ' Seconds
            _ss := 0
            _mm += 1

        if _mm > 59                                 ' Minutes
            _mm := 0
            _hh += 1

        if _hh > 23                                 ' Hours
            _hh := 0
            _dd += 1
            _wkday += 1

            if _wkday > SAT
                _wkday := SUN

        if _dd == _monthdays + 1                    ' Days
            _dd := 1
            _mo += 1

        if _mo > DEC                                 ' Months
            _mo := JAN
            _yy += 1

        if _yy > 32                                 ' Years
            _yy := 32

        unparsetime(timeaddress)                    ' Pack current time variable values into 'long'

PUB Resume{}

    unparsetime(_timeaddress)                       ' Pack current time variable values into 'long'
    _clockflag := 0                                 ' Resume Clock

PUB Suspend{}

    _clockflag := 1                                 ' Suspend Clock
    repeat while _clockflag == 1                    ' Clock responds with a 2 when suspend received
    parsetime(_timeaddress)                         ' Unpack current time variable values from 'long'

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

