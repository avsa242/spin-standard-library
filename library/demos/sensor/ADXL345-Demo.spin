{
    --------------------------------------------
    Filename: ADXL345-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADXL345 driver (PST-compatible version)
    Copyright (c) 2020
    Started Mar 19, 2020
    Updated Mar 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    CS_PIN      = 11
    SCL_PIN     = 15
    SDA_PIN     = 14
    SDO_PIN     = 13
    SCL_DELAY   = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    io      : "io"
    int     : "string.integer"
    accel   : "sensor.accel.3dof.adxl345.spi"

VAR

    long _overruns
    byte _ser_cog, _accel_cog

PUB Main | dispmode

    Setup

    accel.AccelADCRes(accel#FULL)                           ' 10, accel#FULL (dynamic, based on AccelScale)
    accel.AccelScale(2)                                     ' 2, 4, 8, 16 (g's)
    accel.AccelDataRate(800)                                ' 0_10, 0_20, 0_39, 0_78, 1_56, 3_13, 6_25, 12_5,
'                                                               25, 50, 100, 200, 400, 800, 1600, 3200
    accel.FIFOMode(accel#BYPASS)                            ' accel#BYPASS, accel#FIFO, accel#STREAM, accel#TRIGGER
    accel.OpMode(accel#MEASURE)                             ' accel#STANDBY, accel#MEASURE
    accel.IntMask(%0000_0000)                               ' 0, 1 each bit
    accel.AccelSelfTest(FALSE)                              ' FALSE, TRUE
    dispmode := 0

    ser.position(0, 3)
    ser.str(string("AccelScale: "))
    ser.dec(accel.AccelScale(-2))
    ser.newline
    ser.str(string("AccelADCRes: "))
    ser.dec(accel.AccelADCRes(-2))
    ser.newline
    ser.str(string("AccelDataRate: "))
    ser.dec(accel.AccelDataRate(-2))
    ser.newline
    ser.str(string("FIFOMode: "))
    ser.dec(accel.FIFOMode(-2))
    ser.newline
    ser.str(string("IntMask: "))
    ser.bin(accel.IntMask(-2), 8)
    ser.newline
    ser.str(string("AccelSelfTest: "))
    ser.dec(accel.AccelSelfTest(-2))
    ser.newline

    repeat
        case ser.RxCheck
            "q", "Q":
                ser.Position(0, 12)
                ser.str(string("Halting"))
                accel.Stop
                time.MSleep(5)
                ser.Stop
                quit
            "c", "C":
                Calibrate
            "r", "R":
                ser.Position(0, 10)
                repeat 2
                    ser.ClearLine
                    ser.Newline
                dispmode ^= 1

        ser.Position (0, 10)
        case dispmode
            0: AccelRaw
            1: AccelCalc

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

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _accel_cog := accel.Startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN, SCL_DELAY)
        ser.Str (string("ADXL345 driver started", ser#NL))
        accel.Defaults
    else
        ser.Str (string("ADXL345 driver failed to start - halting", ser#NL))
        accel.Stop
        time.MSleep (5)
        ser.Stop
        FlashLED(LED, 500)

PUB FlashLED(led_pin, delay_ms)

    io.Output(led_pin)
    repeat
        io.Toggle (led_pin)
        time.MSleep (delay_ms)

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
