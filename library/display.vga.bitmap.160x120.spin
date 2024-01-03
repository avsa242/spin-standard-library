{
    --------------------------------------------
    Filename: display.vga.bitmap.160x120.spin
    Author: Kwabena W. Agyeman
    Modified By: Jesse Burt
    Description: Bitmap VGA display engine (6bpp color, 160x120)
    Started: Nov 17, 2009
    Updated: Jan 2, 2024
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is a modified version of VGA64_PIXEngine.spin,
        originally by Kwabena W. Agyeman.
        The original header is preserved below.
}
{{

 VGA64 6 Bits Per Pixel Engine

 Author: Kwabena W. Agyeman
 Updated: 11172010
 Designed For: P8X32A
 Version: 1.0

 Copyright (c) 2010 Kwabena W. Agyeman
 See end of file for terms of use.

 Update History:

 v1.0 - Original release - 11172009.

 For each included copy of this object only one spin interpreter should access it at a time.

 Nyamekye,

}}
#define MEMMV_NATIVE bytemove
#include "graphics.common.spinh"

CON

    { default I/O configuration - this can be overridden in the parent object }
    PIN_GRP     = 0                             ' 0..3 for each group of 8 consecutive pins

    { driver limits }
    MAX_COLOR   = 63
    WIDTH       = 160
    HEIGHT      = 120
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1
    CENTERX     = WIDTH/2
    CENTERY     = HEIGHT/2
    BYTESPERPX  = 1
    PIX_CLK     = 25_175_000

VAR

    byte _framebuffer[WIDTH * HEIGHT]
    byte _cog

PUB start(): status
' Start VGA engine using default I/O settings
    return startx(PIN_GRP, WIDTH, HEIGHT, @_framebuffer)

