{
    --------------------------------------------
    Filename: DTMFDemo.spin
    Author: Jesse Burt
    Description: Demo of the DTMF signal synthesis object
    Copyright (c) 2022
    Started Apr 22, 2020
    Updated Oct 22, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    SOUND_L     = cfg#SOUND_L
    SOUND_R     = cfg#SOUND_R

OBJ

    cfg     : "boardcfg.activity"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    dtmf    : "signal.synth.audio.dtmf"

PUB main{} | c, t

    setup{}

    { call with the number of entries in the table and the address of the table }
    'dtmf.dtmf_tbl(1, @customtable)

    dtmf.mark_dur(200)
    dtmf.space_dur(10)

    ser.strln(string("Press any of the following keys to generate the corresponding DTMF tones:"))
    ser.strln(string("1   2   3"))
    ser.strln(string("4   5   6"))
    ser.strln(string("7   8   9"))
    ser.strln(string("*   0   #"))
    repeat
        c := ser.rx_check{}
        { look up keypress in the table to get an offset from the beginning of the table of
            DTMF tone pairs }
        if (t := lookdown(c: "1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"))
            dtmf.tone(t-1)

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    dtmf.start(SOUND_L, SOUND_R)

DAT

' Define a custom table of DTMF tones here
' Each entry is a word with two tones as below
' Call dtmf.dtmf_tbl() with the number of entries and the address of the table, as above
    customtable word    1380, 1810
'               word    xxx, xxx
'               .
'               .
'               .

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

