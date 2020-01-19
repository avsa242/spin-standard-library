{
    --------------------------------------------
    Filename: sensor.power.ina260.i2c.spin2
    Author: Jesse Burt
    Description: Test app for the INA260 driver (P2 version)
    Copyright (c) 2019
    Started Nov 13, 2019
    Updated Nov 14, 2019                                                                                         
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

    COL_REG     = 0
    COL_SET     = 12
    COL_READ    = 24
    COL_PF      = 40

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    io          : "io"
    time        : "time"
    ina260      : "sensor.power.ina260.i2c"

VAR

    long _ser_cog, _ina260_cog, _expanded, _fails
    byte _row

PUB Main

    Setup

    ina260.Reset
    _row := 3
    ser.Position(0, _row)
    _expanded := FALSE

    ALERTLIMIT(1)
    LEN(1)
    APOL(1)
    MASKENABLE(1)
    MODE(1)
    ISHCT(1)
    VBUSCT(1)
    AVG(1)
    FlashLED(LED, 100)     ' Signal execution finished

PUB ALERTLIMIT(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 65535
            ina260.IntThresh(tmp)
            read := ina260.IntThresh(-2)
            Message (string("ALERTLIMIT"), tmp, read)

PUB LEN(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -1 to 0
            ina260.IntsLatched(tmp)
            read := ina260.IntsLatched(-2)
            Message (string("LEN"), tmp, read)

PUB APOL(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 1
            ina260.IntLevel(tmp)
            read := ina260.IntLevel(-2)
            Message (string("APOL"), tmp, read)

PUB MASKENABLE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 5
            ina260.IntSource(1 << tmp)
            read := ina260.IntSource(-2)
            Message (string("MASKENABLE"), 1 << tmp, read)

PUB MODE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 7
            ina260.Opmode(tmp)
            read := ina260.OpMode(-2)
            Message (string("MODE"), tmp, read)

PUB ISHCT(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 7
            ina260.CurrentConvTime(lookupz(tmp: 140, 204, 332, 588, 1100, 2116, 4156, 8244))
            read := ina260.CurrentConvTime(-2)
            Message (string("ISHCT"), lookupz(tmp: 140, 204, 332, 588, 1100, 2116, 4156, 8244), read)

PUB VBUSCT(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 7
            ina260.VoltageConvTime(lookupz(tmp: 140, 204, 332, 588, 1100, 2116, 4156, 8244))
            read := ina260.VoltageConvTime(-2)
            Message (string("VBUSCT"), lookupz(tmp: 140, 204, 332, 588, 1100, 2116, 4156, 8244), read)

PUB AVG(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 7
            ina260.SamplesAveraged(lookupz(tmp: 1, 4, 16, 64, 128, 256, 512, 1024))
            read := ina260.SamplesAveraged(-2)
            Message (string("AVG"), lookupz(tmp: 1, 4, 16, 64, 128, 256, 512, 1024), read)

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
            ser.Dec(arg1)

            ser.PositionX (COL_READ)
            ser.str(string("READ: "))
            ser.Dec(arg2)

            ser.Chars (32, 3)
            ser.PositionX (COL_PF)
            PassFail (arg1 == arg2)
            ser.NewLine

        FALSE:
            ser.Position (COL_REG, _row)
            ser.Str (field)

            ser.Position (COL_SET, _row)
            ser.str(string("SET: "))
            ser.Dec(arg1)

            ser.Position (COL_READ, _row)
            ser.str(string("READ: "))
            ser.Dec( arg2)

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
    time.MSleep(30)
    ser.Clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if _ina260_cog := ina260.Startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str(string("INA260 driver started", ser#CR, ser#LF))
    else
        ser.str(string("INA260 driver failed to start - halting", ser#CR, ser#LF))
        FlashLED(LED, 500)

PUB FlashLED(led_pin, delay_ms)

    io.Output(led_pin)
    repeat
        io.Toggle(led_pin)
        time.MSleep(delay_ms)

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
