{
    --------------------------------------------
    Filename: Calculator.spin
    Author: Brett Weir
    Description: Example calculator
        Addition, subtraction, multiplication, division,
        parentheses
    Started Jan 3, 2016
    Updated May 1, 2021
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

    term : "com.serial.terminal.ansi"
    num  : "string.integer"
    cc   : "char.type"
    time : "time"
VAR

    long _sum
    byte _look
    byte _err
    byte _inputstring[32]

PUB Main{}

    term.start(SER_BAUD)
    time.msleep(30)
    term.clear{}

    repeat
        _err := false

        term.flush{}
        term.str(string("> "))

        _look := term.charin{}
        skipspace{}

        _sum := getexpression{}

        if not _err
            term.newline{}
            term.chars(" ", 2)
            term.str(num.dec(_sum))
            repeat 2
                term.newline{}

PUB Error(str)
' Display 'Error:' with accompanying error message
    if not _err
        _err := true
        term.str(string("Error: "))
        term.str(str)

PUB Expected(str)
' Display 'Expected ' with accompanying expected input from user
    if not _err
        error(string("Expected "))
        term.str(str)
        term.char(":")
        term.char(" ")
        term.char(_look)
        repeat 2
            term.newline{}

PUB SkipSpace{}
' Ignore space/enter/return
    repeat while cc.isspace(_look) and _look <> term#CR and _look <> term#LF
        _look := term.charin{}

PUB Match(c)
' Check for matching input from user
    if _look == c
        _look := term.charin{}
        skipspace{}
        return true
    else
        expected(string("a match"))
        return false

PUB GetNumber{} | i
' Read number from user
    if not cc.isdigit(_look) and _look <> term#CR and _look <> term#LF
        expected(string("number"))
        return

    i := 0
    ' copy serial input to temporary string buffer _inputstring,
    '   as long as the input is a number
    ' stop when enter is pressed
    repeat while cc.isdigit(_look) and _look <> term#CR and _look <> term#LF
        _inputstring[i] := _look
        _look := term.charin{}
        i++

    _inputstring[i] := 0                        ' zero-terminate string

    result := num.strtobase(@_inputstring, 10)  ' convert string to a number
    if cc.isalpha(_look)                        ' reject input if it contains
        expected(string("number"))              '   letters
        return
    skipspace{}

PUB GetFactor{}
' Read factor expression for multiplication/division operation
    if _look == "("
        if match("(")
            result := getexpression{}
        else
            expected(string("factor"))
            return
        match(")")
    else
        result := getnumber{}

PUB GetTerm{}
' Read term for addition/subtraction operation
    result := getfactor{}
    if cc.isdigit(_look)
        expected(string("operator"))
        return

    repeat while _look == "*" or _look == "/"
        case _look
            "*":
                result *= getmultiply{}
            "/":
                result /= getdivide{}
            term#CR, term#LF:
                return
            other:
                expected(string("term"))

PUB GetExpression{}
' Read expression from user input
    result := getterm{}
    if cc.isdigit(_look)
        expected(string("operator"))
        return

    repeat while _look == "+" or _look == "-"
        case _look
            "+":
                result += getadd{}
            "-":
                result -= getsubtract{}
            term#CR, term#LF:
                return
            other:
                expected(string("expression"))

PUB GetAdd{}
' Read term for addition operation
    if match("+")
        result := getterm{}
    else
        return

PUB GetSubtract{}
' Read term for subtraction operation
    if match("-")
        result := getterm{}
    else
        return

PUB GetMultiply{}
' Read term/factor for multiplication operation
    if match("*")
        result := getfactor{}
    else
        return

PUB GetDivide{}
' Read term/factor for division operation
    if match("/")
        result := getfactor{}
    else
        return
