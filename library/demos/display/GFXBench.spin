{
    --------------------------------------------
    Filename: GFXBench.spin
    Description: Graphics benchmark
    Author: Jesse Burt
    Copyright (c) 2021
    Started: Apr 10, 2021
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
'   NOTE: not supported by all drivers
'#define GFX_DIRECT

' Check the Setup() method for different possible preset settings
'   for your display type

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
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
    SCL_FREQ    = 400_000

' SPI-connected displays
    CS_PIN      = 16
    SCK_PIN     = 17
    MOSI_PIN    = 18
    DC_PIN      = 19
    RES_PIN     = 20
    SCK_FREQ    = 10_000_000

' VGA
    VGA_PINGRP  = 2

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
    BUFFSZ      = (WIDTH * HEIGHT)
#else
    BUFFSZ      = ((WIDTH * HEIGHT) * BPP) / 2
#endif
    XMAX        = WIDTH - 1
    YMAX        = HEIGHT - 1
    CENTERX     = WIDTH/2
    CENTERY     = HEIGHT/2

    BITMAP      = 0
    BOX         = 1
    BOX_F       = 2
    CIRCLE      = 3
    CIRCLE_F    = 4
    DLINE       = 5
    HLINE       = 6
    PLOT        = 7
    TEXT        = 8
    VLINE       = 9

VAR

    long _stack_timer[50]
    long _timer_set
#ifndef GFX_DIRECT
#ifdef SSD1306_I2C
    byte _framebuff[BUFFSZ]                     ' 1bpp
#elseifdef SSD1306_SPI
    byte _framebuff[BUFFSZ]                     ' 1bpp
#elseifdef VGABITMAP6BPP
    byte _framebuff[BUFFSZ]                     ' 8bpp
#elseifdef HUB75
    byte _framebuff[BUFFSZ]                     ' 3bpp
#else
    word _framebuff[BUFFSZ]                     ' 16bpp
#endif
#else
    byte _framebuff                             ' dummy var, for GFX_DIRECT
#endif

PUB Main{} | time_ms, sz, maxsz, iteration, bench, ch, color

    setup{}

'    disp.mirrorh(false)                         ' change these to reorient for
'    disp.mirrorv(false)                         '   your display

    disp.clear{}
    disp.fgcolor(disp#MAX_COLOR)
    disp.bgcolor(0)
    disp.position(0, 0)
    disp.printf1(string("%s\n"), @_drv_name)
    disp.printf1(string("P8X32A\n @%dMHz\n"), clkfreq/1_000_000)
    disp.printf2(string("%dx%d"), WIDTH, HEIGHT)
    disp.update{}
    time.sleep(5)
    disp.clearall{}

    maxsz := WIDTH <# HEIGHT                    ' find smallest disp. dimension

    color := disp#MAX_COLOR
    time_ms := 2_000                            ' time to run each test
    bench := BITMAP                             ' starting benchmark

    ch := $20
    sz := 1
    ser.position(0, 3)
    repeat
        ser.printf2(string("Bench %s (%dpx): "), @_bench_name[bench*14], sz)

        _timer_set := time_ms
        iteration := 0
        case bench
            BITMAP:
                repeat while _timer_set
                    disp.bitmap(0, 0, 0, sz-1, sz-1)
                    disp.update{}
                    iteration++
            BOX:
                repeat while _timer_set
                    disp.box(0, 0, sz-1, sz-1, color, false)
                    disp.update{}
                    iteration++
            BOX_F:
                repeat while _timer_set
                    disp.box(0, 0, sz-1, sz-1, color, true)
                    disp.update{}
                    iteration++
            CIRCLE:
                repeat while _timer_set
                    disp.circle(CENTERX, CENTERY, sz-1, color, false)
                    disp.update{}
                    iteration++
            CIRCLE_F:
                repeat while _timer_set
                    disp.circle(CENTERX, CENTERY, sz-1, color, true)
                    disp.update{}
                    iteration++
            DLINE:
                repeat while _timer_set
                    disp.line(0, 0, sz-1, sz-1, color)
                    disp.update{}
                    iteration++
            HLINE:
                repeat while _timer_set
                    disp.line(0, 0, sz-1, 0, color)
                    disp.update{}
                    iteration++
            PLOT:
                repeat while _timer_set
                    disp.plot(0, 0, color)
                    disp.update{}
                    iteration++
            TEXT:
                disp.fontscale(lookdown(sz: 2, 4, 8, 16, 32, 64, 128))
                repeat while _timer_set
                    disp.char(ch)
                    ch++
                    if ch > $7F
                        ch := $20
                    disp.update{}
                    iteration++
            VLINE:
                repeat while _timer_set
                    disp.line(0, 0, 0, sz-1, color)
                    disp.update{}
                    iteration++
            other:
                quit
        report(time_ms, iteration)              ' show the results
        disp.clear{}

        sz *= 2

        if sz > maxsz                           ' if max size reached,
            sz := 1                             ' reset it and move on to
            bench++                             ' the next test

        if bench > VLINE
            quit

    ser.strln(string("COMPLETE"))
    disp.stop{}
    repeat

PRI Report(testtime, iterations)
' Display benchmark test results
    ser.printf1(string("%d per sec, "), iterations / (testtime/1000))
    decimal((testtime * 1_000) / iterations, 1_000)
    ser.str(string(" ms/iteration, "))
    ser.printf2(string("(total iterations: %d in %dms)"), iterations, testtime)
    ser.newline{}

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp
' Display a fixed-point scaled up number in decimal-dot notation - scale it back down by divisor
'   e.g., Decimal (314159, 100000) would display 3.14159 on the termainl
'   scaled: Fixed-point scaled up number
'   divisor: Divide scaled-up number by this amount
    whole := scaled / divisor
    tmp := divisor
    places := 0

    repeat
        tmp /= 10
        places++
    until tmp == 1
    part := int.deczeroed(||(scaled // divisor), places)

    ser.dec(whole)
    ser.char(".")
    ser.str(part)

PRI cog_Timer{} | time_left
' Benchmark timer loop
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

    _bench_name byte "Bitmap       ", 0
                byte "Box          ", 0
                byte "BoxFilled    ", 0
                byte "Circle       ", 0
                byte "CircleFilled ", 0
                byte "DLine        ", 0
                byte "HLine        ", 0
                byte "Plot         ", 0
                byte "Text         ", 0
                byte "VLine        ", 0

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
