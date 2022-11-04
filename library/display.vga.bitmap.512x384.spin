{
    --------------------------------------------
    Filename: display.vga.bitmap.512x384.spin
    Description: VGA 512x384 2-color bitmap driver
        * signalled as 1024x768
        * 1bpp (6,144 longs/24kB buffer required)
        * optional sync indicator
    Author: Chip Gracey
    Modified by: Jesse Burt
    Started 2006
    Updated Nov 4, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on vga_512x384_bitmap.spin, originally
        by Chip Gracey

    This object generates a 512x384 pixel bitmap, signaled as 1024x768 VGA.
    Each pixel is one bit, so the entire bitmap requires 512 x 384 / 32 longs,
    or 6,144 longs (24KB). Color words comprised of two byte fields provide
    unique colors for every 32x32 pixel group. These color words require 512/32
    * 384/32 words, or 192 words. Pixel memory and color memory are arranged
    left-to-right then top-to-bottom.

    A sync indicator signals each time the screen is drawn (you may ignore).

    You must provide buffers for the colors, pixels, and sync. Once started,
    all interfacing is done via memory. To this object, all buffers are read-
    only, with the exception of the sync indicator which gets written with a
    non-0 value. You may freely write all buffers to affect screen appearance.

}

CON

    { 512x384 settings - signals as 1024 x 768 @ 67Hz }
    HP          = 512                           ' horizontal pixels
    VP          = 384                           ' vertical pixels
    HF          = 8                             ' horizontal front porch pixels
    HS          = 48                            ' horizontal sync pixels
    HB          = 88                            ' horizontal back porch pixels
    VF          = 1                             ' vertical front porch lines
    VS          = 3                             ' vertical sync lines
    VB          = 28                            ' vertical back porch lines
    HN          = 1                             ' horizontal normal sync state (0|1)
    VN          = 1                             ' vertical normal sync state (0|1)
    PR          = 35                            ' pixel rate in MHz at 80MHz system clock
                                                '   (5MHz granularity)

    XTILES      = HP / 32                       ' tiles
    YTILES      = VP / 32

    HV_INACTIVE = (HN << 1 + VN) * $0101        ' H/V inactive states


VAR

    long _cog

PUB startx(BASEPIN, ptr_colormap, ptr_dispbuff, ptr_sync): status | i, j
' Start VGA driver - starts a COG
'   BASEPIN = VGA starting pin (0, 8, 16, 24)
'       (pin layout: BASEPIN..BASPIN+7: VSYNC, HSYNC, B0, B1, G0, G1, R0, R1)
'   ptr_colormap: Pointer to 192 words which define the "0" and "1" colors for each 32x32
'       pixel group. The lower byte of each word contains the "0" bit RGB data while the
'       upper byte of each word contains the "1" bit RGB data for the associated group. The RGB
'       data in each byte is arranged as %RRGGBB00 (4 levels each).
'
'       color word example: %%0020_3300 = "0" = gold, "1" = blue
'
'   ptr_dispbuff: Pointer to 6,144 longs containing pixels that make up the 512x384 pixel bitmap.
'       Longs' LSBs appear left on the screen, while MSBs appear right. The longs are arranged in
'       sequence from left-to-right, then top-to-bottom.
'
'   ptr_sync: Pointer to long which gets written with non-0 upon each screen refresh. May be used
'       to time writes/scrolls, so that chopiness can be avoided. You must clear it each time if
'       you want to see it re-trigger.
'   Returns: cog ID of PASM driver, or 0 if none available

    stop                                        ' stop if already running

    { implant pin settings and pointers, then launch COG }
    reg_vcfg := $200000FF + (BASEPIN & %111000) << 6
    i := $FF << (BASEPIN & %011000)
    j := BASEPIN & %100000 == 0
    reg_dira := i & j
    reg_dirb := i & !j
    longmove(@color_base, @ptr_colormap, 2)
    if (_cog := cognew(@init, ptr_sync) + 1)
        return true


