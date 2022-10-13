{                                                                                                                
    --------------------------------------------
    Filename: signal.dac.duty.spin
    Author: Jesse Burt
    Description: 2-channel DAC object using the duty mode of the counters as output
    Started Feb 16, 2020
    Updated Oct 13, 2022
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This object is based on the Parallax Simple-Library functionality
}

VAR

    long _dac_stack[6]
    long _ctra, _ctrb, _frqa, _frqb
    byte _dac_res
    byte _ch0, _ch1
    byte _cog

PUB start(ch0_pin, ch1_pin, dac_res_bits)
' ch0_pin: DAC channel 0 I/O pin
' ch1_pin: DAC channel 1 I/O pin (optional; pass invalid pin to ignore)
' dac_res_bits: DAC resolution (bits)
    if (lookup(ch0_pin: 0..31))                 ' validate ch0 pin
        _ch0 := ch0_pin
        outa[ch0_pin] := 0
        dira[ch0_pin] := 1
        if (lookup(ch1_pin: 0..31))             ' optional - ignore if outside of 0..31 range
            _ch1 := ch1_pin
            outa[ch1_pin] := 0
            dira[ch1_pin] := 1
        if (_cog := cognew(cog_dac_loop{}, @_dac_stack) + 1)
            dac_res(dac_res_bits)               ' set resolution (default to 8 if invalid)
            return _cog
    return FALSE                                ' if we got here, something went wrong

PUB stop
' Stop the DAC cog
    if (_cog)
        cogstop(_cog-1)
        _cog := 0

PUB output(channel, value)
' Output value to DAC
'   Valid values:
'       channel: 0, 1
'       value: 0..(1 << Resolution)-1
'   Voltage output will be approx: value * (3.3V / 2^Resolution)
'   Example:
'   OBJ
'
'       dac : "signal.dac.duty"
'
'   PUB example_method
'
'       dac.startx(26, 27, 8)' ch0 = GPIO 26, ch1 = GPIO 27; set resolution to 8 bits
'       dac.output(0, 0)    ' Output 0V on channel 0
'       dac.output(1, 127)  ' Output 1.65V on channel 1
'       dac.output(0, 255)  ' Output 3.3V on channel 0
    ifnot (channel)                                         ' Channel 0
        _frqa := (value << _dac_res)
    else                                                    ' Channel 1
        _frqb := (value << _dac_res)

PUB dac_res(bits)
' Set DAC resolution, in bits
'   Valid values: 1..32
'   Any other value sets a default resolution of 8 bits
    case bits
        1..32:
        other:
            bits := 8

    _dac_res := 32-bits

#include "core.con.counters.spin"

PRI cog_dac_loop | pin
' Digital to Analog Converter
    _ctra := (DUTY_SINGLEEND + _ch0)       ' Set counters to single-ended duty-cycle mode
    _ctrb := (DUTY_SINGLEEND + _ch1)
    repeat
        if (_ctra <> ctra)
            if (ctra <> 0)
                pin := (ctra & %111111)
                dira &= (1 << pin) ^ $FFFFFFFF
            ctra := _ctra

            if (_ctra <> 0)
                pin := (ctra & %111111)
                dira |= (1 << pin)

        if (_ctrb <> ctrb)
            if (ctrb <> 0)
                pin := (ctrb & %111111)
                dira &= (1 << pin) ^ $FFFFFFFF
            ctrb := _ctrb

            if (ctrb <> 0)
                pin := (ctrb & %111111)
                dira |= (1 << pin)
        frqa := _frqa
        frqb := _frqb

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

