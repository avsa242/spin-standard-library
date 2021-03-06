{
    --------------------------------------------
    Filename: string.format.spin
    Author: Jesse Burt
    Based on code by: Eric Smith
    Description: Routines for building formatted
        strings
    Copyright (c) 2020
    Started Nov 9, 2020
    Updated Nov 29, 2020
    See end of file for terms of use.
    --------------------------------------------
}
CON

    HM  = 1                                     ' Home cursor
    PC  = 2                                     '*Position Cursor in x,y
    ML  = 3                                     '*Move cursor Left
    MR  = 4                                     '*Move cursor Right
    MU  = 5                                     '*Move cursor Up
    MD  = 6                                     '*Move cursor Down
    BEL = 7                                     ' Bell
    BS  = 8                                     ' Backspace
    TB  = 9                                     ' Tab
    LF  = 10                                    ' Line Feed
    CE  = 11
    CB  = 12
    CR  = 13                                    ' Carriage Return
    PX  = 14                                    '*Position cursor in X
    PY  = 15                                    '*Position cursor in Y

' * = Parallax Serial Terminal-compatible only

OBJ

    int : "string.integer"
    str : "string"

PUB SNPrintF(ptr_str, sz_str, ptr_fmt, an, bn, cn, dn, en, fn): out_ptr | in, valptr, val, dtmp[3]
' Print formatted string to buffer, with output length limited
'   ptr_str: pointer to destination buffer for formatted string
'   sz_str: maximum length to output to destination buffer, in bytes
'   ptr_fmt: pointer to source format buffer
'   an..fn: values to use in format specifiers' substitution
'   Returns: updated (end-of destination) pointer
    valptr := @an                               ' point to an..fn params
    sz_str += ptr_str
    repeat
        in := byte[ptr_fmt++]                   ' start parsing the format
        if ptr_str => sz_str                    ' if pointer reaches sz_str,
            quit                                '   quit
        case in
            0:                                  ' if byte from ptr_fmt is NUL,
                quit                            '   that's the end
            "%":                                ' reached a format specifier
                case in := byte[ptr_fmt++]
                    0:                          ' NUL reached - quit
                        quit
                    "%":                        ' literal "%"
                        byte[ptr_str++] := in
                        next
                val := long[valptr]             ' get value for current format
                valptr += 4                     '   specifier, then go to next
                case in
                    "d":                        ' decimal
                        dtmp := int.dec(val)    ' append and advance the
                        str.append(ptr_str, dtmp)'   pointer by the length of
                        ptr_str += strsize(dtmp)'   the number
                    "u":                        ' decimal
                        dtmp := int.dec(val)    '   (unsigned not currently
                        str.append(ptr_str, dtmp)'   supported)
                        ptr_str += strsize(dtmp)
                    "x":                        ' hex
                        str.append(ptr_str, int.hex(val, 8))
                        ptr_str += 8
                    "s":                        ' string
                        str.append(ptr_str, val)
                        ptr_str += strsize(val)
                    "c":                        ' char
                        byte[ptr_str++] := val
            "\":                                ' escape sequence
                in := byte[ptr_fmt++]
                if in == 0
                    quit
                case in
                    "n":                        ' newline
                        str.append(ptr_str++, string(CR, LF))
                    "r":                        ' carriage return
                        byte[ptr_str++] := CR
                    "t":                        ' tab
                        byte[ptr_str++] := TB
                    other:                      ' literal (unsupported escape)
                        byte[ptr_str++] := in
                ptr_str++
            other:                              ' literal (no processing)
                byte[ptr_str++] := in

    return ptr_str                              ' return updated pointer

PUB SNPrintF1(ptr_str, sz_str, ptr_fmt, an)
' 1-arg variant of SNPrintF()
    snprintf(ptr_str, sz_str, ptr_fmt, an, 0, 0, 0, 0, 0)

PUB SNPrintF2(ptr_str, sz_str, ptr_fmt, an, bn)
' 2-arg variant of SNPrintF()
    snprintf(ptr_str, sz_str, ptr_fmt, an, bn, 0, 0, 0, 0)