PUB stop
' Stop VGA driver - frees a COG
    if (_cog)
        cogstop(_cog~ - 1)

DAT

            org                                 ' set origin to $000 for start of program

init
' Initialization code - init I/O
            mov     dira, reg_dira              ' set pin directions
            mov     dirb, reg_dirb

            movi    ctra, #%00001_101           ' enable PLL in ctra (VCO runs at 4x)
            movi    frqa, #(PR / 5) << 3        ' set pixel rate

            mov     vcfg, reg_vcfg              ' set video configuration


field
' Main loop, display field and do invisible sync lines
            mov     color_ptr, color_base       ' reset color pointer
            mov     pixel_ptr, pixel_base       ' reset pixel pointer
            mov     y, #ytiles                  ' set y tiles
:ytile      mov     yl, #32                     ' set y lines per tile
:yline      mov     yx, #2                      ' set y expansion
:yexpand    mov     x, #xtiles                  ' set x tiles
            mov     vscl, vscl_pixel            ' set pixel vscl

:xtile      rdword  color, color_ptr            ' get color word
            and     color, colormask            ' clear h/v bits
            or      color, hv                   ' set h/v inactive states
            rdlong  pixel, pixel_ptr            ' get pixel long
            waitvid color, pixel                ' pass colors and pixels to video
            add     color_ptr, #2               ' point to next color word
            add     pixel_ptr, #4               ' point to next pixel long
            djnz    x, #:xtile                  ' another x tile?

            sub     color_ptr, #xtiles * 2      ' repoint to first colors in same line
            sub     pixel_ptr, #xtiles * 4      ' repoint to first pixels in same line

            mov     x,#1                        ' do horizontal sync
            call    #hsync

            djnz    yx, #:yexpand               ' y expand?

            add     pixel_ptr, #xtiles * 4      ' point to first pixels in next line
            djnz    yl, #:yline                 ' another y line in same tile?

            add     color_ptr, #xtiles * 2      ' point to first colors in next tile
            djnz    y, #:ytile                  ' another y tile?


            wrlong  colormask, par              ' visible done, write non-0 to sync

            mov     x, #VF                      ' do vertical front porch lines
            call    #blank
            mov     x, #VS                      ' do vertical sync lines
            call    #vsync
            mov     x, #VB                      ' do vertical back porch lines
            call    #vsync

            jmp     #field                      ' field done, loop


vsync
' Subroutine - do blank lines
            xor     hvsync, #$101               ' flip vertical sync bits

blank       mov     vscl, hvis                  ' do blank pixels
            waitvid hvsync, #0
hsync       mov     vscl, #HF                   ' do horizontal front porch pixels
            waitvid hvsync, #0
            mov     vscl, #HS                   ' do horizontal sync pixels
            waitvid hvsync, #1
            mov     vscl, #HB                   ' do horizontal back porch pixels
            waitvid hvsync, #0
            djnz    x, #blank                   ' another line?
hsync_ret
blank_ret
vsync_ret   ret


{ data }
reg_dira    long    0                           ' set at runtime
reg_dirb    long    0                           ' set at runtime
reg_vcfg    long    0                           ' set at runtime

color_base  long    0                           ' set at runtime (2 contiguous longs)
pixel_base  long    0                           ' set at runtime

vscl_pixel  long    1 << 12 + 32                ' 1 pixel per clock and 32 pixels per set
colormask   long    $FCFC                       ' mask to isolate R,G,B bits from H,V
hvis        long    HP                          ' visible pixels per scan line
hv          long    hv_inactive                 ' -H,-V states
hvsync      long    hv_inactive ^ $200          ' +/-H,-V states


{ uninitialized data }
color_ptr   res     1
pixel_ptr   res     1
color       res     1
pixel       res     1
x           res     1
y           res     1
yl          res     1
yx          res     1

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

