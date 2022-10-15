{
    --------------------------------------------
    Filename: signal.synth.spin
    Author: Jesse Burt
    Description: Object used to synthesize frequencies
        using the counters
    Started 2007
    Updated Oct 15, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is a modified version of synth.spin,
        originally written by Chip Gracey
        (further modified by Beau Schwabe and Thomas E. McInnes)
}

OBJ

    ctrs : "core.con.counters"

VAR

    long _pin

PUB synth = init
PUB init(ctr_ab, pin, freq) | s, d, ctr, frq
' Synthesize waveform
'   Valid values:
'       ctr_ab: "A" (65), "B" (66)
'       pin: 0..31
'       freq: 0..128_000_000
    _pin := pin
    freq := freq #> 0 <# 128_000_000            ' limit frequency to valid range

    if (freq < 500_000)                         ' if 0 to 499_999 Hz,
        ctr := ctrs#NCO_SINGLEEND               '   ..set NCO mode
        s := 1                                  '   ..shift = 1
    else                                        ' if 500_000 to 128_000_000 Hz,
        ctr := ctrs#PLL_SINGLEEND               '   ..set PLL mode
        d := >|((freq - 1) / 1_000_000)         ' determine PLLDIV
        s := (4 - d)                            ' determine shift
        ctr |= d << ctrs#PLLDIV                 ' set PLLDIV

    frq := fraction(freq, clkfreq, s)           ' compute frqa/frqb value
    ctr |= pin                                  ' set PINA to complete ctra/ctrb value

    { setup counter B: set mode, frequency, and drive pin }
    if (ctr_ab == "A")
        ctra := ctr
        frqa := frq
        dira[pin] := 1

    { setup counter B: set mode, frequency, and drive pin }
    if (ctr_ab == "B")
        ctrb := ctr
        frqb := frq
        dira[pin] := 1

PUB stop = deinit
PUB deinit
' Deactivate counters and set I/O pin as input
    ctra := 0
    frqa := 0
    ctrb := 0
    frqb := 0
    outa[_pin] := 0
    dira[_pin] := 0

PUB mutea = mute_a
PUB mute_a
' Mute synth channel A
    synth("A", _pin, 0)

PUB muteb = mute_b
PUB mute_b
' Mute synth channel B
    synth("B", _pin, 0)

PRI fraction(a, b, shift): f

    if (shift > 0)                              ' if shift, pre-shift a or b left
        a <<= shift                             ' to maintain significant bits while
    if (shift < 0)                              ' insuring proper result
        b <<= -shift

    repeat 32                                   ' perform long division of a/b
        f <<= 1
        if (a => b)
            a -= b
            f++
        a <<= 1

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

