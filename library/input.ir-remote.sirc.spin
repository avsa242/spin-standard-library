{
----------------------------------------------------------------------------------------------------
    Filename:       input.ir-remote.sirc.spin
    Description:    Sony Infrared Remote Control decoder
    Author:         Jesse Burt
    Started:        Jun 14, 2024
    Updated:        Jun 14, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------

    NOTE: This is based on IR_Remote.spin,
    originally by Tom Doyle.
}


CON

    { default I/O configuration - these can be overriden by the parent object }
    IR_PIN      = 0


    { timings (values are in microseconds unless otherwise noted) }
    GAP_MIN     = 2000             ' minimum idle gap (# loops) - adjust to eliminate auto repeat
    STARTBIT_MIN= 2000             ' minimum length of start bit in us (2400 us reference)
    STARTBIT_MAX= 2800             ' maximum length of start bit in us (2400 us reference)
    ONEBIT_MIN  = 1000             ' minimum length of 1 (1200 us reference)
    ONEBIT_MAX  = 1400             ' maximum length of 1 (1200 us reference)

    { Sony TV remote key codes }
    ONE         =  0
    TWO         =  1
    THREE       =  2
    FOUR        =  3
    FIVE        =  4
    SIX         =  5
    SEVEN       =  6
    EIGHT       =  7
    NINE        =  8
    ZERO        =  9
    CH_UP       = 16
    CH_DN       = 17
    VOL_UP      = 18
    VOL_DN      = 19
    MUTE        = 20
    POWER       = 21
    LAST        = 59


VAR

    long _last_decode
    byte _auto_rpt_enabled


OBJ

    ctrmd:   "core.con.counters"


pub address_5bit(code): a
' Get the address portion of a 12-bit or 20-bit SIRC code
'   Returns: 5-bit address
    return ( (code >> 7) & $1f )


pub address_8bit(code): a
' Get the address portion of a 15-bit SIRC code
'   Returns: 8-bit address
    return ( (code >> 7) & $ff )


pub command(code): c
' Get the command portion of a SIRC code (any length)
'   Returns: 7-bit command
    return ( code & $7f )


pub enable_auto_repeat(en)
' Enable auto-repeat
'   en: TRUE (non-zero values) or FALSE
    _auto_rpt_enabled := !(en <> 0)


pub extended(code): e
' Get the extended bits portion of a 20-bit SIRC code
    return ( (code >> 12) & $ff )


PUB read_sirc(): code, len | idx, pwid, bit
' Decode remote code
'   Returns:
'       code:   raw code received
'       len:    length of code, in bits (12, 15 or 20)

    dira[IR_PIN] := 0

    ' wait for idle period (IR_PIN=1 for at least GAP_MIN loops)
    if ( _auto_rpt_enabled )
        idx := 0
        repeat
            if ( ina[IR_PIN] == 1 )
                idx++
            else
                idx := 0
        while ( idx < GAP_MIN )

   ' wait for a start pulse ( width > STARTBIT_MIN and < STARTBIT_MAX  )
    ctra := ctrmd.LOGIC_NOTA | IR_PIN           ' accumulate while A = 0
    frqa := 1
    repeat
        waitpeq(1 << IR_PIN, |< IR_PIN, 0)      ' wait for pin to go high
        phsa := 0                               ' init accumulator: zero width
        waitpeq(0 << IR_PIN, |< IR_PIN, 0)      ' start counting
        waitpeq(1 << IR_PIN, |< IR_PIN, 0)      ' stop counting
        pwid := phsa / (clkfreq / 1_000_000)
    while ( (pwid < STARTBIT_MIN) or (pwid > STARTBIT_MAX) )
   
    ' read in next 12..20 bits
    bit := 0
    code := 0
    repeat
        waitpeq(1 << IR_PIN, |< IR_PIN, 0)
        phsa := 0                               ' zero width
        waitpeq(0 << IR_PIN, |< IR_PIN, 0)      ' start counting
        waitpeq(1 << IR_PIN, |< IR_PIN, 0)      ' stop counting
        pwid := phsa / (clkfreq / 1_000_000)    ' calc pulse width in microseconds

        if ( pwid > ONEBIT_MAX )                ' pulse width > '1'?
            quit                                '   must be the end of the code (or invalid)
        if ( (pwid > ONEBIT_MIN) and (pwid < ONEBIT_MAX) )
            code := code + (1 << bit)           ' accumulate valid '1' bits
        bit++
    while ( bit < 20 )

    ctra := 0                                   ' deactivate counter
    _last_decode := code                        ' save this decode for later

    return (code, bit)                          ' return code and number of bits


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

