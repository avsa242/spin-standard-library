{
---------------------------------------------------------------------------------------------------
    Filename:       Tokenize.spin2
    Description:    Demo of the string object tokenize() function
    Author:         Jesse Burt
    Started:        Jan 5, 2016
    Updated:        Jan 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    NOTE: This is based on Tokenize.spin,
        originally written by Brett Weir.
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    str:    "string"
    time:   "time"


PUB main() | tokenptr

    ser.start()
    time.msleep(30)
    ser.clear()

    tokenptr := str.tokenize(@_test_str)        ' init tokenize() with a pointer to a string

    repeat while tokenptr                       ' loop while there is still a token (non-zero)
        ser.strln(tokenptr)
        tokenptr := str.tokenize(0)             ' get pointer to next token ('0' continues using
                                                '   the string it was initialized with)


DAT

    _test_str     byte    "this string needs to be tokenized!", 0


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

