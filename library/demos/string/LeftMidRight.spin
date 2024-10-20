{
---------------------------------------------------------------------------------------------------
    Filename:       LeftMidRight.spin
    Description:    Demo of the string object left(), mid() and right() functions
    Author:         Jesse Burt
    Started:        Jan 5, 2016
    Updated:        Jan 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    NOTE: This is based on LeftMidRight.spin,
        originally written by Brett Weir.
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    str:    "string"
    time:   "time"


VAR

    byte _str[20]                               ' buffer to hold the string


PUB main() | n, s

    ser.start()
    time.msleep(30)
    ser.clear()

    n := 4
    ser.strln(str.left(@dinosaur, n))           ' get and show the leftmost n chars from a string

    s := 5
    n := 9
    ser.strln(str.mid(@dinosaur, s, n))         ' get and show n chars starting from s

    n := 6
    ser.strln(str.right(@dinosaur, n))          ' get and show the rightmost n chars

    str.copy(@_str, str.left(@dinosaur, 2))     ' make a new string from the leftmost n chars
    str.append(@_str, str.right(@dinosaur, 6))  '   and the rightmost 6 chars
    ser.strln(@_str)

    repeat


DAT

dinosaur    byte    "dass pineapplesaurus",0


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

