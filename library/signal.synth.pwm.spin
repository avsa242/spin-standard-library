{
----------------------------------------------------------------------------------------------------
    Filename:       signal.synth.pwm.spin
    Description:    PWM synthesis (up to 8kHz)
    Author:         Jesse Burt
    Started:        Jul 29, 2026
    Updated:        Jul 31, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

var

    long _pwm_stack[50]
    long _pwm_duty
    byte _cog


obj

    ctrs:   "core.con.counters"


pub start(OUT_PIN, PWM_FREQ): s
' Start PWM engine
'   OUT_PIN:    output I/O pin
'   PWM_FREQ:   PWM switching frequency (1..8000)
    _pwm_duty := 0
    _cog := cognew(pwm_engine(OUT_PIN, PWM_FREQ), @_pwm_stack)+1
    return _cog


pub stop()
' Stop the PWM engine
    if ( _cog )
        cogstop(_cog-1)


pub duty(): d
' Get currently set duty cycle
    return _pwm_duty


pub set_duty(d)
' Set duty cycle
'   d:  duty cycle 0..100_0 (tenths of a percent; e.g., 20_0 = 20.0%)
    _pwm_duty := d #> 0 <# 100_0


pri pwm_engine(io_pin, pwm_freq) | waitper, pwm_per, freq
' Counter-based PWM engine
    dira[io_pin] := 1
    frqa := 1
    freq := clkfreq/pwm_freq
    pwm_per := freq / 1000
    waitper := cnt

    repeat
        waitper += freq
        waitcnt(waitper)
        phsa := -(abs(_pwm_duty) * pwm_per)
        ctra := (ctrs.NCO_SINGLEEND | io_pin)


dat
{
Copyright 2026 Jesse Burt

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

