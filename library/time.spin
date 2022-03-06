{
    --------------------------------------------
    Filename: time.spin
    Author: Jesse Burt
    Description: Basic time/delay functions
    Started 2006
    Updated Mar 6, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This object is based on a subset of Clock.spin,
    originally by Jeff Martin
}

CON

    { limits }
    WMIN        = 381                           ' waitcnt() overhead minimum

    { misc time unit symbols }
    SECOND_US   = 1_000_000
    SECOND_MS   = 1_000
    SECOND      = 1
    MINUTE      = (60 * SECOND)
    HOUR        = (60 * MINUTE)
    DAY         = (24 * HOUR)

VAR

    long _sync

PUB MSleep(msecs)
' Sleep for msecs milliseconds.
'   NOTE: When operating with a system clock of 20kHz (ideal RCSLOW)
'       the minimum practical value is 216ms
    waitcnt(((clkfreq / 1_000 * msecs - 3932) #> WMIN) + cnt)

PUB SetSync{}
' Set starting point for synchronized time delays
' Wait for the start of the next window with WaitForSync*() methods below
    _sync := cnt

PUB Sleep(secs)
' Sleep for secs seconds.
    waitcnt(((clkfreq * secs - 3016) #> WMIN) + cnt)

PUB USleep(usecs)
' Sleep for microseconds
'   NOTE: When operating with a system clock of 80MHz,
'       the minimum practical value is 54us
    waitcnt(((clkfreq / 1_000_000 * usecs - 3928) #> WMIN) + cnt)

PUB WaitForSync(secs)
' Wait until start of the next seconds-long time period
'   NOTE: SetSync() must be called before calling WaitForSync() the first time
    waitcnt(_sync += ((clkfreq * secs) #> WMIN))

PUB WaitSyncMSec(msec)
' Wait until start of the next milliseconds-long time period
'   NOTE: SetSync() must be called before calling WaitForSync() the first time
    waitcnt(_sync += (clkfreq / 1_000 * msec) #> WMIN)

PUB WaitSyncUSec(usec)
' Wait until start of the next microseconds-long time period
'   NOTE: SetSync() must be called before calling WaitForSync() the first time
    waitcnt(_sync += (clkfreq / 1_000_000 * usec) #> WMIN)

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

