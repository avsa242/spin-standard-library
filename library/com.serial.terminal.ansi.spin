{
---------------------------------------------------------------------------------------------------
    Filename:       com.serial.terminal.ansi.spin
    Description:    ANSI-compatible serial terminal
    Author:         Jesse Burt
    Started:        Nov 9, 2020
    Updated:        Mar 17, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    Fsys        RX max bitrate  TX max bitrate
    80MHz       250kbps         250kbps
    80MHz       ---             1Mbps

    NOTE: This is based on code originally written by the following sources:
        Parallax, inc. (Jeff Martin, Andy Lindsay, Chip Gracey)
}

#ifndef TERMCODES_H
#   include "termcodes.spinh"
#endif

{ max len of received numerical string (not including zero terminator) }
#ifndef SER_STR_BUFF_SZ
#   define SER_STR_BUFF_SZ 49
#endif

VAR

    byte _str_buff[SER_STR_BUFF_SZ+1]           ' buffer for numerical strings

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
    gets_max(@_str_buff, SER_STR_BUFF_SZ)
    return stl.atoib(@_str_buff, stl#IBIN)

PUB decin = getdec
PUB rx_dec = getdec
PUB get_dec = getdec
PUB getdec{}: d
' Receive CR-terminated string representing a decimal value
'   Returns: the corresponding decimal value
    gets_max(@_str_buff, SER_STR_BUFF_SZ)
    return stl.atoi(@_str_buff)

PUB hexin = gethex
PUB rx_hex = gethex
PUB get_hex = gethex
PUB gethex(digits=SER_STR_BUFF_SZ): h
' Receive CR-terminated string representing a hexadecimal value
'   Returns: the corresponding hexadecimal value
    gets_max(@_str_buff, digits)
    return stl.atoib(@_str_buff, stl#IHEX)

PUB strin = gets
PUB rx_str = gets
PUB gets(ptr_buff)
' Receive a CR-terminated string into ptr_str
'   ptr_str: pointer to buffer in which to store received string
'   NOTE: ptr_str must point to a large enough buffer for entire string
'       plus a zero terminator
    gets_max(ptr_buff, -1)

PUB strinmax = gets_max
PUB rx_str_max = gets_max
PUB readline = gets_max
PUB read_line = gets_max
PUB gets_max(ptr_str, max_len): len | ch
' Read a newline-terminated string up to max_len chars into ptr_str
'   ptr_str: destination buffer to read string into
'   max_len: maximum length of string to read from the input
'   Returns: number of characters received
    len := 0
    repeat while ( len < max_len )
        ch := getchar()
        case ch                                 ' get another character
            BS:
                if ( len )                      ' backspace? Don't count it
                    len--
            CR, LF:                             ' carriage return/line-feed
                quit                            '       that's the end of the string; stop
            other:
                if ( len < max_len )            ' add char to buffer as long as we haven't
                    byte[ptr_str][len++] := ch  '   reached the length limit
                else
                    quit

    byte[ptr_str][len] := NUL                   ' null/zero-terminate the destination string


#include "terminal.common.spinh"
#include "ansiterminal.common.spinh"
#include "termwidgets.spinh"

DAT
{
Copyright 2024 Jesse Burt

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

