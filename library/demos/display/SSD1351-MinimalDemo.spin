{
    --------------------------------------------
    Filename: SSD1351-MinimalDemo.spin
    Description: Graphics demo using minimal code
    Author: Jesse Burt
    Copyright (c) 2023
    Started: May 28, 2022
    Updated: Jul 31, 2023
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

OBJ

    fnt:    "font.5x8"
    disp:   "display.oled.ssd1351" | WIDTH=96, HEIGHT=64, CS=0, SCK=1, MOSI=2, DC=3, RST=4

PUB main{}

    { start the driver }
    disp.start()

    { configure the display with the minimum required setup:
        1. Use a common settings preset for 96x# displays
        2. Tell the driver the size of the font }
    disp.preset_128x{}
    disp.set_font(fnt.ptr(), fnt.setup())
    disp.clear{}

    { draw some text }
    disp.pos_xy(0, 0)
    disp.fgcolor($ffff)
    disp.str(string("Testing 12345"))
    disp.show{}                               ' send the buffer to the display

    { draw one pixel at the center of the screen }
    { disp.plot(x, y, color) }
    disp.plot(CENTERX, CENTERY, $ffff)
    disp.show{}

    { draw a box at the screen edges }
    { disp.box(x_start, y_start, x_end, y_end, color, filled) }
    disp.box(0, 0, XMAX, YMAX, $ffff, false)
    disp.show{}

    repeat

CON

    WIDTH   = disp.WIDTH
    HEIGHT  = disp.HEIGHT
    XMAX    = WIDTH-1
    YMAX    = HEIGHT-1
    CENTERX = WIDTH/2
    CENTERY = HEIGHT/2

DAT
{
Copyright 2023 Jesse Burt

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
