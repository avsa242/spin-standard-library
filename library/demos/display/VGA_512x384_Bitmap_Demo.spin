{
    --------------------------------------------
    Filename: VGA_512x384_Bitmap_Demo.spin
    Description: Demo of the 512x384 VGA bitmap driver
    Author: Chip Gracey
    Modified by: Jesse Burt
    Started 2006
    Updated Nov 4, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on VGA_512x384_Bitmap_Demo.spin, originally
        by Chip Gracey
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

    TILES    = vga#xTILES * vga#yTILES
    TILES32  = TILES * 32


OBJ

    cfg : "boardcfg.quickstart-hib"
    vga : "display.vga.bitmap.512x384"


VAR

    long _sync, _disp_buff[TILES32]
    word _colors[TILES]

PUB main | h, i, j, k, x, y

    { start vga }
    vga.startx(0, @_colors, @_disp_buff, @_sync)

    { init colors to cyan on blue }
    repeat i from 0 to TILES - 1
        _colors[i] := $2804

    { draw some lines }
    repeat y from 1 to 8
        repeat x from 0 to 511
            plot(x, x/y)

    { wait ten seconds }
    waitcnt(clkfreq * 10 + cnt)

    { randomize the colors and pixels }
    repeat
        _colors[||?h // TILES] := ?i
        repeat 100
            _disp_buff[||?j // TILES32] := k?

PRI plot(x,y) | i

    if ((x => 0) and (x < 512) and (y => 0) and (y < 384))
        _disp_buff[(y << 4) + (x >> 5)] |= |< x

{
Copyright 2022 Jesse Burt

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

