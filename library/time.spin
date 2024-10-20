{
----------------------------------------------------------------------------------------------------
    Filename:       time.spin
    Description:    Time-related functions
    Author:         Jesse Burt
    Started:        2006
    Updated:        Aug 31, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------

    NOTE: A portion of this object is based on Clock.spin,
    originally by Jeff Martin
}

#include "time-common.spin"

CON

    { limits }
    WMIN            = 381                       ' waitcnt() overhead minimum

    { misc time unit symbols }
    SECOND_US       = 1_000_000
    SECOND_MS       = 1_000
    SECOND          = 1
    SECS_PER_MINUTE = (60 * SECOND)
    SECS_PER_HOUR   = (60 * SECS_PER_MINUTE)
    SECS_PER_DAY    = (24 * SECS_PER_HOUR)


VAR

    long _sync


PUB days_in_month(m, y=-1): d
' Get number of days in a month
'   mon:    month to count days in
'   yr:     (optional) year, to account for possible leap year
'   Returns: number of days
'   NOTE: If the year isn't specified, the value returned for Feburary will be 28.
    case m
        JAN, MAR, MAY, JUL, AUG, OCT, DEC:
            return 31
        APR, JUN, SEP, NOV:
            return 30
        FEB:
            if ( is_leap_year(y) )
                return 29
            else
                return 28


PUB days_in_year(y): d
' Get the number of days in the specified year
    if ( is_leap_year(y) )
        return 366
    else
        return 365


pub mktime(^tm_s tm): utime | y, m
' Get seconds since UNIX epoch (Jan 1, 1970, 00:00:00), given date and time
'   tm:         tm_s structure
'   Returns:    seconds
'   NOTE: The latest date this function will produce correct data for is:
'       January 19, 2038 at 03:14:07 (2_147_483_647), due to the maximum value
'       representable by SPIN's largest data size, a signed 32-bit integer (long)
    utime := 0
    if ( tm.tm_year > 1970 )
        repeat y from 1970 to (tm.tm_year-1)    ' tally up days in each year since 1970
            utime += 365
            if ( is_leap_year(y) )
                utime += 1

    if ( tm.tm_mon > JANUARY )
        repeat m from 1 to (tm.tm_mon-1)        ' tally up leftover days in the given month
            utime += days_in_month(m, tm.tm_year)

    utime += (tm.tm_mday - 1)

    utime :=    (utime * SECS_PER_DAY) + ...    ' add total seconds in days calculated above
                ((tm.tm_hour * SECS_PER_HOUR) + (tm.tm_min * SECS_PER_MINUTE) + tm.tm_sec)


PUB dtime2utime(y, m, d, h, mn, s): utime | yt, mt
' Get seconds since UNIX epoch (Jan 1, 1970, 00:00:00), given date and time
'   year, month, day, hour, minute, second: discrete time units of desired time
'   Returns: seconds
'   NOTE: The latest date this function will produce correct data for is:
'       January 19, 2038 at 03:14:07 (2_147_483_647), due to the maximum value
'       representable by SPIN's largest data size, a signed 32-bit integer (long)
    utime := 0
    if ( y > 1970 )
        repeat yt from 1970 to (y-1)            ' tally up days in each year since 1970
            utime += 365
            if ( is_leap_year(yt) )
                utime += 1

    if ( m > JANUARY )
        repeat mt from 1 to (m-1)               ' tally up leftover days in the given month
            utime += days_in_month(mt, y)

    utime += (d - 1)

    utime :=    (utime * SECS_PER_DAY) + ...    ' add total seconds in days calculated above
                ((h * 3600) + (mn * 60) + s)


