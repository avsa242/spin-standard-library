{
---------------------------------------------------------------------------------------------------
    Filename:       display.led.smart.spin
    Description:    Driver for various smart LED arrays
    Author:         Jesse Burt
    Started:        Jan 4, 2020
    Updated:        Jan 25, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    NOTE: This is based on jm_rgbx_pixel.spin,
        originally written by Jon McPhalen.

    NOTE: This driver requires a system clock of at least 80MHz
}
#define MEMMV_NATIVE longmove
#include "graphics.common.spinh"

CON

    MAX_PIXELS  = 1024                                          ' max pixels per strip
    MAX_COLOR   = 16_777_215
    BYTESPERPX  = 4

    { -- default I/O configuration - can be overridden in the parent object }
    LED_PIN     = 0
    WIDTH       = 1
    HEIGHT      = 1
    MODEL       = WS2812B
    { -- }

    { specific smart LED models }
    WS2811      = $2811
    WS2812      = $2812
    WS2812B     = $2812B
    WS2813      = $2813
    SK6812_24   = $6812_24
    SK6812_32   = $6812_32
    TM1803      = $1803


    BUFF_SZ     = (WIDTH * HEIGHT) * BYTESPERPX

  ' borrowed from Gavin Garner's TM1804 LED driver
  ' -- additional colors by Lachlan   
  ' -- some alterations by JM
  ' -- modified for RGB and RGBW pixels

  '             RR GG BB WW
    BLACK       = $00_00_00_00
    RED         = $FF_00_00_00
    GREEN       = $00_FF_00_00
    BLUE        = $00_00_FF_00
    WHITE       = $FF_FF_FF_00
    WHITE2      = $00_00_00_FF
    CYAN        = $00_FF_FF_00
    MAGENTA     = $FF_00_FF_00
    YELLOW      = $FF_FF_00_00
    CHARTREUSE  = $7F_FF_00_00
    ORANGE      = $FF_60_00_00
    AQUAMARINE  = $7F_FF_D4_00
    PINK        = $FF_5F_5F_00
    TURQUOISE   = $3F_E0_C0_00
    REALWHITE   = $C8_FF_FF_00
    INDIGO      = $3F_00_7F_00
    VIOLET      = $BF_7F_BF_00
    MAROON      = $32_00_10_00
    BROWN       = $0E_06_00_00
    CRIMSON     = $DC_28_3C_00
    PURPLE      = $8C_00_FF_00

VAR

    long _cog
    long _ptr_framebuffer                       ' pointer to active pixel buffer
    long _npixels                               ' number of pixels in buffer

' do not modify order; this structure passed to PASM cog
'
    long _connection                            ' compressed connection details
    long _resetticks                            ' ticks in reset period
    long _rgfix                                 ' swap r&g? + bit count for pixels
    long _t0h                                   ' bit0 high time (ticks)
    long _t1h                                   ' bit1 high time (ticks)
    long _cycleticks                            ' ticks in 1.25us
    long _updateframe

    long _framebuffer[BUFF_SZ]

PUB null{}
' This is not a top-level object
' -- this code should only be called from another object
  
PUB start(): status
' Start the driver using default I/O settings
    return startx(LED_PIN, WIDTH, HEIGHT, MODEL, @_framebuffer)

