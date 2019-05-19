{
    --------------------------------------------
    Filename: display.gfx.bitmap.spin
    Author: Jesse Burt
    Description: Generic bitmap-oriented graphics rendering routines
    Copyright (c) 2019
    Started May 19, 2019
    Updated May 19, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON


VAR

    long _buff_addr
    long _row, _col
    long _disp_width, _disp_height
    long _buff_sz
    long _font_width, _font_height, _font_addr

PUB Null
''This is not a top-level object

PUB Start(disp_width, disp_height, bpp, disp_addr)
' Set parameters for bitmap graphics object
'   disp_width  - Display's width, in pixels
'   disp_height - Display's height, in pixels
'   bpp         - Bits per pixel/color depth
'   disp_addr   - Address of display buffer
    _disp_width := disp_width
    _disp_height := disp_height

    case bpp
        1:
            _buff_sz := (_disp_width * _disp_height) / 8
        2:
            _buff_sz := (_disp_width * _disp_height) / 4
        4:
            _buff_sz := (_disp_width * _disp_height) / 2
        8:
            _buff_sz := (_disp_width * _disp_height)
        16:
            _buff_sz := (_disp_width * _disp_height) * 2
        24:
            _buff_sz := (_disp_width * _disp_height) * 3

    Address (disp_addr)
    
PUB Address(addr)
' Set framebuffer address
    case addr
        $0004..$7FFF:
            _buff_addr := addr
        OTHER:
            return _buff_addr

PUB Clear
' Clear the display buffer
    longfill(_buff_addr, $00, _buff_sz/4)

PUB Char (ch) | i
' Write a character to the display @ row and column (character cell)
    repeat i from 0 to 7
        byte[_buff_addr][_row << 7 + _col << 3 + i] := byte[_font_addr + 8 * ch + i]

PUB Circle(x0, y0, radius, color) | x, y, err, cdx, cdy
' Draw a circle at x0, y0
    x := radius - 1
    y := 0
    cdx := 1
    cdy := 1
    err := cdx - (radius << 1)

    repeat while (x => y)
        Plot(x0 + x, y0 + y, color)
        Plot(x0 + y, y0 + x, color)
        Plot(x0 - y, y0 + x, color)
        Plot(x0 - x, y0 + y, color)
        Plot(x0 - x, y0 - y, color)
        Plot(x0 - y, y0 - x, color)
        Plot(x0 + y, y0 - x, color)
        Plot(x0 + x, y0 - y, color)

        if (err =< 0)
            y++
            err += cdy
            cdy += 2

        if (err > 0)
            x--
            cdx += 2
            err += cdx - (radius << 1)

PUB FontAddress(addr)
' Set address of font definition
    case addr
        $0004..$7FFF:
            _font_addr := addr
        OTHER:
            return _font_addr

PUB FontSize(width, height)
' Set expected dimensions of font, in pixels
    _font_width := width
    _font_height := height

PUB Line(x1, y1, x2, y2, c) | sx, sy, ddx, ddy, err, e2
' Draw line from x1, y1 to x2, y2, in color c
    ddx := ||(x2-x1)
    ddy := ||(y2-y1)
    err := ddx-ddy

    sx := -1
    if (x1 < x2)
        sx := 1

    sy := -1
    if (y1 < y2)
        sy := 1

    case c
        1:
            repeat until ((x1 == x2) AND (y1 == y2))
                byte[_buff_addr][x1 + (y1>>3{/8})*_disp_width] |= (1 << (y1&7))'try >>3 instead of /8

                e2 := err << 1

                if e2 > -ddy
                    err := err - ddy
                    x1 := x1 + sx

                if e2 < ddx
                    err := err + ddx
                    y1 := y1 + sy

        0:
            repeat until ((x1 == x2) AND (y1 == y2))
                byte[_buff_addr][x1 + (y1>>3{/8})*_disp_width] &= (1 << (y1&7))

                e2 := err << 1

                if e2 > -ddy
                    err := err - ddy
                    x1 := x1 + sx

                if e2 < ddx
                    err := err + ddx
                    y1 := y1 + sy

        -1:
            repeat until ((x1 == x2) AND (y1 == y2))
                byte[_buff_addr][x1 + (y1>>3{/8})*_disp_width] ^= (1 << (y1&7))

                e2 := err << 1

                if e2 > -ddy
                    err := err - ddy
                    x1 := x1 + sx

                if e2 < ddx
                    err := err + ddx
                    y1 := y1 + sy

        OTHER:
            return

PUB Plot (x, y, c)
' Plot pixel at x, y, color c
    case x
        0.._disp_width-1:
        OTHER:
            return
    case y
        0.._disp_height-1:
        OTHER:
            return

    case c
        1:
            byte[_buff_addr][x + (y>>3)*_disp_width] |= (1 << (y&7))
        0:
            byte[_buff_addr][x + (y>>3)*_disp_width] &= (1 << (y&7))
        -1:
            byte[_buff_addr][x + (y>>3)*_disp_width] ^= (1 << (y&7))
        OTHER:
            return

PUB Position(col, row)
' Set text draw position, in character-cell col and row
    _col := col &= (_disp_width / 8) - 1    'Clamp position based on
    _row := row &= (_disp_height / 8) - 1   ' screen's dimensions

PUB Str (string_addr) | i
' Write string at string_addr to the display @ row and column.
'   NOTE: Wraps to the left at end of line and to the top-left at end of display
    repeat i from 0 to strsize(string_addr)-1
        char(byte[string_addr][i])
        _col++
        if _col > (_disp_width / 8) - 1
            _col := 0
            _row++
            if _row > (_disp_height / 8) - 1
                _row := 0

DAT
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
