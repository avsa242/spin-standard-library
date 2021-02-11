{
    --------------------------------------------
    Filename: VCNL4200-Demo.spin
    Author: Jesse Burt
    Description: Demo of the VCNL4200 driver
    Copyright (c) 2021
    Started Feb 07, 2021
    Updated Feb 10, 2021
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000                       ' max is 400_000
' --

    DAT_COL     = 20

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    vcnl    : "sensor.light.vcnl4200.i2c"

PUB Main{}

    setup{}

    vcnl.preset_als_prox{}                      ' set to combined ALS and prox.
                                                ' sensor operating mode

    repeat
        ser.position(0, 3)
        ser.str(string("Lux: "))
        ser.positionx(DAT_COL)
        decimal(vcnl.lux{}, 1000)
        ser.clearline{}
        ser.newline{}

        ser.str(string("White ADC: "))
        ser.positionx(DAT_COL)
        ser.hex(vcnl.whitedata{}, 4)
        ser.newline{}

        ser.str(string("Proximity ADC: "))
        ser.positionx(DAT_COL)
        ser.hex(vcnl.proxdata{}, 4)

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp, sign
' Display a scaled up number as a decimal
'   Scale it back down by divisor (e.g., 10, 100, 1000, etc)
    whole := scaled / divisor
    tmp := divisor
    places := 0
    part := 0
    sign := 0
    if scaled < 0
        sign := "-"
    else
        sign := " "

    repeat
        tmp /= 10
        places++
    until tmp == 1
    scaled //= divisor
    part := int.deczeroed(||(scaled), places)

    ser.char(sign)
    ser.dec(||(whole))
    ser.char(".")
    ser.str(part)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if vcnl.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.strln(string("VCNL4200 driver started"))
    else
        ser.strln(string("VCNL4200 driver failed to start - halting"))
        vcnl.stop{}
        time.msleep(30)
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
