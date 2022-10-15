{
    --------------------------------------------
    Filename: SmartLED-Demo.spin
    Description: Demo of the SmartLED driver
    Author: Jesse Burt
    Copyright (c) 2021
    Started: Jun 13, 2021
    Updated: Oct 18, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    SMLED_PIN  = 0
    SMLED_MODEL= $6812_32                      ' $2811, $2812, $2812B, $2813,
                                                ' $6812_24, $6812_32, $1803

    WIDTH       = 87                            ' width/length of strip
    HEIGHT      = 1                             ' height (1 = simple strip)
                                                ' total must be between
                                                '   1 and 1024, inclusive
' --
    BPP         = 4
    BPL         = WIDTH * BPP
    BUFFSZ      = ((WIDTH * HEIGHT) * BPP) + 1
    XMAX        = WIDTH - 1
    YMAX        = HEIGHT - 1

OBJ

    cfg : "boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    disp: "display.led.smart.spin"
    int : "string.integer"
    fnt : "font.5x8"
    math: "math.int"

VAR

    long _stack_timer[50]
    long _timer_set
    long _rndseed
    long _framebuff[BUFFSZ], _offscreen[BUFFSZ]
    byte _timer_cog

PUB Main{} | time_ms

    setup{}
    disp.clear{}

    demo_greet{}
    time.sleep(5)
    disp.clear{}

    time_ms := 5_000

    ser.position(0, 3)

    demo_sinewave(time_ms)
    disp.clear{}

    demo_triwave(time_ms)
    disp.clear{}

    demo_memscroller(time_ms, $0000, $FFFF-BUFFSZ)
    disp.clear{}

    demo_bitmap(time_ms, $8000)
    disp.clear{}

    demo_box(time_ms)
    disp.clear{}

    demo_boxfilled(time_ms)
    disp.clear{}

    demo_linesweepx(time_ms)
    disp.clear{}

    demo_linesweepy(time_ms)
    disp.clear{}

    demo_line(time_ms)
    disp.clear{}

    demo_plot(time_ms)
    disp.clear{}

    demo_bouncingball(time_ms, 5)
    disp.clear{}

    demo_circle(time_ms)
    disp.clear{}

    demo_wander(time_ms)
    disp.clear{}

    demo_seqtext(time_ms)
    disp.clear{}

    demo_rndtext(time_ms)

    repeat

PUB Demo_Bitmap(testtime, ptr_bitmap) | iteration
' Continuously redraws bitmap at address ptr_bitmap
    ser.str(string("Demo_Bitmap - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        disp.bitmap(ptr_bitmap, 0, 0, XMAX, YMAX)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_BouncingBall(testtime, radius) | iteration, bx, by, dx, dy
' Draws a simple ball bouncing off screen edges
' Pick a random screen location to start from, and a random direction
    bx := (math.rndi(XMAX) // (WIDTH - radius * 4)) + radius * 2
    by := (math.rndi(YMAX) // (HEIGHT - radius * 4)) + radius * 2
    dx := math.rndi(4) // 2 * 2 - 1
    dy := math.rndi(4) // 2 * 2 - 1

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

        disp.circle(bx, by, radius, disp#MAX_COLOR, false)
        disp.update{}
        iteration++
        disp.clear{}

    report(testtime, iteration)

PUB Demo_Box(testtime) | iteration, c
' Draws random lines
    ser.str(string("Demo_Box - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := math.rndi(disp#MAX_COLOR)
        disp.box(math.rndi(XMAX), math.rndi(YMAX), math.rndi(XMAX), math.rndi(YMAX), c, FALSE)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_BoxFilled(testtime) | iteration, c
' Draws random lines
    ser.str(string("Demo_BoxFilled - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := math.rndi(disp#MAX_COLOR)
        disp.box(math.rndi(XMAX), math.rndi(YMAX), math.rndi(XMAX), math.rndi(YMAX), c, TRUE)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_Circle(testtime) | iteration, x, y, r
' Draws circles at random locations
    ser.str(string("Demo_Circle - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        x := math.rndi(XMAX)
        y := math.rndi(YMAX)
        r := math.rndi(YMAX/2)
        disp.circle(x, y, r, math.rndi(disp#MAX_COLOR), false)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_Greet{}
' Display the banner/greeting on the LEDs
    disp.fgcolor(disp#MAX_COLOR)
    disp.bgcolor(0)
    disp.position(0, 0)
    disp.strln(string("SmartLED on the"))
    disp.strln(string("Parallax"))
    disp.printf1(string("P8X32A @ %dMHz\n"), clkfreq/1_000_000)
    disp.printf2(string("%dx%d"), WIDTH, HEIGHT)
    disp.update{}

PUB Demo_Line(testtime) | iteration
' Draws random lines with color -1 (invert)
    ser.str(string("Demo_Line - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        disp.line(math.rndi(XMAX), math.rndi(YMAX), math.rndi(XMAX), math.rndi(YMAX), math.rndi(disp#MAX_COLOR))
        disp.update{}
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
        disp.line(x, 0, XMAX-x, YMAX, x)
        disp.update{}
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
        disp.line(XMAX, y, 0, YMAX-y, y)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_MEMScroller(testtime, start_addr, end_addr) | iteration, ptr
' Dumps Propeller Hub RAM (and/or ROM) to the display buffer
    ptr := start_addr

    ser.str(string("Demo_MEMScroller - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        disp.bitmap(ptr, 0, 0, XMAX, YMAX)      ' show 1 screenful of RAM
        ptr += BPL                              ' advance memory pointer
        if ptr > end_addr                       ' wrap around if the end of
            ptr := start_addr                   '   Propeller RAM is reached
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_Plot(testtime) | iteration, x, y
' Draws random pixels to the screen, with color -1 (invert)
    ser.str(string("Demo_Plot - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        disp.plot(math.rndi(XMAX), math.rndi(YMAX), math.rndi(disp#MAX_COLOR))
        disp.update{}
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
            disp.plot(x, y, disp#MAX_COLOR)

        disp.update{}
        iteration++
        disp.clear{}

    report(testtime, iteration)

PUB Demo_SeqText(testtime) | iteration, ch
' Sequentially draws the whole font table to the screen, then random characters
    disp.fgcolor(disp#MAX_COLOR)
    disp.bgcolor(0)
    ch := 32
    disp.position(0, 0)

    ser.str(string("Demo_SeqText - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        disp.char(ch)
        ch++
        if ch > 127
            ch := 32
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_RndText(testtime) | iteration

    disp.position(0, 0)

    ser.str(string("Demo_RndText - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        disp.fgcolor(math.rndi(disp#MAX_COLOR))
        disp.bgcolor(math.rndi(disp#MAX_COLOR))
        disp.char(32 #> math.rndi(127))
        disp.update{}
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
            disp.plot(x, y, disp#MAX_COLOR)
        disp.update{}
        iteration++
        disp.clear{}

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

    if disp.start(SMLED_PIN, WIDTH, HEIGHT, SMLED_MODEL, @_framebuff)
        ser.strln(string("SmartLED driver started"))
        disp.drawto(@_offscreen)
        disp.fontaddress(fnt.baseaddr{})
        disp.fontsize(6, 8)
        disp.clear{}
    else
        ser.strln(string("SmartLED driver failed to start - halting"))
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
