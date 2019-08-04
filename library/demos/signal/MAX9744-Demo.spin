{
    --------------------------------------------
    Filename: MAX9744-Demo.spin
    Author: Jesse Burt
    Description: Simple serial terminal-based demo of the MAX9744
        audio amp driver.
    Copyright (c) 2019
    Started Jul 7, 2018
    Updated Mar 16, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode  = cfg#_clkmode
    _xinfreq  = cfg#_xinfreq

    I2C_SCL   = 28
    I2C_SDA   = 29
    I2C_HZ    = 400_000
    SHDN_PIN  = 18

OBJ

    cfg   : "core.con.boardcfg.flip"
    ser   : "com.serial.terminal"
    time  : "time"
    amp   : "signal.audio.amp.max9744.i2c"

PUB Main | i, level

    Setup
    level := 31
    ser.Clear

    repeat
        ser.Position (0, 0)
        ser.Str (string("Volume: "))
        ser.Dec (level)
        ser.NewLine
        ser.Str (string("Press [ or ] for Volume Down or Up, respectively", ser#NL))
        i := ser.CharIn
            case i
                "[":
                    level := 0 #> (level - 1)
                    amp.VolDown
                "]":
                    level := (level + 1) <# 63
                    amp.VolUp
                "f":
                    ser.Str (string("Modulation mode: Filterless ", ser#NL))
                    amp.ModulationMode (0)
                "p":
                    ser.Str (string("Modulation mode: Classic PWM", ser#NL))
                    amp.ModulationMode (1)
                OTHER:

PUB Setup

    repeat until ser.Start (115_200)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#NL))
    if amp.Startx (I2C_SCL, I2C_SDA, I2C_HZ, SHDN_PIN)
        ser.Str (string("MAX9744 driver started", ser#NL))
    else
        ser.Str (string("MAX9744 driver failed to start - halting", ser#NL))
        amp.Stop
        time.MSleep (500)
        ser.Stop
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
