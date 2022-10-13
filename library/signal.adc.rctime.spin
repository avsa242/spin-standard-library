{
    --------------------------------------------
    Filename: signal.adc.rctime.spin
    Author: Jesse Burt
    Description: Measure capacitor charge time
        through resistor
    Started 2007
    Updated Oct 13, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on RCTIME.spin, originally by
        Beau Schwabe
}

OBJ

    time : "time"

VAR

    long _cog
    long _rcstack[16]
    long _rctemp
    long _mode

PUB null{}
' This is not a top-level object

PUB start(pin, state, ptr_rcvalue): status
' Start CalculateRCTime - starts a cog
' returns false if no cog available
    stop{}
    status := _cog := (cognew(calc_rctime(pin, state, ptr_rcvalue), @_rcstack) + 1)
    _mode := 1

PUB stop{}
' Stop CalculateRCTime - frees a cog
    if _cog
        cogstop(_cog)

PUB calc_rctime(pin, state, ptr_rcvalue)

    repeat
        outa[pin] := state                      ' charge cap
        dira[pin] := 1
        time.msleep(1)                          ' pause for 1mS to charge cap
        dira[pin] := 0
        _rctemp := cnt                          ' grab clock tick counter value
        waitpeq(1 - state, |< pin, 0)           ' wait until pin goes into the opposite state you wish to measure; state: 1=discharge 0=charge
        _rctemp := cnt - _rctemp                ' see how many clock cycles passed until desired state changed
        _rctemp := _rctemp - 1600               ' offset adjustment (entry and exit clock cycles Note: this can vary slightly with code changes)
        _rctemp := _rctemp >> 4                 ' scale result (divide by 16) <<-number of clock cycles per itteration loop
        long[ptr_rcvalue] := _rctemp            ' Write _rctemp to RCValue

        if (_mode == 0)                         ' Check for forground (0) or background (1) _mode of operation; forground = no seperate cog / background = seperate running cog
            quit

DAT
{
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

