{
    --------------------------------------------
    Filename: display.vga.bitmap.160x120.spin
    Author: Kwabena W. Agyeman
    Modified By: Jesse Burt
    Description: Bitmap VGA display engine (6bpp color, 160x120)
    Started: Nov 17, 2009
    Updated: Apr 4, 2021
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
#define _PASM_
#define VGABITMAP6BPP
#include "lib.gfx.bitmap.spin"

CON

    MAX_COLOR   = 63
    DISP_WIDTH  = 160
    DISP_HEIGHT = 120
    BYTESPERPX  = 1
    PIX_CLK     = 25_175_000

VAR

    long _ptr_drawbuffer
    word _disp_width, _disp_height, _disp_xmax, _disp_ymax, _buff_sz
    word _bytesperln
    byte _cog

OBJ

    ctrs    : "core.con.counters"

PUB Start(pinGroup, WIDTH, HEIGHT, drawbuffer_address): okay
' PinGroup - Pin group to use to drive the video circuit. Between 0 and 3.
    Stop

    _disp_width := DISP_WIDTH                               ' Use these constants DISP_WIDTH and HEIGHT
    _disp_height := DISP_HEIGHT                             ' WIDTH and HEIGHT are just dummy params
    _disp_xmax := _disp_width - 1                           '   for API compatibility with other drivers
    _disp_ymax := _disp_height - 1
    _buff_sz := _disp_width * _disp_height
    _bytesperln := DISP_WIDTH * BYTESPERPX
    Address(drawbuffer_address)

    pinGroup := ((pinGroup <# 3) #> 0)
    directionState := ($FF << (8 * pinGroup))
    videoState := ($30_00_00_FF | (pinGroup << 9))

    pinGroup := constant((PIX_CLK + 1_600) / 4)
    frequencyState := 1
    repeat 32
        pinGroup <<= 1
        frequencyState <-= 1
        if(pinGroup => clkfreq)
            pinGroup -= clkfreq
            frequencyState += 1

    displayIndicatorAddress := @displayIndicator
    syncIndicatorAddress := @syncIndicator
    okay := _cog := cognew(@initialization, _ptr_drawbuffer)+1

PUB Stop

    if(_cog)
        cogstop(_cog-1)
        _cog := 0

PUB Address(addr)
' Set address of display buffer
'   Example:
'       display.Address(@_framebuffer)
    _ptr_drawbuffer := addr

PUB ClearAccel
' Clear screen to black
    longfill(_ptr_drawbuffer, 0, constant((DISP_WIDTH * DISP_HEIGHT) / 4))

PUB DisplayState(state)
' Enable video output
'   Valid values: TRUE (-1), FALSE (0)
    displayIndicator := state

PUB DisplayRate(rate)
' Returns true or false depending on the time elasped according to a specified rate.
'   Rate - A display rate to return at. 0=0.234375Hz, 1=0.46875Hz, 2=0.9375Hz, 3=1.875Hz, 4=3.75Hz, 5=7.5Hz, 6=15Hz, 7=30Hz.
    result or= (($80 >> ((rate <# 7) #> 0)) & syncIndicator)

PUB WaitVSync
' Waits for the display vertical refresh.
    result := syncIndicator
    repeat until(result <> syncIndicator)

PUB Update
' dummy method

DAT

                        org     0

' Initialization

initialization          mov     vcfg,           videoState                 ' Setup video hardware.
                        mov     frqa,           frequencyState             '
                        movi    ctra,           #(ctrs#VCO_DIV_4 | ctrs#PLL_INTERNAL)

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

