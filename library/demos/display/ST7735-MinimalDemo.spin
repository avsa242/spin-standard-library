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

OBJ

    fnt:    "font.5x8"
    disp:   "display.lcd.st7735" | WIDTH=240, HEIGHT=240, CS=0, SCK=1, MOSI=2, DC=3, RST=4

PUB main()

    { start the driver
    NOTE: The Propeller 1 doesn't have enough RAM to buffer a typically sized
    ST7735 panel (e.g., 128x128), so drawing directly to display is the only supported
    mode of operation. }
    disp.start()

    { configure the display with the minimum required setup }
    { Presets for ST7735R }
'    disp.preset_adafruit_1p44_128x128_land_up()
'    disp.preset_adafruit_1p44_128x128_land_down()
'    disp.preset_adafruit_1p44_128x128_port_up()
'    disp.preset_adafruit_1p44_128x128_port_down()

    { Presets for ST7789VW (build with -DST7789 defined) }
    disp.preset_adafruit_1p3_240x240_land_up()
'    disp.preset_adafruit_1p3_240x240_land_down()
'    disp.preset_adafruit_1p3_240x240_port_up()
'    disp.preset_adafruit_1p3_240x240_port_down()

    disp.set_font(fnt.ptr(), fnt.setup())
    disp.clear()

    { draw some text }
    disp.pos_xy(0, 0)
    disp.fgcolor($ffff)
    disp.strln(@"Testing 12345")

    { draw one pixel at the center of the screen }
    { disp.plot(x, y, color) }
    disp.plot(CENTERX, CENTERY, $ffff)

    { draw a box at the screen edges }
    { disp.box(x_start, y_start, x_end, y_end, color, filled) }
    disp.box(0, 0, XMAX, YMAX, $ffff, false)

    repeat

CON

    WIDTH       = disp.WIDTH
    HEIGHT      = disp.HEIGHT
    XMAX        = (WIDTH - 1)
    YMAX        = (HEIGHT - 1)
    CENTERX     = (WIDTH / 2)
    CENTERY     = (HEIGHT / 2)

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

