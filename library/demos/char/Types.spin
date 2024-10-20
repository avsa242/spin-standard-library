{
---------------------------------------------------------------------------------------------------
    Filename:       Types.spin
    Description:    Demo of the string object types functions
    Author:         Jesse Burt
    Started:        Jan 5, 2016
    Updated:        Jan 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    NOTE: This is based on Types.spin,
        originally written by Brett Weir.
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    str:    "string"
    time:   "time"


PUB main()

    ser.start()
    time.msleep(30)
    ser.clear()

    test_string(@"BACON")
    test_string(@"bacon")
    test_string(@"34545")
    test_string(@"345aaaa")
    test_string(@"       ")


PUB test_string(ptr_str)
' Test a string for various types
    ser.printf1(@"String: %s\n\r", ptr_str)

    ser.strln(@"----------------------")
    ser.printf1(@"  Alphanumeric: %s\n\r", outcome(str.isalphanum(ptr_str)))
    ser.printf1(@"         Alpha: %s\n\r", outcome(str.isalpha(ptr_str)))
    ser.printf1(@"         Digit: %s\n\r", outcome(str.isdigit(ptr_str)))
    ser.printf1(@"         Lower: %s\n\r", outcome(str.islower(ptr_str)))
    ser.printf1(@"         Upper: %s\n\r", outcome(str.isupper(ptr_str)))
    ser.printf1(@"         Space: %s\n\r", outcome(str.isspace(ptr_str)))
    ser.strln(@"----------------------")
    ser.newline()


PUB outcome(val): p
' Return pointer to string based on input value
    if ( val )
        return @"true"                          ' non-zero? true
    else
        return @"false"                         ' zero? false


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

