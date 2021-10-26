{
    --------------------------------------------
    Filename: GFXDemo.spin
    Description: Graphics demo for all supported
        display types
    Author: Jesse Burt
    Copyright (c) 2021
    Started: Apr 11, 2021
    Updated: Oct 26, 2021
    See end of file for terms of use.
    --------------------------------------------
}
' Uncomment one display type below
'#define SSD1306_I2C
'#define SSD1306_SPI
'#define SSD1309
'#define SSD1331
'#define SSD1351
'#define ST7735
'#define VGABITMAP6BPP
#define HUB75

' Uncomment to bypass the draw buffer, and draw directly to the display
'   (required if the buffer would be too big for RAM)
' NOTE: not supported by all drivers
'#define GFX_DIRECT

' Check the Setup() method for different possible preset settings
'   for your display type

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    math    : "math.int"
    fnt     : "font.5x8"
#ifdef SSD1306_I2C
#define SSD130X_I2C
    disp    : "display.oled.ssd1306.i2cspi"
#elseifdef SSD1306_SPI
#define SSD130X_SPI
    disp    : "display.oled.ssd1306.i2cspi"
#elseifdef SSD1309
    disp    : "display.oled.ssd1309.spi"
#elseifdef SSD1331
    disp    : "display.oled.ssd1331.spi"
#elseifdef SSD1351
    disp    : "display.oled.ssd1351.spi"
#elseifdef ST7735
    disp    : "display.lcd.st7735.spi"
#elseifdef VGABITMAP6BPP
    disp    : "display.vga.bitmap.160x120"
#elseifdef HUB75
    disp    : "display.led.hub75"
#endif

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants:
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    WIDTH       = 64                            ' change these for your
    HEIGHT      = 32                            '   display

' I2C-connected displays                        ' free-form I/O connections
    SCL_PIN     = 28
    SDA_PIN     = 29
    ADDR_BITS   = 0
    SCL_FREQ    = 1_000_000

' SPI-connected displays
    CS_PIN      = 16
    SCK_PIN     = 17
    MOSI_PIN    = 18
    DC_PIN      = 19
    RES_PIN     = 20

' VGA
    VGA_PINGRP  = 2                             ' 0, 1, 2, 3

' HUB75
    RGB_BASEPIN = 0
    ADDR_BASEPIN= 6
    CLKPIN      = 10
    LATPIN      = 11
    BLPIN       = 12
' --

    BPP         = disp#BYTESPERPX
    BYTESPERLN  = WIDTH * BPP
#ifdef SSD1306_I2C
    BUFFSZ      = (WIDTH * HEIGHT) / 8
#elseifdef SSD1306_SPI
    BUFFSZ      = (WIDTH * HEIGHT) / 8
#elseifdef SSD1309
    BUFFSZ      = (WIDTH * HEIGHT) / 8
#elseifdef VGABITMAP6BPP
    BUFFSZ      = (WIDTH * HEIGHT) * BPP
#elseifdef HUB75
    BUFFSZ      = (WIDTH * HEIGHT) * BPP
#else
    BUFFSZ      = ((WIDTH * HEIGHT) * BPP) / 2
#endif
    XMAX        = WIDTH - 1
    YMAX        = HEIGHT - 1
    CENTERX     = WIDTH/2
    CENTERY     = HEIGHT/2

VAR

    long _stack_timer[50]
    long _timer_set, _time
#ifndef GFX_DIRECT
#ifdef SSD1306_I2C
    byte _framebuff[BUFFSZ]                     ' 1bpp
#elseifdef SSD1306_SPI
    byte _framebuff[BUFFSZ]                     ' 1bpp
#elseifdef VGABITMAP6BPP
    byte _framebuff[BUFFSZ]                     ' 6bpp
#elseifdef HUB75
    byte _framebuff[BUFFSZ]                     ' 3bpp
#else
    word _framebuff[BUFFSZ]                     ' 16bpp
#endif
#else
    byte _framebuff                             ' dummy VAR for GFX_DIRECT
#endif

PUB Main{}

    setup{}
'    disp.mirrorh(false)                         ' change these to reorient for
'    disp.mirrorv(false)                         '   your display
    disp.clear{}

    _time := 5_000                              ' time each demo runs (ms)
    demo_greet{}
    demo_bitmap(0, XMAX, YMAX)                  ' (pointer to bitmap, size)
    demo_bounce{}
    demo_box{}
    demo_boxfilled{}
    demo_circle{}
    demo_circlefilled{}
    demo_line{}
    demo_plot{}
    demo_sinewave{}
    demo_text{}
    demo_wander{}

    disp.stop{}
    repeat