PUB SNPrintF3(ptr_str, sz_str, ptr_fmt, an, bn, cn)
' 3-arg variant of SNPrintF()
    snprintf(ptr_str, sz_str, ptr_fmt, an, bn, cn, 0, 0, 0)

PUB SNPrintF4(ptr_str, sz_str, ptr_fmt, an, bn, cn, dn)
' 4-arg variant of SNPrintF()
    snprintf(ptr_str, sz_str, ptr_fmt, an, bn, cn, dn, 0, 0)

PUB SNPrintF5(ptr_str, sz_str, ptr_fmt, an, bn, cn, dn, en)
' 5-arg variant of SNPrintF()
    snprintf(ptr_str, sz_str, ptr_fmt, an, bn, cn, dn, en, 0)

PUB SPrintF(ptr_str, ptr_fmt, an, bn, cn, dn, en, fn): out_ptr | in, valptr, val, dtmp[3]
' Print formatted string to buffer
'   ptr_str: pointer to destination buffer for formatted string
'   ptr_fmt: pointer to source format buffer
'   an..fn: values to use in format specifiers' substitution
'   Returns: updated (end-of destination) pointer
    valptr := @an                               ' point to an..fn params
    repeat
        case (in := byte[ptr_fmt++])            ' start parsing the format
            0:                                  ' if byte from ptr_fmt is NUL,
                quit                            '   that's the end
            "%":                                ' reached a format specifier
                case (in := byte[ptr_fmt++])
                    0:                          ' NUL reached - quit
                        quit
                    "%":                        ' literal "%"
                        byte[ptr_str++] := in
                        next
                val := long[valptr]             ' get value for current format
                valptr += 4                     '   specifier, then advance it
                case in
                    "d":                        ' decimal
                        dtmp := int.dec(val)    ' append and advance the
                        str.append(ptr_str, dtmp)'   pointer by the length of
                        ptr_str += strsize(dtmp)'   the number
                    "u":                        ' decimal
                        dtmp := int.dec(val)    '   (unsigned not currently
                        str.append(ptr_str, dtmp)'   supported)
                        ptr_str += strsize(dtmp)
                    "x":                        ' hex
                        str.append(ptr_str, int.hex(val, 8))
                        ptr_str += 8
                    "s":                        ' string
                        str.append(ptr_str, val)
                        ptr_str += strsize(val)
                    "c":                        ' char
                        byte[ptr_str++] := val
            "\":                                ' escape sequence
                in := byte[ptr_fmt++]
                if in == 0
                    quit
                case in
                    "n":                        ' newline
                        str.append(ptr_str++, string(CR, LF))
                    "r":                        ' carriage return
                        byte[ptr_str++] := CR
                    "t":                        ' tab
                        byte[ptr_str++] := TB
                    other:                      ' literal (unsupported escape)
                        byte[ptr_str++] := in
                ptr_str++
            other:                              ' literal (no processing)
                byte[ptr_str++] := in

    return ptr_str                              ' return updated pointer

PUB SPrintF1(ptr_str, ptr_fmt, an)
' 1-arg variant of SPrintF()
    sprintf(ptr_str, ptr_fmt, an, 0, 0, 0, 0, 0)

PUB SPrintF2(ptr_str, ptr_fmt, an, bn)
' 2-arg variant of SPrintF()
    sprintf(ptr_str, ptr_fmt, an, bn, 0, 0, 0, 0)

PUB SPrintF3(ptr_str, ptr_fmt, an, bn, cn)
' 3-arg variant of SPrintF()
    sprintf(ptr_str, ptr_fmt, an, bn, cn, 0, 0, 0)

PUB SPrintF4(ptr_str, ptr_fmt, an, bn, cn, dn)
' 4-arg variant of SPrintF()
    sprintf(ptr_str, ptr_fmt, an, bn, cn, dn, 0, 0)

PUB SPrintF5(ptr_str, ptr_fmt, an, bn, cn, dn, en)
' 5-arg variant of SPrintF()
    sprintf(ptr_str, ptr_fmt, an, bn, cn, dn, en, 0)

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
