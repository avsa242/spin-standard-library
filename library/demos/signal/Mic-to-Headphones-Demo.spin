{
    --------------------------------------------
    Filename: Mic-to-Headphones-Demo.spin
    Author: Chip Gracey
    Modified by: Jesse Burt
    Description: Demo using the Propeller's counters
        to digitize audio from an electret mic and play
        it back on headphones/speakers
    Started 2006
    Updated Oct 22, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on microphone_to_headphones.spin,
        originally by Chip Gracey
}

CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' At 80MHz the ADC/DAC sample resolutions and rates are as follows:
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

' -- User-modifiable constants
    MIC_IN      = cfg#MIC_IN
    MIC_FB      = cfg#MIC_FB
    AUDIO_L     = cfg#AUDIO_L
    AUDIO_R     = cfg#AUDIO_R
    BITS        = 11                            ' 5..14 (see above table)

' --

OBJ

    cfg : "boardcfg.demoboard"                  ' board with a mic

PUB go{}

    cognew(@asm_entry, 0)                       ' launch assembly program into a COG

{ tell the counters object we want constants shifted into position for PASM programs }
#define _PASM_

#include "core.con.counters.spin"

DAT
' Assembly program
            org

asm_entry   mov       dira, asm_dira            ' make pins 8 (ADC) and 0 (DAC) outputs

            movs      ctra, #MIC_IN             ' POS W/FEEDBACK mode for CTRA
            movd      ctra, #MIC_FB
            movi      ctra, #POS_DETECT_FB
            mov       frqa, #1

            movs      ctrb, #AUDIO_L            ' DUTY DIFFERENTIAL mode for CTRB
            movd      ctrb, #AUDIO_R
            movi      ctrb, #DUTY_DIFFERENTIAL

            mov       asm_cnt, cnt              ' prepare for WAITCNT loop
            add       asm_cnt, asm_cycles

:loop       waitcnt   asm_cnt, asm_cycles       ' wait for next CNT value (timing is determinant after WAITCNT)

            mov       asm_sample, phsa          ' capture PHSA and get difference
            sub       asm_sample, asm_old
            add       asm_old, asm_sample

            shl       asm_sample, #32-BITS      ' justify sample and output to FRQB
            mov       frqb, asm_sample

            jmp       #:loop                    ' wait for next sample period

' Data
asm_cycles  long      |< BITS - 1               ' sample time
asm_dira    long      $00000E00                 ' output mask

asm_cnt     res       1
asm_old     res       1
asm_sample  res       1

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

