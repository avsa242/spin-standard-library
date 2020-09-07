{
    --------------------------------------------
    Filename: time.rtc.soft.spin
    Author: Jesse Burt
    Description: Soft RTC
    Started 2009
    Updated Sep 7, 2020
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
VAR

    long _time_stack[100]
    long _timer, _temp, _clockflag, _timeaddress
    byte _monthdays, _ss, _mm, _hh, _dd, _mo, _yy, _ly
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

PUB Days(dd)

    case dd
        01..31:
            suspend{}
            _dd := dd
            resume{}
        other:
            return _dd

PUB Hours(hh)

    case hh
        00..23:
            suspend{}
            _hh := hh
            resume{}
        other:
            return _hh

PUB Minutes(mm)

    case mm
        00..59:
            suspend{}
            _mm := mm
            resume{}
        other:
            return _mm

PUB Months(mo)

    case mo
        01..12:
            suspend{}
            _mo := mo
            resume{}
        other:
            return _mo

PUB Seconds(ss)

    case ss
        00..59:
            suspend{}
            _ss := ss
            resume{}
        other:
            return _ss

PUB Year(yy)

    case yy
        00..99:
            suspend{}
            _yy := yy
            resume{}
        other:
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
    _datetimestamp[2] := $30 + _yy/10               ' Year
    _datetimestamp[3] := $30 + _yy-(_yy/10)*10      ' Year
    _datetimestamp[4] := "/"
    _datetimestamp[5] := $30 + _mo/10               ' Month
    _datetimestamp[6] := $30 + _mo-(_mo/10)*10      ' Month
    _datetimestamp[7] := "/"
    _datetimestamp[8] := $30 + _dd/10               ' Day
    _datetimestamp[9] := $30 + _dd-(_dd/10)*10      ' Day
    _datetimestamp[10] := 0                         ' String terminator
    bytemove(dataaddress, @_datetimestamp, 11)

PUB ParseTimeStamp(dataaddress)

    _datetimestamp[0] := $30 + _hh/10               ' Hour
    _datetimestamp[1] := $30 + _hh-(_hh/10)*10      ' Hour
    _datetimestamp[2] := ":"
    _datetimestamp[3] := $30 + _mm/10               ' Minute
    _datetimestamp[4] := $30 + _mm-(_mm/10)*10      ' Minute
    _datetimestamp[5] := ":"
    _datetimestamp[6] := $30 + _ss/10               ' Second
    _datetimestamp[7] := $30 + _ss-(_ss/10)*10      ' Second
    _datetimestamp[8] := 0                         ' String terminator
    bytemove(dataaddress, @_datetimestamp, 11)

PRI cog_RTCLoop(timeaddress)
' timeaddress variable allocation:
' Leap   Year    Month   Date     Hours   Minutes   Seconds
' (0-1) (00-31)  (1-12) (1-31)   (1-12)  (00-59)   (00-59)
'   0____00000____0000___00000____0000____000000____000000
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

        _monthdays := 28                            ' Decode number of days in each month
        if _mo <> 2
            _monthdays += 2
            if _mo & %0001 <> (_mo & %1000) / %1000
                _monthdays += 1
        else
            _monthdays += _ly

        _ss += 1                                    ' Increment Time Calendar

        if _ss == 60                                ' Seconds
            _ss := 0
            _mm += 1

        if _mm == 60                                ' Minutes
            _mm := 0
            _hh += 1

        if _hh == 24                                ' Hours
            _hh := 0
            _dd += 1

        if _dd == _monthdays + 1                    ' Days
            _dd := 1
            _mo += 1

        if _mo == 13                                ' Months
            _mo := 1
            _yy += 1

        if _yy == 33                                ' Years
            _yy := 32

        unparsetime(timeaddress)                    ' Pack current time variable values into 'long'

PRI Resume{}

    unparsetime(_timeaddress)                       ' Pack current time variable values into 'long'
    _clockflag := 0                                 ' Resume Clock

PRI Suspend{}

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

