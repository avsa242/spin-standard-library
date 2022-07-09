{
    --------------------------------------------
    Filename: PrintF-Demo.spin
    Author: Jesse Burt
    Description: Demonstrate the functionality of
        the printf() method variants
    Copyright (c) 2022
    Started Nov 9, 2020
    Updated Jul 9, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    BUFFSZ      = 200                           ' maximum buffer size, in bytes
' --

    CR          = 13
    LF          = 10
    TB          = 9

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    sf      : "string.format"

VAR

    byte _buff[BUFFSZ]

PUB Main{} | sz, format, str1, str2

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}

'   printf() prints directly to the terminal (serial, vga, oled, lcd, etc)
'       whereas sprintf() and snprintf() output to a user-allocated buffer
'       (e.g., _buff in this demo)

'   Allowed format specifiers:
'       %%: literal, i.e., just print a % sign
'       %d or %u: decimal (signed; unsigned is not supported at this time)
'       %x: hex (always 8 digits, with leading zeroes)
'       %s: string

'   Allowed escape sequences:
'       \\: literal, i.e., just print a \ symbol
'       \r: carriage return
'       \n: carriage return, line feed (newline)
'       \t: tab (ASCII $09)

'   Any unused parameters must still be specified (SPIN1 limitation), but will
'       be ignored
'       e.g.: printf(string("Number %d"), 1234, 0, 0, 0, 0, 0)
'           The last five params (0, 0, 0, 0, 0) will be ignored, because only
'           one format specifier was defined in the string (%d)
'           The output will be: Number 1234
'
'   Alternatively, n-parameter variants of printf can be used:
'       e.g.:   printf1(string("Number %d"), 1234)
'               printf2(string("Numbers %d %d"), 1234, 5678)

'   a simple example:
    format := string("A decimal: %d\n")

'   a more complex example
'    format := string("Test literal: %%  char: %c  dec: %d  hex: %x  str: %s  str: %s\nnext line\n\n\n")

    str1 := string("a string")
    str2 := string("another")

    ser.position(0, 0)

    ' You can specify the format inline:
    ser.printf6(string("Test literal: %%  char: %c  dec: %d  hex: %x  str: %s  str: %s\nnext line\n\n\n"), "A", -1000, $DEADBEEF, str1, str2, 0)

    '   or use a pre-defined format:
    ser.printf6(format, "A", -1000, $DEADBEEF, str1, str2, 0)

    ' Print to a buffer (for use in e.g., a file written to SD, or
    '   other external memory, etc)
    sf.sprintf(@_buff, format, "A", -1000, $DEADBEEF, str1, str2, 0)
    ser.str(@_buff)

    bytefill(@_buff, 0, BUFFSZ)                 ' clear the buffer

    ' As above, but the second parameter specifies the maximum number
    '   of bytes to write
    sf.snprintf(@_buff, BUFFSZ, format, "A", -1000, $DEADBEEF, str1, str2, 0)
    ser.str(@_buff)

    bytefill(@_buff, 0, BUFFSZ)

    ' An example showing comma-separated values, which could, for example,
    '   be written to a file on an SD-card
    format := string("%d,%d,%d,%d,%d,%d\n\n")
    sf.sprintf(@_buff, format, 7, 10, 3, 84, 16, 51)
    ser.str(@_buff)

    ' n-parameter alternate variants of printf that can be used
    ser.printf1(string("printf1() prints format with 1 param: %d\n"), 1234)
    ser.printf2(string("printf2() prints format with 2 params: %d %d\n"), 1234, 5678)
    ser.printf3(string("printf3() prints format with 3 params: %d %d %d\n"), 1234, 5678, 9012)
    ser.printf4(string("printf4() prints format with 4 params: %d %d %d %d\n"), 1234, 5678, 9012, 3456)
    ser.printf5(string("printf5() prints format with 5 params: %d %d %d %d %d\n"), 1234, 5678, 9012, 3456, 7890)

    repeat

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
