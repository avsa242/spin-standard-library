{
    --------------------------------------------
    Filename: signal.synth.audio.dtmf.spin
    Author: Jesse Burt
    Description: Object to generate DTMF tones
    Copyright (c) 2020
    Started Apr 22, 2020
    Updated Apr 22, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' DTMF preset tables for use with Preset()
    US_TOUCHTONE        = 0

VAR

    long _pin_l, _pin_r, _dtmf_standard
    long _table_entries, _ptr_table
    long _dur_mark, _dur_space

OBJ

    synth   : "signal.synth"
    time    : "time"

PUB Start(AUDIOPIN_L, AUDIOPIN_R)

    if lookdown(AUDIOPIN_L: 0..31) and lookdown(AUDIOPIN_R: 0..31)
        longmove(@_pin_l, @AUDIOPIN_L, 2)

    Preset(TOUCHTONE)

PUB Stop

    synth.Stop

PUB DTMFTable(nr_entries, ptr_table)
' Set pointer to table of DTMF tone words, and number of entries in table
    _table_entries := nr_entries
    _ptr_table := ptr_table

PUB MarkDuration(ms)
' Set duration of mark (tone), in ms
    _dur_mark := ms

PUB Preset(std)
' Set DTMF table to a preset value
    case std
        US_TOUCHTONE:
            DTMFTable(12, @touchtone)
        OTHER:
            DTMFTable(12, @touchtone)

PUB SpaceDuration(ms)
' Set duration of space (silence between tones), in ms
    _dur_space := ms

PUB Tone(tone_nr)
' Generate DTMF assigned to 'key'
    case tone_nr
        0.._table_entries:
            synth.synth("A", _pin_l, word[_ptr_table][tone_nr * 2])
            synth.synth("B", _pin_r, word[_ptr_table][(tone_nr * 2)+1])
            time.msleep(_dur_mark)
            synth.MuteA
            synth.MuteB
            time.msleep(_dur_space)
        OTHER:
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
