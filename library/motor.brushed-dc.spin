{
    --------------------------------------------
    Filename: motor.brushed-dc.spin
    Author: Jesse Burt
    Description: PWM control of H-bridge for
        brushed DC-motors
    Started May 31, 2021
    Updated Oct 13, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on PWM2C_HBDEngine.spin,
        originally by Kwabena W. Agyeman
}
CON

    PWM_FREQ_MAX    = 8_000                     ' maximum supported PWM freq

OBJ

    ctrs : "core.con.counters"

VAR

    long _cog
    long _l_duty, _r_duty, _pin_masks, _freq, _pwm_stack[50]
    long _dir_left[2], _dir_right[2]

PUB null{}
' This is not a top-level object

PUB start(L_FWD_PIN, L_REV_PIN, R_FWD_PIN, R_REV_PIN, PWM_FREQ): status
' Start H-Bridge PWM engine
'   H-Bridge control pins:  
'       L_FWD_PIN: Forward pin, left channel (0 - 31, or -1 to disable)
'       L_REV_PIN: Reverse pin, left channel (0 - 31, or -1 to disable)
'       R_FWD_PIN: Forward pin, right channel (0 - 31, or -1 to disable)
'       R_REV_PIN: Reverse pin, right channel (0 - 31, or -1 to disable)
'       PWM_FREQ - PWM frequency, in Hz (1..8000 @ 80MHz Fsys)
    stop{}                                      ' stop existing engine
    if lookdown(L_FWD_PIN: -1..31) and lookdown(L_REV_PIN: -1..31) and {
}   lookdown(R_FWD_PIN: -1..31) and lookdown(R_REV_PIN: -1..31) and {
}   lookdown(PWM_FREQ: 1..PWM_FREQ_MAX)         ' validate pins and PWM freq
        longmove(@_dir_left, @L_FWD_PIN, 4)     ' copy pins to hub vars

        _pin_masks := (((|<_dir_left) & (L_FWD_PIN <> -1)) | {
}       ((|<_dir_left[1]) & (L_REV_PIN <> -1)) | ((|<_dir_right) & {
}       (R_FWD_PIN <> -1)) | ((|<_dir_right[1]) & (R_REV_PIN <> -1)))

        _freq := clkfreq / PWM_FREQ             ' calculate PWM period
        if status := _cog := cognew(pwm_engine{}, @_pwm_stack) + 1
            return
    return FALSE

PUB stop{}
' Stop PWM engine
    if (_cog)
        cogstop(_cog - 1)
        _cog := 0

PUB both_duty(duty)
' Set both channels' duty cycle, in tenths of a percent
'   Valid values: -100_0..100_0 (clamped to range)
'   100_0:   forward pin, full high
'   0:      brake
'   -100_0:  reverse pin, full high
    longfill(@_l_duty, ((duty <# 1_000) #> -1_000), 2)

PUB coast{}
' Stop motor effort (allow to coast or free-wheel)
    both_duty(0)

PUB forward(duty)
' Command motor forward, in tenths of a percent duty cycle
'   (e.g., 50_5 == 50.5%)
    longfill(@_l_duty, ((duty <# 1_000) #> 0), 2)

PUB left_duty(duty)
' Set left-channel duty cycle, in tenths of a percent
'   Valid values: -100_0..100_0 (clamped to range)
'   100_0:   forward pin, full high
'   0:      brake
'   -100_0:  reverse pin, full high
    _l_duty := ((duty <# 1_000) #> -1_000)

PUB ptr_duty{}: ptr
' Get pointer to duty-cycle data
'   long[ptr_duty()][0]: left, [1]: right
    return @_l_duty

PUB reverse(duty)
' Command motor reverse, in tenths of a percent duty cycle
'   (e.g., 50_5 == 50.5%)
    longfill(@_l_duty, ((duty <# 0) #> -1_000), 2)

PUB right_duty(duty)
' Set right-channel duty cycle, in tenths of a percent
'   Valid values: -100_0..100_0 (clamped to range)
'   100_0:   forward pin, full high
'   0:      brake
'   -100_0:  reverse pin, full high
    _r_duty := ((duty <# 1_000) #> -1_000)

PRI pwm_engine{} | waitper, pwm_per
' Counter-based PWM engine
    dira := _pin_masks
    frqa := 1
    frqb := 1
    waitper := cnt
    pwm_per := (_freq / 1_000)
    repeat
        waitper += _freq
        waitcnt(waitper)
        phsa := -( ||(_l_duty) * pwm_per)
        phsb := -( ||(_r_duty) * pwm_per)
        ctra := (ctrs#NCO_SINGLEEND | _dir_left[-(_l_duty < 0)])
        ctrb := (ctrs#NCO_SINGLEEND | _dir_right[-(_r_duty < 0)])

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

