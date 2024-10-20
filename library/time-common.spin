{
----------------------------------------------------------------------------------------------------
    Filename:       time-common.spin
    Description:    Common time-related data structures and code
    Author:         Jesse Burt
    Started:        Jul 21, 2024
    Updated:        Aug 31, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

' other files can test if this symbol is already defined to decide whether to #include this file
#define TIME_COMMON

CON

    { POSIX compatible time tm structure }
    tm_s(   word tm_sec, ...
            word tm_min, ...
            word tm_hour, ...
            word tm_mday, ...
            word tm_mon, ...
            word tm_year, ...
            word tm_wday, ...
            word tm_yday, ...
            word tm_isdst )

    { months enumerations }
    #1, JANUARY, FEBRUARY, MARCH, APRIL, MAY, JUNE, JULY, AUGUST, SEPTEMBER, OCTOBER, NOVEMBER, ...
        DECEMBER
    #1, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC

    { day enumerations }    ' xxx these will eventually be 0-based
    #1, SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY
    #1, SUN, MON, TUE, WED, THU, FRI, SAT


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

