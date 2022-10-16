{
    --------------------------------------------
    Filename: com.serial.terminal.spin
    Author: Jesse Burt
    Description: Parallax Serial Terminal-compatible
        serial terminal driver
    Started 2006
    Updated Oct 16, 2022
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

   MAXSTR_LENGTH = 49                           ' Maximum length of received
                                                '   numerical string (not
                                                '   including zero terminator)

VAR

    byte    _str_buffer[MAXSTR_LENGTH+1]        ' Buffer for numerical strings

#include "com.serial.spin"                      ' low-level async serial driver

PUB chars(ch, nr_ch)
' Send character 'ch' nr_ch times
    repeat nr_ch
        char(ch)

PUB binin = get_bin
PUB rx_bin = get_bin
PUB get_bin{}: b
' Receive CR-terminated string representing a binary value
'   Returns: the corresponding binary value
    strinmax(@_str_buff, MAXSTR_LENGTH)
    return stl.atoib(@_str_buff, stl#IBIN)

PUB clear
' Clear screen and place cursor at top-left.
    char(CS)

PUB clearline = clear_line
PUB clear_line
' Clear from cursor to end of line
    char(CE)

PUB decin = get_dec
PUB rx_dec = get_dec
PUB get_dec{}: d
' Receive CR-terminated string representing a decimal value
'   Returns: the corresponding decimal value
    strinmax(@_str_buff, MAXSTR_LENGTH)
    return stl.atoib(@_str_buff, stl#IDEC)

PUB hexin = get_hex
PUB rx_hex = get_hex
PUB get_hex{}: h
' Receive CR-terminated string representing a hexadecimal value
'   Returns: the corresponding hexadecimal value
    strinmax(@_str_buff, MAXSTR_LENGTH)
    return stl.atoib(@_str_buff, stl#IHEX)

PUB movedown = move_down
PUB move_down(y)
' Move cursor down y lines.
    repeat y
        char(MD)

PUB moveleft = move_left
PUB move_left(x)
' Move cursor left x characters.
    repeat x
        char(ML)

PUB moveright = move_right
PUB move_right(x)
' Move cursor right x characters.
    repeat x
        char(MR)

PUB moveup = move_up
PUB move_up(y)
' Move cursor up y lines.
    repeat y
        char(MU)

{ common terminal code normally provides this, but tell it we already have one }
#define _HAS_NEWLINE_
PUB newline
' Clear screen and place cursor at top-left.
    char(NL)

PUB position = pos_xy
PUB pos_xy(x, y)
' Position cursor at column x, row y (from top-left).
    char(PC)
    char(x)
    char(y)

PUB positionx = pos_x
PUB pos_x(x)
' Position cursor at column x of current row.
    char(PX)
    char(x)

PUB positiony = pos_y
PUB pos_y(y)
' Position cursor at row y of current column.
    char(PY)
    char(y)

PUB readline = read_line
PUB read_line(line, maxline): size | c
' Read a line of text, terminated by a newline, or 'maxline' characters
    repeat
        case c := charin
            BS:     if size
                        size--
                        char(c)
            NL, LF: byte[line][size] := 0
                    char(c)
                    quit
            other:  if size < maxline
                        byte[line][size++] := c
                        char(c)

PUB strin = gets
PUB rx_str = gets
PUB gets(ptr_buff)
' Receive a CR-terminated string into ptr_str
'   ptr_str: pointer to buffer in which to store received string
'   NOTE: ptr_str must point to a large enough buffer for entire string
'       plus a zero terminator
    strinmax(ptr_buff, -1)

PUB strinmax = gets_max
PUB rx_str_max = gets_max
PUB gets_max(ptr_buff, max_len)
' Receive a CR-terminated string (or max_len size; whichever is first)
'   into ptr_buff
'   ptr_str: pointer to buffer in which to store received string
'   max_len: maximum length of string to receive, or -1 for unlimited

    { get up to max_len chars, or until CR received }
    repeat while (max_len--)
        if ((byte[ptr_buff++] := ser.charin{}) == CR)
            quit

    { zero terminate string; overwrite CR or append 0 char }
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

