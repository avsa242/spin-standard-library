{
----------------------------------------------------------------------------------------------------
    Filename:       display.oled.ssd1351.spin
    Description:    Driver for Solomon Systech SSD1351 RGB OLED displays
    Author:         Jesse Burt
    Started:        Mar 11, 2020
    Updated:        Apr 1, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

#define MEMMV_NATIVE wordmove
#include "graphics.common.spinh"

CON

    MAX_COLOR       = 65535
    BYTESPERPX      = 2

' Display power on/off modes
    OFF             = 0
    ON              = 1

' Display visibility modes
    ALL_OFF         = 0
    ALL_ON          = 1
    NORMAL          = 2
    INVERTED        = 3

' Color depth formats
    COLOR_65K       = %00   ' or %01
    COLOR_262K      = %10
    COLOR_262K65K2  = %11

' Address increment mode
    ADDR_HORIZ      = 0
    ADDR_VERT       = 1

' Subpixel order
    RGB             = 0
    BGR             = 1

' OLED command lock
    ALL_UNLOCK      = $12
    ALL_LOCK        = $16
    CFG_LOCK        = $B0
    CFG_UNLOCK      = $B1

    { default I/O settings; these can be overridden in the parent object }
    { display dimensions }
    WIDTH           = 96
    HEIGHT          = 64
    XMAX            = WIDTH-1
    YMAX            = HEIGHT-1
    CENTERX         = WIDTH/2
    CENTERY         = HEIGHT/2

    { SPI }
    CS              = 0
    SCK             = 1
    MOSI            = 2
    DC              = 3
    RST             = 4

OBJ

    core:   "core.con.ssd1351"                  ' HW-specific constants
    time:   "time"                              ' timekeeping methods
    spi:    "com.spi.20mhz"                     ' PASM SPI engine (20MHz)

VAR

    long _CS, _DC, _RES

#ifndef GFX_DIRECT
    word _framebuffer[(WIDTH*HEIGHT)]
#endif

    byte _offs_x, _offs_y

    ' shadow registers
    byte _clkdiv, _rmapcolor, _phs1_2

PUB null()
' This is not a top-level object

PUB start(): status
' Start the driver using default I/O settings
#ifdef GFX_DIRECT
    return startx(CS, SCK, MOSI, DC, RST, WIDTH, HEIGHT, 0)
#else
    return startx(CS, SCK, MOSI, DC, RST, WIDTH, HEIGHT, @_framebuffer)
#endif

PUB startx(CS_PIN, CLK_PIN, DIN_PIN, DC_PIN, RES_PIN, DISP_W, DISP_H, ptr_dispbuff): status
' Start driver using custom I/O settings
    if ( lookdown(CS_PIN: 0..31) and lookdown(DC_PIN: 0..31) and lookdown(DIN_PIN: 0..31) and ...
        lookdown(CLK_PIN: 0..31) )
        if ( status := spi.init(CLK_PIN, DIN_PIN, -1, core.SPI_MODE) )
            _DC := DC_PIN
            _RES := RES_PIN
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            outa[_DC] := 1
            dira[_DC] := 1
            set_dims(DISP_W, DISP_H)
            set_address(ptr_dispbuff)
            reset()
            time.usleep(core.T_POR)
            disp_lock(ALL_UNLOCK)
            disp_lock(CFG_UNLOCK)
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop()
' Stop the driver
    visibility(ALL_OFF)
    powered(FALSE)
    spi.deinit()
    dira[_CS] := 0
    dira[_DC] := 0

PUB defaults()
' Apply power-on-reset default settings
    visibility(ALL_OFF)
    disp_start_line(0)
    disp_lines(128)
    clk_freq(3020)
    clk_div(1)
    contrast_abc(138, 81, 138)
    powered(TRUE)
    draw_area(0, 0, 127, 127)
    clear()
    visibility(NORMAL)

PUB preset_newhaven_nhd_1p5 = preset_adafruit_1431
PUB preset_adafruit_1431()
' Preset: Adafruit #1431 (128x128)
    draw_area(0, 0, 127, 127)
    subpix_order(RGB)
    interlace_ena(FALSE)
    color_depth(COLOR_65K)
    disp_start_line(0)
    disp_offset(0, 0)
    clk_freq(3020)
    clk_div(1)
    contrast(127)
    disp_lines(128)

    powered(TRUE)
    visibility(NORMAL)

PUB preset_newhaven_nhd_1p5_port_up = preset_adafruit_1431_port_up
PUB preset_adafruit_1431_port_up()
' Preset: Adafruit #1431 (128x128)
'   Oriented portrait-up (soldered pins are at the top, display ribbon at the bottom)
    preset_adafruit_1431()
    rotation(false)
    mirror_h(false)
    mirror_v(true)

PUB preset_newhaven_nhd_1p5_port_down = preset_adafruit_1431_port_down
PUB preset_adafruit_1431_port_down()
' Preset: Adafruit #1431 (128x128)
'   Oriented portrait-down (soldered pins are at the top, display ribbon at the bottom)
    preset_adafruit_1431()
    rotation(false)
    mirror_h(true)
    mirror_v(false)

PUB preset_newhaven_nhd_1p5_land_left = preset_adafruit_1431_land_left
PUB preset_adafruit_1431_land_left()
' Preset: Adafruit #1431 (128x128)
'   Oriented landscape-left (soldered pins are at the left, display ribbon at the right)
    preset_adafruit_1431()
    rotation(true)
    mirror_h(true)
    mirror_v(true)

PUB preset_newhaven_nhd_1p5_land_right = preset_adafruit_1431_land_right
PUB preset_adafruit_1431_land_right()
' Preset: Adafruit #1431 (128x128)
'   Oriented landscape-right (soldered pins are at the right, display ribbon at the left)
    preset_adafruit_1431()
    rotation(true)
    mirror_h(false)
    mirror_v(false)

PUB preset_clickc_away()
' Preset: MikroE OLED C Click (96x96)
'   (Parallax #64208, MikroE #MIKROE-1585)
'   **Oriented so glass panel is facing away from user user, PCB facing towards
'   origin (upper-left) isn't at 0, 0 on this panel
'   start at 16 pixels in from the left, and add that to the right-hand side
    draw_area(0, 0, 95, 95)
    addr_mode(ADDR_HORIZ)
    subpix_order(RGB)
    interlace_ena(FALSE)
    color_depth(COLOR_65K)
    disp_start_line(0)
    mirror_h(TRUE)
    mirror_v(TRUE)
    disp_offset(16, 32)
    clk_freq(3020)
    clk_div(1)
    contrast(127)
    disp_lines(96)

    powered(TRUE)
    visibility(NORMAL)

PUB preset_clickc_towards()
' Preset: MikroE OLED C Click (96x96)
'   (Parallax #64208, MikroE #MIKROE-1585)
'   **Oriented so glass panel is facing towards user, PCB facing away
'   origin (upper-left) isn't at 0, 0 on this panel
'   start at 16 pixels in from the left, and add that to the right-hand side
    draw_area(0, 0, 95, 95)
    addr_mode(ADDR_HORIZ)
    subpix_order(RGB)
    interlace_ena(FALSE)
    color_depth(COLOR_65K)
    disp_start_line(0)
    mirror_h(FALSE)
    mirror_v(FALSE)
    disp_offset(16, 96)
    clk_freq(3020)
    clk_div(1)
    contrast(127)
    disp_lines(96)

    powered(TRUE)
    visibility(NORMAL)

PUB preset_128x()
' Preset: 128px wide, determine settings for height at runtime
    draw_area(0, 0, _disp_xmax, _disp_ymax)
    addr_mode(ADDR_HORIZ)
    subpix_order(RGB)
    interlace_ena(FALSE)
    color_depth(COLOR_65K)
    disp_start_line(0)
    disp_offset(0, 0)
    clk_freq(3020)
    clk_div(1)
    contrast(127)
    disp_lines(_disp_height)

    powered(TRUE)
    visibility(NORMAL)

PUB preset_128x128()
' Preset: 128px wide, 128px high
    draw_area(0, 0, 127, 127)
    addr_mode(ADDR_HORIZ)
    subpix_order(RGB)
    interlace_ena(FALSE)
    color_depth(COLOR_65K)
    disp_start_line(0)
    disp_offset(0, 0)
    clk_freq(3020)
    clk_div(1)
    contrast(127)
    disp_lines(128)

    powered(TRUE)
    visibility(NORMAL)

PUB preset_128xhiperf()
' Preset: 128px wide, determine settings for height at runtime
'   display osc. set to max clock
    draw_area(0, 0, _disp_xmax, _disp_ymax)
    addr_mode(ADDR_HORIZ)
    subpix_order(RGB)
    interlace_ena(FALSE)
    color_depth(COLOR_65K)
    disp_start_line(0)
    disp_offset(0, 0)
    clk_freq(3100)
    clk_div(1)
    contrast(127)
    disp_lines(_disp_height)

    powered(TRUE)
    visibility(NORMAL)

PUB addr_mode(mode)
' Set display internal addressing mode
'   Valid values:
'  *ADDR_HORIZ (0): Horizontal addressing mode
'   ADDR_VERT (1): Vertical addressing mode
    _rmapcolor := ((_rmapcolor & core.SEGREMAP_MASK) | (ADDR_HORIZ #> mode <# ADDR_VERT))
    writereg(core.SETREMAP, 1, @_rmapcolor)

#ifdef GFX_DIRECT
PUB bitmap(ptr_bmap, xs, ys, bm_wid, bm_lns) | offs, nr_pix
' Display bitmap
'   ptr_bmap: pointer to bitmap data
'   (xs, ys): upper-left corner of bitmap
'   bm_wid: width of bitmap, in pixels
'   bm_lns: number of lines in bitmap
    draw_area(xs, ys, xs+(bm_wid-1), ys+(bm_lns-1))
    outa[_CS] := 0
    outa[_DC] := core.CMD
    spi.wr_byte(core.WRITERAM)

    ' calc total number of pixels to write, based on dims and color depth
    ' clamp to a minimum of 1 to avoid odd behavior
    nr_pix := 1 #> ((xs + bm_wid-1) * (ys + bm_lns-1) * BYTESPERPX)

    outa[_DC] := core.DATA
    spi.wrblock_lsbf(ptr_bmap, nr_pix)
    outa[_CS] := 1
#endif

#ifdef GFX_DIRECT
PUB box(x1, y1, x2, y2, c, fill) | cmd_pkt[2]
' Draw a box
'   (x1, y1): upper-left corner of box
'   (x2, y2): lower-right corner of box
'   c: color
'   fill: filled flag (0: no fill, nonzero: fill)
    if ((x2 < x1) or (y2 < y1))
        return
    if (fill)
        cmd_pkt.byte[0] := core.SETCOLUMN       ' D/C L
        cmd_pkt.byte[1] := x1+_offs_x           ' D/C H
        cmd_pkt.byte[2] := x2+_offs_x
        cmd_pkt.byte[3] := core.SETROW          ' D/C L
        cmd_pkt.byte[4] := y1                   ' D/C H
        cmd_pkt.byte[5] := y2

        outa[_DC] := core.CMD
        outa[_CS] := 0
        spi.wr_byte(cmd_pkt.byte[0])            ' column cmd
        outa[_DC] := core.DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[1], 2)   ' x0, x1

        outa[_DC] := core.CMD
        spi.wr_byte(cmd_pkt.byte[3])            ' row cmd
        outa[_DC] := core.DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[4], 2)   ' y0, y1

        outa[_DC] := core.CMD
        spi.wr_byte(core.WRITERAM)
        outa[_DC] := core.DATA
        spi.wrwordx_msbf(c, ((y2-y1)+1) * ((x2-x1)+1))
    else
        draw_area(x1, y1, x2, y1)               ' top
        outa[_CS] := 0
        outa[_DC] := core.CMD
        spi.wr_byte(core.WRITERAM)
        outa[_DC] := core.DATA
        spi.wrwordx_msbf(c, (x2-x1)+1)

        draw_area(x1, y2, x2, y2)               ' bottom
        outa[_CS] := 0
        outa[_DC] := core.CMD
        spi.wr_byte(core.WRITERAM)
        outa[_DC] := core.DATA
        spi.wrwordx_msbf(c, (x2-x1)+1)

        draw_area(x1, y1, x1, y2)               ' left
        outa[_CS] := 0
        outa[_DC] := core.CMD
        spi.wr_byte(core.WRITERAM)
        outa[_DC] := core.DATA
        spi.wrwordx_msbf(c, (y2-y1)+1)

        draw_area(x2, y1, x2, y2)               ' right
        outa[_CS] := 0
        outa[_DC] := core.CMD
        spi.wr_byte(core.WRITERAM)
        outa[_DC] := core.DATA
        spi.wrwordx_msbf(c, (y2-y1)+1)
    outa[_CS] := 1
#endif

#ifdef GFX_DIRECT
PUB clear()
' Clear the display directly, bypassing the display buffer
    draw_area(0, 0, _disp_xmax, _disp_ymax)
    outa[_DC] := core.CMD
    outa[_CS] := 0
    spi.wr_byte(core.WRITERAM)
    outa[_DC] := core.DATA
    spi.wrwordx_msbf(_bgcolor, _buff_sz/2)
    outa[_CS] := 1

#else

PUB clear()
' Clear the display buffer
    wordfill(_ptr_drawbuffer, _bgcolor, _buff_sz/2)
#endif

PUB clk_div(divider)
' Set clock frequency divider used by the display controller
'   Valid values: 1..16 (clamped to range)
    _clkdiv := ((_clkdiv & core.CLK_DIV_MASK) | ((1 #> divider <# 16)-1))
    writereg(core.CLKDIV, 1, @_clkdiv)

PUB clk_freq(freq)
' Set display internal oscillator frequency, in kHz
'   Valid values: 2500..3100 (clamped to range; POR: 3020)
'   NOTE: Range is interpolated, based on the datasheet min/max values and
'   number of steps, so actual clock frequency may not be accurate.
'   Value set will be rounded to the nearest 40kHz
    freq := ((((2500 #> freq <# 3100) - 2500) / 40) << core.FOSCFREQ)
    _clkdiv := ((freq & core.FOSCFREQ_MASK) | freq)
    writereg(core.CLKDIV, 1, @_clkdiv)

PUB color_depth(format)
' Set expected color format of pixel data
'   Valid values:
'      *COLOR_65K (0): 16-bit/65536 color format 1
'       COLOR_262K (1): 18-bits/262144 color format
'       COLOR_262K65K2 (2): 18-bit/262144 color format, 16-bit/65536 color format 2
    format := ((COLOR_65K #> format <# COLOR_262K65K2) << core.COLORFMT)
    _rmapcolor := ((_rmapcolor & core.COLORFMT_MASK) | format)
    writereg(core.SETREMAP, 1, @_rmapcolor)

PUB comh_voltage(level)
' Set logic high level threshold of COM pins rel. to Vcc, in millivolts
'   Valid values: 720..860 (clamped to range; POR: 820)
'   NOTE: Range is interpolated, based on the datasheet min/max values and number of steps,
'       so actual voltage may not be accurate. Value set will be rounded to the nearest 20mV
    level := (((720 #> level <# 860) - 720) / 20)
    writereg(core.VCOMH, 1, @level)

PUB contrast(level)
' Set display contrast/brightness of all subpixels to the same value
'   Valid values: 0..255 (clamped to range)
    contrast_abc(level, level, level)

PUB contrast_abc(a, b, c) | tmp
' Set contrast/brightness level of subpixels a, b, c
'   Valid values: 0..255 (clamped to range; POR a: 138, b: 81, c: 138)
    tmp.byte[0] := (0 #> a <# 255)
    tmp.byte[1] := (0 #> b <# 255)
    tmp.byte[2] := (0 #> c <# 255)
    writereg(core.SETCNTRSTABC, 3, @tmp)

PUB draw_area(sx, sy, ex, ey) | tmpx, tmpy
' Set drawable display region for subsequent drawing operations
'   Valid values:
'       sx, ex: 0..127
'       sy, ey: 0..127
'   Any other value will be ignored
    ifnot (lookup(sx: 0..127) or lookup(sy: 0..127) or lookup(ex: 0..127) or lookup(ey: 0..127))
        return

    tmpx.byte[0] := (sx + _offs_x)
    tmpx.byte[1] := (ex + _offs_x)
    tmpy.byte[0] := sy
    tmpy.byte[1] := ey

    ' the SSD1351 requires (ex, ey) be greater than (sx, ey)
    ' if they're not, swap them
    if (ex < sx)
        tmpx.byte[2] := tmpx.byte[0]            ' use byte 2 as a temp var
        tmpx.byte[0] := tmpx.byte[1]            ' since it's otherwise unused
        tmpx.byte[1] := tmpx.byte[2]
    if (ey < sy)
        tmpy.byte[2] := tmpy.byte[0]
        tmpy.byte[0] := tmpy.byte[1]
        tmpy.byte[1] := tmpy.byte[2]
    writereg(core.SETCOLUMN, 2, @tmpx)
    writereg(core.SETROW, 2, @tmpy)

PUB disp_lines(lines)
' Set total number of display lines
'   Valid values: 16..128 (clamped to range; POR: 128)
'   Any other value is ignored
    lines := ((16 #> lines <# 128) - 1)
    writereg(core.SETMUXRATIO, 1, @lines)

PUB invert_colors(state)
' Invert display colors
'   Valid values: TRUE (non-zero), *FALSE (0)
    visibility(INVERTED - ((state <> 0) & 1))

PUB disp_offset(x, y)
' Set display offset
    _offs_x := (0 #> x <# 127)
    y := (0 #> y <# 127)
    writereg(core.DISPOFFSET, 1, @y)            ' SSD1351 built-in

PUB disp_start_line(sline)
' Set display start line
'   Valid values: 0..127 (clamped to range; POR: 0)
    sline := (0 #> sline <# 127)
    writereg(core.STARTLINE, 1, @sline)

PUB interlace_ena(state)
' Alternate every other display line:
' Lines 0..31 will appear on even rows (starting on row 0)
' Lines 32..63 will appear on odd rows (starting on row 1)
'   Valid values: TRUE (non-zero), *FALSE (0)
    state := ((((state <> 0) & 1) ^ 1) << core.COMSPLIT)
    _rmapcolor := ((_rmapcolor & core.COMSPLIT_MASK) | state)
    writereg(core.SETREMAP, 1, @_rmapcolor)

#ifdef GFX_DIRECT
PUB line(x1, y1, x2, y2, c) | sx, sy, ddx, ddy, err, e2
' Draw line from x1, y1 to x2, y2, in color c
    if (x1 == x2)
        draw_area(x1, y1, x1, y2)               ' vertical
        outa[_CS] := 0
        outa[_DC] := core.CMD
        spi.wr_byte(core.WRITERAM)
        outa[_DC] := core.DATA
        spi.wrwordx_msbf(c, (||(y2-y1))+1)
        outa[_CS] := 1
        return
    if (y1 == y2)
        draw_area(x1, y1, x2, y1)               ' horizontal
        outa[_CS] := 0
        outa[_DC] := core.CMD
        spi.wr_byte(core.WRITERAM)
        outa[_DC] := core.DATA
        spi.wrwordx_msbf(c, (||(x2-x1))+1)
        outa[_CS] := 1
        return

    ddx := ||(x2-x1)
    ddy := ||(y2-y1)
    err := (ddx - ddy)

    sx := -1
    if (x1 < x2)
        sx := 1

    sy := -1
    if (y1 < y2)
        sy := 1

    repeat until ((x1 == x2) and (y1 == y2))
        plot(x1, y1, c)
        e2 := (err << 1)

        if (e2 > -ddy)
            err -= ddy
            x1 += sx

        if (e2 < ddx)
            err += ddx
            y1 += sy
#endif

PUB disp_lock(mode)
' Lock the display controller from executing commands
'   Valid values:
'      *ALL_UNLOCK ($12): Normal operation - OLED display accepts commands
'       LOCK ($16): Locked - OLED will not process any commands, except LockDisplay(ALL_UNLOCK)
'      *CFG_LOCK ($B0): Configuration registers locked
'       CFG_UNLOCK ($B1): Configuration registers unlocked
    case mode
        ALL_UNLOCK, ALL_LOCK, CFG_LOCK, CFG_UNLOCK:
            writereg(core.SETLOCK, 1, @mode)
        other:
            return

PUB mirror_h(state)
' Mirror the display, horizontally
'   Valid values: TRUE (non-zero), *FALSE (0)
    _rmapcolor := ((_rmapcolor & core.SEGREMAP_MASK) | (((state <> 0) & 1) << core.SEGREMAP))
    writereg(core.SETREMAP, 1, @_rmapcolor)

PUB mirror_v(state)
' Mirror the display, vertically
'   Valid values: TRUE (non-zero), *FALSE (0)
    _rmapcolor := ((_rmapcolor & core.COMREMAP_MASK) | (((state <> 0) & 1) << core.COMREMAP))
    writereg(core.SETREMAP, 1, @_rmapcolor)

PUB phase1_period(clks)
' Set discharge/phase 1 period, in display clocks
'   Valid values: 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31 (clamped to range; POR: 5)
    clks := ((((5 #> clks <# 31) - 1) / 2) - 1)
    clks := ((_phs1_2 & core.PHASE1_MASK) | clks)
    writereg(core.PRECHG, 1, @_phs1_2)

PUB phase2_period(clks)
' Set charge/phase 2 period, in display clocks
'   Valid values: 3..15 (clamped to range; POR: 8)
    clks := ((3 #> clks <# 15) << core.PHASE2)
    _phs1_2 := ((_phs1_2 & core.PHASE2_MASK) | ((3 #> clks <# 15) << core.PHASE2))
    writereg(core.PRECHG, 1, @_phs1_2)

PUB phase3_period(clks)
' Set second charge/phase 3 period, in display clocks
'   Valid values: 1..15 (clamped to range; POR: 8)
    clks := (1 #> clks <# 15)
    writereg(core.SETSECPRECHG, 1, @clks)

PUB plot(x, y, color) | cmd_pkt[3]
' Plot pixel at (x, y) in color
    if ((x < 0) or (x > _disp_xmax) or (y < 0) or (y > _disp_ymax))
        return                                  ' coords out of bounds, ignore
#ifdef GFX_DIRECT
' direct to display
    cmd_pkt.byte[0] := core.SETCOLUMN           ' D/C L
    cmd_pkt.byte[1] := x+_offs_x                ' D/C H
    cmd_pkt.byte[2] := x+_offs_x
    cmd_pkt.byte[3] := core.SETROW              ' D/C L
    cmd_pkt.byte[4] := y                        ' D/C H
    cmd_pkt.byte[5] := y
    cmd_pkt.byte[6] := core.WRITERAM            ' D/C L
    cmd_pkt.byte[7] := color.byte[1]            ' D/C H
    cmd_pkt.byte[8] := color.byte[0]
    outa[_DC] := core.CMD
    outa[_CS] := 0
    spi.wr_byte(cmd_pkt.byte[0])
    outa[_DC] := core.DATA
    spi.wrblock_lsbf(@cmd_pkt.byte[1], 2)

    outa[_DC] := core.CMD
    spi.wr_byte(cmd_pkt.byte[3])
    outa[_DC] := core.DATA
    spi.wrblock_lsbf(@cmd_pkt.byte[4], 2)

    outa[_DC] := core.CMD
    spi.wr_byte(cmd_pkt.byte[6])
    outa[_DC] := core.DATA
    spi.wrblock_lsbf(@cmd_pkt.byte[7], 2)
    outa[_CS] := 1
#else
' buffered display
    word[_ptr_drawbuffer][x + (y * _disp_width)] := color
#endif

#ifndef GFX_DIRECT
PUB point(x, y): pix_clr
' Get color of pixel at x, y
    x := (0 #> x <# _disp_xmax)
    y := (0 #> y <# _disp_ymax)
    return word[_ptr_drawbuffer][x + (y * _disp_width)]
#endif

PUB powered(state)
' Enable display power
'   Valid values:
'       OFF/FALSE (0): Turn off display power
'       ON/TRUE (non-zero): Turn on display power
    state := (((state <> 0) & 1) + core.DISPOFF)
    writereg(state, 0, 0)

PUB prechg_level(level)
' Set first pre-charge voltage level (phase 2) of segment pins, in millivolts
'   Valid values: 200..600 (default: 497)
'   NOTE: Range is interpolated, based on the datasheet min/max values and number of steps,
'       so actual voltage may not be accurate. Value set will be rounded to the nearest 13mV
    level := (((200 #> level <# 600) - 200) / 13)
    writereg(core.PRECHGLEVEL, 1, @level)

PUB reset()
' Reset the display controller
    if (lookdown(_RES: 0..31))
        outa[_RES] := 1
        dira[_RES] := 1
        outa[_RES] := 0
        time.usleep(2)
        outa[_RES] := 1

PUB rotation(state)
' Rotate display
'   Valid values: TRUE (non-zero values), FALSE (0)
'   Any other value returns the current setting
    _rmapcolor := ( (_rmapcolor & core.ADDRINC_MASK) | ((state <> 0) & 1) )
    writereg(core.SETREMAP, 1, @_rmapcolor)

#ifdef GFX_DIRECT
PUB scroll_up_fs(px)
' dummy method
#endif

PUB set_seg_current_scale_factor(s)
' Set segment current scaling factor, in 16ths
'   s: 1..16 (clamped to range; default is 16)
    s := (1 #> s <# 16)-1
    writereg(core.MASTCNTRST_CURR_CTRL, 1, @s)

PUB show()
' Send the draw buffer to the display
#ifndef GFX_DIRECT
    draw_area(0, 0, _disp_xmax, _disp_ymax)
    outa[_DC] := core.CMD
    outa[_CS] := 0
    spi.wr_byte(core.WRITERAM)
    outa[_DC] := core.DATA
    spi.wrblock_lsbf(_ptr_drawbuffer, _buff_sz)
    outa[_CS] := 1
#endif

PUB subpix_order(order)
' Set subpixel color order
'   Valid values:
'      *RGB (0): Red-Green-Blue order
'       BGR (1): Blue-Green-Red order
    order := ((RGB #> order <# BGR) << core.SUBPIX_ORDER)
    _rmapcolor := ((_rmapcolor & core.SUBPIX_ORDER_MASK) | order)
    writereg(core.SETREMAP, 1, @_rmapcolor)

PUB visibility(mode)
' Set display visibility
'   Valid values:
'       ALL_OFF (0): Turns off all pixels
'       ALL_ON (1): Turns on all pixels (white)
'      *NORMAL (2): Normal display (display graphics RAM contents)
'       INVERTED (3): Like NORMAL, but with inverted colors
'   NOTE: This setting doesn't affect the contents of graphics RAM,
'       only how they are displayed
    mode := ((ALL_OFF #> mode <# INVERTED) + core.DISPALLOFF)
    writereg(mode, 0, 0)

#ifndef GFX_DIRECT
PRI memfill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    wordfill(_ptr_drawbuffer + ((xs << 1) + (ys * _bytesperln)), ((val >> 8) & $FF) | ((val << 8) & $FF00), count)
#endif

PRI writereg(reg_nr, nr_bytes, ptr_buff) | tmp
' Write nr_bytes to device from ptr_buff
    case reg_nr
        $9E, $9F, $A4..$A7, $AD..$AF, $B0, $B9, $D1, $E3:
        ' Single-byte command
            outa[_DC] := core.CMD
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            outa[_CS] := 1
            return
        $15, $5C, $75, $96, $A0..$A2, $AB, $B1..$B6, $B8, $BB, $BE, $C1, $C7, $CA, $FD:
        ' Multi-byte command
            outa[_DC] := core.CMD
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            outa[_DC] := core.DATA
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
            return
        other:
            return

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

