{
    --------------------------------------------
    Filename: Calculator.spin
    Description: Example calculator
        Addition, subtraction, multiplication, division,
        parentheses
    Author: Brett Weir
    Modified by: Jesse Burt
    Started Jan 3, 2016
    Updated Oct 22, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' -- User-modifiable constants
    SER_BAUD    = 115_200
' --

OBJ

    term: "com.serial.terminal.ansi"
    cc  : "char.type"
    time: "time"
    str : "string"

VAR

    long _sum
    byte _look
    byte _err
    byte _inputstring[32]

PUB main{}

    term.start(SER_BAUD)
    time.msleep(30)
    term.clear{}

    repeat
        _err := false

        term.flush{}
        term.puts(string("> "))

        _look := term.getchar{}
        skipspace{}

        _sum := getexpression{}

        ifnot (_err)
            term.newline{}
            term.chars(" ", 2)
            term.putdec(_sum)
            repeat 2
                term.newline{}

PUB error(str)
' Display 'Error:' with accompanying error message
    ifnot (_err)
        _err := true
        term.str(string("Error: "))
        term.str(str)

PUB expected(str)
' Display 'Expected ' with accompanying expected input from user
    ifnot (_err)
        error(string("Expected "))
        term.puts(str)
        term.putchar(":")
        term.putchar(" ")
        term.putchar(_look)
        repeat 2
            term.newline{}

PUB skipspace{}
' Ignore space/enter/return
    repeat while (cc.isspace(_look) and (_look <> term#CR) and (_look <> term#LF))
        _look := term.getchar{}

PUB match(c)
' Check for matching input from user
    if (_look == c)
        _look := term.getchar{}
        skipspace{}
        return true
    else
        expected(string("a match"))
        return false

PUB getnumber{}: num | i
' Read number from user
    if ((not cc.isdigit(_look)) and (_look <> term#CR) and (_look <> term#LF))
        expected(string("number"))
        return

    i := 0
    ' copy serial input to temporary string buffer _inputstring,
    '   as long as the input is a number
    ' stop when enter is pressed
    repeat while (cc.isdigit(_look) and (_look <> term#CR) and (_look <> term#LF))
        _inputstring[i] := _look
        _look := term.getchar{}
        i++

    _inputstring[i] := 0                        ' zero-terminate string

    num := str.atoi(@_inputstring)              ' convert string to a number
    if (cc.isalpha(_look))                      ' reject input if it contains
        expected(string("number"))              '   letters
        return
    skipspace{}

PUB getfactor{}: expr
' Read factor expression for multiplication/division operation
    if (_look == "(")
        if (match("("))
            return getexpression{}
        else
            expected(string("factor"))
            return
        match(")")
    else
        return getnumber{}

PUB getterm{}: trm
' Read term for addition/subtraction operation
    trm := getfactor{}
    if (cc.isdigit(_look))
        expected(string("operator"))
        return

    repeat while ((_look == "*") or (_look == "/"))
        case _look
            "*":
                trm *= getmultiply{}
            "/":
                trm /= getdivide{}
            term#CR, term#LF:
                return
            other:
                expected(string("term"))

PUB getexpression{}: expr
' Read expression from user input
    expr := getterm{}
    if (cc.isdigit(_look))
        expected(string("operator"))
        return

    repeat while ((_look == "+") or (_look == "-"))
        case _look
            "+":
                expr += getadd{}
            "-":
                expr -= getsubtract{}
            term#CR, term#LF:
                return
            other:
                expected(string("expression"))

PUB getadd{}: trm
' Read term for addition operation
    if (match("+"))
        return getterm{}
    else
        return

PUB getsubtract{}: trm
' Read term for subtraction operation
    if (match("-"))
        return getterm{}
    else
        return

PUB getmultiply{}: trm
' Read term/factor for multiplication operation
    if (match("*"))
        return getfactor{}
    else
        return

PUB getdivide{}: trm
' Read term/factor for division operation
    if (match("/"))
        return getfactor{}
    else
        return

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

