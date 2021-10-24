{
    --------------------------------------------
    Filename: display.led.hub75.spin
    Author: Jesse Burt
    Description: Driver for HUB75 RGB LED matrix displays
    Copyright (c) 2021
    Started: Oct 24, 2021
    Updated: Oct 24, 2021
    See end of file for terms of use.
    --------------------------------------------
}

#define HUB75
#define MEMMV_NATIVE bytemove
#include "lib.gfx.bitmap.spin"

CON

    BYTESPERPX  = 1
    MAX_COLOR   = 7

VAR

    long _eng_stack[50]
    long _ptr_drawbuffer
    long _bl, _clk, _lat
    word _disp_width, _disp_height, _disp_xmax, _disp_ymax, _buff_sz
    word _bytesperln
    byte _rgbio, _addr
    byte _vsync
    byte _cog

OBJ

    time    : "time"

PUB Null{}
' This is not a top-level object

PUB Startx(RGB_BASEPIN, ADDR_BASEPIN, BLPIN, CLKPIN, LATPIN, WIDTH, HEIGHT, PTR_DISP): status
' Start using custom I/O settings
'   RGB_BASEPIN: starting (lowest) pin of 6 contiguous RGB data pins
'       (LSB..MSB: R0, G0, B0, R1, G1, B1)
'   ADDR_BASEPIN: starting (lowest) pin of 4 contiguous address pins
'       (LSB..MSB: A, B, C, D)
'   _____                                           __
'   BLPIN: blank control pin (sometimes labelled as OE)
'   CLKPIN: clock pin
'   LATPIN: latch pin
'   WIDTH, HEIGHT: dimensions of RGB matrix display, in pixels
'   PTR_DISP: pointer to display buffer
'       (must be at least (WIDTH * HEIGHT) bytes)
    if lookdown(RGB_BASEPIN: 0..25) and lookdown(ADDR_BASEPIN: 0..27) and {
}   lookdown(BLPIN: 0..31) and lookdown(CLKPIN: 0..31) and {
}   lookdown(LATPIN: 0..31)
        if (_cog := status := (cognew(hub75_engine{}, @_eng_stack) + 1))
            _disp_width := WIDTH
            _disp_height := HEIGHT
            _disp_xmax := _disp_width - 1
            _disp_ymax := _disp_height - 1
            _buff_sz := (_disp_width * _disp_height) * BYTESPERPX
            _bytesperln := _disp_width * BYTESPERPX

            _rgbio := RGB_BASEPIN
            _addr := ADDR_BASEPIN
            longmove(@_bl, @BLPIN, 3)

            address(PTR_DISP)
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}
' Stop engine, clear variable space
    if _cog
        cogstop(_cog-1)
        longfill(@_eng_stack, 0, 54)
        wordfill(@_disp_width, 0, 6)
        bytefill(@_rgbio, 0, 4)

PUB Address(addr): curr_addr
' Set framebuffer/display buffer address
    case addr
        $0004..$7FFF-_buff_sz:
            _ptr_drawbuffer := addr
        other:
            return _ptr_drawbuffer

PUB MirrorH(m)
' dummy method

PUB MirrorV(m)
' dummy method

PUB Update{}
' dummy method

PRI HUB75_Engine{} | r0, g0, b0, r1, g1, b1, a, b, c, d, bl, clk, lat, tmp, {
} y, x, ty_offs, by_offs, top_offs, bot_offs, bnkht
' HUB75 engine (secondary cog)
    repeat until _lat                           ' wait until all vars are set

    repeat tmp from 0 to 5                      ' copy hub I/O pin vars to 
        long[@r0][tmp] := _rgbio+tmp            '   locals
    repeat tmp from 0 to 3                      '
        long[@a][tmp] := _addr+tmp              '
    longmove(@bl, @_bl, 3)                      '

    bnkht := _disp_height/2                     ' bank (top/bot half) height
    dira[bl..r0] := %1111111111111              ' init I/O pins outputs, and
    outa[b1..r0] := 0                           '   inactive
    outa[d..a] := 0
    outa[bl] := 1
    outa[clk] := 0
    outa[lat] := 0

    repeat                                      ' main loop
        repeat y from 0 to bnkht-1              ' (( Y/row loop ))
            outa[_lat] := 0
            ty_offs := (y * _disp_width)        ' precalc bank row offsets
            by_offs := ((y + bnkht) * _disp_width)
            outa[bl] := 1                       ' turn off output
            outa[d..a] := y                     ' set row address
            repeat x from 0 to _disp_xmax       ' (( X/column loop ))
                top_offs := (ty_offs + x)       ' calc top and bottom bank
                bot_offs := (by_offs + x)       '   offsets
                outa[b1..r0] := (byte[_ptr_drawbuffer][bot_offs] << 3) | {
}               byte[_ptr_drawbuffer][top_offs] ' output the pixel data
                outa[clk] := 1                  ' clock it out
                outa[clk] := 0
            outa[lat] := 1                      ' latch the data shifted in
            outa[bl] := 0                       ' unblank the display
'            time.usleep(1)

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
