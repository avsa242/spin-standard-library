{
    --------------------------------------------
    Filename: Types.spin
    Author: Jesse Burt
    Description: Demonstrate string types functionality
    Started Jan 5, 2016
    Updated Aug 14, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on code from an unknown author
}
CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

OBJ

    cfg : "core.con.boardcfg.flip"
    term: "com.serial.terminal.ansi"
    ss  : "string"
    time: "time"

PUB main{}

    term.start(115200)
    time.msleep(30)
    term.clear{}

    test_string(string("BACON"))
    test_string(string("bacon"))
    test_string(string("34545"))
    test_string(string("345aaaa"))
    test_string(string("       "))

PUB test_string(ptr_str)
' Test a string for various types
    term.str(string("String: "))
    term.str(ptr_str)
    term.newline{}

    term.strln(string("----------------------"))
    term.printf1(string("  Alphanumeric: %s\n\r"), outcome(ss.isalphanum(ptr_str)))
    term.printf1(string("         Alpha: %s\n\r"), outcome(ss.isalpha(ptr_str)))
    term.printf1(string("         Digit: %s\n\r"), outcome(ss.isdigit(ptr_str)))
    term.printf1(string("         Lower: %s\n\r"), outcome(ss.islower(ptr_str)))
    term.printf1(string("         Upper: %s\n\r"), outcome(ss.isupper(ptr_str)))
    term.printf1(string("         Space: %s\n\r"), outcome(ss.isspace(ptr_str)))
    term.strln(string("----------------------"))
    term.newline{}

PUB outcome(val)
' Return pointer to string based on input value
    if (val)
        return string("true")                   ' non-zero? true
    else
        return string("false")                  ' zero? false

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

