{
    --------------------------------------------
    Filename: SSD1351-Demo.spin
    Description: Demo of the SSD1351 driver
    Author: Jesse Burt
    Copyright (c) 2021
    Started: Nov 3, 2019
    Updated: Apr 8, 2021
    See end of file for terms of use.
    --------------------------------------------
}
#define GFX_DIRECT
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    DIN_PIN     = 11
    CLK_PIN     = 12
    CS_PIN      = 15
    DC_PIN      = 13
    RES_PIN     = 14

    WIDTH       = 128
    HEIGHT      = 128
' --

    ' calculate some constraints used by the demo
    BUFFSZ      = (WIDTH * HEIGHT) * oled#BYTESPERPX
    BPL         = WIDTH * oled#BYTESPERPX       ' bytes per line
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1

OBJ

    cfg         : "core.con.boardcfg.flip"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    oled        : "display.oled.ssd1351.spi"
    int         : "string.integer"
    fnt5x8      : "font.5x8"

VAR

    long _stack_timer[50]
    long _timer_set
    long _rndseed
#ifndef GFX_DIRECT
    byte _framebuff[BUFFSZ]
#endif
    byte _timer_cog

PUB Main{} | time_ms

    setup{}
    ' change these to suit the orientation of your display
    oled.mirrorh(false)
    oled.mirrorv(true)

    oled.bgcolor(0)
    oled.clear{}

    demo_greet{}
    time.sleep(1)
    oled.clear{}

    time_ms := 5_000

    ser.position(0, 3)

    demo_sinewave(time_ms)
    oled.clear{}

    demo_triwave(time_ms)
    oled.clear{}

    demo_memscroller(time_ms, $0000, $FFFF-BUFFSZ)
    oled.clear{}

    demo_bitmap(time_ms, $8000)
    oled.clear{}

    demo_box(time_ms)
    oled.clear{}

    demo_boxfilled(time_ms)
    oled.clear{}

    demo_linesweepx(time_ms)
    oled.clear{}

    demo_linesweepy(time_ms)
    oled.clear{}

    demo_line(time_ms)
    oled.clear{}

    demo_plot(time_ms)
    oled.clear{}

    demo_bouncingball(time_ms, 5)
    oled.clear{}

    demo_circle(time_ms)
    oled.clear{}

    demo_wander(time_ms)
    oled.clear{}

    demo_seqtext(time_ms)
    oled.clear{}

    demo_rndtext(time_ms)

    demo_contrast(2, 1)

    oled.clear{}
    oled.stop
    repeat