PUB is_leap_year(y): b
' Indicate if the given year is a leap-year
'   Returns: TRUE (-1) or FALSE (0)
    ifnot ( y // 400 )                          ' evenly divisible by 400? yes
        return true
    ifnot ( y // 100 )                          ' evenly divisible by 100? no, unless it's also
        return false                            '   evenly divisible by 400, caught above already
    ifnot ( y // 4 )                            ' evenly divisible by 4? yes
        return true


PUB msleep(msecs)
' Sleep for msecs milliseconds.
'   NOTE: When operating with a system clock of 20kHz (ideal RCSLOW)
'       the minimum practical value is 216ms
    waitcnt(((clkfreq / 1_000 * msecs - 3932) #> WMIN) + cnt)


PUB setsync = set_sync
PUB set_sync()
' Set starting point for synchronized time delays
' Wait for the start of the next window with wait_for_sync*() methods below
    _sync := cnt


PUB sleep(secs)
' Sleep for secs seconds.
    waitcnt(((clkfreq * secs - 3016) #> WMIN) + cnt)


PUB usleep(usecs)
' Sleep for microseconds
'   NOTE: When operating with a system clock of 80MHz,
'       the minimum practical value is 54us
    waitcnt(((clkfreq / 1_000_000 * usecs - 3928) #> WMIN) + cnt)


PUB gmtime = utime2dtime
PUB utime2dtime(utime, p_dest) | y, mo, d, h, mn, s
' Convert seconds since UNIX epoch to discrete units of time
'   utime:      seconds since Jan 1, 1970 00:00:00
'   p_dest:     pointer to destination array of longs holding date/time datum
'       Structure:
'           long[p_dest][0] := year
'           long[p_dest][1] := month
'           long[p_dest][2] := day
'           long[p_dest][3] := hour
'           long[p_dest][4] := minute
'           long[p_dest][5] := second
    y := get_year(utime)
    utime -= (days_since_unix_epoch(y) * SECS_PER_DAY)  ' days since 1970 * seconds per day

    mo := get_month(y, utime)
    utime -= (days_since_year_start(y, mo) * SECS_PER_DAY)

    d := get_day(utime)

    utime -= ((d - 1) * SECS_PER_DAY)
    h := (utime / SECS_PER_HOUR)
    utime := (utime // SECS_PER_HOUR)
    mn := (utime / SECS_PER_MINUTE)
    s := (utime // SECS_PER_MINUTE)
    longmove(p_dest, @y, 6)                     ' copy date/time to destination


PUB waitforsync = wait_for_sync
PUB wait_for_sync(secs)
' Wait until start of the next seconds-long time period
'   NOTE: set_sync() must be called before calling wait_for_sync() the first time
    waitcnt(_sync += ((clkfreq * secs) #> WMIN))


PUB waitsyncmsec = wait_sync_msec
PUB wait_sync_msec(msec)
' Wait until start of the next milliseconds-long time period
'   NOTE: set_sync() must be called before calling wait_for_sync() the first time
    waitcnt(_sync += (clkfreq / 1_000 * msec) #> WMIN)


PUB waitsyncusec = wait_sync_usec
PUB wait_sync_usec(usec)
' Wait until start of the next microseconds-long time period
'   NOTE: set_sync() must be called before calling wait_for_sync() the first time
    waitcnt(_sync += (clkfreq / 1_000_000 * usec) #> WMIN)


PRI days_since_unix_epoch(y): d | yt
' Calculate the total number of days from the UNIX epoch (January 1, 1970)
'   to the start of the given year
    d := 0
    if ( y > 1970 )
        repeat yt from 1970 to (y - 1)
            d += 365
            if ( is_leap_year(yt) )
                d++


PRI get_year(utime): y
' Get the year from a UNIX timestamp
    y := 1970
    repeat until ( utime < ( (days_in_year(y) * SECS_PER_DAY)) )
        utime -= (days_in_year(y) * SECS_PER_DAY)
        y += 1


PRI get_day(utime): d
' Get the day from a UNIX timestmap
    return (utime / SECS_PER_DAY) + 1


PRI get_month(y, utime): mo
' Get the month from a UNIX timestamp
'   yr:     year the timestamp is within
'   utime:  UNIX timestamp
    mo := 1
    repeat until ( utime < (days_in_month(mo, y) * SECS_PER_DAY) )
        utime -= (days_in_month(mo, y) * SECS_PER_DAY)
        mo += 1


PRI days_since_year_start(y, mo): d | m
' Number of days from the start of the year to the start of the given month
    d := 0
    if ( mo > JANUARY )
        repeat m from 1 to (mo - 1)
            d += days_in_month(m, y)


DAT
{
Copyright 2024 Jesse Burt

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

