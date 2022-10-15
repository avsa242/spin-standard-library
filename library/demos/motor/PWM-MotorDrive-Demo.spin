{
    --------------------------------------------
    Filename: BDC-MotorDrive-Demo.spin
    Author: Jesse Burt
    Description: Demo of the H-Bridge brushed DC motor
        engine
    Started May 31, 2021
    Updated Sep 5, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on PWM2C_HBDDemo.spin,
        originally by Kwabena W. Agyeman

    NOTE: Intended for use with H-bridge driver chips
        that do not have an output enable pin (e.g. DRV8871)
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    L_FWD_PIN   = 0                            ' left, right fwd & rev pins
    L_REV_PIN   = -1                            '   0..31, or -1 to disable
    R_FWD_PIN   = 1                            '
    R_REV_PIN   = -1                            '

    TIMESTEP    = 10                            ' ramp up/down delay, in ms
    PWM_FREQ    = 8_000                         ' 1..8_000
' --

OBJ

    cfg     : "boardcfg.flip"
    time    : "time"
    ser     : "com.serial.terminal.ansi"
    motor   : "motor.brushed.hbridge-pwm"

PUB main{} | duty

    setup{}

    repeat
        repeat duty from 0 to 100_0 step 1      ' ramp up from 0 to 100.0%
            update_motors(duty)

        repeat duty from 100_0 to 0 step 10     ' ramp back down, more quickly
            update_motors(duty)

        repeat duty from 0 to -100_0 step 1     ' same as above, but in reverse
            update_motors(duty)

        repeat duty from -100_0 to 0 step 10
            update_motors(duty)

PRI update_motors(duty)

    ser.position(0, 3)
    ser.printf2(string("Duty cycle: %d.%d%% "), duty/10, ||(duty//10))
    motor.left_duty(duty)
    motor.right_duty(duty)
    time.msleep(TIMESTEP)

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}

    ser.strln(string("Serial terminal started"))

    if motor.start(L_FWD_PIN, L_REV_PIN, R_FWD_PIN, R_REV_PIN, PWM_FREQ)
        ser.strln(string("Motor driver started"))
    else
        ser.strln(string("Motor driver failed to start - halting"))
        repeat

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

