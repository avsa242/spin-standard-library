{
    --------------------------------------------
    Filename: ILI9341-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the ILI9341 driver
    Copyright (c) 2021
    Started Oct 14, 2021
    Updated Oct 14, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    DATA        = 0                             ' 0, 8, 16, 24
    RESX        = 8
    CS          = 9
    DC          = 10
    WRX         = 11
    RDX         = 12

    WIDTH       = 240
    HEIGHT      = 320
' --

    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1
    CENTERX     = WIDTH/2
    CENTERY     = HEIGHT/2
    BUFFSZ      = (WIDTH * HEIGHT)

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    lcd : "display.lcd.ili9341.8bp"
    fnt : "font.5x8"

PUB Main

    setup
    lcd.preset{}

    lcd.bgcolor(0)
    lcd.clear{}
    lcd.box(0, 0, XMAX, YMAX, $FFFF, false)
    lcd.line(0, 0, XMAX, YMAX, $07e0)
    lcd.line(XMAX, 0, 0, YMAX, $07e0)
    lcd.fgcolor($f800)
    lcd.position(13, 1)
    lcd.str(string("Testing 1 2 3"))
    repeat

PUB Setup

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if lcd.startx(DATA, RESX, CS, DC, WRX, RDX, WIDTH, HEIGHT)
        ser.strln(string("ILI9341 driver started"))
        lcd.fontspacing(1, 1)
        lcd.fontscale(1)
        lcd.fontsize(fnt#WIDTH, fnt#HEIGHT)
        lcd.fontaddress(fnt.baseaddr{})
    else
        ser.strln(string("ILI9341 driver failed to start-halting"))
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
