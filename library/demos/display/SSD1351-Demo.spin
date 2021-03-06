{
    --------------------------------------------
    Filename: SSD1351-Demo.spin
    Description: Demo of the SSD1351 driver
    Author: Jesse Burt
    Copyright (c) 2020
    Started: Mar 11, 2019
    Updated: Mar 29, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    RES_PIN     = 4
    DC_PIN      = 3
    CS_PIN      = 2
    CLK_PIN     = 1
    DIN_PIN     = 0

    WIDTH       = 128
    HEIGHT      = 64
    BPP         = 2
    BPL         = WIDTH * BPP
    BUFFSZ      = (WIDTH * HEIGHT) * 2  'in BYTEs - 12288
    XMAX        = WIDTH - 1
    YMAX        = HEIGHT - 1

OBJ

    cfg         : "core.con.boardcfg.activityboard"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    io          : "io"
    oled        : "display.oled.ssd1351.spi"
    int         : "string.integer"
    fnt         : "font.5x8"

VAR

    long _stack_timer[50]
    long _timer_set
    long _rndSeed
    byte _framebuff[BUFFSZ]
    byte _timer_cog, _ser_cog, _oled_cog

PUB Main | time_ms, r

    Setup
    oled.ClearAll

    oled.MirrorH(FALSE)
    oled.MirrorV(FALSE)

    Demo_Greet
    time.Sleep (5)
    oled.ClearAll

    time_ms := 10_000

    ser.position (0, 3)

    Demo_SineWave (time_ms)
    oled.ClearAll

    Demo_TriWave (time_ms)
    oled.ClearAll

    Demo_MEMScroller(time_ms, $0000, $FFFF-BUFFSZ)
    oled.ClearAll

    Demo_Bitmap (time_ms, $8000)
    oled.ClearAll

    Demo_LineSweepX(time_ms)
    oled.ClearAll

    Demo_LineSweepY(time_ms)
    oled.ClearAll

    Demo_Line (time_ms)
    oled.ClearAll

    Demo_Plot (time_ms)
    oled.ClearAll

    Demo_PlotAccel (time_ms)
    oled.ClearAll

    Demo_BouncingBall (time_ms, 5)
    oled.ClearAll

    Demo_Circle(time_ms)
    oled.ClearAll

    Demo_Wander (time_ms)
    oled.ClearAll

    Demo_SeqText (time_ms)
    oled.ClearAll

    Demo_RndText (time_ms)

    Demo_Contrast(2, 1)
    oled.ClearAll

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
        bx += dx
        by += dy
        if (by =< radius OR by => HEIGHT - radius)          'If we reach the top or bottom of the screen,
            dy *= -1                                        ' change direction
        if (bx =< radius OR bx => WIDTH - radius)           'Ditto with the left or right sides
            dx *= -1

        oled.Circle (bx, by, radius, $FFFF)
        oled.Update
        iteration++
        oled.Clear

    Report(testtime, iteration)
    return iteration

PUB Demo_Bitmap(testtime, bitmap_addr) | iteration
' Continuously redraws bitmap at address bitmap_addr
    ser.str(string("Demo_Bitmap - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        oled.Bitmap (bitmap_addr, BUFFSZ, 0)
        oled.Update
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
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Circle (x, y, r, c)
        oled.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Contrast(reps, delay_ms) | contrast_level
' Fades out and in display contrast
    ser.str(string("Demo_Contrast - N/A"))

    repeat reps
        repeat contrast_level from 255 to 1
            oled.Contrast (contrast_level)
            time.MSleep (delay_ms)
        repeat contrast_level from 0 to 254
            oled.Contrast (contrast_level)
            time.MSleep (delay_ms)

    ser.newline

PUB Demo_Greet
' Display the banner/greeting on the OLED
    oled.FGColor($FFFF)
    oled.BGColor(0)
    oled.Position (0, 0)
    oled.Str (string("SSD1351 on the"))

    oled.Position (0, 1)
    oled.Str (string("Parallax"))

    oled.Position (0, 2)
    oled.Str (string("P8X32A @ "))

    oled.Position (0, 3)
    oled.Str (int.Dec(clkfreq/1_000_000))
    oled.Str (string("MHz"))

    oled.Position (0, 4)
    oled.Str (int.DecPadded (WIDTH, 3))

    oled.Position (3, 4)
    oled.Str (string("x"))

    oled.Position (4, 4)
    oled.Str (int.DecPadded (HEIGHT, 2))
    oled.Update

PUB Demo_Line (testtime) | iteration, c
' Draws random lines with color -1 (invert)
    ser.str(string("Demo_Line - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Line (rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c)
        oled.Update
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
        oled.Line (x, 0, XMAX-x, YMAX, x)
        oled.Update
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
        oled.Line (XMAX, y, 0, YMAX-y, y)
        oled.Update
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
        oled.Bitmap (pos, BUFFSZ, 0)
        oled.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_Plot(testtime) | iteration, x, y, c
' Draws random pixels to the screen, with color -1 (invert)
    ser.str(string("Demo_Plot - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Plot (rnd(XMAX), rnd(YMAX), c)
        oled.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_PlotAccel(testtime) | iteration, x, y, c
' Draws random pixels (accelerated/native) to the screen, with color -1 (invert)
    ser.str(string("Demo_PlotAccel - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.PlotAccel (rnd(XMAX), rnd(YMAX), c)
        iteration++

    oled.DisplayBounds(0, 0, XMAX, YMAX)
    Report(testtime, iteration)
    return iteration

PUB Demo_Sinewave(testtime) | iteration, x, y, modifier, offset, div
' Draws a sine wave the length of the screen, influenced by the system counter
    ser.str(string("Demo_Sinewave - "))

    div := 3072
    offset := YMAX/2                                    ' Offset for Y axis

    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        repeat x from 0 to XMAX
            modifier := (||cnt / 1_000_000)           ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            oled.Plot(x, y, $FFFF)

        oled.Update
        iteration++
        oled.Clear

    Report(testtime, iteration)
    return iteration

PUB Demo_SeqText(testtime) | iteration, col, row, maxcol, maxrow, ch, st
' Sequentially draws the whole font table to the screen, then random characters
'    oled.FGColor(1)
'    oled.BGColor(0)
    maxcol := (WIDTH/oled.FontWidth)-1
    maxrow := (HEIGHT/oled.FontHeight)-1
    ch := $00

    ser.str(string("Demo_SeqText - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        repeat row from 0 to maxrow
            repeat col from 0 to maxcol
                ch++
                if ch > $7F
                    ch := $00
                oled.FGColor((?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26))
                oled.BGColor((?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26))
                oled.Position (col, row)
                oled.Char (ch)
        oled.Update
        iteration++

    Report(testtime, iteration)
    return iteration

PUB Demo_RndText(testtime) | iteration, col, row, maxcol, maxrow, ch, st

    oled.FGColor(1)
    oled.BGColor(0)
    maxcol := (WIDTH/oled.FontWidth)-1
    maxrow := (HEIGHT/oled.FontHeight)-1
    ch := $00

    ser.str(string("Demo_RndText - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        repeat row from 0 to maxrow
            repeat col from 0 to maxcol
                ch++
                if ch > $7F
                    ch := $00
                oled.FGColor((?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26))
                oled.BGColor((?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26))
                oled.Position (col, row)
                oled.Char (rnd(127))
        oled.Update
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
            oled.Plot (x, y, $FFFF)
        oled.Update
        iteration++
        oled.Clear

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
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Plot (x, y, c)
        oled.Update
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
    if _oled_cog := oled.Start (CS_PIN, DC_PIN, DIN_PIN, CLK_PIN, RES_PIN, WIDTH, HEIGHT, @_framebuff)
        ser.str(string("SSD1351 driver started", ser#CR, ser#LF))
        oled.FontAddress(fnt.BaseAddr)
        oled.FontSize(6, 8)
        oled.DefaultsCommon
        oled.ClearAll
    else
        ser.str(string("SSD1351 driver failed to start - halting", ser#CR, ser#LF))
        Stop

    _timer_cog := cognew(cog_Timer, @_stack_timer)

PUB Stop

    oled.Powered (FALSE)
    oled.Stop
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
