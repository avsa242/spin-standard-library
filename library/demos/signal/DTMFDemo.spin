{
    --------------------------------------------
    Filename: DTMFDemo.spin
    Author: Jesse Burt
    Description: Demo of the DTMF signal synthesis object
    Copyright (c) 2020
    Started Apr 22, 2020
    Updated Apr 23, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    SOUND_L     = cfg#SOUND_L
    SOUND_R     = cfg#SOUND_R

OBJ

    cfg     : "boardcfg.activityboard"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    dtmf    : "signal.synth.audio.dtmf"

VAR

    byte _ser_cog

PUB Main | c, t

    Setup

'   dtmf.DTMFTable(1, @customtable)                         ' Call with the number of entries in the table
'                                                           and the address of the table
    dtmf.MarkDuration(200)
    dtmf.SpaceDuration(10)

    ser.str(string("Press any of the following keys to generate the corresponding DTMF tones:", ser#CR, ser#LF))
    ser.str(string("Press ESC to exit", ser#CR, ser#LF))
    ser.str(string("1   2   3", ser#CR, ser#LF))
    ser.str(string("4   5   6", ser#CR, ser#LF))
    ser.str(string("7   8   9", ser#CR, ser#LF))
    ser.str(string("*   0   #", ser#CR, ser#LF))
    repeat while c <> 27
        c := ser.RXCheck
        if t := lookdown(c: "1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#")
            dtmf.Tone(t-1)

    dtmf.Stop

    ser.str(string("Halted"))
    FlashLED(LED, 100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    dtmf.Start(SOUND_L, SOUND_R)

#include "lib.utility.spin"

DAT

' Define a custom table of DTMF tones here
' Each entry is a word with two tones as below
' Call dtmf.DTMFTable() with the number of entries and the address of the table, as above
    customtable   word    1380, 1810

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
