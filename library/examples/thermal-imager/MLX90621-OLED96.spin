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

OBJ

    cfg : "boardcfg.flip"
    sens: "sensor.thermal-array.mlx90621"
    disp: "display.oled.ssd1331"

PUB Main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    disp.startx(SPI_CS, SPI_CLK, SPI_DIN, SPI_DC, SPI_RES, WIDTH, HEIGHT, 0)
    ser.strln(string("SSD1331 driver started"))
    disp.fontspacing(1, 0)
    disp.fontscale(1)
    disp.fontsize(fnt#WIDTH, fnt#HEIGHT)
    disp.fontaddress(fnt.ptr{})
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

    imager{}

#include "thermal-imager-common.spinh"

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

