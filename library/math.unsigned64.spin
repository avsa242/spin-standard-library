{
    --------------------------------------------
    Filename: math.unsigned64.spin
    Description: Unsigned 64-bit int multiply and divide
    Author: Philip C. Pilgrim
    Modified by: Jesse Burt
    Created Jun 11, 2019
    Updated Jun 11, 2019
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is a modified version of umath.spin, originally
        by Philip C. Pilgrim. The original header is preserved below.
}

'' Copyright (c) 2008 Philip C. Pilgrim
'' (See end of file for terms of use.)
''
''-----------[ Description ]----------------------------------------------------
''
'' This Propeller object provides the following unsigned integer math functions:
''
''   div: Divides a 64-bit integer by a 32-bit integer to yield a 32-bit quotient.
''
''   multdiv: Multiplies a 32-bit integer by the rational fraction formed by
''     the ratio of two 32-bit numbers.
''
''   unsigned comparisons: <, =<, =>, and >

CON

    UGT = %100
    EQ  = %010
    ULT = %001

VAR

    long _producth, _productl

PUB MultDiv(x, num, denom)
'' Multiply x by num, forming a 64-bit unsigned product.
'' Divide this by denom, returning the result.
'' x ** num must be less than (unsigned) denom.
    Mult(x, num)
    return Div(_producth, _productl, denom)

PUB Div(dvndh, dvndl, dvsr) | carry, quotient
'' Divide the 64-bit dividend, dvdnh:dvndl by the 32-bit divisor, dvsr,
'' returning a 32-bit quotient. Returns 0 on overflow.
    quotient~
    if (GE(dvndh, dvsr))
        return 0
    repeat 32
        carry := dvndh < 0
        dvndh := (dvndh << 1) + (dvndl >> 31)
        dvndl <<= 1
        quotient <<= 1
        if (GE(dvndh, dvsr) or carry)
            quotient++
            dvndh -= dvsr
    return quotient

PUB GT(x,y)
'' Return true if x > y unsigned.
    return CPR(x,y) & UGT <> 0

PUB GE(x,y)
'' Return true if x => y unsigned.
    return CPR(x,y) & constant(UGT | EQ) <> 0

PUB LE(x,y)
'' Return true if x =< y unsigned.
    return CPR(x,y) & constant(ULT | EQ) <> 0

PUB LT(x,y)
'' Return true if x < y unsigned.
    return CPR(x,y) & ULT <> 0

PRI Mult(mplr, mpld) | umplr, umpld

    _producth := (mplr & $7fff_ffff) ** (mpld & $7fff_ffff)
    _productl := (mplr & $7fff_ffff) * (mpld & $7fff_ffff)
    if (mplr < 0)
        DAdd(_producth, _productl, mpld >> 1, mpld << 31)
    if (mpld < 0)
        DAdd(_producth, _productl, mplr << 1 >> 2, mplr << 31)

PRI DAdd(addh, addl, augh, augl)

    _producth := addh + augh
    _productl := addl + augl
    if (LT(_productl, addl))
        _producth++

PRI CPR(x, y)

    if (x == y)
        return EQ
    elseif (x ^ $8000_0000 > y ^ $8000_0000)
        return UGT
    else
        return ULT

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}

