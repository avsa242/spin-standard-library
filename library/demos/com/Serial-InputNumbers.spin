{
---------------------------------------------------------------------------------------------------
    Filename:       Serial-InputNumbers.spin
    Description:    Demonstrate reading decimal numbers from the serial terminal
    Author:         Jesse Burt
    Started:        Jan 3, 2016
    Updated:        Jan 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    NOTE: This is based on InputNumbers.spin,
        originally written by Brett Weir
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"


PUB main() | a, b

    ser.start()
    time.msleep(30)
    ser.clear()

    ser.puts(@"Input a value: ")
    ser.set_attrs(ser.ECHO)                     ' show what the user is typing

    a := ser.getdec()                           ' read a decimal number from the terminal
    ser.newline()

    ser.puts(@"Input another value: ")
    b := ser.getdec()                           '   and a second one
    ser.newline()

    ser.str(@"a + b: ")
    ser.putdec(a + b)                           ' add them
    ser.newline()

    ser.str(@"a - b: ")
    ser.putdec(a - b)                           ' subtract them
    ser.newline()

    ser.str(@"a * b: ")
    ser.putdec(a * b)                           ' multiply them
    ser.newline()

    ser.str(@"a / b: ")
    ser.putdec(a / b)                           ' divide them

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

