{
    --------------------------------------------
    Filename: com.serial.terminal.ansi.spin
    Author: Jesse Burt
    Description: ANSI-compatible serial terminal
    Started Nov 9, 2020
    Updated May 29, 2022
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

OBJ

    ser : "com.serial"                          ' UART/async serial engine
    time: "time"                                ' time delay routines

VAR

    byte _str_buff[MAXSTR_LENGTH+1]             ' buffer for numerical strings

PUB Start(BPS): status
' Start UART/serial engine using default I/O pins
'   BPS: serial bitrate (bits per second)
'       (max TX/RX: 250_000; max TX only: 1_000_000)
'   Returns: cog ID+1 of engine (if started), FALSE otherwise
    status := ser.start(BPS)
    time.msleep(10)
    return

PUB StartRxTx(RX_PIN, TX_PIN, MODE, BPS): status
' Start UART/serial engine using custom I/O pins and mode
'   RX_PIN: input pin (receive from external device's TX pin)
'   TX_PIN: output pin (send to external device's RX pin)
'   MODE: signaling mode (bits 3..0)
'       3 - ignore tx echo on rx
'       2 - open drain/source tx
'       1 - invert TX
'       0 - invert RX
'   BPS: serial bitrate (bits per second)
'   Returns: cog ID+1 of engine (if started), FALSE otherwise
    return ser.startrxtx(RX_PIN, TX_PIN, MODE, BPS)

PUB Stop{}
' Stop serial engine
    ser.stop{}

PUB BinIn{}: b
' Receive CR-terminated string representing a binary value
'   Returns: the corresponding binary value
    strinmax(@_str_buff, MAXSTR_LENGTH)
    return stl.atoib(@_str_buff, stl#IBIN)

PUB Char(ch)
' Send single-byte character
'   NOTE: Waits for room in transmit buffer if necessary
    ser.char(ch)

PUB CharIn{}: c
' Receive single-byte character (blocks)
    return ser.charin{}

PUB Chars(ch, nr_ch)
' Send nr_ch number of character ch
    repeat nr_ch
        ser.char(ch)

PUB Count{}: c
' Count of characters in receive buffer
    return ser.count{}

PUB DecIn{}: d
' Receive CR-terminated string representing a decimal value
'   Returns: the corresponding decimal value
    strinmax(@_str_buff, MAXSTR_LENGTH)
    return stl.atoib(@_str_buff, stl#IDEC)

PUB Flush{}
' Flush receive buffer
    ser.flush{}

PUB HexIn{}: h
' Receive CR-terminated string representing a hexadecimal value
'   Returns: the corresponding hexadecimal value
    strinmax(@_str_buff, MAXSTR_LENGTH)
    return stl.atoib(@_str_buff, stl#IHEX)

PUB ReadLine(ptr_str, max_len): size | c
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

PUB RxCheck{}: ch
' Check if character received (does not block)
'   Returns:
'       -1 if no byte received
'       $00..$FF if character received
    return ser.rxcheck{}

PUB StrIn(ptr_buff)
' Receive a CR-terminated string into ptr_str
'   ptr_str: pointer to buffer in which to store received string
'   NOTE: ptr_str must point to a large enough buffer for entire string
'       plus a zero terminator
    strinmax(ptr_buff, -1)

PUB StrInMax(ptr_buff, max_len)
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

#include "terminal-common.spinh"
#include "lib.ansiterminal.spin"
#include "lib.termwidgets.spin"

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