PUB startx(SMLED_PIN, DISP_W, DISP_H, led_model, ptr_fb): status | ustix, holdoff, rgswap, bits, ns0h, ns1h, nsperiod, count
' Start smart-LED engine
'   SMLED_PIN:  I/O pin connected to smart-LED strip/array (0..31)
'   WIDTH:      strip/array width, in pixels (1..1024)
'   HEIGHT:     strip/array height, in pixels (1..1024) (NOTE: (WIDTH * HEIGHT) must be <= 1024)
'   led_model:  Specific model of LEDs
'   ptr_fb:     pointer to display buffer
'   Returns: cogid+1 of PASM engine
    holdoff := 1
    case led_model
        $2811:                                  ' WS2811
            rgswap := FALSE
            bits := 24                          ' 24bpp
            ns0h := 250
            ns1h := 600
            nsperiod := 1250
        $2812:                                  ' WS2812
            rgswap := TRUE
            bits := 24                          ' 24bpp
            ns0h := 350
            ns1h := 700
            nsperiod := 1250
        $2812B:                                 ' WS2812B
            rgswap := TRUE
            bits := 24                          ' 24bpp
            ns0h := 400
            ns1h := 800
            nsperiod := 1250
        $2813:                                  ' WS2813
            rgswap := TRUE
            bits := 24                          ' 24bpp
            ns0h := 375
            ns1h := 875
            nsperiod := 1250
        $6812_24:                               ' SK6812 (RGB)
            rgswap := TRUE
            bits := 24                          ' 24bpp
            ns0h := 300
            ns1h := 600
            nsperiod := 1250
        $6812_32:                               ' SK6812 (RGBW)
            rgswap := TRUE
            bits := 32                          ' 32bpp
            ns0h := 300
            ns1h := 600
            nsperiod := 1250
        $1803:                                  ' TM1803
            rgswap := FALSE
            bits := 24                          ' 24bpp
            ns0h := 780
            ns1h := 1550
            nsperiod := 2330
        OTHER:
            return FALSE

    stop{}                                      ' stop if running
    dira[SMLED_PIN] := 0                        ' clear tx pin in this cog

    if (clkfreq < 80_000_000)                   ' requires 80MHz clock
        return FALSE

    count := (DISP_W * DISP_H)
    if (count < 1 or count > 1024)              ' Must be between 1 and 1024 pixels, inclusive
        return FALSE

    ustix := clkfreq / 1_000_000                ' ticks in 1us

    set_address(ptr_fb)
    _ptr_framebuffer := _ptr_drawbuffer
    setup_led_array(count, SMLED_PIN, bits)     ' set connection details
  
    _resetticks := ustix * 100 * (1 #> holdoff <# 50)           ' note: 80us min reset timing
    _rgfix      := rgswap <> 0                  ' promote non-zero to true
    _t0h        := ustix * ns0h / 1000 - 9      ' pulse widths in ticks (adjusted)
    _t1h        := ustix * ns1h / 1000 - 9
    _cycleticks := ustix * nsperiod / 1000
   
    _cog := cognew(@pixdriver, @_connection) + 1' start the cog
    if (_cog)                                   ' if it started
        repeat until (_connection == 0)         '  wait until ready
    else
        return FALSE                            ' cog didn't start

    _disp_width := DISP_W
    _disp_height := DISP_H
    _disp_xmax := _disp_width - 1
    _disp_ymax := _disp_height - 1
    _buff_sz := (_disp_width * _disp_height) * (bits >> 3) + 1
    _bytesperln := _disp_width * BYTESPERPX
    return _cog

PUB stop{}
' Stops pixel driver cog (if running)
    if (_cog)
        cogstop(_cog - 1)
        _cog := 0

PUB setup_led_array(count, pin, bits): c
' Set attributes of the connected LED array
'   count: total number of LEDs
'   pin: I/O pin the array is connected to
'   bits: bits per color of the LEDs (32 for 32bpp; all other values will effectively set 24)
'   NOTE: this depends on the framebuffer address being set, so must be called _after_
'       calling set_address()
    _npixels := count

    c := _ptr_framebuffer | ((_npixels-1) << 16) | (pin << 26)  ' compress for driver cog

    if (bits == 32)
        c |= |< 31                                              ' set bit 31 for 32-bit pixels

    _connection := c                                            ' set new connection

PUB clear{}
' Clear the display buffer
    longfill(_ptr_drawbuffer, _bgcolor, _npixels)

PUB connected{}
' Returns true when latest connection details picked up by driver
    return (_connection == 0)

PUB draw_to(addr)
' Set address of (optional) draw/render buffer
'   NOTE: This is typically used as an offscreen buffer,
'       to subsequently be copied to the display or "live" buffer,
'       once a complete frame is rendered.
    _ptr_drawbuffer := addr

PUB num_pixels{}
' Returns number of pixels in assiged pixel array                      
    return _npixels

PUB plot(x, y, color)
' Plot pixel at (x, y) in color
    if (x < 0 or x > _disp_xmax) or (y < 0 or y > _disp_ymax)
        return                                  ' coords out of bounds, ignore
#ifdef GFX_DIRECT
' direct to display
'   (not implemented)
#else
' buffered display
    long[_ptr_drawbuffer][x + (y * _disp_width)] := color
#endif

#ifndef GFX_DIRECT
PUB point(x, y): pix_clr
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    return long[_ptr_drawbuffer][x + (y * _disp_width)]
#endif

PUB show{}
' Write the draw buffer to the display
'   NOTE: This is only required when using double-buffering
    longmove(_ptr_framebuffer, _ptr_drawbuffer, _buff_sz/4)

#ifndef GFX_DIRECT
PRI memfill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    longfill(_ptr_drawbuffer + ((xs << 1) + (ys * _bytesperln)), ((val >> 8) & $FF) | ((val << 8) & $FF00), count)
#endif

DAT
' Gamma table
' Liberated from an Adafruit WS2812 demo
  GammaTable            byte      0,   0,   0,   0,   0,   0,   0,   0 
                        byte      0,   0,   0,   0,   0,   0,   0,   0
                        byte      0,   0,   0,   0,   0,   0,   0,   0
                        byte      1,   1,   1,   1,   1,   1,   1,   1
                        byte      1,   1,   1,   1,   2,   2,   2,   2
                        byte      2,   2,   2,   2,   3,   3,   3,   3
                        byte      3,   3,   4,   4,   4,   4,   5,   5
                        byte      5,   5,   5,   6,   6,   6,   6,   7
                        byte      7,   7,   8,   8,   8,   9,   9,   9
                        byte     10,  10,  10,  11,  11,  11,  12,  12
                        byte     13,  13,  13,  14,  14,  15,  15,  16
                        byte     16,  17,  17,  18,  18,  19,  19,  20
                        byte     20,  21,  21,  22,  22,  23,  24,  24
                        byte     25,  25,  26,  27,  27,  28,  29,  29
                        byte     30,  31,  31,  32,  33,  34,  34,  35
                        byte     36,  37,  38,  38,  39,  40,  41,  42
                        byte     42,  43,  44,  45,  46,  47,  48,  49
                        byte     50,  51,  52,  53,  54,  55,  56,  57
                        byte     58,  59,  60,  61,  62,  63,  64,  65
                        byte     66,  68,  69,  70,  71,  72,  73,  75
                        byte     76,  77,  78,  80,  81,  82,  84,  85
                        byte     86,  88,  89,  90,  92,  93,  94,  96
                        byte     97,  99, 100, 102, 103, 105, 106, 108
                        byte    109, 111, 112, 114, 115, 117, 119, 120
                        byte    122, 124, 125, 127, 129, 130, 132, 134
                        byte    136, 137, 139, 141, 143, 145, 146, 148
                        byte    150, 152, 154, 156, 158, 160, 162, 164
                        byte    166, 168, 170, 172, 174, 176, 178, 180
                        byte    182, 184, 186, 188, 191, 193, 195, 197
                        byte    199, 202, 204, 206, 209, 211, 213, 215
                        byte    218, 220, 223, 225, 227, 230, 232, 235
                        byte    237, 240, 242, 245, 247, 250, 252, 255

DAT { auto-run driver } 
                        org     0

pixdriver               mov     t1, par                         ' hub address of parameters -> t1
                        movd    :read, #connect                 ' location of cog parameters -> :read(dest)
                        mov     t2, #6                          ' get 6 parameters
:read                   rdlong  0-0, t1                         ' copy parameter from hub to cog
                        add     t1, #4                          ' next hub element
                        add     :read, INC_DEST                 ' next cog element                         
                        djnz    t2, #:read                      ' done?
                        
setup                   mov     p_hub, connect                  ' extract pointer to pixel array         
                        shl     p_hub, #16
                        shr     p_hub, #16

                        mov     pixcount, connect               ' extract/fix pixel count
                        shl     pixcount, #6                    ' (remove bits flag, tx pin)
                        shr     pixcount, #22                   ' align, 0..MAX_PIXELS-1
                        add     pixcount, #1                    ' fix, 1..MAX_PIXELS

                        mov     t1, connect                     ' extract pin
                        shl     t1, #1                          ' (remove bits flag)
                        shr     t1, #27                         ' align, 0..31
                        mov     txmask, #1                      ' create mask for tx
                        shl     txmask, t1                    
                        andn    outa, txmask                    ' set to output low
                        or      dira, txmask                     

                        mov     pixelbits, #24                  ' assume 24-bit pixels
                        rcl     connect, #1             wc, nr  ' check bit 31
        if_c            add     pixelbits, #8                   ' if set add 8 for 32-bit pixels

                        mov     t1, #0
                        wrlong  t1, par                         ' tell hub we have connection
                        
rgbx_main               rdlong  connect, par            wz      ' check connection
        if_nz           jmp     #setup                            

                        mov     pixaddr, p_hub                  ' point to rgbbuf[0]
                        mov     npix, pixcount                  ' set # active pixels

frame_loop              rdlong  colorbits, pixaddr              ' read a channel
                        add     pixaddr, #4                     ' point to next
                        tjz     swapflag, #shift_out            ' skip fix if swap = 0   

                        
' Correct placement of rg color bytes                    
' -- $RR_GG_BB_WW --> $GG_RR_BB_WW                               

swap_rg                 mov     t1, colorbits                   ' copy for red
                        mov     t2, colorbits                   ' copy for green
                        and     colorbits, HX_0000FFFF          ' isolate blue and white
                        and     t1, HX_FF000000                 ' isolate red
                        shr     t1, #8                          ' move red from byte3 to byte2
                        or      colorbits, t1                   ' add red back in 
                        and     t2, HX_00FF0000                 ' isolate green
                        shl     t2, #8                          ' move green from byte2 to byte3
                        or      colorbits, t2                   ' add green back in 

                        
shift_out               mov     nbits, pixelbits                ' set for pixel used
                        mov     bittimer, cycletix              ' set cycle timer for 800kHz
                        add     bittimer, cnt                   ' sync with system   

:loop                   rcl     colorbits, #1           wc      ' msb --> C
        if_nc           mov     t1, bit0hi                      ' if C = 0, use bit0 timing
        if_c            mov     t1, bit1hi                      ' if C = 1, use bit1 timing
                        or      outa, txmask                    ' make tx high
                        add     t1, cnt                         ' sync with system
                        waitcnt t1, #0                          ' hold high       
                        andn    outa, txmask                    ' make tx low     
                        waitcnt bittimer, cycletix              ' finish low side of cycle
                        djnz    nbits, #:loop                   ' more bits?

next_pixel              djnz    npix, #frame_loop               ' done with all leds?                  

reset_delay             mov     bittimer, resettix              ' set reset timing
                        add     bittimer, cnt                   ' sync timer 
                        waitcnt bittimer, #0                    ' let timer expire 

                        jmp     #rgbx_main                      ' back to top

' --------------------------------------------------------------------------------------------------

INC_DEST                long    1 << 9                          ' to increment D field

HX_0000FFFF             long    $0000FFFF                       ' byte masks
HX_00FF0000             long    $00FF0000                         
HX_FF000000             long    $FF000000

connect                 res     1                               ' packed connection details
resettix                res     1                               ' frame reset timing
swapflag                res     1                               ' if !0, swap R & G
bit0hi                  res     1                               ' bit0 high timing
bit1hi                  res     1                               ' bit1 high timing    
cycletix                res     1                               ' 1.25us cycle ticks

p_hub                   res     1                               ' pointer to pixel buffer in use                              
pixcount                res     1                               ' # pixels in buffer                                 
txmask                  res     1                               ' mask for output pin

pixelbits               res     1                               ' bits per pixel                                                                
bittimer                res     1                               ' timer for reset/bit
pixaddr                 res     1                               ' address of current rgbw pixel
npix                    res     1                               ' # of pixels to process
colorbits               res     1                               ' rgbw for current pixel
nbits                   res     1                               ' # of bits to process

t1                      res     1                               ' work vars
t2                      res     1                                
t3                      res     1                                

                        fit     496                                   

DAT
{
Copyright 2024 Jesse Burt

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

