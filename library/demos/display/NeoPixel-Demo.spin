{
    --------------------------------------------
    Filename: NeoPixel-Demo.spin
    Description: Demo of the NeoPixel driver
    Author: Jesse Burt
    Copyright (c) 2020
    Started: Jun 18, 2020
    Updated: Jun 18, 2020
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

    NEOPIX_PIN  = 23
    NEOPIX_MODEL= $6812_32
' --

    WIDTH       = 87
    HEIGHT      = 1
    BPP         = 4
    BPL         = WIDTH * BPP
    BUFFSZ      = (WIDTH * HEIGHT) * BPP  'in BYTEs - 12288
    XMAX        = WIDTH - 1
    YMAX        = HEIGHT - 1

OBJ

    cfg         : "core.con.boardcfg.activityboard"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    io          : "io"
    neopixel    : "display.led.addressable.neopixel.spin"
    int         : "string.integer"
    fnt         : "font.5x8"

VAR

    long _stack_timer[50]
    long _timer_set
    long _rndSeed
    byte _framebuff[BUFFSZ], _offscreen[BUFFSZ]
    byte _timer_cog, _ser_cog, _neopixel_cog

PUB Main | time_ms, r

    Setup
    neopixel.ClearAll

    Demo_Greet
    time.Sleep (5)
    neopixel.ClearAll

    time_ms := 10_000

    ser.position (0, 3)

    Demo_SineWave (time_ms)
    neopixel.ClearAll

    Demo_TriWave (time_ms)
    neopixel.ClearAll

    Demo_MEMScroller(time_ms, $0000, $FFFF-BUFFSZ)
    neopixel.ClearAll

    Demo_Bitmap (time_ms, $8000)
    neopixel.ClearAll

    Demo_Box (time_ms)
    neopixel.ClearAll

    Demo_BoxFilled (time_ms)
    neopixel.ClearAll

    Demo_LineSweepX(time_ms)
    neopixel.ClearAll

    Demo_LineSweepY(time_ms)
    neopixel.ClearAll

    Demo_Line (time_ms)
    neopixel.ClearAll

    Demo_Plot (time_ms)
    neopixel.ClearAll

    Demo_BouncingBall (time_ms, 5)
    neopixel.ClearAll

    Demo_Circle(time_ms)
    neopixel.ClearAll

    Demo_Wander (time_ms)
    neopixel.ClearAll

    Demo_SeqText (time_ms)
    neopixel.ClearAll

    Demo_RndText (time_ms)

    neopixel.ClearAll

    Stop
    FlashLED(LED, 100)

PUB Demo_Bitmap(testtime, bitmap_addr) | iteration
' Continuously redraws bitmap at address bitmap_addr
    ser.str(string("Demo_Bitmap - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        neopixel.Bitmap (bitmap_addr, BUFFSZ, 0)
        neopixel.Update
        iteration++

    Report(testtime, iteration)
    return iteration

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
        bx += dx
        by += dy
        if (by =< radius OR by => HEIGHT - radius)          'If we reach the top or bottom of the screen,
            dy *= -1                                        ' change direction
        if (bx =< radius OR bx => WIDTH - radius)           'Ditto with the left or right sides
            dx *= -1

        neopixel.Circle (bx, by, radius, $00_00_00_FF)
        neopixel.Update
        iteration++
        neopixel.Clear

    Report(testtime, iteration)
    return iteration

PUB Demo_Box (testtime) | iteration, c
' Draws random lines
    ser.str(string("Demo_Box - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        ?c
        neopixel.Box (rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c, FALSE)
        neopixel.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_BoxFilled (testtime) | iteration, c, x1, y1, x2, y2
' Draws random lines
    ser.str(string("Demo_BoxFilled - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        ?c
        neopixel.Box (rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c, TRUE)
        neopixel.Update
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
        ?c
        neopixel.Circle (x, y, r, c)
        neopixel.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Greet
' Display the banner/greeting on the OLED
    neopixel.FGColor($00_00_00_FF)
    neopixel.BGColor(0)
    neopixel.Position (0, 0)
    neopixel.Str (string("Neopixels on the"))

    neopixel.Position (0, 1)
    neopixel.Str (string("Parallax"))

    neopixel.Position (0, 2)
    neopixel.Str (string("P8X32A @ "))

    neopixel.Position (0, 3)
    neopixel.Str (int.Dec(clkfreq/1_000_000))
    neopixel.Str (string("MHz"))

    neopixel.Position (0, 4)
    neopixel.Str (int.DecPadded (WIDTH, 3))

    neopixel.Position (3, 4)
    neopixel.Str (string("x"))

    neopixel.Position (4, 4)
    neopixel.Str (int.DecPadded (HEIGHT, 2))
    neopixel.Update

PUB Demo_Line (testtime) | iteration, c
' Draws random lines with color -1 (invert)
    ser.str(string("Demo_Line - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        ?c
        neopixel.Line (rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c)
        neopixel.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_LineSweepX (testtime) | iteration, x, c
' Draws lines top left to lower-right, sweeping across the screen, then
'  from the top-down
    x := c := 0

    ser.str(string("Demo_LineSweepX - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        x++
        if x > XMAX
            x := 0
        c := (c + 16) << 8
        neopixel.Line (x, 0, XMAX-x, YMAX, c)
        neopixel.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_LineSweepY (testtime) | iteration, y, c
' Draws lines top left to lower-right, sweeping across the screen, then
'  from the top-down
    y := c := 0

    ser.str(string("Demo_LineSweepY - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        y++
        if y > YMAX
            y := 0
        c := (c + 16) << 8
        neopixel.Line (XMAX, y, 0, YMAX-y, c)
        neopixel.Update
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
        neopixel.Bitmap (pos, BUFFSZ, 0)
        neopixel.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Plot(testtime) | iteration, x, y, c
' Draws random pixels to the screen, with color -1 (invert)
    ser.str(string("Demo_Plot - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        ?c
        neopixel.Plot (rnd(XMAX), rnd(YMAX), c)
        neopixel.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Sinewave(testtime) | iteration, x, y, modifier, offset, div
' Draws a sine wave the length of the screen, influenced by the system counter
    ser.str(string("Demo_Sinewave - "))

    div := 8192
    offset := YMAX/2                                    ' Offset for Y axis

    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        repeat x from 0 to XMAX
            modifier := (||cnt / 1_000_000)           ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            neopixel.Plot(x, y, $FFFF)

        neopixel.Update
        iteration++
        neopixel.Clear

    Report(testtime, iteration)
    return iteration

PUB Demo_SeqText(testtime) | iteration, col, row, ch, st, fg, bg
' Sequentially draws the whole font table to the screen, then random characters
'    neopixel.FGColor(1)
'    neopixel.BGColor(0)
'    maxcol := (WIDTH/neopixel.FontWidth)-1
'    maxrow := (HEIGHT/neopixel.FontHeight)-1
    ch := $20

    ser.str(string("Demo_SeqText - "))
    _timer_set := testtime
    iteration := 0
    neopixel.position(0, 0)
    repeat while _timer_set
        ch++
        if ch > $7F
            ch := $20
        ?fg
        ?bg
        neopixel.FGColor(fg)
        neopixel.BGColor(bg)
        neopixel.Char (ch)
        neopixel.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_RndText(testtime) | iteration, col, row, st, fg, bg

    neopixel.FGColor(1)
    neopixel.BGColor(0)

    ser.str(string("Demo_RndText - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        ?fg
        ?bg
        neopixel.FGColor(fg)
        neopixel.BGColor(bg)
        neopixel.Position (col, row)
        neopixel.Char (32 #> rnd(127))
        neopixel.Update
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
        repeat x from 0 to XMAX
            if y == YMAX
                ydir := -1
            if y == 0
                ydir := 1
            y := y + ydir
            neopixel.Plot (x, y, $FFFF)
        neopixel.Update
        iteration++
        neopixel.Clear

    Report(testtime, iteration)
    return iteration

PUB Demo_Wander(testtime) | iteration, x, y, d, c
' Draws randomly wandering pixels
    _rndSeed := cnt
    x := XMAX/2
    y := YMAX/2

    ser.str(string("Demo_Wander - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        case d := rnd(4)
            1:
                x += 2
                if x > XMAX
                    x := 0
            2:
                x -= 2
                if x < 0
                    x := XMAX
            3:
                y += 2
                if y > YMAX
                    y := 0
            4:
                y -= 2
                if y < 0
                    y := YMAX
        ?c
        neopixel.Plot (x, y, c)
        neopixel.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB RND(max_val) | i
' Returns a random number between 0 and max_val
    i := ?_rndseed
    i >>= 16
    i *= (max_val + 1)
    i >>= 16

    return i

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

    ser.str(string(", Iterations/ms: "))
    Decimal( (iterations * 1_000) / testtime, 1_000)
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

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if _neopixel_cog := neopixel.Start (NEOPIX_PIN, WIDTH, HEIGHT, NEOPIX_MODEL, @_framebuff)
        ser.str(string("Neopixel driver started", ser#CR, ser#LF))
        neopixel.DrawTo(@_offscreen)
        neopixel.FontAddress(fnt.BaseAddr)
        neopixel.FontSize(6, 8)
        neopixel.ClearAll
    else
        ser.str(string("Neopixel driver failed to start - halting", ser#CR, ser#LF))
        Stop

    _timer_cog := cognew(cog_Timer, @_stack_timer)

PUB Stop

    neopixel.Stop
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
