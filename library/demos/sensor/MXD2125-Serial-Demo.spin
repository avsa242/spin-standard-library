{
    --------------------------------------------
    Filename: MXD2125-Serial-Demo.spin
    Author: Jesse Burt
    Description: Serial terminal demo of the
        MXD2125 driver
    Copyright (c) 2022
    Started Sep 8, 2020
    Updated Dec 23, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    CLK_FREQ    = (_clkmode >> 6) * _xinfreq
    CLK_SCALE   = CLK_FREQ / 500_000

' -- User-modifiable constants
    SER_BAUD    = 115_200

    MXD_XPIN    = 6
    MXD_YPIN    = 7

' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    accel   : "sensor.accel.2dof.mxd2125"
    time    : "time"

PUB main{} | ax, ay, az

    setup{}

    repeat
        ser.pos_xy(0, 3)

        repeat until accel.accel_data_rdy{}
        accel.accel_g(@ax, @ay, @az)
        ser.str(string("Accel g: "))
        ser.pos_x(DAT_X_COL)
        ser.printf6(string("%3.3d.%04.4d   %3.3d.%04.4d   %3.3d.%04.4d"), (ax/1000), ||(ax//1000),{
                                                                        } (ay/1000), ||(ay//1000),{
                                                                        } (az/1000), ||(az//1000))
        ser.clear_line{}
        ser.newline{}

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    accel.startx(MXD_XPIN, MXD_YPIN)
    ser.strln(string("MXD2125 driver started"))

{{
    NOTE: At rest, normal RAW x and y values should be at about 400_000 if
    the Propeller is running at 80MHz.
    Since the frequency of the mxd2125 is about 100Hz this means that the
    Period is 10ms... At rest this is a 50% duty cycle, the signal that we
    are measuring is only HIGH for 5ms.  At 80MHz (12.5ns) this equates to
    a value of 400_000 representing a 5ms pulse width.
}}

{
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
