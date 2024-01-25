{
---------------------------------------------------------------------------------------------------
    Filename:       MLX90621-VGA-Demo.spin
    Description:    Demo of the MLX90621 driver using a VGA display
    Author:         Jesse Burt
    Started:        Jun 27, 2020
    Updated:        Jan 25, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}
CON

    _clkmode        = cfg._clkmode
    _xinfreq        = cfg._xinfreq

' -- User-modifiable constants
' MLX90621
    SCL_PIN         = 16
    SDA_PIN         = 17
    I2C_FREQ        = 1_000_000
' --


OBJ

    cfg:    "boardcfg.quickstart-hib"
    fnt:    "font.5x8"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    mlx:    "sensor.thermal-array.mlx90621"
    vga:    "display.vga.bitmap.160x120" | PIN_GRP=0    { 0 .. 3 }
    time:   "time"


VAR

    long _keyinput_stack[50]
    long _ir_frame[66]
    long _offset
    long _settings_changed

    word _mlx_refrate

    word _fx, _fy, _fw, _fh

    byte _palette[64]
    byte _mlx_adc_res, _mlx_adcref
    byte _invert_x, _col_scl
    byte _hotspot_mark


PUB main()

    setup()
    draw_vscale(vga.XMAX-5, 0, vga.YMAX)

    repeat
        if (_settings_changed)
            update_settings()
        mlx.get_frame(@_ir_frame)
        draw_frame(_fx, _fy, _fw, _fh)


PUB draw_frame(fx, fy, pixw, pixh) | x, y, color_c, ir_offset, pixsx, pixsy, pixex, pixey, maxx, maxy, maxp
' Draw the thermal image
    vga.wait_vsync()                             ' wait for vertical sync
    repeat y from 0 to mlx.YMAX
        repeat x from 0 to mlx.XMAX
            if (_invert_x)                      ' Invert X display if set
                ir_offset := ((mlx.XMAX-x) * 4) + y
            else
                ir_offset := (x * 4) + y
            ' compute color
            color_c := _palette[(_ir_frame[ir_offset] * _col_scl) >> 10 + _offset]
            pixsx := fx + (x * pixw)            ' start and end image pixel
            pixsy := fy + (y * (pixh + 1))      '   coords
            pixex := pixsx + pixw
            pixey := pixsy + pixh

            if (_ir_frame[ir_offset] > maxp)    ' Check if this is the hottest
                maxp := _ir_frame[ir_offset]    '   spot in the image
                maxx := pixsx
                maxy := pixsy
            vga.box(pixsx, pixsy, pixex, pixey, color_c, TRUE)

    if (_hotspot_mark)                          ' Mark hotspot
        ' white box
'        vga.box(maxx, maxy, maxx+pixw, maxy+pixh, vga.MAX_COLOR, false)

        ' white cross-hair
        vga.line(maxx, maxy+(pixh/2), maxx+pixw, maxy+(pixh/2), vga.MAX_COLOR)
        vga.line(maxx+(pixw/2), maxy, maxx+(pixw/2), maxy+pixh, vga.MAX_COLOR)


PUB draw_vscale(x, y, ht) | idx, color, scl_width, bottom, top, range
' Draw the color scale setup at program start
    range := bottom := y+ht
    top := 0
    scl_width := 5

    repeat idx from bottom to top+(vga.YMAX-vga.MAX_COLOR)
        color := _palette[(range-idx)]
        vga.line(x, idx, x+scl_width, idx, color)


PUB update_settings() | col, row, reftmp
' Settings have been changed by the user - update the sensor and the
'   displayed settings
    mlx.temp_adc_res(_mlx_adc_res)              ' Update sensor with current
    mlx.refresh_rate(_mlx_refrate)              '   settings
    mlx.adc_ref(_mlx_adcref)

    reftmp := mlx.adc_ref(-2)                   ' read from sensor for display
    col := 0
    row := (vga.textrows()-1) - 5               ' Position at screen bottom
    vga.fgcolor(vga.MAX_COLOR)
    vga.pos_xy(col, row)

    vga.printf1(@"X-axis invert: %s\n\r", lookupz(_invert_x: @"No ", @"Yes"))
    vga.printf1(@"FPS: %dHz   \n\r", mlx.refresh_rate(-2))
    vga.printf1(@"ADC: %dbits\n\r", mlx.temp_adc_res(-2))
    vga.printf1(@"ADC reference: %s\n\r", lookupz(reftmp: @"High", @"Low  "))

    _fx := vga.CENTERX - ((_fw * 16) / 2)       ' Approx center of screen
    _fy := 10
    vga.box(0, 0, vga.XMAX-10, vga.CENTERY, 0, TRUE)    ' Clear out last thermal image
                                                ' (in case resizing smaller)
    _settings_changed := FALSE


