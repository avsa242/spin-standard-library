{
    --------------------------------------------
    Filename: PS2_Mouse-Demo.spin
    Description: Demo of the PS/2 mouse interface driver
    Author: Jesse Burt
    Copyright (c) 2022
    Started Oct 29, 2022
    Updated Oct 29, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    { PS/2 mouse I/O }
    MOUSE_DATA  = 24
    MOUSE_CLK   = 25
' --

OBJ

    cfg  : "boardcfg.quickstart-hib"
    mouse: "input.mouse.ps2"
    ser  : "com.serial.terminal.ansi"
    time : "time"

PUB main{}

    setup{}

    repeat
        ser.pos_xy(0, 3)
        ser.strln(string("Current coordinates:"))
        ser.printf3(string("Absolute:           X = %5.5d  Y = %5.5d  Z = %5.5d\n\r"), {
}                                               mouse.abs_x{}, mouse.abs_y{}, mouse.abs_z{})

        ser.printf3(string("Rel./delta:         X = %5.5d  Y = %5.5d  Z = %5.5d\n\r"), {
}                                               mouse.delta_x{}, mouse.delta_y{}, mouse.delta_z{})

        ser.printf1(string("Button bitmask:     %05.5b"), mouse.buttons{})

PUB setup{} | elapsed, timed_out

    ser.start(SER_BAUD)
    time.msleep(10)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    mouse.start(MOUSE_DATA, MOUSE_CLK)
    ser.puts(string("Probing for mouse..."))

    elapsed := timed_out := 0
    repeat until mouse.present{}
        if (elapsed > 3_000)                    ' wait up to about 3 seconds before giving up
            ser.strln(string("not found - timed out"))
            repeat
        elapsed++
        time.msleep(1)

    ser.strln(string("found"))

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

