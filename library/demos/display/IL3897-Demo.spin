{
    --------------------------------------------
    Filename: IL3897-Demo.spin
    Author: Jesse Burt
    Description: Demo of the IL3897 driver
    Copyright (c) 2022
    Started Feb 21, 2021
    Updated Jan 30, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_PIN      = 4
    SCK_PIN     = 1
    MOSI_PIN    = 2
    RST_PIN     = 5
    DC_PIN      = 6
    BUSY_PIN    = 7

    WIDTH       = 122
    HEIGHT      = 250
' --

    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1
    CENTERX     = XMAX/2
    CENTERY     = YMAX/2
    MIDLEFT     = CENTERX/2
    MIDTOP      = CENTERY/2
    MIDRIGHT    = CENTERX+MIDLEFT
    MIDBOTTOM   = CENTERY+MIDTOP
    BUFF_SZ     = ((WIDTH + 6) * HEIGHT) / 8

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    epaper  : "display.epaper.il3897"
    fnt     : "font.5x8"

VAR

    byte _framebuff[BUFF_SZ]

PUB Main{} | i

    setup{}

    epaper.preset_2_13_bw{}                     ' set presets for 2.13" BW

    repeat until epaper.displayready{}          ' wait for display to be ready

    epaper.bgcolor(epaper#WHITE)                ' set BG color for text and
    epaper.clear{}                              '   Clear()
    epaper.fgcolor(epaper#BLACK)                ' set FG color for text
    epaper.box(0, 0, XMAX, YMAX, 0, FALSE)      ' draw box full-screen size

    epaper.position(5, 2)
    epaper.str(string("HELLO WORLD"))

    repeat i from XMAX/2 to 0 step 4            ' concentric circles
        epaper.circle(CENTERX, CENTERY, i, epaper#INVERT, false)
    epaper.line(0, 0, XMAX, YMAX, epaper#INVERT)' draw diagonal lines
    epaper.line(XMAX, 0, 0, YMAX, epaper#INVERT)
    epaper.box(MIDLEFT, MIDTOP, MIDRIGHT, MIDBOTTOM, -1, false)

    hrule{}                                     ' draw rulers at screen edges
    vrule{}

    epaper.update{}                             ' update the display

    repeat

PUB HRule{} | x, grad_len
' Draw a simple rule along the x-axis
    grad_len := 5

    repeat x from 0 to XMAX step 5
        if x // 10 == 0
            epaper.line(x, 0, x, grad_len, epaper#INVERT)
        else
            epaper.line(x, 0, x, grad_len*2, epaper#INVERT)

PUB VRule{} | y, grad_len
' Draw a simple rule along the y-axis
    grad_len := 5

    repeat y from 0 to YMAX step 5
        if y // 10 == 0
            epaper.line(0, y, grad_len, y, epaper#INVERT)
        else
            epaper.line(0, y, grad_len*2, y, epaper#INVERT)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if epaper.startx(CS_PIN, SCK_PIN, MOSI_PIN, RST_PIN, DC_PIN, BUSY_PIN, WIDTH, HEIGHT, @_framebuff)
        ser.strln(string("IL3897 driver started"))
        epaper.fontscale(1)
        epaper.fontaddress(fnt.baseaddr{})
        epaper.fontsize(6, 8)
    else
        ser.strln(string("IL3897 driver failed to start - halting"))
        epaper.stop{}
        time.msleep(500)
        ser.stop{}
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
