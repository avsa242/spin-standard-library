{
    --------------------------------------------
    Filename: SHT3x-ThreshIntDemo.spin
    Author: Jesse Burt
    Description: Demo of the SHT3x driver
        Threshold interrupt functionality
    Copyright (c) 2022
    Started Jan 8, 2022
    Updated Feb 3, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED1            = cfg#LED1
    SER_BAUD        = 115_200

    SCL_PIN         = 28 
    SDA_PIN         = 29
    RESET_PIN       = 24                        ' optional (-1 to disable)
    INT1            = 25                        ' ALERT pin (active high)

    ADDR_BIT        = 0                         ' 0, 1: opt. I2C address bit
    I2C_HZ          = 1_000_000                 ' max is 1_000_000
' --

' Temperature scale
    C               = 0
    F               = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    sht3x   : "sensor.temp_rh.sht3x"
    int     : "string.integer"
    time    : "time"

VAR

    long _isr_stack[50]                         ' stack for ISR core
    long _intflag                               ' interrupt flag

PUB Main{} | dr

    setup{}

    dr := 2                                     ' data rate: 0 (0.5), 1, 2, 4, 10Hz
    sht3x.repeatability(0)
    sht3x.datarate(dr)
    sht3x.opmode(sht3x#CONT)

    sht3x.tempscale(C)
    sht3x.intrhhithresh(25)                     ' RH hi/lo thresholds
    sht3x.intrhlothresh(5)
    sht3x.intrhhiclear(24)                      ' hi/lo thresh hysteresis
    sht3x.intrhloclear(6)

    sht3x.inttemphithresh(30)                   ' temp hi/lo thresholds
    sht3x.inttemplothresh(10)
    sht3x.inttemphiclear(29)                    ' hi/lo thresh hysteresis
    sht3x.inttemploclear(7)

    ser.strln(string("Set thresholds:"))
    ser.printf2(string("RH Set low: %d  hi: %d\n"), sht3x.intrhlothresh(-2), {
}   sht3x.intrhhithresh(-2))
    ser.printf2(string("RH Clear low: %d  hi: %d\n"), sht3x.intrhloclear(-2), {
}   sht3x.intrhhiclear(-2))
    ser.printf2(string("Temp Set low: %d  hi: %d\n"), sht3x.inttemplothresh(-256), {
}   sht3x.inttemphithresh(-256))
    ser.printf2(string("Temp Clear low: %d  hi: %d\n"), sht3x.inttemploclear(-256), {
}   sht3x.inttemphiclear(-256))

    repeat
        if (dr > 0)
            time.msleep(1000/dr)
        else
            time.msleep(2000)
        ser.position(0, 10)

        ser.str(string("Temperature: "))
        decimal(sht3x.temperature{}, 100)
        ser.newline{}

        ser.str(string("Relative humidity: "))
        decimal(sht3x.lasthumidity{}, 100)
        ser.newline{}
        if _intflag
            ser.position(0, 12)
            ser.str(string("Interrupt"))
        else
            ser.position(0, 12)
            ser.clearline{}

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

PRI ISR{}
' Interrupt service routine
    dira[INT1] := 0                             ' INT1 as input
    repeat
        waitpeq(|< INT1, |< INT1, 0)            ' wait for INT1 (active high)
        _intflag := 1                           '   set flag
        waitpne(|< INT1, |< INT1, 0)            ' now wait for it to clear
        _intflag := 0                           '   clear flag

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if sht3x.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BIT, RESET_PIN)
#ifdef SHT3X_SPIN
        ser.strln(string("SHT3x driver started (I2C-SPIN)"))
#elseifdef SHT3X_PASM
        ser.strln(string("SHT3x driver started (I2C-PASM)"))
#endif
    else
        ser.strln(string("SHT3x driver failed to start - halting"))
        repeat

    cognew(isr, @_isr_stack)                    ' start ISR in another core

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
