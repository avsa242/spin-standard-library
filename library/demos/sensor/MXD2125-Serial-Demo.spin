{
    --------------------------------------------
    Filename: MXD2125-Serial-Demo.spin
    Author: Jesse Burt
    Description: Serial terminal demo of the
        MXD2125 driver
    Started Sep 8, 2020
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
    accel   : "sensor.accel.2dof.mxd2125.pwm"
    time    : "time"

VAR

    long _overruns

PUB Main{} | dispmode

    setup{}

    ser.hidecursor{}
    repeat
        case ser.rxcheck{}
            "q", "Q":
                ser.position(0, 12)
                ser.str(string("Halting"))
                accel.stop{}
                time.msleep(5)
                ser.stop{}
                quit
'            "c", "C":
'                calibrate{}
            "r", "R":
                ser.position(0, 10)
                repeat 2
                    ser.clearline{}
                    ser.newline{}
                dispmode ^= 1

        ser.position (0, 10)
        case dispmode
            0: accelraw{}
            1: accelcalc{}

    ser.showcursor{}

PUB AccelCalc{} | ax, ay, az

    repeat until accel.acceldataready{}
    accel.accelg (@ax, @ay, @az)
    if accel.acceldataoverrun
        _overruns++
    ser.str (string("Accel micro-g: "))
    ser.str (int.decpadded (ax, 10))
    ser.str (int.decpadded (ay, 10))
    ser.str (int.decpadded (az, 10))
    ser.newline
    ser.str (string("Overruns: "))
    ser.dec (_overruns)

PUB AccelTilt{} | x, y, z

    repeat until accel.acceldataready{}
    accel.acceltilt (@x, @y, @z)
    if accel.acceldataoverrun
        _overruns++
    ser.str (string("Accel tilt: "))
    ser.str (int.decpadded (x, 10))
    ser.str (int.decpadded (y, 10))
    ser.str (int.decpadded (z, 10))
    ser.newline
    ser.str (string("Overruns: "))
    ser.dec (_overruns)

PUB AccelRaw{} | ax, ay, az

    repeat until accel.acceldataready{}
    accel.acceldata (@ax, @ay, @az)
    if accel.acceldataoverrun{}
        _overruns++
    ser.str (string("Raw Accel: "))
    ser.str (int.decpadded (ax, 7))
    ser.str (int.decpadded (ay, 7))
    ser.str (int.decpadded (az, 7))

    ser.newline
    ser.str (string("Overruns: "))
    ser.dec (_overruns)

PUB Setup{}

    repeat until ser.startrxtx(SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#CR, ser#LF))

    if accel.start(MXD_XPIN, MXD_YPIN)
        ser.str(string("MXD2125 driver started", ser#CR, ser#LF))
    else
        ser.str(string("MXD2125 driver failed to start - halting", ser#CR, ser#LF))
        accel.stop{}
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
