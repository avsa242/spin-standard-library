{
    --------------------------------------------
    Filename: SCD30-Demo.spin
    Author: Jesse Burt
    Description: Demo of the SCD30 driver
    Copyright (c) 2021
    Started Jul 10, 2021
    Updated Aug 15, 2021
    See end of file for terms of use.
    --------------------------------------------
}
' Uncomment one of the below to choose either the PASM or SPIN I2C engine
#define SCD30_PASM
'#define SCD30_SPIN
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 100_000                       ' max is 100_000
                                                ' (Sensirion recommends 50_000)

' --

    C           = 0
    F           = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    env     : "sensor.co2.scd30.i2c"
    int     : "string.integer"
    sf      : "string.format"

VAR

    byte    _tmp_buff[16]

PUB Main{} | co2, temp, rh

    setup{}

    env.reset{}
    env.opmode(env#CONT)
    env.measinterval(2)
    env.tempscale(C)
    repeat
        repeat until env.dataready{} == true
        env.measure{}
        co2 := env.co2ppm{}
        temp := env.temperature{}
        rh := env.humidity{}

        ser.position(0, 3)
        ser.printf1(string("CO2: %sppm     \n"), int2dp(co2, 1))
        ser.printf1(string("Temp: %s\n"), int2dp(temp, 2))
        ser.printf1(string("RH: %s%%      \n"), int2dp(rh, 2))
        time.msleep(100)

PRI Int2DP(scaled, places): ptr_dp | whole, part, sign, divisor
' Convert integer to string, with a decimal point 'places' to the left
'   Example: Int2DP(314159, 5) would return a pointer to a string
'       containing "3.14159"
'   Returns: pointer to string representation of number
    bytefill(@_tmp_buff, 0, 16)                 ' clear working buffer
    case places
        0:                                      ' whole; just return the same
            return int.dec(scaled)              ' number, as a string
        1..9:
            if scaled < 0                       ' determine sign character
                sign := "-"
            else
                sign := " "

            divisor := 1                        ' determine divisor based
            repeat places                       '   on number of places
                divisor *= 10

            whole := scaled / divisor           ' whole part of the number

            ' fractional part, with leading zeroes added
            part := int.deczeroed(||(scaled // divisor), places)
            ' print formatted string to temporary working buffer
            sf.sprintf3(@_tmp_buff, string("%c%d.%s"), sign, ||(whole), part)
            return @_tmp_buff                       ' pointer to buffer

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if env.startx(I2C_SCL, I2C_SDA, I2C_HZ)
#ifdef SCD30_PASM
        ser.strln(string("SCD30 driver started (I2C-PASM)"))
#elseifdef SCD30_SPIN
        ser.strln(string("SCD30 driver started (I2C-SPIN)"))
#endif
    else
        ser.strln(string("SCD30 driver failed to start - halting"))
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
