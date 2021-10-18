{
    --------------------------------------------
    Filename: VGA Bitmap-Demo.spin
    Description: Demo of the VGA Bitmap driver
    Author: Jesse Burt
    Copyright (c) 2021
    Started: Apr 24, 2020
    Updated: Oct 18, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    VGA_PINGROUP= 2                                         ' 0, 1, 2, 3 (VGA pin base = pingroup * 8)
' --

    WIDTH       = 160
    HEIGHT      = 120
    BPP         = 1
    BPL         = WIDTH * BPP
    BUFFSZ      = (WIDTH * HEIGHT)
    XMAX        = WIDTH - 1
    YMAX        = HEIGHT - 1

OBJ

    cfg         : "core.con.boardcfg.quickstart-hib"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    io          : "io"
    display     : "display.vga.bitmap.160x120"
    int         : "string.integer"
    fnt         : "font.5x8"

VAR

    long _stack_timer[50]
    long _timer_set
    long _rnd_seed
    byte _timer_cog
    byte _framebuff[BUFFSZ]

PUB Main | time_ms, r

    Setup
    display.ClearAll

    Demo_Greet
    time.Sleep (5)
    display.ClearAll

    time_ms := 10_000

    ser.position (0, 3)

    Demo_SineWave (time_ms)
    display.ClearAll

    Demo_TriWave (time_ms)
    display.ClearAll

    Demo_MEMScroller(time_ms, $0000, $FFFF-BUFFSZ)
    display.ClearAll

    Demo_Bitmap (time_ms, $8000)
    display.ClearAll

    Demo_Box(time_ms)
    display.ClearAll

    Demo_BoxFilled(time_ms)
    display.ClearAll

    Demo_LineSweepX(time_ms)
    display.ClearAll

    Demo_LineSweepY(time_ms)
    display.ClearAll

    Demo_Line (time_ms)
    display.ClearAll

    Demo_Plot (time_ms)
    display.ClearAll

    Demo_BouncingBall (time_ms, 5)
    display.ClearAll

    Demo_Circle(time_ms)
    display.ClearAll

    Demo_Wander (time_ms)
    display.ClearAll

    Demo_SeqText (time_ms)
    display.ClearAll

    Demo_RndText (time_ms)

    display.ClearAll

    Stop
    FlashLED(LED, 100)

PUB Demo_BouncingBall(testtime, radius) | iteration, bx, by, dx, dy
' Draws a simple ball bouncing off screen edges
    bx := (rnd(XMAX) // (WIDTH - radius * 4)) + radius * 2  'Pick a random screen location to
    by := (rnd(YMAX) // (HEIGHT - radius * 4)) + radius * 2 ' start from
    dx := rnd(4) // 2 * 2 - 1                               'Pick a random direction to
    dy := rnd(4) // 2 * 2 - 1                               ' start moving

    ser.str(string("Demo_BouncingBall - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        display.Clear
        bx += dx
        by += dy
        if (by =< radius OR by => HEIGHT - radius)          'If we reach the top or bottom of the screen,
            dy *= -1                                        ' change direction
        if (bx =< radius OR bx => WIDTH - radius)           'Ditto with the left or right sides
            dx *= -1
        display.WaitVSync
        display.Circle (bx, by, radius, display#MAX_COLOR, false)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Bitmap(testtime, bitmap_addr) | iteration
' Continuously redraws bitmap at address bitmap_addr
    ser.str(string("Demo_Bitmap - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        display.Bitmap (bitmap_addr, 0, 0, XMAX, YMAX)

        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Box (testtime) | iteration, c
' Draws random boxes
    ser.str(string("Demo_Box - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := rnd(display#MAX_COLOR)
        display.Box (rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c, FALSE)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_BoxFilled (testtime) | iteration, c
' Draws random filled boxes
    ser.str(string("Demo_BoxFilled - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := rnd(display#MAX_COLOR)
        display.Box (rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c, TRUE)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Circle(testtime) | iteration, x, y, r, c
' Draws circles at random locations
    ser.str(string("Demo_Circle - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        x := rnd(XMAX)
        y := rnd(YMAX)
        r := rnd(YMAX/2)
        c := rnd(display#MAX_COLOR)
        display.Circle (x, y, r, c, false)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Greet
' Display the banner/greeting on the OLED
    display.FGColor(display#MAX_COLOR)
    display.BGColor(0)
    display.Position (0, 0)
    display.Str (string("VGA Bitmap 6bpp on the"))

    display.Position (0, 1)
    display.Str (string("Parallax"))

    display.Position (0, 2)
    display.Str (string("P8X32A @ "))

    display.Position (0, 3)
    display.Str (int.Dec(clkfreq/1_000_000))
    display.Str (string("MHz"))

    display.Position (0, 4)
    display.Str (int.DecPadded (WIDTH, 3))

    display.Position (3, 4)
    display.Str (string("x"))

    display.Position (4, 4)
    display.Str (int.DecPadded (HEIGHT, 2))

PUB Demo_Line (testtime) | iteration, c
' Draws random lines with color -1 (invert)
    ser.str(string("Demo_Line - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := rnd(display#MAX_COLOR)
        display.Line (rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_LineSweepX (testtime) | iteration, x
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
        display.Line (x, 0, XMAX-x, YMAX, x)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_LineSweepY (testtime) | iteration, y
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
        display.Line (XMAX, y, 0, YMAX-y, y)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_MEMScroller(testtime, start_addr, end_addr) | iteration, pos, st, en
' Dumps Propeller Hub RAM (and/or ROM) to the display buffer
    pos := start_addr

    ser.str(string("Demo_MEMScroller - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        pos += BPL
        if pos >end_addr
            pos := start_addr
        display.WaitVSync
        display.Bitmap (pos, 0, 0, XMAX, YMAX)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Plot(testtime) | iteration, x, y, c
' Draws random pixels to the screen, with color -1 (invert)
    ser.str(string("Demo_Plot - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        display.Plot (rnd(XMAX), rnd(YMAX), rnd(display#MAX_COLOR))
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Sinewave(testtime) | iteration, x, y, modifier, offset, div
' Draws a sine wave the length of the screen, influenced by the system counter
    ser.str(string("Demo_Sinewave - "))

    div := 2048
    offset := YMAX/2                                    ' Offset for Y axis

    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        display.WaitVSync
        repeat x from 0 to XMAX
            modifier := (||cnt / 1_000_000)           ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            display.Plot(x, y, display#MAX_COLOR)
            iteration++
        display.Clear

    Report(testtime, iteration)
    return iteration

PUB Demo_SeqText(testtime) | iteration, ch, fg, bg
' Sequentially draws the whole font table to the screen, then random characters
    ch := $20

    ser.str(string("Demo_SeqText - "))
    _timer_set := testtime
    iteration := 0
    display.Position(0, 0)

    repeat while _timer_set
        ch++
        if ch > $7F
            ch := $20
        fg++
        if fg > display#MAX_COLOR
            fg := 0
        bg--
        if bg < 0
            bg := display#MAX_COLOR
        display.FGColor(fg)
        display.BGColor(bg)
        display.Char (ch)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_RndText(testtime) | iteration

    ser.str(string("Demo_RndText - "))
    _timer_set := testtime
    iteration := 0
    display.Position(0, 0)
    repeat while _timer_set
        display.FGColor(rnd(display#MAX_COLOR))
        display.BGColor(rnd(display#MAX_COLOR))
        display.Char ($20 #> rnd($7F))
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_TriWave(testtime) | iteration, x, y, ydir
' Draws a simple triangular wave
    ydir := 1
    y := 0

    ser.str(string("Demo_TriWave - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        display.Clear
        display.WaitVSync
        repeat x from 0 to XMAX
            y := y+ydir

            if y => YMAX or y =< 0
                ydir *= -1
            display.Plot (x, y, display#MAX_COLOR)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Wander(testtime) | iteration, x, y, d, c
' Draws randomly wandering pixels
    x := XMAX/2
    y := YMAX/2

    ser.str(string("Demo_Wander - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        case d := rnd(4)
            0:
                x += 2
                if x > XMAX
                    x := 0
            1:
                x -= 2
                if x < 0
                    x := XMAX
            2:
                y += 2
                if y > YMAX
                    y := 0
            3:
                y -= 2
                if y < 0
                    y := YMAX
        c := rnd(display#MAX_COLOR)
        display.Plot (x, y, c)
        iteration++

    Report(testtime, iteration)
    return iteration

PUB RND(max_val): r
' Returns a random number between 0 and max_val
    r := ||(?_rnd_seed // max_val)

PUB Sin(angle)
' Sin angle is 13-bit; Returns a 16-bit signed value
    result := angle << 1 & $FFE
    if angle & $800
       result := word[$F000 - result]
    else
       result := word[$E000 + result]
    if angle & $1000
       -result

PRI Report(testtime, iterations)

    ser.str(string("Total iterations: "))
    ser.dec(iterations)

    ser.str(string(", Iterations/sec: "))
    ser.dec(iterations / (testtime/1000))

    ser.str(string(", ms/iteration: "))
    Decimal( (testtime * 1_000) / iterations, 1_000)
    ser.newline

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
    part := int.DecZeroed(||(scaled // divisor), places)

    ser.Dec (whole)
    ser.Char (".")
    ser.Str (part)

PRI cog_Timer | time_left

    repeat
        repeat until _timer_set
        time_left := _timer_set

        repeat
            time_left--
            time.MSleep(1)
        while time_left > 0
        _timer_set := 0

PUB Setup

    repeat until ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if display.Start (VGA_PINGROUP, WIDTH, HEIGHT, @_framebuff)
        ser.str(string("VGA Bitmap driver started", ser#CR, ser#LF))
        display.FontAddress(fnt.BaseAddr)
        display.FontSize(6, 8)
    else
        ser.str(string("VGA Bitmap driver failed to start - halting", ser#CR, ser#LF))
        Stop
    _rnd_seed := cnt
    _timer_cog := cognew(cog_Timer, @_stack_timer)

PUB Stop

    display.Stop
    cogstop(_timer_cog)

#include "lib.utility.spin"


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
