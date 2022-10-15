{
    --------------------------------------------
    Filename: sensor.range.ultrasonic.spin
    Description: Driver for single-wire ultrasonic range sensors
        Parallax Ping))) (ultrasonic) sensor (#28015)
        Parallax LaserPing))) (laser) sensor (#28041)
    Author: Chris Savage, Jeff Martin
    Modified by: Jesse Burt
    Created May 8, 2006
    Updated Oct 15, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Ping.spin,
        originally by Chris Savage, Jeff Martin

    Connection to Propeller:
   -------------------
  |/---\         /---\|
  ||   | PING))) |   ||
  |\---/         \---/|
  |    GND +5V SIG    │
   -----|---|---|-----
        |   |   |
       ///  |   |-/\/\/-- I/O pin
            |      3.3k (IMPORTANT: needed to protect the Propeller's I/O pin)
           ---
           5VDC
}
#ifdef __OUTPUT_ASM__
OBJ time:   "time"
#endif

PUB centimeters(pin): dist
' Measure object distance in centimeters
    return (millimeters(pin) / 10)              ' dist in centimeters

CON TO_IN   = 73_746
PUB inches(pin): dist
' Measure object distance in inches
    return ((echo_time(pin) * 1_000) / TO_IN)   ' dist in inches

CON TO_CM   = 29_034
PUB millimeters(pin): dist
' Measure object distance in millimeters
    return ((echo_time(pin) * 10_000) / TO_CM)  ' dist in millimeters

PUB echo_time(pin): usec | cnt1, cnt2
' Return ping))) echo travel time in microseconds
    { pulse pin for >2µs }
    outa[pin] := 0
    dira[pin] := 1
    outa[pin] := 1
#ifdef __OUTPUT_ASM__
    { may be needed if PASM is being generated - the high/low transition of 'pin' may be too fast }
    { for the sensor to register it as a pulse without an explicit delay }
    time.usleep(2)
#endif
    outa[pin] := 0

    { switch pin to input and sample: time pulse width }
    dira[pin] := 0
    waitpne(0, |< pin, 0)                       ' wait for pin high
    cnt1 := cnt                                 '   measure width
    waitpeq(0, |< pin, 0)                       ' wait for pin low
    cnt2 := cnt                                 '   measure width

    { convert system ticks to microseconds }
    usec := (||(cnt1 - cnt2) / (clkfreq / 1_000_000)) >> 1

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

