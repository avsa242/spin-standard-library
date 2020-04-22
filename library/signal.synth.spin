{
    --------------------------------------------
    Filename: signal.synth.spin
    Author: Chip Gracey, Beau Schwabe, Thomas E. McInnes
    Modified by: Jesse Burt
    Description: Object used to synthesize frequencies
        using the counters
    Started 2007
    Updated Apr 22, 2020
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is a modified version of synth.spin,
        originally written by Chip Gracey.
        The original header is preserved below

*****************************************
* Frequency Synthesizer demo v1.2       *
* Author: Beau Schwabe, Thomas E. McInnes*
* Copyright (c) 2007 Parallax           *
* See end of file for terms of use.     *
*****************************************
  Original Author: Chip Gracey
  Modified by Beau Schwabe
  Modified by Thomas E. McInnes
*****************************************
}

OBJ

    counters    : "core.con.counters"

VAR

    long _pin

PUB MuteA
' Mute synth channel A
    Synth("A", _pin, 0)

PUB MuteB
' Mute synth channel B
    Synth("B", _pin, 0)

PUB Synth(CTR_AB, pin, freq) | s, d, ctr, frq
' Synthesize waveform
'   Valid values:
'       CTR_AB: "A" (65), "B" (66)
'       pin: 0..31
'       freq: 0..128_000_000
    _pin := pin
    freq := freq #> 0 <# 128_000_000                        ' Limit frequency range

    if freq < 500_000                                       ' If 0 to 499_999 Hz,
        ctr := counters#NCO_SINGLEEND                       '   ..set NCO mode
        s := 1                                              '   ..shift = 1
    else                                                    ' If 500_000 to 128_000_000 Hz,
        ctr := counters#PLL_SINGLEEND                       '   ..set PLL mode
        d := >|((freq - 1) / 1_000_000)                     ' Determine PLLDIV
        s := 4 - d                                          ' Determine shift
        ctr |= d << counters#PLLDIV                         ' Set PLLDIV

    frq := fraction(freq, CLKFREQ, s)                       ' Compute frqa/frqb value
    ctr |= pin                                              ' Set PINA to complete ctra/ctrb value

    if CTR_AB == "A"
        ctra := ctr                                         ' Set ctra
        frqa := frq                                         ' Set frqa
        dira[pin] := 1                                      ' Make pin output

    if CTR_AB == "B"
        ctrb := ctr                                         ' Set ctrb
        frqb := frq                                         ' Set frqb
        dira[pin] := 1                                      ' Make pin output

PUB Stop
' Deactivate counters and set I/O pin as input
    ctra := 0
    frqa := 0
    ctrb := 0
    frqb := 0
    outa[_pin] := 0
    dira[_pin] := 0

PRI fraction(a, b, shift) : f

    if shift > 0                         'if shift, pre-shift a or b left
        a <<= shift                        'to maintain significant bits while
    if shift < 0                         'insuring proper result
        b <<= -shift

    repeat 32                            'perform long division of a/b
        f <<= 1
        if a => b
            a -= b
            f++
        a <<= 1

