{
---------------------------------------------------------------------------------------------------
    Filename:       MLX90621-LCD-QVGA.spin
    Description:    Basic thermal imager
    Author:         Jesse Burt
    Started:        Jul 7, 2022
    Updated:        Jan 27, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    Hardware required:
        * MLX90621 thermal sensor
        * ILI9341 LCD
}

CON

    _xinfreq    = cfg._xinfreq
    _clkmode    = cfg._clkmode

' -- User-modifiable constants
    { MLX90621 I2C }
    I2C_SCL     = 24                            ' don't connect to pins 28, 29
    I2C_SDA     = 25                            ' (sensor contains EEPROM with the same address as
    I2C_HZ      = 1_000_000                     '   the Propeller's EEPROM)
' --

OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    fnt:    "font.5x8"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.thermal-array.mlx90621"
    disp:   "display.lcd.ili9341" | WIDTH=320, HEIGHT=240, DBASEPIN=0, RST=8, CS=9, DC=10, ...
                                    WRX=11, RDX=12

PUB main()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    disp.start()
    ser.strln(@"ILI9341 driver started")
    disp.set_font(fnt.ptr(), fnt.setup())

    { uncomment one of the following depending on the orientation of the display }
    'disp.preset_hiletgo_2p4_320x240_land_up()
    'disp.preset_hiletgo_2p4_320x240_land_down()
    'disp.preset_hiletgo_2p4_240x320_port_up()
    'disp.preset_hiletgo_2p4_240x320_port_down()

    { or instead, set orientation manually }
    'disp.defaults()
    'disp.rotation(1)
    'disp.mirror_v(true)
    'disp.mirror_h(false)

    disp.subpix_order(disp.BGR)                 ' alternatively, disp.RGB
    disp.bgcolor(0)
    disp.clear()

    if ( sensor.startx(I2C_SCL, I2C_SDA, I2C_HZ) )
        ser.strln(@"MLX90621 driver started")
        sensor.defaults()
        sensor.opmode(sensor.CONT)
    else
        ser.strln(@"MLX90621 driver failed to start - halting")
        repeat

    cognew(cog_keyinput(), @_key_stack)

    { initial settings }
    _sens_adcres := 18
    _sens_rate := 32
    _sens_adcref := 0
    _cscl := 2048
    _cdiv := 8
    _fw := disp.WIDTH/sensor.WIDTH
    _fh := disp.WIDTH/sensor.WIDTH
    _inv_x := 0
    _set_chgd := 1
    _show_sets := 1
    _show_scl := 1

    imager()


#include "thermal-imager-common.spinh"          ' code common to all thermal imager demos


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

