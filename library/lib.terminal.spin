{
    --------------------------------------------
    Filename: lib.terminal.spin
    Author: Eric Smith
    Modified by: Jesse Burt
    Description: Library to extend a terminal driver with
        standard terminal routines (Bin, Dec, Hex, PrintF, Str)
    Copyright (c) 2020
    Started Dec 14, 2019
    Updated Nov 9, 2020
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is a derivative of std_text_routines.spinh, by Eric Smith.
        (No existing header)
}

{
    Must be included using the preprocessor #include directive

    Requires:
        An object with a Char(param) method
}

CON

    HM  = 1     ' Home cursor
    PC  = 2     ' Position Cursor in x,y (PST-compatible only)
    ML  = 3     ' Move cursor Left (PST-compatible only)
    MR  = 4     ' Move cursor Right (PST-compatible only)
    MU  = 5     ' Move cursor Up (PST-compatible only)
    MD  = 6     ' Move cursor Down (PST-compatible only)
    BEL = 7     ' Bell
    BS  = 8     ' Backspace
    TB  = 9     ' Tab
    LF  = 10    ' Line Feed
    CE  = 11
    CB  = 12
    CR  = 13    ' Carriage Return
    PX  = 14    ' Position cursor in X (PST-compatible only)
    PY  = 15    ' Position cursor in Y (PST-compatible only)

VAR

    byte buf[32]

PUB Bin(val, digits) | mask
' Print a number in binary form
    if digits > 0 and digits < 32
        mask := (|< digits) - 1
        val &= mask
    Num(val, 2, 0, digits)

PUB Dec(val)
' Print a signed decimal number
    Num(val, 10, 1, 0)

PUB DecUns(val, digits)
' Print an unsigned decimal number with the specified
'   number of digits; 0 means just use as many as we need
    Num(val, 10, 0, digits)

PUB Hex(val, digits) | mask
' Print a hex number with the specified number
'   of digits; 0 means just use as many as we need
    val <<= (8 - digits) << 2
    repeat digits
        Char(lookupz((val <-= 4) & $F : "0".."9", "A".."F"))

PUB NewLine
' Print a carriage return and line-feed
    Char(CR)
    Char(LF)

PUB Num(val, base, signflag, digitsNeeded) | i, digit, r1, q1
' Print an number with a given base
' We do this by finding the remainder repeatedly
' This gives us the digits in reverse order
'   so we store them in a buffer; the worst case
'   buffer size needed is 32 (for base 2)
'
'
' signflag indicates how to handle the sign of the
' number:
'   0 == treat number as unsigned
'   1 == print nothing before positive numbers
'   anything else: print before positive numbers
' for signed negative numbers we always print a "-"
'
' we will print at least prec digits
'
' If signflag is nonzero, it indicates we should treat
' val as signed; if it is > 1, it is a character we should
' print for positive numbers (typically "+")
    if (signflag)
        if (val < 0)
            signflag := "-"
            val := -val

' Make sure we will not overflow our buffer
    if (digitsNeeded > 32)
        digitsNeeded := 32

' Accumulate the digits
    i := 0
    repeat
        if (val < 0)
' Synthesize unsigned division from signed
' Basically shift val right by 2 to make it positive
' Then adjust the result afterwards by the bit we
' shifted out
            r1 := val&1  ' Capture low bit
            q1 := val>>1 ' Divide val by 2
            digit := r1 + 2*(q1 // base)
            val := 2*(q1 / base)
            if (digit => base)
                val++
                digit -= base
        else
            digit := val // base
            val := val / base

        if (digit => 0 and digit =< 9)
            digit += "0"
        else
            digit := (digit - 10) + "A"
        buf[i++] := digit
        --digitsNeeded
    while (val <> 0 or digitsNeeded > 0) and (i < 32)
    if (signflag > 1)
        Char(signflag)

' Now print the digits in reverse order
    repeat while (i > 0)
        Char(buf[--i])

PUB PrintF(fmt, an, bn, cn, dn, en, fn) | c, valptr, val
' C like formatted print
    valptr := @an
    repeat
        c := byte[fmt++]
        case c
            0:
                quit
            "%":
                case c := byte[fmt++]
                    0:
                        quit
                    "%":
                        Char(c)
                        next
                val := long[valptr]
                valptr += 4
                case c
                    "d": Dec(val)
                    "u": DecUns(val, 10)
                    "x": Hex(val, 8)
                    "s": Str(val)
                    "c": Char(val)
            "\":
                c := byte[fmt++]
                if c == 0
                    quit
                case c
                    "n": NewLine
                    "r": Char(CR)
                    "t": Char(TB)
                    other: Char(c)
            other:
                Char(c)

PUB Str(s) | c
' Output a string
    repeat while ((c := byte[s++]) <> 0)
        Char(c)

PUB StrLn(s) | c
' Output a string, with a newline appended
    str(s)
    newline

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

