{{
************************************************
* Propeller RTC Emulator                  v1.0 *
* Author: Beau Schwabe                         *
* Copyright (c) 2009 Parallax                  *
* See end of file for terms of use.            *
************************************************
}}
VAR

    long _timer, _temp, _clockflag, _timeaddress
    byte _monthdays, _ss, _mm, _hh, _ap, _dd, _mo, _yy, _ly
    byte _apswitch, _datetimestamp[11]
    long stack[100]

PUB Start(timeaddress)

    _timeaddress := timeaddress
    cognew(run(timeaddress), @stack)

PUB SetSec(ss)

    _ss := ss

PUB SetMin(mm)

    _mm := mm

PUB SetHour(hh)

    _hh := hh

PUB SetAMPM(ap)

    _ap := ap

PUB SetDate(dd)

    _dd := dd

PUB SetMonth(mo)

    _mo := mo

PUB SetYear(yy)

    _yy := yy

PUB Suspend

    _clockflag := 1                                 ' Suspend Clock
    repeat while _clockflag == 1                    ' Clock responds with a 2 when suspend received
    parsetime(_timeaddress)                         ' Unpack current time variable values from 'long'

PUB Restart

    unparsetime(_timeaddress)                       ' Pack current time variable values into 'long'
    _clockflag := 0                                 ' Restart Clock

PUB Run(timeaddress)
' timeaddress variable allocation:
' Leap   Year    Month   Date   AM/PM  Hours   Minutes   Seconds
' (0-1) (00-31)  (1-12) (1-31)  (0-1) (1-12)  (00-59)   (00-59)
'   0____00000____0000___00000____0____0000____000000____000000
    _apswitch := 1
    _timer := cnt
    repeat
        waitcnt(_timer += clkfreq)                  ' 1 Second Synchronized Delay

        if _clockflag <> 0                          ' Check for request to suspend clock?
            _clockflag := 2                         ' respond by acknowledging request
            repeat while _clockflag <> 0            ' Wait for the OK to resume clock
            _timer := cnt

        ParseTime(timeaddress)

        if ((_yy >> 2) << 2) == _yy                 ' Detect Leap Year
            _ly := 1
        else
            _ly := 0

        _monthdays := 28                            ' Decode number of days in each month
        If _mo <> 2
            _monthdays += 2
            if _mo & %0001 <> (_mo & %1000) / %1000
                _monthdays += 1
        else
            _monthdays += _ly

        _ss += 1                                    ' Increment Time Calendar

        if _ss == 60                                ' Seconds LOGIC
            _ss := 0
            _mm += 1

        if _mm == 60                                ' Minutes LOGIC
            _mm := 0
            _hh += 1

        if _hh == 13                                ' Hours LOGIC
            _hh := 1

        if _hh == 11                                ' AM/PM LOGIC
            _apswitch := 0
        if _hh < 11
            _apswitch := 1
        if _hh == 12
            if _apswitch == 0
                _apswitch := 1
                _ap := 1 - _ap
                if _ap == 0
                    _dd += 1


        if _dd == _monthdays + 1                    ' Days LOGIC
            _dd := 1
            _mo += 1

        if _mo == 13                                ' Months LOGIC
            _mo := 1
            _yy += 1

        if _yy == 33                                ' Years LOGIC
            _yy := 32

        unparsetime(timeaddress)                    ' Pack current time variable values into 'long'

PUB UnParseTime(timeaddress)

    result := _ly << 31 | _yy << 26 | _mo << 22 | _dd << 17 | _ap << 16 | _hh << 12 | _mm << 6 | _ss
    longmove(timeaddress, @result, 1)

PUB ParseTime(timeaddress)

    longmove(@_temp, timeaddress, 1)                ' Parse Data
    _ss := _temp & %111111
    _temp := _temp >> 6
    _mm := _temp & %111111
    _temp := _temp >> 6
    _hh := _temp & %1111
    _temp := _temp >> 4
    _ap := _temp & %1
    _temp := _temp >> 1
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
    _datetimestamp[2] := $30 + _yy/10               ' Year
    _datetimestamp[3] := $30 + _yy-(_yy/10)*10      ' Year
    _datetimestamp[4] := "/"
    _datetimestamp[5] := $30 + _mo/10               ' Month
    _datetimestamp[6] := $30 + _mo-(_mo/10)*10      ' Month
    _datetimestamp[7] := "/"
    _datetimestamp[8] := $30 + _dd/10               ' Day
    _datetimestamp[9] := $30 + _dd-(_dd/10)*10      ' Day
    _datetimestamp[10] := 0                         ' String terminator
    bytemove(DataAddress,@_datetimestamp,11)

PUB ParseTimeStamp(DataAddress)

    _datetimestamp[0] := $30 + _hh/10               ' Hour
    _datetimestamp[1] := $30 + _hh-(_hh/10)*10      ' Hour
    _datetimestamp[2] := ":"
    _datetimestamp[3] := $30 + _mm/10               ' Minute
    _datetimestamp[4] := $30 + _mm-(_mm/10)*10      ' Minute
    _datetimestamp[5] := ":"
    _datetimestamp[6] := $30 + _ss/10               ' Second
    _datetimestamp[7] := $30 + _ss-(_ss/10)*10      ' Second
    if _ap < 1
        _datetimestamp[8] := "a"                    ' Set am
    else
        _datetimestamp[8] := "p"                    ' Set pm
    _datetimestamp[9] := "m"
    _datetimestamp[10] := 0                         ' String terminator
    bytemove(dataaddress, @_datetimestamp, 11)

