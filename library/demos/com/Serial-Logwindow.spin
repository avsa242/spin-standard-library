{
---------------------------------------------------------------------------------------------------
    Filename:       Serial-Logwindow.spin
    Description:    Display a scrolling text/logging "window" on the serial terminal
    Author:         Jesse Burt
    Started:        Oct 25, 2020
    Updated:        Jan 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    WIDTH       = 104                           ' terminal width
    HEIGHT      = 44                            ' height
    LINEWIDTH   = 64                            ' window (inner) width
    LINES       = 4                             ' height
' --

    LASTLINE    = LINES-1
    BTM         = LINEWIDTH*LASTLINE
    SCRLBYTES   = BTM-1
    LOGBUFFSZ   = LINEWIDTH * LINES

    LOG_W       = LINEWIDTH+2
    LOG_H       = LINES+2

    TOP         = 0
    LINE1       = TOP+LINEWIDTH
    LINE2       = LINE1+LINEWIDTH
    LINE3       = LINE2+LINEWIDTH


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    str:    "string"
    time:   "time"


VAR

    byte    _logbuff[LOGBUFFSZ]
    byte    _msg[LINEWIDTH]


PUB main() | i, x, y

    setup()

    x := 0
    y := 4                                      ' x, y coords of 'window'
    ser.text_win(@"Log messages", x, y, LOG_W, LOG_H, ser.CYAN, ser.BLUE, ser.WHITE)

    i := 0
    ser.hide_cursor()
    ser.fgcolor(ser.CYAN)
    ser.bgcolor(ser.BLUE)
    repeat
        ' copy formatted string to temp buffer _msg
        str.sprintf1(@_msg, @"this is message %d", i)

        ' display the scroll buffer and scroll it up one line
        msg_scroll_up(@_msg, x, y)
        bytefill(@_msg, 0, LINEWIDTH)           ' clear out the buffer
        i++                                     ' increment counter used above


PUB msg_scroll_down(ptr_msg, x, y) | ln, ins_left, ins_top
' Scroll a message buffer down one line and add new message to the top row
    ins_left := x+1
    ins_top := y+1

    ' scroll lines from top line down
    bytemove(@_logbuff[LINE1], @_logbuff[TOP], SCRLBYTES)

    ' move the new message into the top line
    bytemove(@_logbuff[TOP], ptr_msg, LINE1)

    ' now display them
    repeat ln from 0 to LASTLINE
        ser.pos_xy(ins_left, ins_top+ln)
        ser.puts(@_logbuff[LINEWIDTH*ln])


PUB msg_scroll_up(ptr_msg, x, y) | ln, ins_left, ins_top
' Scroll a message buffer up one line and add new message to the bottom row
    ins_left := x+1
    ins_top := y+1

    ' scroll lines from bottom line up
    bytemove(@_logbuff[TOP], @_logbuff[LINE1], SCRLBYTES)
    ' move the new message into the bottom line
    bytemove(@_logbuff[BTM], ptr_msg, LINEWIDTH)
    ' now display them
    repeat ln from 0 to LASTLINE
        ser.pos_xy(ins_left, ins_top+ln)
        ser.puts(@_logbuff[LINEWIDTH*ln])


PUB setup()

    ser.start()
    time.msleep(30)
    ser.reset()
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

