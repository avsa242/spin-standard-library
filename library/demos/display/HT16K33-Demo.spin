{
    --------------------------------------------
    Filename: HT16K33-Demo.spin
    Description: Demo of the HT16K33 driver
    Author: Jesse Burt
    Copyright (c) 2022
    Created: Nov 21, 2020
    Updated: Jan 30, 2022
    See end of file for terms of use.
    --------------------------------------------
}


CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants:
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000                       ' max is 400_000
    ADDR_BITS   = %000                          ' %000..%111

    WIDTH       = 8
    HEIGHT      = 8
' --

    BUFFSZ      = (WIDTH * HEIGHT) / 8
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    disp: "display.led.ht16k33"
    int : "string.integer"
    fnt : "font.5x8"

VAR

    long _stack_timer[50]
    long _timer_set
    long _rnd_seed
    byte _framebuff[BUFFSZ]
    byte _timer_cog

PUB Main{} | time_ms

    setup{}
    disp.clear{}

    ser.position(0, 3)

    demo_greet{}
    time.sleep(5)
    disp.clear{}

    time_ms := 5_000

    demo_sinewave(time_ms)
    disp.clear{}

    demo_triwave(time_ms)
    disp.clear{}

    demo_memscroller(time_ms, $0000, $FFFF-BUFFSZ)
    disp.clear{}

    demo_lineSweepx(time_ms)
    disp.clear{}

    demo_linesweepy(time_ms)
    disp.clear{}

    demo_line(time_ms)
    disp.clear{}

    demo_plot(time_ms)
    disp.clear{}

    demo_circle(time_ms)
    disp.clear{}

    demo_wander(time_ms)
    disp.clear{}

    demo_seqtext(time_ms)
    disp.clear{}

    demo_rndtext(time_ms)
    disp.clear{}

    repeat

PUB Demo_Bitmap(testtime, bitmap_addr) | iteration
' Continuously redraws bitmap at address bitmap_addr
    ser.str(string("Demo_Bitmap - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        disp.bitmap(bitmap_addr, 0, 0, XMAX, YMAX)
        disp.update{}
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
        r := rnd(HEIGHT/2)
        disp.circle(x, y, r, -1, false)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_Greet{} | ch, idx
' Display the banner/greeting on the disp
    ser.strln(string("Demo_Greet"))

    disp.fgcolor(1)
    disp.bgcolor(0)
    ch := idx := 0

    repeat
        disp.position(0, 0)
        ch := byte[@greet_str][idx++]
        if ch == 0
            quit
        disp.char(ch)
        disp.update{}
        time.msleep(333)

PUB Demo_Line(testtime) | iteration
' Draws random lines with color -1 (invert)
    ser.str(string("Demo_Line - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        disp.line(rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), -1)
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
        disp.line(x, 0, XMAX-x, YMAX, -1)
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
        disp.line(XMAX, y, 0, YMAX-y, -1)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_MEMScroller(testtime, start_addr, end_addr) | iteration, pos, st, en
' Dumps Propeller Hub RAM (and/or ROM) to the display buffer
    pos := start_addr

    ser.str(string("Demo_MEMScroller - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        pos += 128
        if pos >end_addr
            pos := start_addr
        disp.bitmap(pos, 0, 0, XMAX, YMAX)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_Plot(testtime) | iteration, x, y
' Draws random pixels to the screen, with color -1 (invert)
    ser.str(string("Demo_Plot - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        disp.plot(rnd(XMAX), rnd(YMAX), -1)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_Sinewave(testtime) | iteration, x, y, modifier, offset, div
' Draws a sine wave the length of the screen, influenced by the system counter
    ser.str(string("Demo_Sinewave - "))

    div := 16_384

    offset := YMAX/2                            ' Offset for Y axis

    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        repeat x from 0 to XMAX
            modifier := ||(cnt) / 10_000        ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            disp.plot(x, y, 1)

        disp.update{}
        iteration++
        disp.clear{}

    report(testtime, iteration)

PUB Demo_SeqText(testtime) | iteration, col, row, maxcol, maxrow, ch, st
' Sequentially draws the whole font table to the screen, then random characters
    disp.fgcolor(1)
    disp.bgcolor(0)
    maxcol := (WIDTH/disp.fontwidth{})-1
    maxrow := (HEIGHT/disp.fontheight{})-1
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
                disp.position(col, row)
                disp.char(ch)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Demo_RndText(testtime) | iteration, col, row, maxcol, maxrow, ch, st

    disp.fgcolor(1)
    disp.bgcolor(0)
    maxcol := (WIDTH/disp.fontwidth{})-1
    maxrow := (HEIGHT/disp.fontheight{})-1
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
                disp.position(col, row)
                disp.char(rnd(127))
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
            disp.plot(x, y, 1)
        disp.update{}
        iteration++
        disp.clear{}

    report(testtime, iteration)

PUB Demo_Wander(testtime) | iteration, x, y, d
' Draws randomly wandering pixels
    _rnd_seed := cnt
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
        disp.plot(x, y, -1)
        disp.update{}
        iteration++

    report(testtime, iteration)

PUB Sin(angle): sine
' Return the sine of angle
    sine := angle << 1 & $FFE
    if angle & $800
       sine := word[$F000 - sine]               ' Use sine table from ROM
    else
       sine := word[$E000 + sine]
    if angle & $1000
       -sine

PUB RND(maxval): rndn
' Return random number up to maxval
    rndn := ?_rnd_seed
    rndn >>= 16
    rndn *= (maxval + 1)
    rndn >>= 16

PRI Report(testtime, iterations) 

    ser.str(string("Total iterations: "))
    ser.dec(iterations)

    ser.str(string(", Iterations/sec: "))
    ser.dec(iterations / (testtime/1000))

    ser.str(string(", Iterations/ms: "))
    decimal((iterations * 1_000) / testtime, 1_000)
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
    time.msleep(100)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if disp.startx(I2C_SCL, I2C_SDA, I2C_HZ, ADDR_BITS, WIDTH, HEIGHT, @_framebuff)
        ser.strln(string("HT16K33 driver started"))
        disp.defaults{}
        disp.fontsize(6, 8)
        disp.fontaddress(fnt.baseaddr{})
    else
        ser.str(string("HT16K33 driver failed to start - halting"))
        repeat

    _timer_cog := cognew(cog_Timer, @_stack_timer)

DAT

    greet_str   byte    "HT16K33 on the Parallax P8X32A", 0

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
