{
    --------------------------------------------
    Filename: display.vga.text.spin
    Author: Chip Gracey
    Modified by: Jesse Burt
    Description: VGA 32x15 text-mode/terminal display
    Started 2006
    Updated Oct 18, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on VGA_Text.spin, originally
        by Chip Gracey
}
CON

    COLS        = 32
    ROWS        = 15

    SCREENSIZE  = COLS * ROWS
    LASTROW     = SCREENSIZE - COLS

    PARAM_CNT   = 21

VAR

    long _col, _row, _color, _flag

    word _screen[SCREENSIZE]
    long _colors[8 * 2]

    long _vga_status    '0/1/2 = off/visible/invisible      read-only   (21 longs)
    long _vga_enable    '0/non-0 = off/on                   write-only
    long _vga_pins      '%pppttt = pins                     write-only
    long _vga_mode      '%tihv = tile,interlace,hpol,vpol   write-only
    long _vga_screen    'pointer to screen (words)          write-only
    long _vga_colors    'pointer to colors (longs)          write-only
    long _vga_ht        'horizontal tiles                   write-only
    long _vga_vt        'vertical tiles                     write-only
    long _vga_hx        'horizontal tile expansion          write-only
    long _vga_vx        'vertical tile expansion            write-only
    long _vga_ho        'horizontal offset                  write-only
    long _vga_vo        'vertical offset                    write-only
    long _vga_hd        'horizontal display ticks           write-only
    long _vga_hf        'horizontal front porch ticks       write-only
    long _vga_hs        'horizontal sync ticks              write-only
    long _vga_hb        'horizontal back porch ticks        write-only
    long _vga_vd        'vertical display lines             write-only
    long _vga_vf        'vertical front porch lines         write-only
    long _vga_vs        'vertical sync lines                write-only
    long _vga_vb        'vertical back porch lines          write-only
    long _vga_rate      'tick rate (Hz)                     write-only

OBJ

    vga : "display.vga"

PUB null{}
' This is not a top-level object

PUB start(VGA_BASEPIN): status
' Start terminal - starts a cog
'   Returns:
'       cog number of VGA engine
'       FALSE if no cog available
'
' NOTE: Requires at least 80MHz system clock
    set_colors(@_palette)
    char(0)

    longmove(@_vga_status, @_vga_params, PARAM_CNT)
    _vga_pins := VGA_BASEPIN | %000_111
    _vga_screen := @_screen
    _vga_colors := @_colors
    _vga_rate := clkfreq >> 2

    return vga.startx(@_vga_status)

PUB stop
' Stop terminal - frees a cog
    vga.stop

PUB tx = putchar
PUB char = putchar
PUB putchar(c) | i, k
' Output a character
'
'     $00 = clear screen
'     $01 = home
'     $08 = backspace
'     $09 = tab (8 spaces per)
'     $0A = set X position (X follows)
'     $0B = set Y position (Y follows)
'     $0C = set _color (_color follows)
'     $0D = return
'   others = printable characters
    case _flag
        $00:
            case c
                $00:
                    wordfill(@_screen, $220, SCREENSIZE)
                    _col := _row := 0
                HM:
                    _col := _row := 0
                BS:
                    if _col
                        _col--
                TB:
                    repeat
                        print(" ")
                    while _col & 7
                LF..CB:
                    _flag := c
                    return
                CR:
                    newline
                other:
                    print(c)
        $0A: _col := c // COLS
        $0B: _row := c // ROWS
        $0C: _color := c & 7
    _flag := 0

{ normally the terminal common code provides this, but tell it we have our own, instead }
#define _HAS_NEWLINE_
PUB newline
' Move to first column of next line
    _col := 0

    ' reached last row? scroll up the display
    if ++_row == ROWS
        _row--
        wordmove(@_screen, @_screen[COLS], LASTROW)  'scroll lines
        wordfill(@_screen[LASTROW], $220, COLS)      'clear new line

PUB set_colors(ptr_color) | i, fore, back
' Override default color palette
' ptr_color must point to a list of up to 8 colors
' arranged as follows (where r, g, b are 0..3):
'
'               fore   back
'               ------------
' palette  byte %%rgb, %%rgb     'color 0
'          byte %%rgb, %%rgb     'color 1
'          byte %%rgb, %%rgb     'color 2
'          ...
    repeat i from 0 to 7
        fore := byte[ptr_color][i << 1] << 2
        back := byte[ptr_color][i << 1 + 1] << 2
        _colors[i << 1]     := (fore << 24) + (back << 16) + (fore << 8) + back
        _colors[i << 1 + 1] := (fore << 24) + (fore << 16) + (back << 8) + back

PRI print(c)

    _screen[(_row * COLS) + _col] := ((_color << 1) + (c & 1)) << 10 + $200 + c & $FE
    if ++_col == COLS
        newline

#include "terminal.common.spinh"

DAT

_vga_params long    0                           ' status
            long    1                           ' enable
            long    0                           ' pins
            long    %1000                       ' mode
            long    0                           ' videobase
            long    0                           ' colorbase
            long    COLS                        ' hc
            long    ROWS                        ' vc
            long    1                           ' hx
            long    1                           ' vx
            long    0                           ' ho
            long    0                           ' vo
            long    512                         ' hd
            long    10                          ' hf
            long    75                          ' hs
            long    43                          ' hb
            long    480                         ' vd
            long    11                          ' vf
            long    2                           ' vs
            long    31                          ' vb
            long    0                           ' rate

'                   fore   back
'                     RGB    RGB
_palette    byte    %%333, %%001                ' 0    white / dark blue
            byte    %%330, %%110                ' 1   yellow / brown
            byte    %%202, %%000                ' 2  magenta / black
            byte    %%111, %%333                ' 3     grey / white
            byte    %%033, %%011                ' 4     cyan / dark cyan
            byte    %%020, %%232                ' 5    green / gray-green
            byte    %%100, %%311                ' 6      red / pink
            byte    %%033, %%003                ' 7     cyan / blue

DAT
{
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

