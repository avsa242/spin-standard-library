{
    --------------------------------------------
    Filename: io.spin
    Description: Object for getting/setting Propeller I/O pin states
    Author: Brett Weir
    Modified by: Jesse Burt
    Copyright (c) 2022
    Created: 2016
    Updated: Oct 17, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON
' Constants that may be used as parameters in the below methods to set pin states
    IO_OUT      = 1
    IO_IN       = 0
    IO_HIGH     = 1
    IO_LOW      = 0

PUB direction(pin)
' Get current direction of pin
'   Returns:
'       0: Pin is set as input
'       1: Pin is set as output
    return dira[pin]

PUB output(pin)
' Set direction of pin to output
    dira[pin] := IO_OUT

PUB input(pin)
' Set direction of pin to input
    dira[pin] := IO_IN
    result := ina[pin]

PUB high(pin)
' Set state of pin high
    outa[pin] := IO_HIGH

PUB low(pin)
' Set state of pin low
    outa[pin] := IO_LOW

PUB toggle(pin)
' Toggle state of pin
    !outa[pin]

PUB set(pin, io_st)
' Set pin to specific state
    outa[pin] := io_st

PUB state(pin)
' Get current state of pin
'   Returns:
'       0: Pin is low
'       1: Pin is high
    return outa[pin]

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

