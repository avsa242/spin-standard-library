{
    --------------------------------------------
    Filename: time.rtc.soft.spin
    Author: Jesse Burt
    Description: Soft/emulated RTC
    Started 2009
    Updated Oct 14, 2022
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is based on PropellerRTC_Emulator.spin,
        originally written by Beau Schwabe.
}

CON

' Constants representing months, and day of week
    #1, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC
    #1, SUN, MON, TUE, WED, THU, FRI, SAT

VAR

    long _time_stack[100]
    long _timer, _temp, _clkflag, _ptr_time
    byte _monthdays, _ss, _mm, _hh, _dd, _mo, _yy, _ly, _wkday
    byte _cog

PUB start(ptr_time): status
' Start the soft RTC driver
'   ptr_time: pointer to buffer to copy time/date data to (1 long)
    _ptr_time := ptr_time
    if (status := _cog := (cognew(cog_rtc_loop(ptr_time), @_time_stack) + 1))
        return
    return false

PUB stop{}
' Stop the driver
    if _cog
        cogstop(_cog-1)

PUB date{}: d
' Get current date/day of month
    return _dd

PUB hours{}: h
' Get current hour
    return _hh

PUB minutes{}: m
' Get current minute
    return _mm

PUB month{}: m
' Get current month
    return _mo

PUB poll_rtc{}
' Dummy method

PUB seconds{}: s
' Get current second
    return _ss

PUB set_date(d)
' Set current date/day of month
'   Valid values: 1..31 (clamped to range)
    _dd := (1 #> d <# 31)

PUB set_hours(h)
' Set current hour
'   Valid values: 0..23 (clamped to range)
    _hh := (0 #> h <# 23)

PUB set_minutes(m)
' Set current minute
'   Valid values: 0..59 (clamped to range)
    _mm := (0 #> m <# 59)

PUB set_month(m)
' Set current month
'   Valid values: 1..12 (clamped to range)
    _mo := (1 #> m <# 12)

PUB set_seconds(s)
' Set current second
'   Valid values: 0..59 (clamped to range)
    _ss := (0 #> s <# 59)

PUB set_weekday(w)
' Set day of week
'   Valid values: 1..7 (clamped to range)
    _wkday := (1 #>w <# 7)

PUB set_year(y)
' Set 2-digit year
'   Valid values: 0..99 (clamped to range)
    _yy := (0 #> y <# 99)

PUB weekday{}
' Get current week day
    return _wkday

PUB year{}
' Get current year
    return _yy

PUB unparse_time(ptr_time): t
' Copy a binary representation of the current date/time to ptr_time (1 long)
    t := (_ly << 31) | (_yy << 26) | (_mo << 22) | (_dd << 17) | (_hh << 12) | (_mm << 6) | _ss
    longmove(ptr_time, @t, 1)

PUB parse_time(ptr_time)
' Copy a binary representation of the current date/time to the driver
    longmove(@_temp, ptr_time, 1)               ' Parse Data
    _ss := (_temp & %111111)
    _temp := (_temp >> 6)
    _mm := (_temp & %111111)
    _temp := (_temp >> 6)
    _hh := (_temp & %11111)
    _temp := (_temp >> 5)
    _dd := (_temp & %11111)
    _temp := (_temp >> 5)
    _mo := (_temp & %1111)
    _temp := (_temp >> 4)
    _yy := (_temp & %11111)
    _temp := (_temp >> 5)
    _ly := (_temp & %1)

PUB parse_date_stamp(ptr_data) | date_tmp[3]
' Copy a string representation of the current date to ptr_data
'   NOTE: ptr_data must point to a buffer of at least 11 bytes
    date_tmp.byte[0] := "2"                     ' Year
    date_tmp.byte[1] := "0"                     ' Year
    date_tmp.byte[2] := "0" + (_yy / 10)        ' Year
    date_tmp.byte[3] := "0" + (_yy // 10)       ' Year
    date_tmp.byte[4] := "/"
    date_tmp.byte[5] := "0" + (_mo / 10)        ' Month
    date_tmp.byte[6] := "0" + (_mo // 10)       ' Month
    date_tmp.byte[7] := "/"
    date_tmp.byte[8] := "0" + (_dd / 10)        ' Day
    date_tmp.byte[9] := "0" + (_dd // 10)       ' Day
    date_tmp.byte[10] := 0                      ' String terminator
    bytemove(ptr_data, @date_tmp, 11)

PUB parse_time_stamp(ptr_data) | time_tmp[3]
' Copy a string representation of the current date to ptr_data
'   NOTE: ptr_data must point to a buffer of at least 9 bytes
    time_tmp.byte[0] := "0" + (_hh / 10)        ' Hour
    time_tmp.byte[1] := "0" + (_hh // 10)       ' Hour
    time_tmp.byte[2] := ":"
    time_tmp.byte[3] := "0" + (_mm / 10)        ' Minute
    time_tmp.byte[4] := "0" + (_mm // 10)       ' Minute
    time_tmp.byte[5] := ":"
    time_tmp.byte[6] := "0" + (_ss / 10)        ' Second
    time_tmp.byte[7] := "0" + (_ss // 10)       ' Second
    time_tmp.byte[8] := 0                       ' String terminator
    bytemove(ptr_data, @time_tmp, 9)

PRI cog_rtc_loop(ptr_time)
' ptr_time variable allocation:
' Bits 31..0:
'   Leap   Year    Month   Date     Hours   Minutes   Seconds
'   (0-1) (00-31)  (1-12)  (1-31)   (1-12)  (00-59)   (00-59)
'     0____00000____0000___00000____00000___000000____000000
    _timer := cnt
    repeat
        waitcnt(_timer += clkfreq)              ' 1 Second Synchronized Delay

        if (_clkflag <> 0)                      ' Check for request to suspend clock?
            _clkflag := 2                       ' respond by acknowledging request
            repeat while (_clkflag <> 0)        ' Wait for the OK to resume clock
            _timer := cnt

        parse_time(ptr_time)

        if (((_yy >> 2) << 2) == _yy)           ' Detect Leap Year
            _ly := 1
        else
            _ly := 0

        case _mo
            FEB:
                _monthdays := (28 + _ly)        ' Decode number of days in each month
            APR, JUN, SEP, NOV:
                _monthdays := 30
            JAN, MAR, MAY, JUL, AUG, OCT, DEC:
                _monthdays := 31

        _ss += 1                                ' Increment Time Calendar

        if (_ss > 59)                           ' Seconds
            _ss := 0
            _mm += 1

        if (_mm > 59)                           ' Minutes
            _mm := 0
            _hh += 1

        if (_hh > 23)                           ' Hours
            _hh := 0
            _dd += 1
            _wkday += 1

            if (_wkday > SAT)
                _wkday := SUN

        if (_dd == _monthdays + 1)              ' Days
            _dd := 1
            _mo += 1

        if (_mo > DEC)                          ' Months
            _mo := JAN
            _yy += 1

        if (_yy > 32)                           ' Years
            _yy := 32

        unparse_time(ptr_time)                  ' Pack current time variable values into 'long'

PUB resume{}
' Resume running the RTC
    unparse_time(_ptr_time)                     ' Pack current time variable values into 'long'
    _clkflag := 0                               ' Resume Clock

PUB suspend{}
' Suspend the RTC
    _clkflag := 1                               ' Suspend Clock
    repeat while (_clkflag == 1)                ' Clock responds with a 2 when suspend received
    parse_time(_ptr_time)                       ' Unpack current time variable values from 'long'

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

