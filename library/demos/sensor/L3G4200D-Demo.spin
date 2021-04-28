{
    --------------------------------------------
    Filename: L3G4200D-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the L3G4200D driver
    Copyright (c) 2020
    Started Nov 27, 2019
    Updated Dec 26, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_PIN      = 16
    SCL_PIN     = 17
    SDA_PIN     = 18
    SDO_PIN     = 19
' --

    DAT_X_COL   = 15
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg         : "core.con.boardcfg.flip"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    l3g4200d    : "sensor.gyroscope.3dof.l3g4200d.spi"
    int         : "string.integer"

PUB Main{} | gx, gy, gz

    setup{}

    l3g4200d.defaults_active{}
    ser.hidecursor{}
    ser.position(DAT_X_COL, 3)
    ser.char("X")
    ser.position(DAT_Y_COL, 3)
    ser.char("Y")
    ser.position(DAT_Z_COL, 3)
    ser.char("Z")
    repeat
        repeat until l3g4200d.gyrodataready{}
        l3g4200d.gyrodps(@gx, @gy, @gz)
        ser.position(0, 4)
        ser.str(string("Gyro DPS:  "))
        ser.positionx(DAT_X_COL)
        decimal(gx, 1_000_000)
        ser.positionx(DAT_Y_COL)
        decimal(gy, 1_000_000)
        ser.positionx(DAT_Z_COL)
        decimal(gz, 1_000_000)

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp, sign
' Display a scaled up number as a decimal
'   Scale it back down by divisor (e.g., 10, 100, 1000, etc)
    whole := scaled / divisor                   ' separate the whole part
    tmp := divisor                              ' temp/working copy of divisor
    places := 0
    part := 0
    sign := 0
    if scaled < 0                               ' determine sign character
        sign := "-"
    else
        sign := " "

    repeat                                      ' how many places to display:
        tmp /= 10                               ' increment every divide-by-10
        places++                                '   until we're left with 1
    until tmp == 1
    scaled //= divisor                          ' separate the fractional part
    part := int.deczeroed(||(scaled), places)   ' convert to string

    ser.char(sign)                              ' display it
    ser.dec(||(whole))
    ser.char(".")
    ser.str(part)
    ser.chars(32, 5)                            ' erase trailing chars

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if l3g4200d.start(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.strln(string("L3G4200D driver started"))
    else
        ser.strln(string("L3G4200D driver failed to start - halting"))
        l3g4200d.stop{}
        time.msleep(5)
        ser.stop{}
        repeat

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
