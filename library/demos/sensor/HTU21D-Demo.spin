{
    --------------------------------------------
    Filename: HTU21D-Demo.spin
    Author: Jesse Burt
    Description: Demo of the HTU21D driver
    Copyright (c) 2021
    Started Jun 16, 2021
    Updated Aug 15, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000                       ' max is 400_000
' --

' Temperature scales
    C           = 0
    F           = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    sens    : "sensor.temp_rh.htu21d"

PUB Main{}

    setup{}

    sens.tempscale(C)                           ' C (0) or F (1)
    sens.crccheckenabled(true)                  ' TRUE, FALSE

    repeat
        ser.position(0, 3)
        ser.str(string("Temperature: "))
        int2dp(sens.temperature{}, 100)
        ser.str(string("  (CRC valid: "))
        ser.str(lookupz(||(sens.lasttempvalid{}): string("No "), string("Yes")))
        ser.char(")")

        ser.newline{}
        ser.str(string("Humidity: "))
        int2dp(sens.humidity{}, 100)
        ser.str(string("  (CRC valid: "))
        ser.str(lookupz(||(sens.lastrhvalid{}): string("No "), string("Yes")))
        ser.char(")")

PRI Int2DP(scaled, divisor) | whole[4], part[4], places, tmp, sign
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

    if sens.startx(SCL_PIN, SDA_PIN, I2C_HZ)
#ifdef HTU21D_SPIN
        ser.strln(string("HTU21D driver started (I2C-SPIN)"))
#elseifdef HTU21D_PASM
        ser.strln(string("HTU21D driver started (I2C-PASM)"))
#endif
    else
        ser.strln(string("HTU21D driver failed to start - halting"))
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
