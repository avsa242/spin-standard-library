{
    --------------------------------------------
    Filename: MXD2125-Cog-Demo.spin
    Author: Paul Baker
    Modified By: Jesse Burt
    Description: Demo of the new cog and same cog
        functionality of the MXD2125 driver
    Started 2007
    Updated Apr 30, 2021
    See end of file for terms of use.
    --------------------------------------------
}

''***********************************************
''*  Memsic Dual Accelerometer Simple Demo v1.0 *
''*  Author: Paul Baker                         *
''*  Copyright (c) 2007 Parallax, Inc.          *
''*  See end of file for terms of use.          *
''***********************************************
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

' MXD2125 X & Y output pins
    MXD_XPIN    =  24
    MXD_YPIN    =  25
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    accel   : "tiny.sensor.accel.2dof.mxd2125.pwm"
    time    : "time"

PUB Main{} | x, y

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}

    ' seperate cog example
    accel.start(MXD_XPIN, MXD_YPIN)             ' cog accelerometer driver
    ser.strln(string("Seperate cog example"))
    repeat 20
        ser.dec(accel.x{})                      ' get/display X axis value
        ser.char(" ")
        ser.dec(accel.y{})                      ' get/display Y axis value
        ser.newline{}
        time.msleep(500)
    accel.stop{}                                ' stop the accelerometer cog

    ser.newline{}

    ' now show in same cog example
    accel.init(MXD_XPIN, MXD_YPIN)
    ser.strln(string("Same cog example"))
    repeat 20
        accel.get_xy(@x, @y)                    ' get X and Y values by passing
        ser.dec(x)                              '   pointers to variables
        ser.char(" ")
        ser.dec(y)
        ser.newline{}
        time.msleep(500)
    ser.str(string("Demo complete"))

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}

