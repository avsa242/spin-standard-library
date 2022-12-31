{
    --------------------------------------------
    Filename: BBQ20KBD-Demo.spin
    Author: Jesse Burt
    Description: Demo of the BBQ20KBD driver
    Copyright (c) 2022
    Started Dec 30, 2022
    Updated Dec 31, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    { I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000
' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    time:   "time"
    keybd:  "input.keyboard.bbq20kbd"

PUB main{}

    setup{}
    repeat
        ser.clear{}
        ser.pos_xy(0, 0)
        ser.strln(@"Press a key to run a demo:")
        ser.strln(@"k, K: keyboard/keypress demo")
        ser.strln(@"t, T: trackpad demo")

        case ser.getchar{}
            "k", "K":
                keypress_demo{}
            "t", "T":
                trackpad_demo{}
            other:
                next

PUB keypress_demo{} | ch
' Demonstrate the keyboard input capability
    ser.clear{}
    ser.strln(string("Type on the BBQ20KBD and the keypresses will be shown here:"))
    ser.strln(string("  Caps lock on: alt + right shift, Num lock on: alt + left shift"))
    ser.strln(string("  Caps lock off: right shift, Num lock off: Left shift"))
    ser.strln(string("  (press 'q' in the serial terminal to return to the main menu)"))

    repeat
        repeat until keybd.available{}
        ser.putchar(keybd.getchar{})
    while (ser.rx_check{} <> "q")

PUB trackpad_demo{}
' Demonstrate the trackpad input capability
    ser.clear{}
    ser.strln(string("Touch the trackpad to see the position delta:"))
    ser.strln(string("  (press 'q' in the serial terminal to return to the main menu)"))

    { set the minimum and maximum absolute position for the X and Y axes: NEGX to POSX }
    keybd.set_trackpad_abs_x_min(0)
    keybd.set_trackpad_abs_x_max(1024)
    keybd.set_trackpad_abs_y_min(0)
    keybd.set_trackpad_abs_y_max(1024)

    { set trackpad sensitivty: 1..8 (1 = least sensitive, 8 = most sensitive) }
    keybd.set_trackpad_sens_x(8)
    keybd.set_trackpad_sens_y(8)

    repeat
        ser.pos_xy(0, 3)
        ser.printf2(string("Relative x = %4.4d\ty = %4.4d\n\r"), keybd.trackpad_rel_x{}, {
}                                                                keybd.trackpad_rel_y{})
        ser.printf2(string("Absolute x = %9.9d\ty = %9.9d\n\r"), keybd.trackpad_abs_x{}, {
}                                                                keybd.trackpad_abs_y{})
    while (ser.rx_check{} <> "q")

PUB setup{}

    ser.init_def(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(@"Serial terminal started")

    if (keybd.startx(SCL_PIN, SDA_PIN, I2C_FREQ))
        ser.strln(@"BBQ20KBD driver started")
    else
        ser.strln(@"BBQ20KBD driver failed to start - halting")
        repeat

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

