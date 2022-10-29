{
    --------------------------------------------
    Filename: PrintF-Demo.spin
    Description: Demonstrate the functionality of
        the (s)printf() method variants
    Author: Jesse Burt
    Copyright (c) 2022
    Started Nov 9, 2020
    Updated Oct 29, 2022
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

OBJ

    cfg : "boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    str : "string"

VAR

    byte _buff[BUFFSZ]

PUB main{} | sz, format, str1, str2

    setup{}

'   printf() is embedded in a string library, used by most display/terminal output device drivers,
'       (serial, vga, oled, lcd, etc), so can be used directly through the respective drivers,
'       whereas sprintf() and snprintf() output to a user-allocated buffer
'       (e.g., _buff in this demo)

'   Escape codes:
'       \\: backslash
'       \t: tab
'       \n: line-feed (next line, same column)
'       \r: carriage-return (first column of current line)
'           (combine \n\r for start of next line)
'       \###: 3-digit/1-byte octal code for non-printable chars (e.g., \033 for ESC)
'
'   Formatting specifiers:
'       %%: percent-sign
'       %c: character
'       %d, %i: decimal (signed)
'       %b: binary
'       %o: octal
'       %u: decimal (unsigned)
'       %x, %X: hexadecimal (lower-case, upper-case)
'       %f: IEEE-754 float (not yet implemented)
'       %s: string
'
'   Optionally precede formatting spec letter with the following:
'       0: pad numbers with zeroes (e.g., %0d for zero-padded decimal)
'           (default padding character is space, when padding is necessary)
'       #.#: minimum field width.maximum field width (e.g. %2.5d for decimal with 2..5 digits)
'       -: left-justify (e.g. %-4.8x for left-justified hex with 4..8 digits)

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
    format := string("A decimal: %d\n\r")

'   a more complex example
'    format := string("Test literal: %%  char: %c  dec: %d  hex: %x  str: %s  str: %s\n\rnext line\n\r\n\r\n\r")

    str1 := string("a string")
    str2 := string("another")

    ser.pos_xy(0, 0)

    ' You can specify the format inline:
    ser.printf5(string("Test literal: %%  char: %c  dec: %d  hex: %x  str: %s  str: %s\n\r"), {
}   "A", -1000, $DEADBEEF, str1, str2)

    '   or use a pre-defined format:
    ser.printf6(format, "A", -1000, $DEADBEEF, str1, str2, 0)

    ' Print to a buffer (for use in e.g., a file written to SD, or
    '   other external memory, etc)
    str.sprintf5(@_buff, format, "A", -1000, $DEADBEEF, str1, str2)
    ser.puts(@_buff)

    bytefill(@_buff, 0, BUFFSZ)                 ' clear the buffer

    ' An example showing comma-separated values, which could, for example,
    '   be written to a file on an SD-card
    format := string("%d,%d,%d,%d,%d,%d\n\r\n\r")
    str.sprintf6(@_buff, format, 7, 10, 3, 84, 16, 51)
    ser.puts(@_buff)

    ' n-parameter alternate variants of printf that can be used (up to 10)
    ser.printf1(string("printf1() prints format with 1 param: %d\n\r"), 1234)
    ser.printf2(string("printf2() prints format with 2 params: %d %d\n\r"), 1234, 5678)
    ser.printf3(string("printf3() prints format with 3 params: %d %d %d\n\r"), 1234, 5678, 9012)
    ser.printf4(string("printf4() prints format with 4 params: %d %d %d %d\n\r"), 1234, 5678, {
}   9012, 3456)

    ser.printf5(string("printf5() prints format with 5 params: %d %d %d %d %d\n\r"), 1234, 5678, {
}   9012, 3456, 7890)

    repeat

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

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

