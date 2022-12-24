{
    --------------------------------------------
    Filename: display.tv.terminal.spin
    Description: TV text/terminal driver
    Author: Chip Gracey
    Modified by: Jesse Burt
    Started 2005
    Updated Dec 24, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on TV_Terminal.spin, originally
        by Chip Gracey
}
CON

    X_TILES         = 16
    Y_TILES         = 13

    X_SCREEN        = X_TILES << 4
    Y_SCREEN        = Y_TILES << 4

    WIDTH           = 0                         ' 0 = minimum
    X_SCALE         = 1                         ' 1 = minimum
    Y_SCALE         = 1                         ' 1 = minimum
    X_SPACING       = 6                         ' 6 = normal
    Y_SPACING       = 13                        ' 13 = normal

    X_CHR           = X_SCALE * X_SPACING
    Y_CHR           = Y_SCALE * Y_SPACING

    Y_OFFSET        = Y_SPACING / 6 + Y_CHR - 1

    X_LIMIT         = X_SCREEN / (X_SCALE * X_SPACING)
    Y_LIMIT         = Y_SCREEN / (Y_SCALE * Y_SPACING)
    Y_MAX           = Y_LIMIT - 1

    Y_SCREEN_BYTES  = Y_SCREEN << 2
    Y_SCROLL        = Y_CHR << 2
    Y_SCROLL_LONGS  = Y_CHR * Y_MAX
    Y_CLEAR         = Y_SCROLL_LONGS << 2
    Y_CLEAR_LONGS   = Y_SCREEN - Y_SCROLL_LONGS

    PARAMCOUNT      = 14

VAR

    long _x, _y, _ptr_bitmap

    long _tv_status     '0/1/2 = off/visible/invisible           read-only
    long _tv_enable     '0/? = off/on                            write-only
    long _tv_pins       '%ppmmm = pins                           write-only
    long _tv_mode       '%ccinp = chroma,interlace,ntsc/pal,swap write-only
    long _tv_screen     'pointer to screen (words)               write-only
    long _tv_colors     'pointer to colors (longs)               write-only
    long _tv_hc         'horizontal cells                        write-only
    long _tv_vc         'vertical cells                          write-only
    long _tv_hx         'horizontal cell expansion               write-only
    long _tv_vx         'vertical cell expansion                 write-only
    long _tv_ho         'horizontal offset                       write-only
    long _tv_vo         'vertical offset                         write-only
    long _tv_broadcast  'broadcast frequency (Hz)                write-only
    long _tv_auralcog   'aural fm cog                            write-only

    long _bitmap[X_TILES * Y_TILES << 4 + 16]   ' add 16 longs to allow for 64-byte alignment
    word _screen[X_TILES * Y_TILES]

OBJ

    tv : "display.tv"
    gr : "graphics.tile"

PUB null{}
' This is not a top-level object

PUB start(TV_BASEPIN): status
' Start terminal
'
'  TV_BASEPIN: first of three pins on a 4-pin boundary (0, 4, 8...) to have
'  1.1k, 560, and 270 ohm resistors connected and summed to form the 1V,
'  75 ohm DAC for baseband video

    { init bitmap and tile screen }
    _ptr_bitmap := (@_bitmap + $3F) & $7FC0
    repeat _x from 0 to X_TILES - 1
        repeat _y from 0 to Y_TILES - 1
            _screen[_y * X_TILES + _x] := _ptr_bitmap >> 6 + _y + _x * Y_TILES

    { start tv }
    _tvparams_pins := (TV_BASEPIN & $38) << 1 | (TV_BASEPIN & 4 == 4) & %0101
    longmove(@_tv_status, @_tvparams, PARAMCOUNT)
    _tv_screen := @_screen
    _tv_colors := @_color_schemes
    tv.start(@_tv_status)

    { start graphics }
    gr.start
    gr.setup(X_TILES, Y_TILES, 0, Y_SCREEN, _ptr_bitmap)
    gr.textmode(X_SCALE, Y_SCALE, X_SPACING, 0)
    gr.width(WIDTH)
    char(0)

PUB stop{}
' Stop terminal
    tv.stop
    gr.stop

PUB tx = putchar
PUB char = putchar
PUB putchar(c)
' Print a character
'
'       $00 = home
'  $01..$03 = color
'  $04..$07 = color schemes
'       $09 = tab
'       $0D = return
'  $20..$7E = character
    case c
        $00:                                    ' home?
            gr.clear
            _x := _y := 0
        $01..$03:                               ' color?
            gr.color(c)
        $04..$07:                               ' color scheme?
            _tv_colors := @_color_schemes[c & 3]
        TB:                                     ' tab?
            repeat
                putchar(" ")
            while _x & 7
        CR:                                     ' return?
            newline
        " ".."~":                               ' character?
            gr.text(_x * X_CHR, -_y * Y_CHR - Y_OFFSET, @c)
            gr.finish
            if (++_x == X_LIMIT)
                newline

{ normally terminal.common.spinh provides newline(), but tell it we brought our own }
#define _HAS_NEWLINE_
PUB newline

    if (++_y == Y_LIMIT)
        gr.finish
        repeat _x from 0 to X_TILES - 1
            _y := _ptr_bitmap + _x * Y_SCREEN_BYTES
            longmove(_y, _y + Y_SCROLL, Y_SCROLL_LONGS)
            longfill(_y + Y_CLEAR, 0, Y_CLEAR_LONGS)
        _y := Y_MAX
    _x := 0

DAT

_tvparams               long    0               ' status
                        long    1               ' enable
_tvparams_pins          long    %001_0101       ' pins
                        long    %0000           ' mode
                        long    0               ' screen
                        long    0               ' colors
                        long    X_TILES         ' hc
                        long    Y_TILES         ' vc
                        long    10              ' hx
                        long    1               ' vx
                        long    0               ' ho
                        long    0               ' vo
                        long    55_250_000      ' broadcast
                        long    0               ' auralcog

_color_schemes          long    $BC_6C_05_02
                        long    $0E_0D_0C_0A
                        long    $6E_6D_6C_6A
                        long    $BE_BD_BC_BA

' pull in terminal lib methods (putbin(), putdec(), puthex(), printf(), puts(), etc)
#include "terminal.common.spinh"

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