PUB Demo_Bitmap(ptr_bitmap, bm_wid, bm_lns)
' Display bitmap at address ptr_bitmap
    disp.bitmap(ptr_bitmap, 0, 0, bm_wid, bm_lns)
    disp.update{}
    waitclear{}

PUB Demo_Bounce{} | bx, by, dx, dy, radius
' Draw a circle bouncing off screen edges
' Pick a random screen location to start from, and a random direction
    radius := 5
    bx := (math.rndi(XMAX) // (WIDTH - radius * 4)) + radius * 2
    by := (math.rndi(YMAX) // (HEIGHT - radius * 4)) + radius * 2
    dx := math.rndi(4) // 2 * 2 - 1
    dy := math.rndi(4) // 2 * 2 - 1

    _timer_set := _time
    repeat while _timer_set
        bx += dx
        by += dy

        ' if any edge of the screen is reached, change direction
        if (by =< radius OR by => HEIGHT - radius)
            dy *= -1                            ' top/bottom edges
        if (bx =< radius OR bx => WIDTH - radius)
            dx *= -1                            ' left/right edges

        disp.circle(bx, by, radius, disp#MAX_COLOR, false)
        disp.update{}
        disp.clear{}
    waitclear{}

PUB Demo_Box{} | c
' Draw random boxes
    _timer_set := _time
    repeat while _timer_set
        c := math.rndi(disp#MAX_COLOR)
        disp.box(math.rndi(XMAX), math.rndi(YMAX), math.rndi(XMAX), math.rndi(YMAX), c, FALSE)
        disp.update{}
    waitclear{}

PUB Demo_BoxFilled{} | c
' Draw random filled boxes
    _timer_set := _time
    repeat while _timer_set
        c := math.rndi(disp#MAX_COLOR)
        disp.box(math.rndi(XMAX), math.rndi(YMAX), math.rndi(XMAX), math.rndi(YMAX), c, TRUE)
        disp.update{}
    waitclear{}

PUB Demo_Circle{} | x, y, r
' Draw circles at random locations
    _timer_set := _time
    repeat while _timer_set
        x := math.rndi(XMAX)
        y := math.rndi(YMAX)
        r := math.rndi(YMAX/2)
        disp.circle(x, y, r, math.rndi(disp#MAX_COLOR), false)
        disp.update{}
    waitclear{}

PUB Demo_CircleFilled{} | x, y, r
' Draw circles at random locations
    _timer_set := _time
    repeat while _timer_set
        x := math.rndi(XMAX)
        y := math.rndi(YMAX)
        r := math.rndi(YMAX/2)
        disp.circle(x, y, r, math.rndi(disp#MAX_COLOR), true)
        disp.update{}
    waitclear{}

PUB Demo_Greet{}
' Display the banner/greeting
    disp.fgcolor(disp#MAX_COLOR)
    disp.bgcolor(0)
    disp.position(0, 0)
    disp.printf1(string("%s\n"), @_drv_name)
    disp.printf1(string("Parallax P8X32A\n%dMHz\n"), clkfreq/1_000_000)
    disp.printf2(string("%dx%d"), WIDTH, HEIGHT)
    disp.update{}
    waitclear{}

PUB Demo_Line{}
' Draw random lines
    _timer_set := _time
    repeat while _timer_set
        disp.line(math.rndi(XMAX), math.rndi(YMAX), math.rndi(XMAX), math.rndi(YMAX), math.rndi(disp#MAX_COLOR))
        disp.update{}
    waitclear{}

PUB Demo_Plot{} | x, y
' Draw random pixels
    _timer_set := _time
    repeat while _timer_set
        disp.plot(math.rndi(XMAX), math.rndi(YMAX), math.rndi(disp#MAX_COLOR))
        disp.update{}
    waitclear{}

PUB Demo_Sinewave{} | x, y, modifier, offset, div
' Draw a sine wave the length of the screen, influenced by the system counter
    case HEIGHT
        32:
            div := 4096
        64:
            div := 2048
        other:
            div := 2048

    offset := YMAX/2                            ' Offset for Y axis

    _timer_set := _time
    repeat while _timer_set
        repeat x from 0 to XMAX
            modifier := (||(cnt) / 1_000_000)   ' system counter as modifier
            y := offset + math.sin(x * modifier) / div
            disp.plot(x, y, disp#MAX_COLOR)
        disp.update{}
        disp.clear{}
    waitclear{}

PUB Demo_Text{} | ch
' Sequentially draw the whole font table
    disp.fgcolor(disp#MAX_COLOR)
    disp.bgcolor(0)
    ch := 32
    disp.position(0, 0)

    _timer_set := _time
    repeat while _timer_set
        disp.char(ch)
        ch++
        if ch > 127
            ch := 32
        disp.update{}
    waitclear{}

PUB Demo_Wander{} | x, y, d
' Draw randomly wandering pixels
    x := XMAX/2                                 ' start at screen center
    y := YMAX/2

    _timer_set := _time
    repeat while _timer_set
        case d := math.rndi(4)                        ' which way to move?
            1:                                  ' wander right
                x += 2
                if x > XMAX                     ' wrap around at the edge
                    x := 0
            2:                                  ' wander left
                x -= 2
                if x < 0
                    x := XMAX
            3:                                  ' wander down
                y += 2
                if y > YMAX
                    y := 0
            4:                                  ' wander up
                y -= 2
                if y < 0
                    y := YMAX
        disp.plot(x, y, math.rndi(disp#MAX_COLOR))
        disp.update{}
    waitclear{}

PRI waitClear{}
' Wait, then clear the display
    time.msleep(_time)
    disp.clear{}

PRI cog_Timer{} | time_left
' Timer loop
    repeat
        repeat until _timer_set                 ' wait here until a timer has
        time_left := _timer_set                 '   been set

        repeat                                  ' loop for time_left ms
            time_left--
            time.msleep(1)
        while time_left > 0
        _timer_set := 0                         ' signal the timer's been reset

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef SSD1306_I2C
    if disp.startx(SCL_PIN, SDA_PIN, RES_PIN, SCL_FREQ, ADDR_BITS, WIDTH, HEIGHT, @_framebuff)
        disp.preset_128x{}
#elseifdef VGABITMAP6BPP
    if disp.startx(VGA_PINGRP, WIDTH, HEIGHT, @_framebuff)
#elseifdef SSD1306_SPI
    if disp.startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, @_framebuff)
        disp.preset_128x{}
#elseifdef SSD1309
    if disp.startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, @_framebuff)
        disp.preset_128x{}
#elseifdef SSD1331
    if disp.startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, @_framebuff)
        disp.preset_96x64{}
#elseifdef SSD1351
    if disp.startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, @_framebuff)
'       Choose preset settings
'        disp.preset_clickc_away{}               'MikroE Click - facing away
'        disp.preset_clickc_towards{}            'MikroE Click - facing towards
'        disp.preset_128x{}                      'Other 128x displays
        disp.preset_128xhiperf{}                '128x, max display osc. freq.
#elseifdef ST7735
    if disp.startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, @_framebuff)
        disp.preset_greentab128x128{}
#elseifdef HUB75
    if disp.startx(RGB_BASEPIN, ADDR_BASEPIN, BLPIN, CLKPIN, LATPIN, WIDTH, HEIGHT, @_framebuff)
#endif
        disp.fontspacing(1, 1)
        disp.fontscale(1)
        disp.fontsize(fnt#WIDTH, fnt#HEIGHT)
        disp.fontaddress(fnt.baseaddr{})
        ser.printf1(string("%s driver started\n"), @_drv_name)
    else
        ser.printf1(string("%s driver failed to start"), @_drv_name)
        repeat

    cognew(cog_timer{}, @_stack_timer)

DAT

#ifdef SSD1306_I2C
    _drv_name   byte "SSD1306 (I2C)", 0
#elseifdef SSD1306_SPI
    _drv_name   byte "SSD1306 (SPI)", 0
#elseifdef SSD1309
    _drv_name   byte "SSD1309", 0
#elseifdef SSD1331
    _drv_name   byte "SSD1331", 0
#elseifdef SSD1351
    _drv_name   byte "SSD1351", 0
#elseifdef ST7735
    _drv_name   byte "ST7735", 0
#elseifdef VGABITMAP6BPP
    _drv_name   byte "VGA6BPP", 0
#elseifdef HUB75
    _drv_name   byte "HUB75", 0
#endif
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
