{
    --------------------------------------------
    Filename: audio.input.mic-sigmadelta.spin
    Description: Electret microphone driver object using
        a sigma-delta ADC implemented with the Propeller's counters
    Author: Jesse Burt
    Started Jul 3, 2023
    Updated Jul 3, 2023
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on excerpts of microphone_to_headphones.spin,
        originally by Chip Gracey, modified for formatting
        and use as a standalone object
}

CON

' At 80MHz the ADC sample resolutions and rates are as follows:
'
' sample   sample
' BITS       rate
' ----------------
' 5       2.5 MHz
' 6      1.25 MHz
' 7       625 kHz
' 8       313 kHz
' 9       156 kHz
' 10       78 kHz
' 11       39 kHz
' 12     19.5 kHz
' 13     9.77 kHz
' 14     4.88 kHz

    { the following can be overriden from the parent object }
    MIC_IN      = 20
    MIC_FB      = 21
    BITS        = 11                            ' 5..14 (see above table)

VAR

    byte _cog

PUB start(ptr_smp): status
' Start the driver
'   ptr_smp: pointer to a single long to write audio samples to
    status := _cog := (cognew(@asm_entry, ptr_smp)+1)

PUB stop{}
' Stop the driver
    if ( _cog )
        cogstop(_cog-1)

{ tell the counters object we want constants shifted into position for PASM programs }
#define _PASM_
#include "core.con.counters.spin"

DAT

            org
asm_entry   mov       dira, asm_dira            ' set mic and audio pin directions

            movs      ctra, #MIC_IN             ' POS W/FEEDBACK mode for CTRA
            movd      ctra, #MIC_FB
            movi      ctra, #POS_DETECT_FB
            mov       frqa, #1

            mov       asm_cnt, cnt              ' prepare for WAITCNT loop
            add       asm_cnt, asm_cycles

:loop       waitcnt   asm_cnt, asm_cycles       ' wait for next CNT value (timing is determinant
                                                '   after WAITCNT)

            mov       asm_sample, phsa          ' capture PHSA and get difference
            sub       asm_sample, asm_old
            add       asm_old, asm_sample

            wrlong    asm_sample, par           ' write the sample to hub RAM
            jmp       #:loop                    ' wait for next sample period

' Data
asm_cycles  long      |<(BITS) - 1              ' sample time

{ output pinmask }
asm_dira    long      |<(MIC_FB)

asm_cnt     res       1
asm_old     res       1
asm_sample  res       1

DAT
{
Copyright 2023 Jesse Burt

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

