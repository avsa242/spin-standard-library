{
    --------------------------------------------
    Filename: display.tv.text.spin
    Author: Jesse Burt
    Description: 40x13 text composite TV driver
        (based on driver originally by Chip Gracey)
    Started 2006
    Updated Sep 8, 2020
    See end of file for terms of use.
    --------------------------------------------
}

'***************************************
'*  TV Text 40x13 v1.0                 *
'*  Author: Chip Gracey                *
'*  Copyright (c) 2006 Parallax, Inc.  *
'*  See end of file for terms of use.  *
'***************************************

CON

    COLS          = 40
    ROWS          = 13

    SCREENSIZE    = COLS * ROWS
    LASTROW       = SCREENSIZE - COLS

    TV_COUNT      = 14

VAR

    long  _col, _row, _color, _flag

    word  _screen[SCREENSIZE]
    long  _colors[8 * 2]

    long  tv_status     '0/1/2 = off/invisible/visible              read-only   (14 longs)
    long  tv_enable     '0/non-0 = off/on                           write-only
    long  tv_pins       '%pppmmmm = pin group, pin group mode       write-only
    long  tv_mode       '%tccip = tile,chroma,interlace,ntsc/pal    write-only
    long  tv_screen     'pointer to screen (words)                  write-only
    long  tv_colors     'pointer to colors (longs)                  write-only
    long  tv_ht         'horizontal tiles                           write-only
    long  tv_vt         'vertical tiles                             write-only
    long  tv_hx         'horizontal tile expansion                  write-only
    long  tv_vx         'vertical tile expansion                    write-only
    long  tv_ho         'horizontal offset                          write-only
    long  tv_vo         'vertical offset                            write-only
    long  tv_broadcast  'broadcast frequency (Hz)                   write-only
    long  tv_auralcog   'aural fm cog                               write-only

OBJ

    tv  : "display.tv"

PUB Start(basepin): okay
' Start terminal - starts a cog
' returns false if no cog available
    setcolors(@palette)
    char(0)

    longmove(@tv_status, @tv_params, TV_COUNT)
    tv_pins := (basepin & %111000) << 1 | (basepin & 4 == 4) & %0101
    tv_screen := @_screen
    tv_colors := @_colors

    okay := tv.start(@tv_status)

PUB Stop
' Stop terminal - frees a cog
    tv.stop

PUB Char(c) | i, k
' Output a character
'
'     $00 = clear screen
'     $01 = home
'     $08 = backspace
'     $09 = tab (8 spaces per)
'     $0A = set X position (X follows)
'     $0B = set Y position (Y follows)
'     $0C = set color (color follows)
'     $0D = return
'  others = printable characters
    case _flag
        $00:
            case c
                $00:
                    wordfill(@_screen, $220, SCREENSIZE)
                    _col := _row := 0
                $01:
                    _col := _row := 0
                $08:
                    if _col
                        _col--
                $09:
                    repeat
                        print(" ")
                    while _col & 7
                $0A..$0C:
                    _flag := c
                    return
                $0D:
                    _col := 0
                    if ++_row == ROWS
                        _row--
                        wordmove(@_screen, @_screen[COLS], LASTROW) 'scroll lines
                        wordfill(@_screen[LASTROW], $220, COLS)     'clear new line
                other:
                    print(c)
        $0A: _col := c // COLS
        $0B: _row := c // ROWS
        $0C: _color := c & 7
    _flag := 0

PUB Position(x, y)
' Set cursor position
    char($a)
    char(x)
    char($b)
    char(y)

PUB SetColors(colorptr) | i, fore, back
' Override default color palette
' colorptr must point to a list of up to 8 colors
' arranged as follows:
'
'               fore   back
'               ------------
' palette  byte color, color     'color 0
'          byte color, color     'color 1
'          byte color, color     'color 2
'          ...

    repeat i from 0 to 7
        fore := byte[colorptr][i << 1]
        back := byte[colorptr][i << 1 + 1]
        _colors[i << 1]     := fore << 24 + back << 16 + fore << 8 + back
        _colors[i << 1 + 1] := fore << 24 + fore << 16 + back << 8 + back

#include "lib.terminal.spin"

PRI print(c)

    _screen[_row * COLS + _col] := (_color << 1 + c & 1) << 10 + $200 + c & $FE
    if ++_col == COLS
        newline

DAT

tv_params               long    0               'status
                        long    1               'enable
                        long    0               'pins
                        long    %10010          'mode
                        long    0               'screen
                        long    0               'colors
                        long    COLS            'hc
                        long    ROWS            'vc
                        long    4               'hx
                        long    1               'vx
                        long    0               'ho
                        long    0               'vo
                        long    0               'broadcast
                        long    0               'auralcog


                        '       fore   back
                        '       color  color
palette                 byte    $07,   $0A    '0    white / dark blue
                        byte    $07,   $BB    '1    white / red
                        byte    $9E,   $9B    '2   yellow / brown
                        byte    $04,   $07    '3     grey / white
                        byte    $3D,   $3B    '4     cyan / dark cyan
                        byte    $6B,   $6E    '5    green / gray-green
                        byte    $BB,   $CE    '6      red / pink
                        byte    $3C,   $0A    '7     cyan / blue

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

