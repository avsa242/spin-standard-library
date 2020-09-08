{
    --------------------------------------------
    Filename: MXD2125-Serial-Demo.spin
    Author: Jesse Burt
    Description: Serial terminal demo of the
        MXD2125 driver
        (based on demo originally by Beau Schwabe)
    Started 2006
    Updated Sep 8, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    CLK_FREQ    = (_clkmode >> 6) * _xinfreq
    CLK_SCALE   = CLK_FREQ / 500_000

' -- User-modifiable constants
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    MXD_XPIN    = 0
    MXD_YPIN    = 1

' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    int     : "string.integer"
    mxd2125 : "sensor.accel.2dof.mxd2125.pwm"
    time    : "time"

PUB Main{} | a, b, c, d, e, f

    setup{}
    mxd2125.setlevel{}                              ' assume at startup that the memsic2125 is level
                                                    ' Note: This line is important for determining a deg



    repeat
        a := mxd2125.mx{}                           ' get RAW x value
        b := mxd2125.my{}                           ' get RAW y value

        c := mxd2125.ro{}                           ' Get raw value for acceleration
        c := c / CLK_SCALE                          ' convert raw acceleration value to mg's

        d := mxd2125.theta{}                        ' Get raw 32-bit deg
        d := d >> 24                                ' scale 32-bit value to an 8-bit Binary Radian
        d := (d * 45)/32                            ' Convert Binary radians into Degrees

        e := mxd2125.mxtilt{}

        f := mxd2125.mytilt{}

        ser.str(int.dec(a))                         ' Display RAW x value
        ser.char(9)
        ser.str(int.dec(b))                         ' Display RAW y value
        ser.char(9)
        ser.char(9)
        ser.str(int.dec(c))                         ' Display Acceleration value in mg's
        ser.char(9)
        ser.str(int.dec(d))                         ' Display Deg
        ser.char(9)
        ser.str(int.dec(e))                         ' Display X tilt
        ser.char(9)
        ser.str(int.dec(f))                         ' Display X tilt

        ser.char(13)

PUB Setup{}

    repeat until ser.startrxtx(SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#CR, ser#LF))

    if mxd2125.start(MXD_XPIN, MXD_YPIN)
        ser.str(string("MXD2125 driver started", ser#CR, ser#LF))
    else
        ser.str(string("MXD2125 driver failed to start - halting", ser#CR, ser#LF))
        mxd2125.stop{}
        time.msleep(50)
        ser.stop{}
        repeat

{{
Note: At rest, normal RAW x and y values should be at about 400_000 if the Propeller is running at 80MHz.

Since the frequency of the mxd2125 is about 100Hz this means that the Period is 10ms... At rest this is a
50% duty cycle, the signal that we are measuring is only HIGH for 5ms.  At 80MHz (12.5ns) this equates to
a value of 400_000 representing a 5ms pulse width.
}}

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
