{
    --------------------------------------------
    Filename: SSD1331-MinimalDemo.spin
    Description: Demo of the SSD1331 driver
        * minimal code example
    Author: Jesse Burt
    Copyright (c) 2024
    Started: May 28, 2022
    Updated: Jan 3, 2024
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

OBJ

    fnt:    "font.5x8"
    disp:   "display.oled.ssd1331" | WIDTH=96, HEIGHT=64, CS=0, SCK=1, MOSI=2, DC=3, RST=4

PUB main()

    { start the driver }
    disp.start()

    { configure the display with the minimum required setup:
        1. Use a common settings preset for 96x# displays
        2. Tell the driver the size of the font }
    disp.preset_96x64()
    disp.set_font(fnt.ptr(), fnt.setup())
    disp.clear()

    { draw some text }
    disp.pos_xy(0, 0)
    disp.fgcolor($ffff)
    disp.strln(@"Testing 12345")
    disp.show()                               ' send the buffer to the display

    { draw one pixel at the center of the screen }
    { disp.plot(x, y, color) }
    disp.plot(disp.CENTERX, disp.CENTERY, $ffff)
    disp.show()

    { draw a box at the screen edges }
    { disp.box(x_start, y_start, x_end, y_end, color, filled) }
    disp.box(0, 0, disp.XMAX, disp.YMAX, $ffff, false)
    disp.show()

    repeat


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

