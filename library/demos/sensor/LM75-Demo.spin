{
    --------------------------------------------
    Filename: LM75-Demo.spin
    Author: Jesse Burt
    Description: Demo of the LM75 driver
    Copyright (c) 2020
    Started Nov 19, 2020
    Updated Nov 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

' I2C:
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000

    ' alternate slave address bits (%000 default)
    ADDR_BITS   = %000                          ' %000..%111
' --

    DAT_COL     = 20

    C           = 0
    F           = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    temp    : "sensor.temperature.lm75.i2c"

PUB Main{} | dispmode

    setup{}
    temp.tempscale(C)                           ' C (0), F (1)

    ser.hidecursor{}
    dispmode := 0
    displaysettings{}
    repeat
        case ser.rxcheck{}
            "q", "Q":                           ' Quit the demo
                ser.position(0, 17)
                ser.str(string("Halting"))
                temp.stop{}
                time.msleep(5)
                quit
            "r", "R":                           ' Change display mode
                ser.position(0, 14)             '   (raw or calculated)
                repeat 2
                    ser.clearline{}
                    ser.newline{}
                dispmode ^= 1
        case dispmode
            0:
                ser.position(0, 14)
                tempraw{}
            1:
                ser.position(0, 14)
                tempcalc{}

    ser.showcursor{}
    repeat

PUB TempCalc{} | tmp

    tmp := temp.temperature{}
    ser.str(string("Temp deg:  "))
    ser.position(DAT_COL, 14)
    decimal(tmp, 100)
    ser.clearline{}
    ser.newline{}

PUB TempRaw{} | tmp

    tmp := temp.tempdata{}
    ser.str(string("Temp raw:  "))
    ser.position(DAT_COL, 14)
    ser.hex(tmp, 6)
    ser.clearline{}
    ser.newline{}

PUB DisplaySettings{}


PUB Decimal(scaled, divisor) | whole[4], part[4], places, tmp, sign
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
    if temp.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS)
        temp.defaults{}
        ser.str(string("LM75 driver started (I2C)"))
    else
        ser.str(string("LM75 driver failed to start - halting"))
        temp.stop{}
        time.msleep(5)
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