PUB cog_key_input() | cmd

    repeat
        repeat until cmd := ser.getchar()
        case cmd
            "A":                                ' ADC resolution (bits)
                _mlx_adc_res := (_mlx_adc_res + 1) <# 18
            "a":
                _mlx_adc_res := (_mlx_adc_res - 1) #> 15
            "C":                                ' Color scaling/contrast
                _col_scl := (_col_scl + 1) <# 16' ++
            "c":
                _col_scl := (_col_scl - 1) #> 1 ' --
            "F":                                ' sensor refresh rate (Hz)
                _mlx_refrate := (_mlx_refrate * 2) <# 512
            "f":
                _mlx_refrate := (_mlx_refrate / 2) #> 1
            "h":                                ' mark hotspot on/off
                _hotspot_mark ^= 1
            "r":                                ' sensor ADC reference (hi/low)
                _mlx_adcref ^= 1
            "S":                                ' thermal image pixel size
                _fw := (_fw + 1) <# 9           ' ++
                _fh := (_fh + 1) <# 9
            "s":
                _fw := (_fw - 1) #> 1           ' --
                _fh := (_fh - 1) #> 1
            "-":                                ' thermal image reference level
                _offset := 0 #> (_offset - 1)   '   or color offset
            "=":
                _offset := (_offset + 1) <# vga.MAX_COLOR
            "x":                                ' invert thermal image X-axis
                _invert_x ^= 1
            other:
                next
        _settings_changed := TRUE               ' trigger for main loop to call update_settings()


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    setup_palette()
    vga.start()
    ser.strln(@"VGA 8bpp driver started")
    vga.set_font(fnt.ptr(), fnt.setup())
    vga.clear()
    vga.char_attrs(vga.DRAWBG)

    if ( mlx.startx(SCL_PIN, SDA_PIN, I2C_FREQ) )
        ser.strln(@"MLX90621 driver started")
        mlx.defaults()
        mlx.opmode(mlx.CONT)
        _mlx_adc_res := 18                       ' Initial sensor settings
        _mlx_refrate := 32
        _mlx_adcref := 1
    else
        ser.strln(@"MLX90621 driver failed to start - halting")
        repeat

    _col_scl := 16
    _fw := 6
    _fh := 6
    _invert_x := 0
    cognew(cog_key_input(), @_keyinput_stack)
    _settings_changed := TRUE


PUB setup_palette() | i, r, g, b, c, d
' Set up palette
    d := 4
    r := g := b := c := 0
    repeat i from 0 to vga.MAX_COLOR
        case i
            0..7:                                           ' violet
                ifnot i // d                                ' Step color only every (d-1)
                    r += 1 <# 3
                    g := 0
                    b += 1 <# 3
            8..15:                                          ' blue
                ifnot i // d
                    r -= 1 #> 0
                    g := 0
                    b := b
            16..23:                                         ' cyan
                ifnot i // d
                    r := 0
                    g += 1 <# 3
                    b := b
            24..31:                                         ' green
                ifnot i // d
                    r := 0
                    g := g
                    b -= 1 #> 0
            32..39:                                         ' yellow
                ifnot i // d
                    r += 1 <# 3
                    g := g
                    b := b
            40..47:                                         ' red
                ifnot i // d
                    r := r
                    g -= 1 #> 0
                    b := 0
            48..55:                                         ' pink
                ifnot i // d
                    r := r
                    g += 1 <# 3
                    b += 1 <# 3
            56..62:                                         ' grey
                ifnot i // d
                    r -= 1 #> 0
                    g -= 1 #> 0
                    b -= 1 #> 0
            63:                                             ' white
                r := g := b := 3
        c := (r << 4) | (g << 2) | b
        _palette[i] := c
    _palette[0] := $00

DAT
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

