{
    --------------------------------------------
    Filename: LSM9DS1-Test.spin
    Author: Jesse Burt
    Description: Test app for the LSM9DS1 driver
    Copyright (c) 2020
    Started Feb 9, 2019
    Updated Jan 12, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    COL_REG     = 0
    COL_SET     = COL_REG+20
    COL_READ    = COL_REG+32
    COL_PF      = COl_REG+48

' User modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    SCL_PIN     = 1
    SDIO_PIN    = 2
    CS_AG_PIN   = 4
    CS_M_PIN    = 5
    INT_AG_PIN  = 6
    INT_M_PIN   = 8

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    imu     : "sensor.imu.9dof.lsm9ds1.3wspi"
    int     : "string.integer"

VAR

    long _expanded, _fails
    byte _ser_cog, _imu_cog
    byte _max_cols
    byte _row

PUB Main

    Setup
    _row := 3

    BLE(1)
    BDU(1)
    H_LACTIVE(1)
    ODR(1)
    FS(1)
    LP_MODE(1)
    OUT_TEMP(5)
    IG_XL(1)
    IG_G(1)
    IG_INACT(1)
    TDA(1)
    GDA(1)
    XLDA(1)
    FS_XL(1)
    HR(1)
    SLEEP_G(1)
    FIFO_EN (1)
    SLEEP_ON_INACT_EN (1)
    ACT_THS (1)
    ACT_DUR (1)
    FMODE(1)
    FTH(1)
    MAG_DO (1)

    FlashLED(LED, 100)

PUB MAG_DO(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 7
            imu.MagDataRate (lookupz(tmp: 625, 1_250, 2_500, 5000, 10000, 20000, 40000, 80000))
            read := imu.MagDataRate (-2)
            Message (string("MAG_DO"), lookupz(tmp: 625, 1_250, 2_500, 5000, 10000, 20000, 40000, 80000), read)

PUB FTH(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 31
            imu.FIFOThreshold (tmp)
            read := imu.FIFOThreshold (-2)
            Message (string("FTH"), tmp, read)

PUB FMODE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 6
            case tmp
                2, 5:
                    next
                OTHER:
            imu.FIFOMode (tmp)
            read := imu.FIFOMode (-2)
            Message (string("FMODE"), tmp, read)

PUB ACT_DUR(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 255
            imu.GyroInactiveDur (tmp)
            read := imu.GyroInactiveDur (-2)
            Message (string("ACT_DUR"), tmp, read)

PUB ACT_THS(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 127
            imu.GyroInactiveThr (tmp)
            read := imu.GyroInactiveThr (-2)
            Message (string("ACT_THS"), tmp, read)

PUB SLEEP_ON_INACT_EN(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            imu.GyroInactiveSleep (tmp)
            read := imu.GyroInactiveSleep (-2)
            Message (string("SLEEP_ON_INACT_EN"), tmp, read)

PUB FIFO_EN(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            imu.FIFOEnabled (tmp)
            read := imu.FIFOEnabled (-2)
            Message (string("FIFO_EN"), tmp, read)

PUB SLEEP_G(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            imu.GyroSleep (tmp)
            read := imu.GyroSleep (-2)
            Message (string("SLEEP_G"), tmp, read)

PUB HR(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            imu.AccelHighRes (tmp)
            read := imu.AccelHighRes (-2)
            Message (string("HR"), tmp, read)

PUB FS_XL(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 1 to 4
            imu.AccelScale (lookup(tmp: 2, 16, 4, 8))
            read := imu.AccelScale (-2)
            Message (string("FS_XL"), lookup(tmp: 2, 16, 4, 8), read)

PUB XLDA(reps) | read
' XXX No verification
    _row++
    repeat reps
        read := imu.AccelDataReady
        Message (string("XLDA"), read, read)

PUB GDA(reps) | read
' XXX No verification
    _row++
    repeat reps
        read := imu.GyroDataReady
        Message (string("GDA"), read, read)

PUB TDA(reps) | read
' XXX No verification
    _row++
    repeat reps
        read := imu.TempDataReady
        Message (string("TDA"), read, read)

PUB IG_INACT (reps) | read
' XXX No verification
    _row++
    repeat reps
        read := imu.IntInactivity
        Message (string("IG_INACT"), read, read)

PUB IG_G (reps) | read
' XXX No verification
    _row++
    repeat reps
        read := imu.GyroInt
        Message (string("IG_G"), read, read)

PUB IG_XL (reps) | read
' XXX No verification
    _row++
    repeat reps
        read := imu.AccelInt
        Message (string("IG_XL"), read, read)

PUB OUT_TEMP(reps) | read
' XXX No verification
    _row++
    repeat reps
        read := imu.Temperature
        Message (string("OUT_TEMP"), read, read)

PUB LP_MODE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            imu.GyroLowPower (tmp)
            read := imu.GyroLowPower (-2)
            Message (string("LP_MODE"), tmp, read)

PUB FS(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 1 to 4
            if tmp == 3
                next
            imu.GyroScale (lookup(tmp: 245, 500, 0, 2000))
            read := imu.GyroScale (-2)
            Message (string("FS"), lookup(tmp: 245, 500, 0, 2000), read)

PUB ODR(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 1 to 7
            imu.XLGDataRate (lookup(tmp: 0, 14{.9}, 59{.5}, 119, 238, 476, 952))
            read := imu.XLGDataRate (-2)
            Message (string("ODR"), lookup(tmp: 0, 14{.9}, 59{.5}, 119, 238, 476, 952), read)

PUB H_LACTIVE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 1
            imu.XLGIntLevel (tmp)
            read := imu.XLGIntLevel (-2)
            Message (string("H_LACTIVE"), tmp, read)

PUB BDU(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            imu.MagBlockUpdate (tmp)
            read := imu.MagBlockUpdate (-2)
            Message (string("BDU"), tmp, read)

PUB BLE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 1
            imu.Endian (tmp)
            read := imu.Endian (-2)
            Message (string("BLE"), tmp, read)

PUB Message(field, arg1, arg2)

    case _expanded
        TRUE:
            ser.PositionX (COL_REG)
            ser.Str (field)

            ser.PositionX (COL_SET)
            ser.Str (string("SET: "))
            ser.Dec (arg1)
            ser.Chars (32, 3)

            ser.PositionX (COL_READ)
            ser.Str (string("READ: "))
            ser.Dec (arg2)
            ser.Chars (32, 3)
            ser.PositionX (COL_PF)
            PassFail (arg1 == arg2)
            ser.NewLine

        FALSE:
            ser.Position (COL_REG, _row)
            ser.Str (field)

            ser.Position (COL_SET, _row)
            ser.Str (string("SET: "))
            ser.Dec (arg1)
            ser.Chars (32, 3)

            ser.Position (COL_READ, _row)
            ser.Str (string("READ: "))
            ser.Dec (arg2)
            ser.Chars (32, 3)

            ser.Position (COL_PF, _row)
            PassFail (arg1 == arg2)
            ser.NewLine
        OTHER:

PUB PassFail(num)

    case num
        0:
            ser.Str (string("FAIL"))
'            ser.Position (COL_PF+6, _row)
'            ser.Dec (_fails++)
        -1: ser.Str (string("PASS"))
        OTHER: ser.Str (string("???"))

PUB waitkey

    ser.Str (string("Press any key", ser#CR, ser#LF))
    ser.CharIn

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, %0000, SER_BAUD)
    time.MSleep(20)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#CR, ser#LF))

    if _imu_cog := imu.Start (SCL_PIN, SDIO_PIN, CS_AG_PIN, CS_M_PIN, INT_AG_PIN, INT_M_PIN)
        ser.Str (string("LSM9DS1 driver started", ser#CR, ser#LF))
        _max_cols := 4
    else
        ser.Str (string("Failed to start LSM9DS1 driver - halting", ser#CR, ser#LF))
        imu.Stop
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
