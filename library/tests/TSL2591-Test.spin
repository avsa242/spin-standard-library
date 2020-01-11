{
    --------------------------------------------
    Filename: TSL2591-Test.spin2
    Description: Test app for the TSL2591 driver
    Author: Jesse Burt
    Copyright (c) 2020
    Started Nov 23, 2019
    Updated Jan 10, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000

    COL_REG     = 0
    COL_SET     = 12
    COL_READ    = 24
    COL_PF      = 40

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    int     : "string.integer"
    time    : "time"
    io      : "io"
    tsl2591 : "sensor.lux.tsl2591.i2c"

VAR

    long _fails, _expanded
    byte _ser_cog, _tsl2591_cog, _row
    byte _passfail_col

PUB Main

    Setup

'    _expanded := TRUE
    _row := 3
    NPIEN(1)
    AIEN(1)
    AEN(1)
    NPINTR(1)
    ENABLE(1)
    AGAIN(1)
    NPAILTH(1)
    NPAILTL(1)
    ATIME(1)
    AILTH(1)
    AILTL(1)
    APERS(1)
    SAI(1)

    tsl2591.Reset
    FlashLED(LED, 100)

PUB NPIEN(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -1 to 0
            tsl2591.IntsEnabled(tmp)
            read := tsl2591.IntsEnabled(-2)
            Message (string("NPIEN"), tmp, read)

PUB AIEN(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -1 to 0
            tsl2591.PersistIntsEnabled(tmp)
            read := tsl2591.PersistIntsEnabled(-2)
            Message (string("AIEN"), tmp, read)

PUB AEN(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -1 to 0
            tsl2591.SensorEnabled(tmp)
            read := tsl2591.SensorEnabled(-2)
            Message (string("AEN"), tmp, read)

PUB NPINTR(reps) | tmp, read

    _row++
    tsl2591.IntsEnabled (FALSE)
    tsl2591.ClearAllInts
    tmp := 0
    read := tsl2591.Interrupt
    Message (string("NPINTR"), tmp, read)

    _row++
    tsl2591.ForceInt
    tmp := -1
    read := tsl2591.Interrupt
    Message (string("NPINTR"), tmp, read)

PUB ENABLE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -1 to 0
            tsl2591.Powered(tmp)
            read := tsl2591.Powered(-2)
            Message (string("ENABLE"), tmp, read)

PUB AGAIN(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 3
            tsl2591.Gain(lookupz(tmp: 1, 25, 428, 9876))
            read := tsl2591.Gain(-2)
            Message (string("AGAIN"), lookupz(tmp: 1, 25, 428, 9876), read)

PUB NPAILTH(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 65535' step $1000
            tsl2591.IntThresh(0, tmp)
            read := (tsl2591.IntThresh(0, -2) >> 16) & $FFFF
            Message (string("NPAILTH"), tmp, read)

PUB NPAILTL(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 65535' step $1000
            tsl2591.IntThresh(tmp, 0)
            read := tsl2591.IntThresh(-2, 0) & $FFFF
            Message (string("NPAILTL"), tmp, read)

PUB ATIME(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 5
            tsl2591.IntegrationTime(lookupz(tmp: 100, 200, 300, 400, 500, 600))
            read := tsl2591.IntegrationTime(-2)
            Message (string("ATIME"), lookupz(tmp: 100, 200, 300, 400, 500, 600), read)

PUB AILTH(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 65535' step $1000
            tsl2591.PersistIntThresh(0, tmp)
            read := (tsl2591.PersistIntThresh(0, -2) >> 16) & $FFFF
            Message (string("AILTH"), tmp, read)

PUB AILTL(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 65535' step $1000
            tsl2591.PersistIntThresh(tmp, 0)
            read := tsl2591.PersistIntThresh(-2, 0) & $FFFF
            Message (string("AILTL"), tmp, read)

PUB APERS(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 15
            tsl2591.PersistIntCycles(lookupz(tmp: 0, 1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60))
            read := tsl2591.PersistIntCycles(-2)
            Message (string("APERS"), lookupz(tmp: 0, 1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60), read)

PUB SAI(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -1 to 0
            tsl2591.SleepAfterInt(tmp)
            read := tsl2591.SleepAfterInt(-2)
            Message (string("SAI"), tmp, read)

PUB TrueFalse(num)

    case num
        0: ser.str(string("FALSE"))
        -1: ser.str(string("TRUE"))
        OTHER: ser.str(string("???"))

PUB Message(field, arg1, arg2)

   case _expanded
        TRUE:
            ser.PositionX (COL_REG)
            ser.Str (field)

            ser.PositionX (COL_SET)
            ser.str(string("SET: "))
            ser.dec(arg1)

            ser.PositionX (COL_READ)
            ser.str(string("READ: "))
            ser.dec(arg2)

            ser.Chars (32, 3)
            ser.PositionX (COL_PF)
            PassFail (arg1 == arg2)
            ser.NewLine

        FALSE:
            ser.Position (COL_REG, _row)
            ser.Str (field)

            ser.Position (COL_SET, _row)
            ser.str(string("SET: "))
            ser.dec(arg1)

            ser.Position (COL_READ, _row)
            ser.str(string("READ: "))
            ser.dec(arg2)

            ser.Position (COL_PF, _row)
            PassFail (arg1 == arg2)
            ser.NewLine
        OTHER:
            ser.str(string("DEADBEEF"))

PUB PassFail(num)

    case num
        0: ser.str(string("FAIL"))
        -1: ser.str(string("PASS"))
        OTHER: ser.str(string("???"))

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(100)
    ser.Clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))

    if _tsl2591_cog := tsl2591.Startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str(string("TSL2591 driver started", ser#CR, ser#LF))
    else
        ser.str(string("TSL2591 driver failed to start - halting", ser#CR, ser#LF))
        time.MSleep (500)
        tsl2591.Stop
        FlashLED (cfg#LED1, 500)

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
