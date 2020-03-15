P{
    --------------------------------------------
    Filename: L3G4200D-Test.spin
    Author: Jesse Burt
    Description: Test app for the L3G4200D driver
    Copyright (c) 2020
    Started Nov 27, 2019
    Updated Jan 23, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    COL_REG     = 0
    COL_SET     = 12
    COL_READ    = 24
    COL_PF      = 40

    LED         = cfg#LED1

    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200
    CS_PIN      = 3
    SCL_PIN     = 2
    SDA_PIN     = 1
    SDO_PIN     = 0

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    gyro    : "sensor.gyroscope.3dof.l3g4200d.spi"

VAR

    long _fails, _expanded
    byte _ser_cog, _row

PUB Main

    Setup
    _expanded := FALSE

    _row := 3
    ser.Position (0, _row)
'    _expanded := TRUE

    HPEN(1)
    FIFO_EN(1)
    BLE(1)
    BDU(1)
    INT2(1)
    PP_OD(1)
    H_LACTIVE(1)
    FS(1)
    INT1(1)
    HPCF(1)
    HPM(1)
    OPMODE(1)
    DR(1)
    FlashLED (LED, 100)

PUB HPEN(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -1 to 0
            gyro.HighPassFilterEnabled (tmp)
            read := gyro.HighPassFilterEnabled (-2)
            Message (string("HPEN"), tmp, read)

PUB FIFO_EN(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -1 to 0
            gyro.FIFOEnabled (tmp)
            read := gyro.FIFOEnabled (-2)
            Message (string("FIFO_EN"), tmp, read)

PUB BLE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 1
            gyro.DataByteOrder (tmp)
            read := gyro.DataByteOrder (-2)
            Message (string("BLE"), tmp, read)

PUB BDU(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -1 to 0
            gyro.BlockUpdateEnabled (tmp)
            read := gyro.BlockUpdateEnabled (-2)
            Message (string("BDU"), tmp, read)

PUB INT2(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from %0000 to %1111
            gyro.Int2Mask (tmp)
            read := gyro.Int2Mask (-2)
            Message (string("INT2"), tmp, read)

PUB PP_OD(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 1
            gyro.IntOutputType (tmp)
            read := gyro.IntOutputType (-2)
            Message (string("PP_OD"), tmp, read)

PUB H_LACTIVE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 1
            gyro.IntActiveState (tmp)
            read := gyro.IntActiveState (-2)
            Message (string("H_LACTIVE"), tmp, read)

PUB FS(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 2
            gyro.GyroScale (lookupz(tmp: 250, 500, 2000))
            read := gyro.GyroScale (-2)
            Message (string("FS"), lookupz(tmp: 250, 500, 2000), read)

PUB INT1(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from %00 to %11
            gyro.Int1Mask (tmp)
            read := gyro.Int1Mask (-2)
            Message (string("INT1"), tmp, read)

PUB HPCF(reps) | tmp, read

    gyro.GyroDataRate (100)
    _row++
    repeat reps
        repeat tmp from 0 to 8
            gyro.HighPassFilterFreq (lookupz(tmp: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01))
            read := gyro.HighPassFilterFreq (-2)
            Message (string("HPCF"), lookupz(tmp: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01), read)

    gyro.GyroDataRate (200)
    _row++
    repeat reps
        repeat tmp from 0 to 8
            gyro.HighPassFilterFreq (lookupz(tmp: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02))
            read := gyro.HighPassFilterFreq (-2)
            Message (string("HPCF"), lookupz(tmp: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02), read)

    gyro.GyroDataRate (400)
    _row++
    repeat reps
        repeat tmp from 0 to 8
            gyro.HighPassFilterFreq (lookupz(tmp: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05))
            read := gyro.HighPassFilterFreq (-2)
            Message (string("HPCF"), lookupz(tmp: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05), read)

    gyro.GyroDataRate (800)
    _row++
    repeat reps
        repeat tmp from 0 to 8
            gyro.HighPassFilterFreq (lookupz(tmp: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10))
            read := gyro.HighPassFilterFreq (-2)
            Message (string("HPCF"), lookupz(tmp: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10), read)

PUB HPM(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 3
            gyro.HighPassFilterMode (tmp)
            read := gyro.HighPassFilterMode (-2)
            Message (string("HPM"), tmp, read)

PUB OPMODE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 2
            gyro.GyroOpMode (tmp)
            read := gyro.GyroOpMode (-2)
            Message (string("OPMODE"), tmp, read)

PUB DR(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 3
            gyro.GyroDataRate (lookupz(tmp: 100, 200, 400, 800))
            read := gyro.GyroDataRate (-2)
            Message (string("DR"), lookupz(tmp: 100, 200, 400, 800), read)

{
PUB RF_PWR(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -18 to 0 step 6
            nrf24.RFPower (tmp)
            read := nrf24.RFPower (-2)
            Message (string("RF_PWR"), tmp, read)

PUB RF_DR(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 2
            nrf24.Rate (lookupz(tmp: 250, 1000, 2000))
            read := nrf24.Rate (-2)
            Message (string("RF_DR"), lookupz(tmp: 250, 1000, 2000), read)

PUB EN_ACK_PAY(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            nrf24.EnableACK (tmp)
            read := nrf24.EnableACK (-2)
            Message (string("EN_ACK_PAY"), tmp, read)
}
PUB TrueFalse(num)

    case num
        0: ser.Str (string("FALSE"))
        -1: ser.Str (string("TRUE"))
        OTHER: ser.Str (string("???"))

PUB Message(field, arg1, arg2)

   case _expanded
        TRUE:
            ser.PositionX (COL_REG)
            ser.Str (field)

            ser.PositionX (COL_SET)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

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

            ser.Position (COL_READ, _row)
            ser.Str (string("READ: "))
            ser.Dec (arg2)

            ser.Position (COL_PF, _row)
            PassFail (arg1 == arg2)
            ser.NewLine
        OTHER:
            ser.Str (string("DEADBEEF"))

PUB PassFail(num)

    case num
        0: ser.Str (string("FAIL"))
        -1: ser.Str (string("PASS"))
        OTHER: ser.Str (string("???"))

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if gyro.Start (CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.Str(string("L3G4200D driver started", ser#CR, ser#LF))
    else
        ser.Str(string("L3G4200D driver failed to start - halting", ser#CR, ser#LF))
        gyro.Stop
        time.MSleep (500)
        FlashLED (LED, 500)

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
