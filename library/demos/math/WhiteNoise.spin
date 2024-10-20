{
    --------------------------------------------
    Filename: WhiteNoise.spin
    Author: Chip Gracey
    Modified by: Jesse Burt
    Description: Use math.random to generate white noise
        on attached headphones/speakers

        *** WARNING: Loud ***
    Started Jan 13, 2016
    Updated Oct 22, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SOUND       = cfg#SOUND_L
' --

OBJ

    cfg     : "boardcfg.activity"               ' chosen because of the built-in audio jack
    random  : "math.random"

PUB start{} | r

    random.start{}

    r := random.ptr_rand{}
    dira[SOUND] := 1

    repeat
        outa[SOUND] := long[r]                  ' output LSBit of random value

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

