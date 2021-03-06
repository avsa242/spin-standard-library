{
    --------------------------------------------
    Filename: HT16K33-SimpleDemo.spin
    Description: Simplified Demo of the HT16K33 driver
    Author: Jesse Burt
    Created: Nov 21, 2020
    Updated: Nov 22, 2020
    Copyright (c) 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

' -- User-modifiable constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000                       ' 400_000 max
    ADDR_BITS   = %000                          ' %000..%111

    WIDTH       = 8
    HEIGHT      = 8
' --

    BUFFSZ      = (WIDTH * HEIGHT) / 8
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    matrix  : "display.led.ht16k33.i2c"
    fnt     : "font.5x8"

VAR

    byte _framebuff[BUFFSZ]

PUB Main{} | i

    setup{}
    matrix.fontsize(6, 8)
    matrix.fontaddress(fnt.baseaddr{})

    matrix.fgcolor(1)                           ' fg/bg color of following text
    matrix.bgcolor(0)                           '   (colors: -1, 0, 1)
    repeat 5
        repeat i from 0 to 9
            matrix.char(48+i)                   ' ASCII 48+i (nums 0..9)
            time.msleep(100)
            matrix.update{}                     ' update display

    time.sleep(2)
    matrix.clear{}

    matrix.box(0, 0, XMAX, YMAX, 1, false)      ' x1, y1, x2, y2, color, fill
    matrix.update{}

    time.sleep(2)
    matrix.clear{}

    matrix.box(0, 0, 5, 5, -1, true)
    matrix.box(XMAX, YMAX, XMAX-5, YMAX-5, -1, true)
    matrix.update{}

    time.sleep(2)
    matrix.clear{}

    matrix.circle(3, 3, 4, 1)                   ' x, y, radius, color
    matrix.update{}

    time.sleep(2)
    matrix.clear{}

    matrix.line(0, 0, 4, 4, 1)                  ' x1, y1, x2, y2, color
    matrix.update{}

    time.sleep(2)
    matrix.clear{}

    matrix.plot(5, 7, 1)                        ' x, y, color
    matrix.update{}

    time.sleep(2)
    matrix.clear{}

    repeat

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if matrix.startx(WIDTH, HEIGHT, I2C_SCL, I2C_SDA, I2C_HZ, ADDR_BITS, @_framebuff)
        ser.strln(string("HT16K33 driver started"))
    else
        ser.strln(string("HT16K33 driver failed to start - halting"))
        matrix.stop{}
        time.msleep(5)
        ser.stop{}

PUB Stop{}

    matrix.stop{}
    ser.stop{}

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