PUB Demo_Bitmap(testtime, ptr_bitmap) | iteration
' Continuously redraws bitmap at address ptr_bitmap
#ifndef GFX_DIRECT
    ser.str(string("Demo_Bitmap - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        oled.bitmap(ptr_bitmap, BUFFSZ, 0)
        oled.update{}
        iteration++

    report(testtime, iteration)
#endif

PUB Demo_BouncingBall(testtime, radius) | iteration, bx, by, dx, dy
' Draws a simple ball bouncing off screen edges
' Pick a random screen location to start from, and a random direction
    bx := (rnd(XMAX) // (WIDTH - radius * 4)) + radius * 2
    by := (rnd(YMAX) // (HEIGHT - radius * 4)) + radius * 2
    dx := rnd(4) // 2 * 2 - 1
    dy := rnd(4) // 2 * 2 - 1

    ser.str(string("Demo_BouncingBall - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        bx += dx
        by += dy

        ' if any edge of the screen is reached, change direction
        if (by =< radius OR by => HEIGHT - radius)
            dy *= -1                            ' top/bottom edges
        if (bx =< radius OR bx => WIDTH - radius)
            dx *= -1                            ' left/right edges

        oled.circle(bx, by, radius, oled#MAX_COLOR, false)
        oled.update{}
        iteration++
        oled.clear{}

    report(testtime, iteration)

PUB Demo_Box(testtime) | iteration, c
' Draws random lines
    ser.str(string("Demo_Box - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := rnd(oled#MAX_COLOR)
        oled.box(rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c, FALSE)
        oled.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_BoxFilled(testtime) | iteration, c
' Draws random lines
    ser.str(string("Demo_BoxFilled - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := rnd(oled#MAX_COLOR)
        oled.box(rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c, TRUE)
        oled.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_Circle(testtime) | iteration, x, y, r
' Draws circles at random locations
    ser.str(string("Demo_Circle - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        x := rnd(XMAX)
        y := rnd(YMAX)
        r := rnd(YMAX/2)
        oled.circle(x, y, r, rnd(oled#MAX_COLOR), false)
        oled.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_Contrast(reps, delay_ms) | contrast_level
' Fades out and in display contrast
    ser.str(string("Demo_Contrast - N/A"))

    repeat reps
        repeat contrast_level from 255 to 1
            oled.contrast(contrast_level)
            time.msleep(delay_ms)
        repeat contrast_level from 0 to 254
            oled.contrast(contrast_level)
            time.msleep(delay_ms)

    ser.newline{}

PUB Demo_Greet{}
' Display the banner/greeting on the OLED
    oled.fgcolor(oled#MAX_COLOR)
    oled.bgcolor(0)
    oled.position(0, 0)
    oled.strln(string("SSD1351 on the"))
    oled.strln(string("Parallax"))
    oled.printf1(string("P8X32A @ %dMHz\n"), clkfreq/1_000_000)
    oled.printf2(string("%dx%d"), WIDTH, HEIGHT)
    oled.update{}

PUB Demo_Line(testtime) | iteration
' Draws random lines with color -1 (invert)
    ser.str(string("Demo_Line - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        oled.line(rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), rnd(oled#MAX_COLOR))
        oled.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_LineSweepX(testtime) | iteration, x
' Draws lines top left to lower-right, sweeping across the screen, then
'  from the top-down
    x := 0

    ser.str(string("Demo_LineSweepX - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        x++
        if x > XMAX
            x := 0
        oled.line(x, 0, XMAX-x, YMAX, x)
        oled.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_LineSweepY(testtime) | iteration, y
' Draws lines top left to lower-right, sweeping across the screen, then
'  from the top-down
    y := 0

    ser.str(string("Demo_LineSweepY - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        y++
        if y > YMAX
            y := 0
        oled.line(XMAX, y, 0, YMAX-y, y)
        oled.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_MEMScroller(testtime, start_addr, end_addr) | iteration, ptr
' Dumps Propeller Hub RAM (and/or ROM) to the display buffer
#ifndef GFX_DIRECT
    ptr := start_addr

    ser.str(string("Demo_MEMScroller - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        oled.bitmap(ptr, BUFFSZ, 0)             ' show 1 screenful of RAM
        ptr += BPL                              ' advance memory pointer
        if ptr > end_addr                       ' wrap around if the end of
            ptr := start_addr                   '   Propeller RAM is reached
        oled.update{}
        iteration++

    report(testtime, iteration)
#endif

PUB Demo_Plot(testtime) | iteration, x, y
' Draws random pixels to the screen, with color -1 (invert)
    ser.str(string("Demo_Plot - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        oled.plot(rnd(XMAX), rnd(YMAX), rnd(oled#MAX_COLOR))
        oled.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_Sinewave(testtime) | iteration, x, y, modifier, offset, div
' Draws a sine wave the length of the screen, influenced by the system counter
    ser.str(string("Demo_Sinewave - "))

    case HEIGHT
        32:
            div := 4096
        64:
            div := 2048
        other:
            div := 2048

    offset := YMAX/2                            ' Offset for Y axis

    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        repeat x from 0 to XMAX
            modifier := (||(cnt) / 1_000_000)   ' system counter as modifier
            y := offset + sin(x * modifier) / div
            oled.plot(x, y, oled#MAX_COLOR)

        oled.update{}
        iteration++
        oled.clear{}

    report(testtime, iteration)

PUB Demo_SeqText(testtime) | iteration, ch
' Sequentially draws the whole font table to the screen, then random characters
    oled.fgcolor(oled#MAX_COLOR)
    oled.bgcolor(0)
    ch := 32
    oled.position(0, 0)

    ser.str(string("Demo_SeqText - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        oled.char(ch)
        ch++
        if ch > 127
            ch := 32
        oled.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_RndText(testtime) | iteration

    oled.position(0, 0)

    ser.str(string("Demo_RndText - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        oled.fgcolor(rnd(oled#MAX_COLOR))
        oled.bgcolor(rnd(oled#MAX_COLOR))
        oled.char(32 #> rnd(127))
        oled.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_TriWave(testtime) | iteration, x, y, ydir
' Draws a simple triangular wave
    ydir := 1
    y := 0

    ser.str(string("Demo_TriWave - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        repeat x from 0 to XMAX
            if y == YMAX
                ydir := -1
            if y == 0
                ydir := 1
            y := y + ydir
            oled.plot(x, y, oled#MAX_COLOR)
        oled.update{}
        iteration++
        oled.clear{}

    report(testtime, iteration)

PUB Demo_Wander(testtime) | iteration, x, y, d
' Draws randomly wandering pixels
    _rndseed := cnt
    x := XMAX/2                                 ' start at screen center
    y := YMAX/2

    ser.str(string("Demo_Wander - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        case d := rnd(4)                        ' which way to move?
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
        oled.plot(x, y, rnd(oled#MAX_COLOR))
        oled.update{}
        iteration++

    report(testtime, iteration)

PRI Sin(angle): sine
' Return the sine of angle
    sine := angle << 1 & $FFE
    if angle & $800
       sine := word[$F000 - sine]   ' Use sine table from ROM
    else
       sine := word[$E000 + sine]
    if angle & $1000
       -sine

PRI RND(maxval): r
' Return random number up to maxval
    return ||(? _rndseed) // maxval

PRI Report(testtime, iterations)

    ser.printf2(string("Total iterations: %d, iterations/sec: %d, ms/iteration: "),{
}   iterations, iterations / (testtime/1000))
    decimal((testtime * 1_000) / iterations, 1_000)
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

    repeat
        repeat until _timer_set
        time_left := _timer_set

        repeat
            time_left--
            time.msleep(1)
        while time_left > 0
        _timer_set := 0

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifndef GFX_DIRECT
    if oled.startx(CS_PIN, CLK_PIN, DIN_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, @_framebuff)
#else
    if oled.startx(CS_PIN, CLK_PIN, DIN_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, 0)
#endif
        ser.strln(string("SSD1351 driver started"))
        oled.preset_128xhiperf{}
        oled.fontaddress(fnt5x8.baseaddr{})
        oled.fontscale(1)
        oled.fontspacing(1, 1)
        oled.fontsize(fnt5x8#WIDTH, fnt5x8#HEIGHT)
    else
        ser.strln(string("SSD1351 driver failed to start - halting"))
        repeat
    _timer_cog := cognew(cog_timer{}, @_stack_timer)

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
