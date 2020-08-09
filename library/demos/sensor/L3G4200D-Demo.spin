{
    --------------------------------------------
    Filename: L3G4200D-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the L3G4200D driver that
        outputs live data from the chip.
    Copyright (c) 2020
    Started Nov 27, 2019
    Updated Aug 9, 2020
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

    CS_PIN      = 10
    SCL_PIN     = 15
    SDA_PIN     = 14
    SDO_PIN     = 13

OBJ

    cfg         : "core.con.boardcfg.flip"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    io          : "io"
    l3g4200d    : "sensor.gyroscope.3dof.l3g4200d.spi"
    int         : "string.integer"

VAR

    long _overruns
    byte _ser_cog, _l3g4200d_cog

PUB Main | dispmode

    Setup

    l3g4200d.GyroOpMode(l3g4200d#NORMAL)                ' POWERDOWN (0), SLEEP (1), NORMAL (2)
    l3g4200d.GyroDataRate(800)                          ' 100, 200, 400, 800 Hz
    l3g4200d.GyroAxisEnabled(%111)                      ' 0 or 1 for each bit (Axis: %XYZ)
    l3g4200d.GyroScale(2000)                            ' 250, 500, 200 degrees per second

    ser.HideCursor
    repeat
        case ser.RxCheck
            "q", "Q":                                   ' Quit the demo, and power down
                ser.Position(0, 5)
                ser.str(string("Halting"))
                l3g4200d.Stop
                time.MSleep(5)
                ser.Stop
                quit
            "r", "R":                                   ' Switch between raw ADC output and DPS
                ser.Position(0, 3)
                repeat 2
                    ser.clearline{}
                    ser.Newline
                dispmode ^= 1


        ser.Position (0, 3)
        case dispmode
            0:
                GyroRaw
                ser.Newline
                TempRaw
            1:
                GyroCalc
                ser.Newline
                TempRaw

    ser.ShowCursor
    FlashLED(LED, 100)

PUB GyroCalc | gx, gy, gz
' Display calculated gyroscope output, in micro-degrees per second
    repeat until l3g4200d.GyroDataReady
    l3g4200d.GyroDPS (@gx, @gy, @gz)
    if l3g4200d.GyroDataOverrun
        _overruns++
    ser.Str (string("Gyro micro-DPS:  "))
    ser.Str (int.DecPadded (gx, 12))
    ser.Str (int.DecPadded (gy, 12))
    ser.Str (int.DecPadded (gz, 12))
    ser.Newline
    ser.Str (string("Overruns: "))
    ser.Dec (_overruns)

PUB GyroRaw | gx, gy, gz
' Display gyroscope raw ADC output
    repeat until l3g4200d.GyroDataReady
    l3g4200d.GyroData (@gx, @gy, @gz)
    if l3g4200d.GyroDataOverrun
        _overruns++
    ser.Str (string("Raw Gyro:  "))
    ser.Str (int.DecPadded (gx, 7))
    ser.Str (int.DecPadded (gy, 7))
    ser.Str (int.DecPadded (gz, 7))
    ser.Newline
    ser.Str (string("Overruns: "))
    ser.Dec (_overruns)

PUB TempRaw
' Display temperature raw output
    ser.Str (string("Temperature: "))
    ser.Str (int.DecPadded (l3g4200d.Temperature, 7))

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, %0000, SER_BAUD)
    time.MSleep(20)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#CR, ser#LF))
    if _l3g4200d_cog := l3g4200d.Start (CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.Str (string("L3G4200D driver started", ser#CR, ser#LF))
        l3g4200d.Defaults
    else
        ser.Str (string("L3G4200D driver failed to start - halting", ser#CR, ser#LF))
        l3g4200d.Stop
        time.MSleep (5)
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
