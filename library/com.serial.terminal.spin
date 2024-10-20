{
    --------------------------------------------
    Filename: com.serial.terminal.spin
    Author: Jesse Burt
    Description: Parallax Serial Terminal-compatible
        serial terminal driver
    Started 2006
    Updated Dec 23, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on FullDuplexSerial.spin,
    originally by Jeff Martin, Andy Lindsay, Chip Gracey
}

CON

    ' Control Character Constants
    HM =  1                                     ' HoMe cursor
    PC =  2                                     ' Position Cursor in x,y
    ML =  3                                     ' Move cursor Left
    MR =  4                                     ' Move cursor Right
    MU =  5                                     ' Move cursor Up
    MD =  6                                     ' Move cursor Down
    BS =  8                                     ' BackSpace
    TB =  9                                     ' TaB
    LF = 10                                     ' Line Feed
    CE = 11                                     ' Clear to End of line
    CB = 12                                     ' Clear lines Below
    NL = 13                                     ' Carriage-return/New Line
    PX = 14                                     ' Position cursor in X
    PY = 15                                     ' Position cursor in Y
    CS = 16                                     ' Clear Screen

CON

    MAXSTR_LENGTH = 49                          ' Maximum length of received
                                                '   numerical string (not
                                                '   including zero terminator)

VAR

    byte _str_buff[MAXSTR_LENGTH+1]             ' Buffer for numerical strings

#include "com.serial.spin"                      ' low-level async serial driver

PUB chars(ch, nr_ch)
' Send character 'ch' nr_ch times
    repeat nr_ch
        putchar(ch)

PUB binin = getbin
PUB rx_bin = getbin
PUB get_bin = getbin
PUB getbin{}: b
' Receive CR-terminated string representing a binary value
'   Returns: the corresponding binary value
    gets_max(@_str_buff, MAXSTR_LENGTH)
    return stl.atoib(@_str_buff, stl#IBIN)

PUB clear
' Clear screen and place cursor at top-left.
    putchar(CS)

PUB clearline = clear_line
PUB clear_line = clear_ln
PUB clear_ln
' Clear from cursor to end of line
    putchar(CE)

PUB decin = getdec
PUB rx_dec = getdec
PUB get_dec = getdec
PUB getdec{}: d
' Receive CR-terminated string representing a decimal value
'   Returns: the corresponding decimal value
    gets_max(@_str_buff, MAXSTR_LENGTH)
    return stl.atoib(@_str_buff, stl#IDEC)

PUB hexin = gethex
PUB rx_hex = gethex
PUB get_hex = gethex
PUB gethex{}: h
' Receive CR-terminated string representing a hexadecimal value
'   Returns: the corresponding hexadecimal value
    gets_max(@_str_buff, MAXSTR_LENGTH)
    return stl.atoib(@_str_buff, stl#IHEX)

PUB movedown = move_down
PUB move_down(y)
' Move cursor down y lines.
    repeat y
        putchar(MD)

PUB moveleft = move_left
PUB move_left(x)
' Move cursor left x characters.
    repeat x
        putchar(ML)

PUB moveright = move_right
PUB move_right(x)
' Move cursor right x characters.
    repeat x
        putchar(MR)

PUB moveup = move_up
PUB move_up(y)
' Move cursor up y lines.
    repeat y
        putchar(MU)

{ common terminal code normally provides this, but tell it we already have one }
#define _HAS_NEWLINE_
PUB newline{}
' Move to the start of the next line
    putchar(NL)

PUB position = pos_xy
PUB pos_xy(x, y)
' Position cursor at column x, row y (from top-left).
    putchar(PC)
    putchar(x)
    putchar(y)

PUB positionx = pos_x
PUB pos_x(x)
' Position cursor at column x of current row.
    putchar(PX)
    putchar(x)

PUB positiony = pos_y
PUB pos_y(y)
' Position cursor at row y of current column.
    putchar(PY)
    putchar(y)

PUB readline = read_line
PUB read_line(line, maxline): size | c
' Read a line of text, terminated by a newline, or 'maxline' characters
    repeat
        case (c := getchar{})
            BS:
                if (size)
                    size--
                    putchar(c)
            NL, LF:
                byte[line][size] := 0
                putchar(c)
                quit
            other:
                if (size < maxline)
                    byte[line][size++] := c
                    putchar(c)

PUB strin = gets
PUB rx_str = gets
PUB gets(ptr_buff): rcnt
' Receive a CR-terminated string into ptr_str
'   ptr_str: pointer to buffer in which to store received string
'   NOTE: ptr_str must point to a large enough buffer for entire string
'       plus a zero terminator
'   Returns: length of received string
    return gets_max(ptr_buff, -1)

PUB strinmax = gets_max
PUB rx_str_max = gets_max
PUB gets_max(ptr_buff, max_len): rcnt
' Receive a CR-terminated string (or max_len size; whichever is first)
'   into ptr_buff
'   ptr_str: pointer to buffer in which to store received string
'   max_len: maximum length of string to receive, or -1 for unlimited
'   Returns: length of received string
    rcnt := 0

    { get up to max_len chars, or until CR received }
    repeat while (max_len--)
        rcnt++
        if ((byte[ptr_buff++] := getchar{}) == CR)
            quit

    { zero terminate string; overwrite CR or append 0 char }
    rcnt--
    byte[ptr_buff+(byte[ptr_buff-1] == CR)] := NUL


#include "terminal.common.spinh"
#include "termwidgets.spinh"

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

