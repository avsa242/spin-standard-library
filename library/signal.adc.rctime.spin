{
    --------------------------------------------
    Filename: signal.adc.rctime.spin
    Author: Jesse Burt
    Description: Measure capacitor charge time
        through resistor
    Started 2007
    Updated May 13, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on RCTIME.spin, originally by
        Beau Schwabe
}

OBJ

    time : "time"
    io   : "io"

VAR

    long _cog
    long _rcstack[16]
    long _rctemp
    long _mode

PUB Null{}
' This is not a top-level object

PUB Start(pin, state, ptr_rcvalue): status
' Start CalculateRCTime - starts a cog
' returns false if no cog available
    stop{}
    status := _cog := (cognew(calculaterctime(pin, state, ptr_rcvalue), @_rcstack) + 1)
    _mode := 1

PUB Stop{}
' Stop CalculateRCTime - frees a cog
    if _cog
        cogstop(_cog)

PUB CalculateRCTime(pin, state, ptr_rcvalue)
    repeat
        io.set(pin, state)                      ' make I/O an output in the state you wish to measure... and then charge cap
        io.output(pin)
        time.msleep(1)                          ' pause for 1mS to charge cap
        io.input(pin)                           ' make I/O an input
        _rctemp := cnt                          ' grab clock tick counter value
        waitpeq(1 - state, |< pin, 0)           ' wait until pin goes into the opposite state you wish to measure; state: 1=discharge 0=charge
        _rctemp := cnt - _rctemp                ' see how many clock cycles passed until desired state changed
        _rctemp := _rctemp - 1600               ' offset adjustment (entry and exit clock cycles Note: this can vary slightly with code changes)
        _rctemp := _rctemp >> 4                 ' scale result (divide by 16) <<-number of clock cycles per itteration loop
        long[ptr_rcvalue] := _rctemp            ' Write _rctemp to RCValue

        if _mode == 0                           ' Check for forground (0) or background (1) _mode of operation; forground = no seperate cog / background = seperate running cog
            quit
