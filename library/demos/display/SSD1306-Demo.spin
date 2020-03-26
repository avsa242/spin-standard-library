{
    --------------------------------------------
    Filename: SSD1306-Demo.spin
    Description: Demo of the SSD1306 driver
    Author: Jesse Burt
    Copyright (c) 2019
    Created: Apr 26, 2018
    Updated: Dec 28, 2019
    See end of file for terms of use.
    --------------------------------------------
}

#define FPS_MON_ENABLE  ' Optionally undef/comment out to disable the terminal framerate monitor

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    BUFFSZ      = (WIDTH * HEIGHT) / 8
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1

' User-modifiable constants:
    WIDTH       = 128
    HEIGHT      = 32

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 1_000_000

    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    LED         = cfg#LED1

OBJ

    cfg         : "core.con.boardcfg.flip"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    io          : "io"
    oled        : "display.oled.ssd1306.i2c"
    int         : "string.integer"
    fnt5x8      : "font.5x8"

VAR

    long _fps_mon_stack[50]
    long _rndSeed
    byte _framebuff[BUFFSZ]
    byte _frames, _fps_mon_cog, _ser_cog
    byte _ser_row

PUB Main

    _frames := 0
    _ser_row := 3
    Setup
    oled.ClearAll

    oled.MirrorH(TRUE)
    oled.MirrorV(TRUE)

    Demo_Greet
    time.Sleep (5)
    oled.ClearAll

    Demo_SineWave (500)
    oled.ClearAll

    Demo_TriWave (500)
    oled.ClearAll

    Demo_MEMScroller($0000, $FFFF-BUFFSZ)
    oled.ClearAll

    Demo_Bitmap (@Beanie, 500)
    oled.ClearAll

    Demo_LineSweep(2)
    oled.ClearAll

    Demo_Line (500)
    oled.ClearAll

    Demo_Plot (500)
    oled.ClearAll

    Demo_BouncingBall (500, 5)
    oled.ClearAll

    Demo_Circle(500)
    oled.ClearAll

    Demo_Wander (1000)
    oled.ClearAll

    Demo_Text (20)

    Demo_Contrast(2, 1)
    oled.ClearAll

    Stop
    FlashLED(LED, 100)

