{
    --------------------------------------------
    Filename: DS18B2x-Demo.spin
    Author: Jesse Burt
    Description: Demo of the DS18B2x driver
    Copyright (c) 2021
    Started Jul 13, 2019
    Updated Jan 8, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    OW_PIN      = 2
    SCALE       = C

    NR_DEVICES  = 2
    BITS        = 12                            ' ADC res (9..12 bits)
' --

    C           = 0
    F           = 1

OBJ

    cfg : "core.con.boardcfg.flip"
    time: "time"
    ds  : "sensor.temperature.ds18b2x.ow"
    ser : "com.serial.terminal.ansi"
    int : "string.integer"

VAR

    long _devs[NR_DEVICES * 2]

PUB Main{} | temp, i, nr_found

    setup{}

    ds.tempscale(SCALE)                         ' set temperature scale
    ds.opmode(ds#MULTI)                         ' ONE (1 sensor), MULTI

    nr_found := ds.search(@_devs, 2)            ' how many sensors found?

    i := 0
    repeat nr_found                             ' for each sensor,
        ds.select(@_devs[i])                    '   address it and set its
        ds.adcres(BITS)                         '   ADC resolution (9..12 bits)
        i += 2

    repeat
        ser.position(0, 3)
        nr_found := ds.search(@_devs, 2)        ' how many sensors found?

        i := 0
        repeat nr_found                         ' for each sensor,
            ds.select(@_devs[i])                '   address it
            temp := ds.temperature{}            '   read its temperature
            ser.printf3(string("(%d) %x%x: "), i/2, _devs[i+1], _devs[i])
            decimal(temp, 100)
            ser.newline{}
            i += 2

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
    if ds.startx(OW_PIN)
        ser.strln(string("DS18B2x driver started"))
    else
        ser.strln(string("DS18B2x driver failed to start - halting"))
        ds.stop{}
        time.msleep(500)
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

