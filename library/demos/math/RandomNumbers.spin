{
    --------------------------------------------
    Filename: RandomNumbers.spin
    Author: Brett Weir
    Description: Demonstrate math.random abilty to generate
        unique random numbers on each power-up
    Started Jan 13, 2016
    Updated Oct 22, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000

OBJ

    term    : "com.serial.terminal.ansi"
    random  : "math.random"
    time    : "time"

PUB start{} | i

    random.start{}
    term.start(115200)
    time.msleep(30)
    term.clear{}

    repeat
        term.hexs(random.random{}, 8)
        term.newline{}
        time.msleep(50)

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

