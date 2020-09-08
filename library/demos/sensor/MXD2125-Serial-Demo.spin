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

    _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000

    MMX = 0
    MMY = 1

OBJ

    term    : "com.serial.terminal"
    num     : "string.integer"
    mxd2125 : "sensor.accel.2dof.mxd2125.pwm"

PUB Main | a, b, c, d, e, f, clk_scale

    term.start(115200)                                  ' Initialize serial communication to the PC
    mxd2125.start(MMX, MMY)                              ' Initialize Mx2125
    waitcnt(clkfreq/10 + cnt)                           ' wait for things to settle
    mxd2125.setlevel                                     ' assume at startup that the memsic2125 is level
                                                        ' Note: This line is important for determining a deg

    clk_scale := clkfreq / 500_000                      ' set clk_scale based on system clock


    repeat
        a := mxd2125.Mx                                    ' get RAW x value
        b := mxd2125.My                                    ' get RAW y value

        c := mxd2125.ro                                    ' Get raw value for acceleration
        c := c / clk_scale                                ' convert raw acceleration value to mg's

        d := mxd2125.theta                                 ' Get raw 32-bit deg
        d := d >> 24                                      ' scale 32-bit value to an 8-bit Binary Radian
        d := (d * 45)/32                                  ' Convert Binary radians into Degrees

        e := mxd2125.MxTilt

        f := mxd2125.MyTilt

        term.Str(num.Dec(a))                              ' Display RAW x value
        term.Char(9)
        term.Str(num.Dec(b))                              ' Display RAW y value
        term.Char(9)
        term.Char(9)
        term.Str(num.Dec(c))                              ' Display Acceleration value in mg's
        term.Char(9)
        term.Str(num.Dec(d))                              ' Display Deg
        term.Char(9)
        term.Str(num.Dec(e))                              ' Display X Tilt
        term.Char(9)
        term.Str(num.Dec(f))                              ' Display X Tilt

        term.Char(13)

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
