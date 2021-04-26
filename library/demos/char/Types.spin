{
    --------------------------------------------
    Filename: Types.spin
    Author: Unknown
    Description: Demonstrate string.type functionality
    Started Jan 5, 2016
    Updated Apr 26, 2021
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000

OBJ

    term    : "com.serial.terminal.ansi"
    ss      : "string.type"
    time    : "time"

PUB Main{}

    term.start(115200)
    time.msleep(30)
    term.clear{}

    teststring(string("BACON"))
    teststring(string("bacon"))
    teststring(string("34545"))
    teststring(string("345aaaa"))
    teststring(string("       "))

PUB TestString(ptr_string)

    term.str    (string("        String: "))
    term.str    (ptr_string)
    term.newline{}

    term.strln  (string("----------------------"))
    printoutcome(string("  Alphanumeric"), ss.isalphanumeric(ptr_string))
    printoutcome(string("         Alpha"), ss.isalpha(ptr_string))
    printoutcome(string("         Digit"), ss.isdigit(ptr_string))
    printoutcome(string("         Lower"), ss.islower(ptr_string))
    printoutcome(string("         Upper"), ss.isupper(ptr_string))
    printoutcome(string("         Space"), ss.isspace(ptr_string))
    term.str    (string("----------------------"))

    repeat 2
        term.newline{}

PUB PrintOutcome(stringptr, outcome)

    term.str(stringptr)
    term.str(string(": "))

    if outcome
        term.str(string("true"))
    else
        term.str(string("false"))

    term.newline{}

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
