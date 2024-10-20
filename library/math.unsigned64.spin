{
    --------------------------------------------
    Filename: math.unsigned64.spin
    Description: Unsigned 64-bit int math
    Author: Jesse Burt
    Created Jun 11, 2019
    Updated Oct 12, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on the following sources:
        umath.spin - Philip C. Pilgrim
        29124_altimeter.spin - Parallax, inc.
}
CON

    { high, low 32-bits of 64-bit value }
    H   = 0
    L   = 1

PUB dadd(ptr_sum, addh, addl) | sum64[2]
' Add two 64-bit values (@ptr_sum + [addh:addl])
'   ptr_sum: pointer to value to add and store values to
'   [addh:addl]: upper and lower 32-bits of 64-bit number to add
'   Returns: n/a (result stored at ptr_sum)
    longmove(@sum64, ptr_sum, 2)
    sum64[H] += addh
    sum64[L] += addl
    if (ult(sum64[L], addl))
        sum64++
    longmove(ptr_sum, @sum64, 2)

PUB div(dvndh, dvndl, dvsr): quot | carry
' Divide 64-bit number by 32-bit number
'   [dvndh:dvndl]: 64-bit dividend
'   dvsr: 32-bit divisor
'   Returns: 32-bit quotient, or $ffff_ffff on overflow
    quot := 0
    ifnot (ult(dvndh, dvsr))
        return $ffff_ffff
    repeat 32
        carry := (dvndh < 0)
        dvndh := (dvndh << 1) + (dvndl >> 31)
        dvndl <<= 1
        quot <<= 1
        if (not ult(dvndh, dvsr) or carry)
            quot++
            dvndh -= dvsr
    return quot

PUB dsub(ptr_diff, subh, subl)
' Subtract 64-bit number from 64-bit number (@ptr_diff - [subh:subl])
'   ptr_diff: pointer to value to subtract from (u64)
'   [subh:subl]: value to subtract
'   Returns: n/a (result stored at ptr_diff)
    dadd(ptr_diff, -subh - 1, -subl)

PUB mult(ptr_prod, mplr, mpld) | prod64[2]
' Multiply 32-bit number by 32-bit number
'   ptr_prod: pointer to variable to store product (u64)
'   [mplr:mpld]: 32-bit multiplier and multiplicand
'   Returns: n/a (product stored at ptr_prod)
    prod64[H] := (mplr & $7fff_ffff) ** (mpld & $7fff_ffff)
    prod64[L] := (mplr & $7fff_ffff) * (mpld & $7fff_ffff)
    if (mplr < 0)
        dadd(@prod64, (mpld >> 1), (mpld << 31))
    if (mpld < 0)
        dadd(@prod64, ((mplr << 1) >> 2), (mplr << 31))
    longmove(ptr_prod, @prod64, 2)

PUB multdiv(mplr, mpld, dvsr) | prod64[2]
' Multiply two 32-bit numbers, with (*internal) 64-bit product divided by a 32-bit divisor
'   mplr: 32-bit multiplier
'   mpld: 32-bit multiplicand
'   dvsr: divisor
'   NOTE: High 32-bits of mplr * mpld must be less than dvsr ((mplr ** mpld) < dvsr)
'   Returns: 32-bit quotient
    mult(@prod64, mplr, mpld)
    return div(prod64[H], prod64[L], dvsr)

PRI ult(x, y)
' Test for (unsigned x) < (unsigned y)
'   Returns: TRUE (-1) if less than, FALSE otherwise
    return (x ^ $8000_0000) < (y ^ $8000_0000)

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