PUB startx(PINGRP, DISP_WIDTH, DISP_HEIGHT, ptr_dispbuff): status
' Start VGA engine
'   PINGRP: 8-pin group number (0, 1, 2, 3 for start pin as 0, 8, 16, 24, resp)
'   pins must be connected contiguously in the following (ascending) order:
'       Vsync, Hsync, B0, B1, G0, G1, R0, R1
'   WIDTH, HEIGHT: ignored for compatibility with other drivers
'   ptr_dispbuff: pointer to 19,200 byte (160*120) display/frame buffer
    stop

    _disp_width := WIDTH                        ' use builtin symbols; params
    _disp_height := HEIGHT                      '   are only for API compat
    _disp_xmax := _disp_width - 1               '   with other drivers
    _disp_ymax := _disp_height - 1
    _buff_sz := _disp_width * _disp_height
    _bytesperln := WIDTH * BYTESPERPX
    set_address(ptr_dispbuff)

    PINGRP := ((PINGRP <# 3) #> 0)
    directionState := ($FF << (8 * PINGRP))
    videoState := ($30_00_00_FF | (PINGRP << 9))

    PINGRP := constant((PIX_CLK + 1_600) / 4)
    frequencyState := 1
    repeat 32
        PINGRP <<= 1
        frequencyState <-= 1
        if(PINGRP => clkfreq)
            PINGRP -= clkfreq
            frequencyState += 1

    displayIndicatorAddress := @displayIndicator
    syncIndicatorAddress := @syncIndicator
    status := _cog := cognew(@initialization, _ptr_drawbuffer)+1

PUB stop

    if(_cog)
        cogstop(_cog-1)
        _cog := 0

PUB clear{}
' Clear the display
    longfill(_ptr_drawbuffer, _bgcolor, constant((WIDTH * HEIGHT) / 4))

PUB disp_state(state)
' Enable video output
'   Valid values: TRUE (-1), FALSE (0)
    displayIndicator := state

PUB disp_rate(rate)
' Returns true or false depending on the time elasped according to a specified rate.
'   Rate - A display rate to return at. 0=0.234375Hz, 1=0.46875Hz, 2=0.9375Hz, 3=1.875Hz, 4=3.75Hz, 5=7.5Hz, 6=15Hz, 7=30Hz.
    result or= (($80 >> ((rate <# 7) #> 0)) & syncIndicator)

PUB plot(x, y, color)
' Plot pixel at (x, y) in color
    if (x < 0 or x > _disp_xmax) or (y < 0 or y > _disp_ymax)
        return                                  ' coords out of bounds, ignore
#ifdef GFX_DIRECT
' direct to display
'   (not implemented)
#else
' buffered display
    byte[_ptr_drawbuffer][x + (y * _disp_width)] := (color << 2) | $3
#endif

#ifndef GFX_DIRECT
PUB point(x, y): pix_clr
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    return byte[_ptr_drawbuffer][x + (y * _disp_width)] >> 2
#endif

PUB show{}
' dummy method for compatibility with other drivers

PUB wait_vsync
' Waits for the display vertical refresh.
    result := syncIndicator
    repeat until(result <> syncIndicator)

#ifndef GFX_DIRECT
PRI memfill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    bytefill(_ptr_drawbuffer + (xs + (ys * _bytesperln)), (val << 2) | $3, count)
#endif

#define _PASM_
#include "core.con.counters.spin"

DAT

                        org     0

' Initialization

initialization          mov     vcfg,           videoState                 ' Setup video hardware.
                        mov     frqa,           frequencyState             '
                        movi    ctra,           #(VCO_DIV_4 | PLL_INTERNAL)

'                       Active Video
loop                    mov     displayCounter, par                        ' Set/Reset tiles fill counter.
                        mov     tilesCounter,   #120                       '

tilesDisplay            mov     tileCounter,    #4                         ' Set/Reset tile fill counter.

tileDisplay             mov     vscl,           visibleScale               ' Set/Reset the video scale.
                        mov     counter,        #40                        '

' Visible Video
videoLoop               rdlong  buffer,         displayCounter             ' Download new pixels.
                        add     displayCounter, #4                         '

                        or      buffer,         HVSyncColors               ' Update display scanline.
                        waitvid buffer,         #%%3210                    '

                        djnz    counter,        #videoLoop                 ' Repeat.

' Invisible Video
                        mov     vscl,           invisibleScale             ' Set/Reset the video scale.

                        waitvid HSyncColors,    syncPixels                 ' Horizontal Sync.

' Repeat
                        sub     displayCounter, #160                       ' Repeat.
                        djnz    tileCounter,    #tileDisplay               '

                        add     displayCounter, #160                       ' Repeat.
                        djnz    tilesCounter,   #tilesDisplay              '

'                       Inactive Video
                        add     refreshCounter, #1                         ' Update sync indicator.
                        wrbyte  refreshCounter, syncIndicatorAddress       '

' Front Porch

                        mov     counter,        #11                        ' Set loop counter.

frontPorch              mov     vscl,           blankPixels                ' Invisible lines.
                        waitvid HSyncColors,    #0                         '

                        mov     vscl,           invisibleScale             ' Horizontal Sync.
                        waitvid HSyncColors,    syncPixels                 '

                        djnz    counter,        #frontPorch                ' Repeat # times.

' Vertical Sync
                        mov     counter,        #(2 + 2)                   ' Set loop counter.

verticalSync            mov     vscl,           blankPixels                ' Invisible lines.
                        waitvid VSyncColors,    #0                         '

                        mov     vscl,           invisibleScale             ' Vertical Sync.
                        waitvid VSyncColors,    syncPixels                 '

                        djnz    counter,        #verticalSync              ' Repeat # times.

' Back Porch
                        mov     counter,        #31                        ' Set loop counter.

backPorch               mov     vscl,           blankPixels                ' Invisible lines.
                        waitvid HSyncColors,    #0                         '

                        mov     vscl,           invisibleScale             ' Horizontal Sync.
                        waitvid HSyncColors,    syncPixels                 '

                        djnz    counter,        #backPorch                 ' Repeat # times.

' Update Display Settings
                        rdbyte  buffer,         displayIndicatorAddress wz ' Update display settings.
                        muxnz   dira,           directionState             '

' Loop
                        jmp     #loop                                      ' Loop.

'                       Data
invisibleScale          long    (16 << 12) + 160                           ' Scaling for inactive video.
visibleScale            long    (4 << 12) + 16                             ' Scaling for active video.
blankPixels             long    640                                        ' Blank scanline pixel length.
syncPixels              long    $00_00_3F_FC                               ' F-porch, h-sync, and b-porch.
HSyncColors             long    $01_03_01_03                               ' Horizontal sync color mask.
VSyncColors             long    $00_02_00_02                               ' Vertical sync color mask.
HVSyncColors            long    $03_03_03_03                               ' Horizontal and vertical sync colors.

' Configuration Settings
directionState          long    0
videoState              long    0
frequencyState          long    0

' Addresses
displayIndicatorAddress long    0
syncIndicatorAddress    long    0

' Run Time Variables
counter                 res     1
buffer                  res     1

tileCounter             res     1
tilesCounter            res     1

refreshCounter          res     1
displayCounter          res     1


                        fit     496


displayIndicator        byte    1                                          ' Video output control.
syncIndicator           byte    0                                          ' Video update control.

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