PUB Demo_BouncingBall(frames, radius) | bx, by, dx, dy
' Draws a simple ball bouncing off screen edges
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_BouncingBall"))

    bx := (rnd(XMAX) // (WIDTH - radius * 4)) + radius * 2  'Pick a random screen location to
    by := (rnd(YMAX) // (HEIGHT - radius * 4)) + radius * 2 ' start from
    dx := rnd(4) // 2 * 2 - 1                               'Pick a random direction to
    dy := rnd(4) // 2 * 2 - 1                               ' start moving

    repeat frames
        bx += dx
        by += dy
        if (by =< radius OR by => HEIGHT - radius)          'If we reach the top or bottom of the screen,
            dy *= -1                                        ' change direction
        if (bx =< radius OR bx => WIDTH - radius)           'Ditto with the left or right sides
            dx *= -1

        oled.Circle (bx, by, radius, 1)
        oled.Update
        _frames++
        oled.Clear

PUB Demo_Bitmap(bitmap_addr, reps)
' Continuously redraws bitmap at address bitmap_addr
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Bitmap"))

    repeat reps
        oled.Bitmap (bitmap_addr, BUFFSZ, 0)
        oled.Update
        _frames++

PUB Demo_Circle(reps) | x, y, r
' Draws circles at random locations
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Circle"))

    repeat reps
        x := rnd(XMAX)
        y := rnd(YMAX)
        r := rnd(YMAX/2)
        oled.Circle (x, y, r, -1)
        oled.Update
        _frames++

PUB Demo_Contrast(reps, delay_ms) | contrast_level
' Fades out and in display contrast
    _ser_row++
    _frames := 0
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Contrast"))

    repeat reps
        repeat contrast_level from 255 to 1
            oled.Contrast (contrast_level)
            time.MSleep (delay_ms)
        repeat contrast_level from 0 to 254
            oled.Contrast (contrast_level)
            time.MSleep (delay_ms)

PUB Demo_Greet
' Display the banner/greeting on the OLED
    _ser_row++
    _frames := 0
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Greet"))

    oled.FGColor(1)
    oled.BGColor(0)
    oled.Position (0, 0)
    oled.Str (string("SSD1306 on the"))

    oled.Position (0, 1)
    oled.Str (string("Parallax"))

    oled.Position (0, 2)
    oled.Str (string("P8X32A @ "))
    oled.Str (int.Dec(clkfreq/1_000_000))
    oled.Str (string("MHz"))

    oled.Position (0, 3)
    oled.Str (int.DecPadded (WIDTH, 3))

    oled.Position (3, 3)
    oled.Str (string("x"))

    oled.Position (4, 3)
    oled.Str (int.DecPadded (HEIGHT, 2))
    oled.Update

PUB Demo_Line (reps)
' Draws random lines with color -1 (invert)
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Line"))

    repeat reps
        oled.Line (rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), -1)
        oled.Update
        _frames++

PUB Demo_LineSweep (reps) | x, y
' Draws lines top left to lower-right, sweeping across the screen, then
'  from the top-down
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_LineSweep"))

    repeat reps
        repeat x from 0 to XMAX step 1
            oled.Line (x, 0, XMAX-x, YMAX, -1)
            oled.Update
            _frames++

        repeat y from 0 to YMAX step 1
            oled.Line (XMAX, y, 0, YMAX-y, -1)
            oled.Update
            _frames++

PUB Demo_MEMScroller(start_addr, end_addr) | pos, st, en
' Dumps Propeller Hub RAM (and/or ROM) to the display buffer
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_MEMScroller"))

    repeat pos from start_addr to end_addr step 128
        oled.Bitmap (pos, BUFFSZ, 0)
        oled.Update
        _frames++

PUB Demo_Plot (reps) | x, y
' Draws random pixels to the screen, with color -1 (invert)
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Plot"))

    repeat reps
        oled.Plot (rnd(XMAX), rnd(YMAX), -1)
        oled.Update
        _frames++

PUB Demo_Sinewave(reps) | x, y, modifier, offset, div
' Draws a sine wave the length of the screen, influenced by the system counter
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Sinewave"))

    case HEIGHT
        32:
            div := 4096
        64:
            div := 2048
        OTHER:
            div := 2048

    offset := YMAX/2                                    ' Offset for Y axis

    repeat reps
        repeat x from 0 to XMAX
            modifier := (||cnt / 1_000_000)           ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            oled.Plot(x, y, 1)
        oled.Update
        _frames++
        oled.Clear

PUB Demo_Text(reps) | col, row, maxcol, maxrow, ch, st
' Sequentially draws the whole font table to the screen, then random characters
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Text"))

    oled.FGColor(1)
    oled.BGColor(0)
    maxcol := (WIDTH/oled.FontWidth)-1
    maxrow := (HEIGHT/oled.FontHeight)-1
    ch := $00
    repeat reps/2
        repeat row from 0 to maxrow
            repeat col from 0 to maxcol
                ch++
                if ch > $7F
                    ch := $00
                oled.Position (col, row)
                oled.Char (ch)
        oled.Update
        _frames++

    repeat reps/2
        repeat row from 0 to maxrow
            repeat col from 0 to maxcol
                oled.Position (col, row)
                oled.Char (rnd(127))
        oled.Update
        _frames++

PUB Demo_TriWave(frames) | x, y, ydir
' Draws a simple triangular wave
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Triwave"))

    ydir := 1
    y := 0
    repeat frames
        repeat x from 0 to XMAX
            if y == YMAX
                ydir := -1
            if y == 0
                ydir := 1
            y := y + ydir
            oled.Plot (x, y, 1)
        oled.Update
        _frames++
        oled.Clear

PUB Demo_Wander(reps) | x, y, d
' Draws randomly wandering pixels
    _ser_row++
    ser.Position(0, _ser_row)
    ser.Str(string("Demo_Wander"))

    _rndSeed := cnt
    x := XMAX/2
    y := YMAX/2
    repeat reps
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
        oled.Plot (x, y, -1)
        oled.Update
        _frames++

PUB Sin(angle)
' Return the sine of angle
    result := angle << 1 & $FFE
    if angle & $800
       result := word[$F000 - result]   ' Use sine table from ROM
    else
       result := word[$E000 + result]
    if angle & $1000
       -result

PUB RND(maxval) | i
' Return random number up to maxval
    i :=? _rndSeed
    i >>= 16
    i *= (maxval + 1)
    i >>= 16

    return i

PUB FPS_mon
' Display to the serial terminal approximate render speed, in frames per second
    repeat
        time.MSleep (1000)
        ser.Position (20, _ser_row)
        ser.Str (string("FPS: "))
        ser.Str (int.DecZeroed (_frames, 3))
        _frames := 0

PUB Setup

    repeat until ser.StartRXTX (SER_RX, SER_TX, %0000, SER_BAUD)
    time.MSleep(100)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#CR, ser#LF))
    if oled.Start (WIDTH, HEIGHT, I2C_SCL, I2C_SDA, I2C_HZ, @_framebuff, 0)
        ser.Str (string("SSD1306 driver started. Draw buffer @ $"))
        ser.Hex (oled.Address (-2), 8)
        oled.Defaults
        oled.OscFreq (407)
        oled.FontSize (6, 8)
        oled.FontAddress (fnt5x8.BaseAddr)
    else
        ser.Str (string("SSD1306 driver failed to start - halting"))
        Stop
        FlashLED (LED, 500)

#ifdef FPS_MON_ENABLE
    _fps_mon_cog := cognew(FPS_mon, @_fps_mon_stack)  'Start framerate monitor in another cog/core
#endif

PUB Stop

    oled.DisplayOff
    oled.Stop

    if _fps_mon_cog
        cogstop(_fps_mon_cog)
    if _ser_cog
        cogstop(_ser_cog)

#include "lib.utility.spin"

DAT

    Beanie      byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $C0
                byte    $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $80, $80, $80, $80, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80
                byte    $80, $00, $00, $00, $80, $80, $80, $80, $C0, $C0, $C0, $C0, $C0, $E0, $E0, $E0
                byte    $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
                byte    $E0, $E0, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0F, $1F, $3F
                byte    $3F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $3F, $3F, $3F, $3F
                byte    $3F, $3F, $1F, $1F, $1E, $1E, $1E, $0E, $0E, $0E, $0E, $06, $06, $06, $F7, $FF
                byte    $FF, $F7, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $07
                byte    $07, $07, $07, $07, $07, $0F, $0F, $0F, $0F, $0F, $1F, $1F, $1F, $1F, $1F, $1F
                byte    $0F, $0F, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $80, $C0, $C0, $E0, $E0, $60, $70, $30, $30, $18, $18, $C8, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $C8, $18, $18, $30, $30, $70, $60, $E0, $E0, $C0, $C0, $80, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $80, $C0, $E0, $F0, $F8, $FC, $FE, $7F
                byte    $3F, $0F, $07, $03, $01, $00, $00, $00, $00, $C0, $FC, $FF, $FF, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $FF, $FF, $FC, $C0, $00, $00, $00, $00, $01, $03, $07, $0F, $3F
                byte    $7F, $FE, $FC, $F8, $F0, $E0, $C0, $80, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $80, $E0, $F8, $FC, $FF, $FF, $FF, $FF, $FF, $3F, $07, $01, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F8, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $01, $07, $3F, $FF, $FF, $FF, $FF, $FF, $FC, $F8, $E0, $80, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $C0, $FC, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BF, $81, $80, $80, $80, $C0
                byte    $C0, $C0, $C0, $C0, $C0, $C0, $C0, $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
                byte    $C0, $80, $80, $80, $81, $BF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FC, $C0, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $78, $FF, $FF, $FF, $FF, $FF, $FF, $CF, $CF, $CF, $CF, $CF, $C7, $87, $87, $87
                byte    $87, $87, $87, $87, $87, $87, $87, $07, $03, $03, $03, $03, $03, $03, $03, $03
                byte    $03, $03, $03, $03, $03, $03, $03, $03, $07, $87, $87, $87, $87, $87, $87, $87
                byte    $87, $87, $87, $C7, $CF, $CF, $CF, $CF, $CF, $FF, $FF, $FF, $FF, $FF, $FF, $78
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $01, $01, $03, $03, $03, $03, $03, $07, $07, $07, $07, $07, $07, $07
                byte    $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
                byte    $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
                byte    $07, $07, $07, $07, $07, $07, $07, $03, $03, $03, $03, $03, $01, $01, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

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
