{
---------------------------------------------------------------------------------------------------
    Filename:       PrintF-Demo.spin
    Description:    Demo of the (s)printf() method variants
    Author:         Jesse Burt
    Started:        Nov 9, 2020
    Updated:        Oct 19, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000

    BUFFSZ      = 200                           ' maximum buffer size, in bytes


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    str:    "string"
    time:   "time"


VAR

    byte _buff[BUFFSZ]


PUB main() | sz, format, str1, str2

    setup()

'   (s)printf() are convenient methods for displaying formatted strings/text to a
'       buffer (sprintf) or a display of some sort (printf)
'   A string is passed to define the basic format or layout of the final output
'   It can be as simple as one character or a string (e.g.,: printf(@"A"), printf(@"some text") )
'       or it can include placeholders for values stored in variables
'       (e.g.,: printf(@"Contents of varible a = %d", a) would replace '%d' with the value
'           currently stored in the variable 'a')

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

'   a simple example:
    format := @"A decimal: %d\n\r"

'   a more complex example
'    format := @"Test literal: %%  char: %c  dec: %d  hex: %x  str: %s  str: %s\nnext line\n\r"

    str1 := @"a string"
    str2 := @"another"

    ser.pos_xy(0, 0)

    ' You can specify the format inline:
    ser.printf(@"Test literal: %%  char: %c  dec: %d  hex: %x  str: %s  str: %s\n\r", ...
                "A", -1000, $DEADBEEF, str1, str2)

    '   or use a pre-defined format:
    ser.printf(format, "A", -1000, $DEADBEEF, str1, str2)

    ' Print to a buffer (for use in e.g., a file written to SD, or
    '   other external memory, etc)
    str.sprintf5(@_buff, format, "A", -1000, $DEADBEEF, str1, str2)
    ser.puts(@_buff)

    bytefill(@_buff, 0, BUFFSZ)                 ' clear the buffer

    ' An example showing comma-separated values, which could, for example,
    '   be written to a file on an SD-card
    format := @"%d,%d,%d,%d,%d,%d\n\r"
    str.sprintf6(@_buff, format, 7, 10, 3, 84, 16, 51)
    ser.puts(@_buff)

    repeat


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")


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
