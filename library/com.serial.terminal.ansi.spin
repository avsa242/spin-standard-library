{
    --------------------------------------------
    Filename: com.serial.terminal.ansi.spin
    Author: Jesse Burt
    Description: ANSI-compatible serial terminal
    Started Nov 9, 2020
    Updated Oct 15, 2022
    See end of file for terms of use.
    --------------------------------------------

    Fsys        RX max br   TX max br
    80MHz       250kbps     250kbps
    80MHz       ---         1Mbps
    NOTE: This is based on code originally written by the following sources:
        Parallax, inc. (Jeff Martin, Andy Lindsay, Chip Gracey)
}
#ifndef TERMCODES_H
#include "termcodes.spinh"
#endif

CON

    MAXSTR_LENGTH   = 49                        ' max len of received numerical
                                                ' string (not including zero terminator)

VAR

    byte _str_buff[MAXSTR_LENGTH+1]             ' buffer for numerical strings

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

PUB readline = read_line
PUB read_line(ptr_str, max_len): size | c
' Read a CR-terminated string up to max_len chars into ptr_str
'   Returns: number of characters received
    size := 0
    repeat
        case (c := charin{})
            BS:
                if (size)
                    size--
            CR, LF:
                byte[ptr_str][size] := NUL
                quit
            other:
                if (size < max_len)
                    byte[ptr_str][size++] := c
                else
                    quit

#include "terminal.common.spinh"
#include "ansiterminal.common.spinh"
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

