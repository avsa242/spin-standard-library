{
    --------------------------------------------
    Filename: CTR-FreqSynthDemo.spin
    Modified by: Jesse Burt
    Description: Simple demo of counter-based frequency synthesis
    Started 2007
    Updated Oct 22, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on FrequencySynth.spin,
        originally by Chip Gracey, Beau Schwabe.
}

CON

    _clkmode    = xtal1 + pll16X
    _xinfreq    = 5_000_000

    PIN         = 27                            ' 0..31
    FREQ        = 440                           ' DC to 128MHz

OBJ

    fsyn : "signal.synth"

PUB ctr_demo{}

    fsyn.synth("A",PIN, FREQ)                   ' synth({Counter"A" or Counter"B"}, pin, freq)

    repeat                                      ' loop forever to keep cog alive

DAT
{
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

