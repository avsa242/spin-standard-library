{
    --------------------------------------------
    Filename: Servo.spin
    Author: Beau Schwabe
    Modified by: Jesse Burt
    Description: Demo of the 32-servo driver
    Started 2009
    Updated Oct 22, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Servo32v7_RampDemo.spin,
    originally by Beau Schwabe (Copyright 2009, Parallax)
}

CON

    _clkmode        = xtal1 + pll16x
    _xinfreq        = 5_000_000

' -- User-modifiable constants
    SERVO_CH1_PIN   = cfg#SERVO1
' --

    CENTERED        = 1500

OBJ

    cfg     : "boardcfg.activity"
    servo   : "motor.servo"
    time    : "time"

PUB Servo32_Demo{} | temp

    servo.start{}                               ' start servo handler
    servo.ramp{}                                ' background Ramping (optional)

    ' NOTE: Ramping requires another core/cog. If ramping is not started, then calls to setramp()
    '   are ignored.
    '
    ' NOTE: At ANY time, calling set() overides the servo position. To 'ramp' from the current
    '   position to the next position, you must call setramp()

        ' set(pin, width)
    servo.set(SERVO_CH1_PIN, CENTERED)          ' move Servo to Center

        ' setramp(pin, width, delay)            ' delay: 100 = 1 sec 6000 = 1 min
    servo.setramp(SERVO_CH1_PIN, 2000, 200)     ' pan Servo

    time.msleep(200)                            ' wait for ramping to complete

    servo.setramp(SERVO_CH1_PIN, 1000, 50)      ' pan Servo

    time.msleep(50)                             ' wait for ramping to complete

    servo.set(SERVO_CH1_PIN, CENTERED)          ' force Servo to Center

    ' To disable a servo channel simply specify a pulsewidth that has a value
    '   outside of the allowed range. The default for this range is set
    '   between 500us and 2500us

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

