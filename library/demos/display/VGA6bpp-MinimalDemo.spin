{
    --------------------------------------------
    Filename: VGA6bpp-MinimalDemo.spin
    Description: Demo of the 6bpp VGA bitmap driver
        * minimal code example
    Author: Jesse Burt
    Copyright (c) 2024
    Started: Jan 2, 2024
    Updated: Jan 2, 2024
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    disp:   "display.vga.bitmap.160x120" | PIN_GRP=0 ' 0..3
    fnt:    "font.5x8"
    { PIN_GRP: 8-pin group number (0, 1, 2, 3 for start pin as 0, 8, 16, 24, resp)
        pins must be connected contiguously in the following (ascending) order:
            Vsync, Hsync, B0, B1, G0, G1, R0, R1 }


PUB main()

    { start the driver }
    disp.start()

    { tell the driver the size of the font }
    disp.set_font(fnt.ptr(), fnt.setup())
    disp.clear()

    { draw some text }
    disp.pos_xy(0, 0)
    disp.fgcolor(disp.MAX_COLOR)                ' 0..63
    disp.str(@"Testing 12345")

    { draw one pixel at the center of the screen }
    {   disp.plot(x, y, color) }
    disp.plot(disp.CENTERX, disp.CENTERY, disp.MAX_COLOR)

    { draw a box at the screen edges }
    {   disp.box(x_start, y_start, x_end, y_end, color, filled) }
    disp.box(0, 0, disp.XMAX, disp.YMAX, disp.MAX_COLOR, false)

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

