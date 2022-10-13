{
    --------------------------------------------
    Filename: signal.synth.audio.dtmf.spin
    Author: Jesse Burt
    Description: Object to generate DTMF tones (square wave)
    Copyright (c) 2022
    Started Apr 22, 2020
    Updated Oct 13, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

' DTMF preset tables for use with preset()
    US_TOUCHTONE        = 0

VAR

    long _pin_l, _pin_r, _dtmf_standard
    long _table_entries, _ptr_table
    long _dur_mark, _dur_space

OBJ

    synth   : "signal.synth"
    time    : "time"

PUB start(AUDIOPIN_L, AUDIOPIN_R)
' Start the driver
'   AUDIOPIN_L, AUDIOPIN_R: left, right audio GPIO pins
    if (lookdown(AUDIOPIN_L: 0..31) and lookdown(AUDIOPIN_R: 0..31))
        longmove(@_pin_l, @AUDIOPIN_L, 2)

    preset(US_TOUCHTONE)

PUB stop
' Stop the driver
    synth.stop

PUB dtmf_tbl(nr_entries, ptr_table)
' Set pointer to table of DTMF tone words, and number of entries in table
    _table_entries := nr_entries
    _ptr_table := ptr_table

PUB mark_dur(ms)
' Set duration of mark (tone), in ms
    _dur_mark := ms

PUB preset(std)
' Set DTMF table to a preset value
    case std
        US_TOUCHTONE:
            dtmf_tbl(12, @touchtone)
        other:
            dtmf_tbl(12, @touchtone)

PUB space_dur(ms)
' Set duration of space (silence between tones), in ms
    _dur_space := ms

PUB tone(tone_nr)
' Generate DTMF assigned to 'key'
    case tone_nr
        0.._table_entries:
            synth.synth("A", _pin_l, word[_ptr_table][tone_nr * 2])
            synth.synth("B", _pin_r, word[_ptr_table][(tone_nr * 2)+1])
            time.msleep(_dur_mark)
            synth.mutea{}
            synth.muteb{}
            time.msleep(_dur_space)
        other:
            return

DAT

    touchtone   word    697, 1209   '1
                word    697, 1336   '2
                word    697, 1477   '3
                word    770, 1209   '4
                word    770, 1336   '5
                word    770, 1477   '6
                word    852, 1209   '7
                word    852, 1336   '8
                word    852, 1477   '9
                word    941, 1209   '*
                word    941, 1336   '0
                word    941, 1477   '#

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

