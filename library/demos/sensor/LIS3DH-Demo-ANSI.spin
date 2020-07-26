{
    --------------------------------------------
    Filename: LIS3DH-Demo.spin
    Author: Jesse Burt
    Description: Demo of the LIS3DH driver
    Copyright (c) 2020
    Started Mar 15, 2020
    Updated Jul 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}
' Uncomment one of the following to choose which interface the LIS3DH is connected to
#define LIS3DH_I2C
'#define LIS3DH_SPI
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    CS_PIN      = 0                                         ' SPI
    SCL_PIN     = 1                                         ' SPI, I2C
    SDA_PIN     = 2                                         ' SPI, I2C
    SDO_PIN     = 3                                         ' SPI
    I2C_HZ      = 400_000                                   ' I2C
    SLAVE_OPT   = 0
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    int     : "string.integer"
    accel   : "sensor.accel.3dof.lis3dh.i2cspi"

VAR

    long _overruns

PUB Main | dispmode

    Setup

    accel.AccelADCRes(10)                                   ' 8, 10, 12 (low-power, normal, high-res, resp.)
    accel.AccelScale(2)                                     ' 2, 4, 8, 16 (g's)
    accel.AccelDataRate(100)                                ' 0, 1, 10, 25, 50, 100, 200, 400, 1344, 1600
    accel.AccelAxisEnabled(%111)                            ' 0 or 1 for each bit (%xyz)
    accel.FIFOMode(accel#BYPASS)                            ' accel#BYPASS, accel#FIFO, accel#STREAM, accel#TRIGGER
    accel.IntThresh(1_000000)                               ' 0..16_000000 (ug's, i.e., 0..16g)
    accel.IntMask(%100000)                                  ' Bits 5..0: Zhigh event | Zlow event | Yh|Yl|Xh|Xl

    ser.HideCursor
    dispmode := 0

    ser.position(0, 3)                                      ' Read back the settings from above
    ser.str(string("AccelScale: "))                         '
    ser.dec(accel.AccelScale(-2))                           '
    ser.newline                                             '
    ser.str(string("AccelADCRes: "))                        '
    ser.dec(accel.AccelADCRes(-2))                          '
    ser.newline                                             '
    ser.str(string("AccelDataRate: "))                      '
    ser.dec(accel.AccelDataRate(-2))                        '
    ser.newline                                             '
    ser.str(string("FIFOMode: "))                           '
    ser.dec(accel.FIFOMode(-2))                             '
    ser.newline                                             '
    ser.str(string("IntThresh: "))                          '
    ser.dec(accel.IntThresh(-2))                            '
    ser.newline                                             '
    ser.str(string("IntMask: "))                            '
    ser.bin(accel.IntMask(-2), 6)                           '
    ser.newline                                             '

    repeat
        case ser.RxCheck
            "q", "Q":                                       ' Quit the demo
                ser.Position(0, 15)
                ser.str(string("Halting"))
                accel.Stop
                time.MSleep(5)
                ser.Stop
                quit
            "c", "C":                                       ' Perform calibration
                Calibrate
            "r", "R":                                       ' Change display mode: raw/calculated
                ser.Position(0, 10)
                repeat 2
                    ser.ClearLine(ser#CLR_CUR_TO_END)
                    ser.Newline
                dispmode ^= 1

        ser.Position (0, 10)
        case dispmode
            0: AccelRaw
            1: AccelCalc

        ser.position (0, 12)
        ser.str(string("Interrupt: "))
        ser.str(lookupz(accel.Interrupt >> 6: string("No "), string("Yes")))

    ser.ShowCursor
    FlashLED(LED, 100)

PUB AccelCalc | ax, ay, az

    repeat until accel.AccelDataReady
    accel.AccelG (@ax, @ay, @az)
    if accel.AccelDataOverrun
        _overruns++
    ser.Str (string("Accel micro-g: "))
    ser.Str (int.DecPadded (ax, 10))
    ser.Str (int.DecPadded (ay, 10))
    ser.Str (int.DecPadded (az, 10))
    ser.Newline
    ser.Str (string("Overruns: "))
    ser.Dec (_overruns)

PUB AccelRaw | ax, ay, az

    repeat until accel.AccelDataReady
    accel.AccelData (@ax, @ay, @az)
    if accel.AccelDataOverrun
        _overruns++
    ser.Str (string("Raw Accel: "))
    ser.Str (int.DecPadded (ax, 7))
    ser.Str (int.DecPadded (ay, 7))
    ser.Str (int.DecPadded (az, 7))

    ser.Newline
    ser.Str (string("Overruns: "))
    ser.Dec (_overruns)

PUB Calibrate

    ser.Position (0, 12)
    ser.Str(string("Calibrating..."))
    accel.Calibrate
    ser.Position (0, 12)
    ser.Str(string("              "))

PUB Setup

    repeat until ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
#ifdef LIS3DH_SPI
    if accel.Start(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        accel.Defaults
        ser.str(string("LIS3DH driver started (SPI)", ser#CR, ser#LF))
#elseifdef LIS3DH_I2C
    if accel.Startx(SCL_PIN, SDA_PIN, I2C_HZ, SLAVE_OPT)
        accel.Defaults
        ser.str(string("LIS3DH driver started (I2C)", ser#CR, ser#LF))
#endif
    else
        ser.str(string("LIS3DH driver failed to start - halting", ser#CR, ser#LF))
        accel.Stop
        time.MSleep(5)
        ser.Stop
        FlashLED(LED, 500)

#include "lib.utility.spin"

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
