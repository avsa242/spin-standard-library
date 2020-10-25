{
    --------------------------------------------
    Filename: SerLogWindow-Demo.spin
    Author: Jesse Burt
    Description: Display a scrolling text/logging
        "window" on the serial terminal
    Copyright (c) 2020
    Started Oct 25, 2020
    Updated Oct 25, 2020
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

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

    cfg     : "core.con.boardcfg.demoboard"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    str     : "string"

VAR

    byte    _logbuff[LOGBUFFSZ]
    byte    _msg[LINEWIDTH]

DAT

    _msg_templ  byte    "this is message ####", 0

PUB Main{} | i, x, y

    setup{}

    x := 0
    y := 4
    ser.textwindow(string("Log messages"), x, y, LOG_W, LOG_H, ser#CYAN, ser#BLUE, ser#WHITE)

    i := 0
    ser.hidecursor{}
    ser.fgcolor(ser#CYAN)
    ser.bgcolor(ser#BLUE)
    repeat
        bytemove(@_msg, @_msg_templ, strsize(@_msg_templ))
        str.replaceall(@_msg, string("####"), int.deczeroed(i, 4))
        msgscrollup(@_msg, x, y)
        i++

PUB MsgScrollDown(ptr_msg, x, y) | ln, ins_left, ins_top
' Scroll a message buffer down one line and add new message to the top row
    ins_left := x+1
    ins_top := y+1

    ' scroll lines from top line down
    bytemove(@_logbuff[LINE1], @_logbuff[TOP], SCRLBYTES)
    ' move the new message into the top line
    bytemove(@_logbuff[TOP], ptr_msg, LINE1)
    ' now display them
    repeat ln from 0 to LASTLINE
        ser.position(ins_left, ins_top+ln)
        ser.str(@_logbuff[LINEWIDTH*ln])

PUB MsgScrollUp(ptr_msg, x, y) | ln, ins_left, ins_top
' Scroll a message buffer up one line and add new message to the bottom row
    ins_left := x+1
    ins_top := y+1

    ' scroll lines from bottom line up
    bytemove(@_logbuff[TOP], @_logbuff[LINE1], SCRLBYTES)
    ' move the new message into the bottom line
    bytemove(@_logbuff[BTM], ptr_msg, LINEWIDTH)
    ' now display them
    repeat ln from 0 to LASTLINE
        ser.position(ins_left, ins_top+ln)
        ser.str(@_logbuff[LINEWIDTH*ln])

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.reset{}
    ser.clear{}
    ser.strln(string("Serial terminal started"))

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
