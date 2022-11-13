 {
    --------------------------------------------
    Filename: MLX90621-LCD-QVGA.spin
    Author: Jesse Burt
    Description: Basic thermal imager
        thermal sensor: MLX90621
        display: ILI9341 (320x240)
    Copyright (c) 2022
    Started: Jul 7, 2022
    Updated: Nov 13, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _xinfreq    = cfg#_xinfreq
    _clkmode    = cfg#_clkmode

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    { LCD 8-bit parallel }
    LCD_BASEPIN = 0
    RES_PIN     = 8
    CS_PIN      = 9
    DC_PIN      = 10
    WR_PIN      = 11
    RD_PIN      = 12

    WIDTH       = 320
    HEIGHT      = 240

    { MLX90621 I2C }
    I2C_SCL     = 24
    I2C_SDA     = 25
    I2C_HZ      = 1_000_000
' --

OBJ

    cfg: "boardcfg.flip"
    sensor: "sensor.thermal-array.mlx90621"
    disp: "display.lcd.ili9341"

PUB main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    disp.startx(LCD_BASEPIN, RES_PIN, CS_PIN, DC_PIN, WR_PIN, RD_PIN, WIDTH, HEIGHT)
    ser.strln(string("ILI9341 driver started"))
    disp.font_spacing(1, 0)
    disp.font_scl(3)
    disp.font_sz(fnt#WIDTH, fnt#HEIGHT)
    disp.font_addr(fnt.ptr{})
    disp.preset_def{}

    { set up for landscape orientation, B-G-R subpixels }
    disp.rotation(1)
    disp.mirror_v(true)
    disp.mirror_h(false)
    disp.subpix_order(disp.BGR)
    disp.bgcolor(0)
    disp.clear{}
    if (sensor.startx(I2C_SCL, I2C_SDA, I2C_HZ))
        ser.strln(string("MLX90621 driver started"))
        sensor.defaults{}
        sensor.opmode(sensor.CONT)
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
    _fw := WIDTH/sensor#WIDTH
    _fh := WIDTH/sensor#WIDTH
    _inv_x := 0
    _set_chgd := 1
    _show_sets := 1
    _show_scl := 1

    imager{}

#include "thermal-imager-common.spinh"

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

