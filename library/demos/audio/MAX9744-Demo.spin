{
    --------------------------------------------
    Filename: MAX9744-Demo.spin
    Author: Jesse Burt
    Description: Simple serial terminal-based demo of the MAX9744
        audio amp driver.
    Copyright (c) 2021
    Started Jul 7, 2018
    Updated May 1, 2021
    See end of file for terms of use.
    --------------------------------------------
}
' Uncomment one of the below lines to start the driver with the
'   PASM I2C engine (1 additional cog) or SPIN I2C engine (no additional cog)
#define PASM
'#define SPIN

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000                       ' max 400_000 (PASM I2C only)
    SHDN_PIN    = 24
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    amp     : "audio.amp.max9744.i2c"

PUB Main{} | i, level

    setup{}
    level := 31
    amp.volume(level)                           ' set starting volume
    ser.clear{}

    repeat
        ser.position(0, 0)
        ser.strln(string("Help:"))
        ser.strln(string("[: Volume down"))
        ser.strln(string("]: Volume up"))
        ser.strln(string("f: Filterless modulation"))
        ser.strln(string("m: Mute"))
        ser.strln(string("p: Classic PWM modulation"))
        ser.newline{}
        ser.newline{}
        ser.printf1(string("Volume: %d \n"), level)

        i := ser.charin{}
            case i
                "[":
                    level := 0 #> (level - 1)
                    amp.voldown{}
                "]":
                    level := (level + 1) <# 63
                    amp.volup{}
                "f":
                    ser.strln(string("Modulation mode: Filterless "))
                    amp.modulationmode(amp#NONE)
                    amp.volume(level)
                "m":
                    amp.mute{}
                    level := 0
                "p":
                    ser.strln(string("Modulation mode: Classic PWM"))
                    amp.modulationmode(amp#PWM)
                    amp.volume(level)
                other:

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
#ifdef PASM
    if amp.startx(SCL_PIN, SDA_PIN, I2C_HZ, SHDN_PIN)
#elseifdef SPIN
    if amp.startx(SCL_PIN, SDA_PIN, SHDN_PIN)
#endif
        ser.strln(string("MAX9744 driver started"))
    else
        ser.strln(string("MAX9744 driver failed to start - halting"))
        amp.stop{}
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
