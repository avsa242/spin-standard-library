{
---------------------------------------------------------------------------------------------------
    Filename:       Serial-Readline.spin
    Description:    Read a line (of maximum length set by the user) from the
        serial terminal and display it
    Author:         Jesse Burt
    Started:        Jan 6, 2016
    Updated:        Jan 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    NOTE: This is based on LoopBack.spin,
        originally written by Brett Weir.
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


    MAX_LINE    = 10                            ' use this to set the max length of text to read


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"


VAR

    byte _line[MAX_LINE+1]                      ' buffer to read the text into (len + 0 terminator)


PUB main()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.set_attrs(ser.ECHO)                     ' enable echo to make the text input visible

    ser.printf1(@"Enter a line of up to %d characters.\n\r", MAX_LINE)
    ser.strln(@"It will be echoed back after reaching this length or ENTER is pressed.")
    repeat
        ser.puts(@"> ")
        ser.gets_max(@_line, MAX_LINE)          ' read a line, up to MAX_LINE characters
        ser.newline()
        ser.strln(@_line)                       ' show what was read


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

