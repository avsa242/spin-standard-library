 {
    --------------------------------------------
    Filename: MLX90621-OLED96.spin
    Author: Jesse Burt
    Description: Basic thermal imager
        thermal sensor: MLX90621
        display: SSD1331 (96x64)
    Copyright (c) 2022
    Started: Jul 6, 2022
    Updated: Jul 7, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _xinfreq    = cfg#_xinfreq
    _clkmode    = cfg#_clkmode

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    { OLED SPI }
    SPI_CS      = 0
    SPI_CLK     = 1
    SPI_DIN     = 2
    SPI_DC      = 3
    SPI_RES     = 4

    WIDTH       = 96
    HEIGHT      = 64

    { MLX90621 I2C }
    I2C_SCL     = 24
    I2C_SDA     = 25
    I2C_HZ      = 1_000_000
' --

    { pre-calc some screen-locations and dims }
    BUFFSZ      = (WIDTH * HEIGHT) * disp.BYTESPERPX
    BPL         = (WIDTH * disp#BYTESPERPX)
    XMAX        = (WIDTH - 1)
    YMAX        = (HEIGHT - 1)
    CENTERX     = (WIDTH / 2)
    CENTERY     = (HEIGHT / 2)

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    sens: "sensor.thermal-array.mlx90621"
    disp: "display.oled.ssd1331"
    time: "time"
    fnt : "font.5x8"

VAR

    long _key_stak[100]
    long _ir_frame[66]
    long _coffs
    long _set_chgd

    word _sens_rate

    word _fx, _fy, _fw, _fh
    word _cscl, _cdiv
    byte _sens_adcres, _sens_adcref
    byte _inv_x
    byte _show_hot, _show_sets, _show_scl

PUB Main{}

    setup{}

    repeat
        if (_set_chgd)
            updatesettings{}
        sens.getframe(@_ir_frame)
        drawframe(_fx, _fy, _fw, _fh)

PUB DrawFrame(fx, fy, pixw, pixh) | x, y, c, offs, pixsx, pixsy, pixex, pixey, maxx, maxy, hottest
' Draw the thermal image
    hottest := 0
    repeat y from 0 to sens#YMAX
        repeat x from 0 to sens#XMAX
            if (_inv_x)                      ' invert X display if set
                offs := (((sens#XMAX-x) * sens#HEIGHT) + y)
            else
                offs := ((x * sens#HEIGHT) + y)

            { calc color and scale up pixels from sensor }
            c := getcolor((_ir_frame[offs] * _cscl) / _cdiv +_coffs)
            pixsx := (fx + (x * pixw))
            pixsy := (fy + (y * (pixh + 1)))
            pixex := (pixsx + pixw)
            pixey := (pixsy + pixh)

            { update the hottest spot in the image }
            if ((_ir_frame[offs] > hottest) and (_show_hot))
                hottest := _ir_frame[offs]
                maxx := pixsx
                maxy := pixsy

            disp.box(pixsx, pixsy, pixex, pixey, c, true)

    if (_show_hot)
        { white box }
        disp.box(maxx, maxy, maxx+pixw, maxy+pixh, disp.MAX_COLOR, false)

        { white cross-hair - span entire thermal image }
'        disp.line(_fx, maxy+(pixh / 2), _fx+(_fw * sens#WIDTH), maxy+(pixh / 2), disp.MAX_COLOR)
'        disp.line(maxx + (pixw / 2), _fy, maxx+(pixw / 2), _fy+(_fh * 4), disp.MAX_COLOR)

PUB DrawScaleH(y, h) | x, reflvl
' Draw horizontal color scale horizontal
    { scale 16-bit color range to display width }
    repeat x from 0 to XMAX
        disp.line(x, y, x, (y + h), getcolor(x * constant(disp#MAX_COLOR/WIDTH)))

    { overlay the current reference level as a white line on the scale }
    reflvl := (_coffs / constant(disp#MAX_COLOR/WIDTH))
    disp.line(reflvl, y, reflvl, (y+h), disp#MAX_COLOR)

PUB UpdateSettings{} | reftmp
' Settings have been changed by the user - update the sensor and the displayed settings
    sens.adcres(_sens_adcres)                     ' Update sensor with current
    sens.refreshrate(_sens_rate)                  '   settings
    sens.adcreference(_sens_adcref)

    reftmp := sens.adcreference(-2)              ' read from sensor for display
    disp.fgcolor(disp#MAX_COLOR)
    disp.position(0, disp.textrows{}/2)
    disp.box(0, CENTERY, XMAX, YMAX, 0, true)   ' erase prev text
    if (_show_scl)
        drawscaleh(YMAX-5, 5)
    if (_show_sets)
        disp.printf1(string("X %s  "), lookupz(_inv_x: string("Norm"), string("Inv ")))
        disp.printf1(string("%dHz   \n\r"), sens.refreshrate(-2))
        disp.printf2(string("%dbit (%s)\n\r"), sens.adcres(-2), lookupz(reftmp: string("High ref"), {
}       string("Low ref")))
    _fx := CENTERX - ((_fw * sens#WIDTH) / 2)   ' center justify thermal image
    _fy := 0                                    ' top
    _set_chgd := false

PUB cog_KeyInput{} | cmd
' Handle keypresses from serial terminal
    repeat
        repeat until (cmd := ser.charin{})
        case cmd
            "A":                                ' ADC resolution (bits)
                _sens_adcres := (_sens_adcres + 1) <# 18
            "a":
                _sens_adcres := (_sens_adcres - 1) #> 15
            "C":                                ' Color scaling/contrast
                _cscl := (_cscl * 2) <# 32768
                next
            "c":
                _cscl := (_cscl / 2) #> 1
                next
            "D":                                ' Color scaling/contrast (divisor)
                _cdiv := (_cdiv * 2) <# 32768
                next
            "d":
                _cdiv := (_cdiv / 2) #> 1
                next
            "F":                                ' sensor refresh rate (Hz)
                _sens_rate := (_sens_rate * 2) <# 512
            "f":
                _sens_rate := (_sens_rate / 2) #> 1
            "h":                                ' mark hotspot on/off
                _show_hot ^= 1
            "r":                                ' sensor ADC reference (hi/low)
                _sens_adcref ^= 1
            "t":
                dumpframe(0, 17)
                next
            "-":                                ' color scale reference level
                _coffs := 0 #> (_coffs - 1000)
            "+":
                _coffs := (_coffs + 1000) <# disp.MAX_COLOR
            "x":                                ' invert thermal image X-axis
                _inv_x ^= 1
            "0":
                _show_sets ^= 1
            "1":
                _show_scl ^= 1
            other:
                showhelp{}                      ' show key input legend on serial terminal
                next
        _set_chgd := true                       ' trigger for main loop to update settings

PUB DumpFrame(x, y) | line, col, offs
' Dump frame to the serial terminal
'   NOTE: Image data are longs, but only words are displayed, for compactness
    repeat line from 0 to 3
        repeat col from 0 to 15
            offs := (col * 4) + line
            ser.position(x + (col * 5), y + line)
            ser.hexs(_ir_frame[offs], 4)
            ser.char(" ")

PUB ShowHelp{}

    ser.position(0, 5)
    ser.strln(string("A/a: Increase/decrease thermal sensor ADC resolution"))
    ser.strln(string("C/c: Increase/decrease color scaler (* or / 2)"))
    ser.strln(string("D/d: Increase/decrease color scale divider (* or / 2)"))
    ser.strln(string("F/f: Increase/decrease thermal sensor capture rate (* or / 2)"))
    ser.strln(string("h: Show/hide hot spot"))
    ser.strln(string("r: Toggle thermal sensor ADC reference high/low"))
    ser.strln(string("t: Dump thermal image frame to serial terminal (words)"))
    ser.strln(string("+/-: Increase/decrease color scale reference level (+ or - 1000)"))
    ser.strln(string("x: Toggle invert X-axis thermal image display"))
    ser.strln(string("0: Toggle show settings on display"))
    ser.strln(string("1: Toggle show color scale on display"))

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    disp.startx(SPI_CS, SPI_CLK, SPI_DIN, SPI_DC, SPI_RES, WIDTH, HEIGHT, 0)
    ser.strln(string("SSD1331 driver started"))
    disp.fontspacing(1, 0)
    disp.fontscale(1)
    disp.fontsize(fnt#WIDTH, fnt#HEIGHT)
    disp.fontaddress(fnt.baseaddr{})
    disp.preset_96x64_hiperf{}
    disp.subpixelorder(disp.RGB)
    disp.contrast(127)

    if (sens.startx(I2C_SCL, I2C_SDA, I2C_HZ))
        ser.strln(string("MLX90621 driver started"))
        sens.defaults{}
        sens.opmode(sens.CONT)
    else
        ser.strln(string("MLX90621 driver failed to start - halting"))
        repeat

    cognew(cog_keyinput{}, @_key_stak)

    { initial settings }
    _sens_adcres := 18
    _sens_rate := 32
    _sens_adcref := 0
    _cscl := 2048
    _cdiv := 8
    _fw := 6
    _fh := 6
    _inv_x := 0
    _set_chgd := 1
    _show_sets := 1
    _show_scl := 1

PRI getColor(val): rgb565 | r, g, b
' Map given input 'index' to color
'   'Jet'-like palette: vio-blu-grn-yel-org-red-whi
    longfill(@r, 0, 3)
    case val                                    ' map 16-bit value to 7-point scale
        0..9361:
            r := (val/293)
            g := 0
            b := (val/293)
        9362..18723:
            r := 31-((val-9362)/293)
            g := 0
            b := 31
        18724..28085:
            r := 0
            g := ((val-18724)/147)
            b := 31
        28086..37447:
            r := 0
            g := 63
            b := 31-((val-28086)/293)
        37448..46809:
            r := ((val-37448)/293)
            g := 63
            b := 0
        46810..56171:
            r := 31
            g := 63-((val-46810)/147)
            b := 0
        56172..65535:
            r := 31
            g := ((val-56172)/147)
            b := ((val-56172)/293)

    return ((r << 11) | (g << 5) | b)           ' pack components into RGB565

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

