{
    --------------------------------------------
    Filename: ST7735-MinimalDemo.spin
    Description: Graphics demo using minimal code
    Author: Jesse Burt
    Copyright (c) 2022
    Started: May 28, 2022
    Updated: May 28, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' -- User-modifiable constants:
    { display size, in pixels }
    WIDTH       = 128
    HEIGHT      = 128

    { SPI-connected displays }
    CS_PIN      = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2
    DC_PIN      = 3

    { reset pin (must be driven either by an I/O pin or other external signal,
    such as the Propeller's reset pin) }
    RES_PIN     = 4
' --

    BUFFSZ      = (WIDTH * HEIGHT)
    XMAX        = (WIDTH - 1)
    YMAX        = (HEIGHT - 1)
    CENTERX     = (WIDTH / 2)
    CENTERY     = (HEIGHT / 2)

OBJ

    fnt     : "font.5x8"
    disp    : "display.lcd.st7735"

PUB Main{}

    { start the driver
    NOTE: The Propeller 1 doesn't have enough RAM to buffer a typically sized
    ST7735 panel (e.g., 128x128), so drawing directly to display is the best
    mode of operation.
    Define the preprocessor symbol GFX_DIRECT when building. }
    disp.startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, 0)

    { configure the display with the minimum required setup:
        1. Use a common settings preset for 96x# displays
        2. Tell the driver the size of the font }
    disp.preset_greentab128x128{}
    disp.fontspacing(1, 1)
    disp.fontscale(1)
    disp.fontsize(fnt#WIDTH, fnt#HEIGHT)
    disp.fontaddress(fnt.baseaddr{})
    disp.clear{}

    { draw some text }
    disp.position(0, 0)
    disp.fgcolor($ffff)
    disp.strln(string("Testing 12345"))

    { draw one pixel at the center of the screen }
    { disp.plot(x, y, color) }
    disp.plot(CENTERX, CENTERY, $ffff)

    { draw a box at the screen edges }
    { disp.box(x_start, y_start, x_end, y_end, color, filled) }
    disp.box(0, 0, XMAX, YMAX, $ffff, false)

    repeat


{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}
