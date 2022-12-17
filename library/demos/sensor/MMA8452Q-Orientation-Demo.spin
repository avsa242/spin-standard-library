{
    --------------------------------------------
    Filename: MMA8452Q-Orientation-Demo.spin
    Author: Jesse Burt
    Description: Demo of the MMA8452Q driver's portrait/landscape orientation
        detection functionality.
    Copyright (c) 2022
    Started Aug 8, 2021
    Updated Nov 5, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
    ADDR_BITS   = 0                             ' 0, 1
' --

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    accel   : "sensor.accel.3dof.mma8452q"

PUB main{}

    setup{}
    accel.preset_active{}                       ' default settings, but enable
                                                ' sensor power, and set
                                                ' scale factors
    accel.orient_detect_ena(true)                   ' enable orientation detection

    repeat
        ser.pos_xy(0, 3)
        ser.puts(string("Orientation: "))
        case accel.orientation{}
            accel#PORTUP_FR:
                ser.str(string("Portrait-up, front-facing"))
            accel#PORTUP_BK:
                ser.str(string("Portrait-up, back-facing"))
            accel#PORTDN_FR:
                ser.str(string("Portrait-down, front-facing"))
            accel#PORTDN_BK:
                ser.str(string("Portrait-down, back-facing"))
            accel#LANDRT_FR:
                ser.str(string("Landscape-right, front-facing"))
            accel#LANDRT_BK:
                ser.str(string("Landscape-right, back-facing"))
            accel#LANDLT_FR:
                ser.str(string("Landscape-left, front-facing"))
            accel#LANDLT_BK:
                ser.str(string("Landscape-left, back-facing"))
            other:
        ser.clear_line{}

        if (ser.rx_check{} == "c")              ' press the 'c' key in the demo
            calibrate{}                         ' to calibrate sensor offsets

PUB calibrate{}

    ser.pos_xy(0, 5)
    ser.puts(string("Calibrating..."))
    accel.calibrate_accel{}
    ser.pos_x(0)
    ser.clear_line{}

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if accel.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS)
        ser.strln(string("MMA8452Q driver started (I2C)"))
    else
        ser.strln(string("MMA8452Q driver failed to start - halting"))
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

