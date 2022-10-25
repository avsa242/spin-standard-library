{
    --------------------------------------------
    Filename: math.float.nocog.spin
    Description: Floating-point math routines
        Single-precision, IEEE-754 (SPIN-based)
        with trig and exp functions
    Started Aug 20, 2013
    Updated Oct 24, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on FloatMathExtended.spin,
        originally by Marty Lawson (in turned based on FloatMath.spin,
        originally by Chip Gracey)
}

CON

    NAN_CON_MASK= %0111_1111_1000_0000__0000_0000_0000_0000 ' exponent is $FF signaling that
                                                            ' the result is something special
    PLUS_INF    = NAN_CON_MASK
    MINUS_INF   = %1111_1111_1000_0000__0000_0000_0000_0000
    NAN_CON     = $7FFF_FFFF                    ' largest value of NaN
    LFSR_SCL    = (1.0 / float(posx))

VAR

    long sprout
    long spud

PUB arccos = acos
PUB acos(singlea) | singleb, temp
' Arccosine
' acos( x ) = atan2( sqrt( 1 - x*x ), x )
'   Valid values: -1 .. 1 (inclusive)

    { calculate opposite side of triangle }
    singleb := fsqrt( fsub( 1.0 , fmul( singlea, singlea) ) )

    { check for valid range }
    if (isnan(singleb))
        return NAN_CON

    { calculate angle }
    return atan2( singleb, singlea)

PUB arcsin = asin
PUB asin(singlea) | singleb, temp
' Arcsine
' asin( x ) = atan2( x, sqrt( 1 - x*x ) )
'   Valid values: -1 .. 1 (inclusive)

    { calculate adjacent side of triangle }
    singleb := fsqrt( fsub( 1.0 , fmul( singlea, singlea) ) )

    { check for valid range }
    if isnan(singleb)
        return NAN_CON

    { calculate angle }
    return atan2( singlea, singleb)

PUB arctan = atan
PUB atan(singlea)
' arctangent
' atan( A ) = atan2( A , 1.0 )
    return atan2(singlea, 1.0)

PUB arctan2 = atan2
PUB atan2(singlea, singleb): angle | sa, xa, ma, sb, xb, mb, a, x, y
' 2-argument arctangent (y, x)
'   Returns: angle over the range of -pi to pi radians

    { re-scale inputs.  (same front end as addition) }
    unpack(@sa, singleb)                        ' unpack inputs
    unpack(@sb, singlea)

    if (sa)                                     ' handle mantissa negation
        -ma
    if (sb)
        -mb

    angle := ||(xa - xb) <# 31                  ' get exponent difference
    if (xa > xb)                                ' shift lower-exponent mantissa down
        mb ~>= angle
    else
        ma ~>= angle
        xa := xb

    { feed to cordic code }
    ma += 1                                     ' round instead of truncate
    mb += 1                                     ' round instead of truncate
    ma ~>= 1                                    ' avoid overflows in the CORDIC code
    mb ~>= 1

    a := 0
    x := ma
    y := mb
    cordic(@a, 1)
    angle := a                                  ' return the angle

    { re-scale and output the angle }
    angle += 1                                  ' round instead of truncate
    angle ~>= 1                                 ' keep the angles in the valid range for ffloat()
    return fmul(ffloat(angle), CORDIC_TO_RAD)   ' convert back to radians

PUB cordic(ptr, mode) | negate, i, da, dx, dy, a, x, y
' CORDIC algorithm
'
' if mode = 0: x,y are rotated by angle in a
' if mode = 1: x,y are converted from cartesian to polar with angle->a, length->x
'
'   - angle range: $00000000-$FFFFFFFF = 0-359.9999999 degrees
'   - hypotenuse of x,y must be within ±1_300_000_000 to avoid overflow
'   - algorithm works best if x,y are kept large:
'       example: x=$40000000, y=0, a=angle, cordic(0) performs cos,sin into x,y

    longmove(@a, ptr, 3)                        ' copy in data

    if (mode)                                   ' if atan2 mode, reset a
        a := 0
        negate := (x < 0)                       ' check quadrant 2 | 3 for atan2 or rotate mode
    else
        negate := (a ^ a << 1) & $80000000

    if (negate)                                 ' if quadrant 2 | 3, (may be outside ±106°
                                                '   convergence range)
        a += $80000000                          ' ..add 180 degrees to angle
        -x                                      ' ..negate x
        -y                                      ' ..negate y

    repeat i from 0 to 26                       ' CORDIC iterations (27: optimal for 32-bit values)
        da := _corlut[i]
        dx := y ~> i
        dy := x ~> i

        if (mode)
            negate := (y < 0)                   ' if atan2 mode, drive y towards 0
        else
            negate := (a => 0)                  ' if rotate mode, drive a towards 0

        if (negate)
            -da
            -dx
            -dy

        a += da
        x += dx
        y -= dy

    { remove CORDIC gain by multiplying by ~0.60725293500888 }
    i := $4DBA76D4
    x := (x ** i) << 1 + (x * i) >> 31
    y := (y ** i) << 1 + (y * i) >> 31

    longmove(ptr, @a, 3)                        ' copy out data

DAT
' CORDIC angle lookup table
_corlut long $20000000
        long $12E4051E
        long $09FB385B
        long $051111D4
        long $028B0D43
        long $0145D7E1
        long $00A2F61E
        long $00517C55
        long $0028BE53
        long $00145F2F
        long $000A2F98
        long $000517CC
        long $00028BE6
        long $000145F3
        long $0000A2FA
        long $0000517D
        long $000028BE
        long $0000145F
        long $00000A30
        long $00000518
        long $0000028C
        long $00000146
        long $000000A3
        long $00000051
        long $00000029
        long $00000014
        long $0000000A

PUB cos(singlea) | a, x, y
' cosine
'   Valid values:
'       -(2^(31-CORDIC_PRECIS)-1)*2*pi .. (2^(31-CORDIC_PRECIS)-1)*2*pi
'       (default of -1605 to 1605 radians)

    { re-scale to cordic angles }
    singlea := fmul(singlea, RAD_TO_SUBCOR)

    { convert to integer }
    singlea := fround(singlea)

    { shift to complete conversion to cordic angle }
    singlea <<= 32-CORDIC_PRECIS

    { feed to cordic (use a LONG vector to rotate) }
    a := singlea
    x := TRIG_VECT_INT
    y := 0
    cordic(@a, 0)

    { convert back to a float }
    singlea := ffloat(x)

    { scale output to -1.0 to 1.0 range }
    return fmul(singlea, constant(1.0 / TRIG_VECT_FLT))

CON
' exp() and log() constants
    MANTISSA_ONE    = 1 << 29                   ' 1.0 expressed in the same binary fractions
                                                '   as the mantissa
    LOG_BASE2_BASEE = 0.693147180559945         ' 1.0 / log2(e)
    LOG_BASE2_BASE10= 0.301029995663981         ' 1.0 / log2(10)
    EXP_BASE2_BASEE = 1.44269504088896          ' log2(e)
    EXP_BASE2_BASE10= 3.32192809488736          ' log2(10)

PUB exp(singlea)
' Evaluate the base 'e' exponential
'   Uses base 2 exponential and change of base identity
'   ((x^a)^b) = x^(a*b) with x = 2 and x^a = new_base then a = log2(new_base)
    return exp2( fmul(singlea, EXP_BASE2_BASEE) )

PUB exp2(singlea): e | s, x, m, temp, work, idx
' Evaluate the base 2 exponential (anti-log) using an invariant,
'   and successive approximation from a table of "nice" numbers.
'   bassed on algorithm shown at http://www.quinapalus.com/efunc.html
    s := (singlea >> 31)                        ' unpack sign
    singlea := (singlea & $7FFF_FFFF)           ' clear the sign bit (abs())
    x := ftrunc(singlea)                        ' get the integer portion of the input
                                                '   (exponent of the result)

    if (x => 127)                               ' if result would excede the size of a float
        return NAN_CON                          ' return NaN for now, should return +infinity?
    m := frac_int(singlea)                      ' get the fractional part of the input

    { start core calculation }
    work := MANTISSA_ONE                        ' start with a result mantissa of 1.0
    repeat idx from 1 to 25                     ' 25 rounds is optimal for single precision numbers
        temp := exp_lut[idx-1]                  ' access current table index
        if (temp < m)                           ' if table entry is less than "m"
            m -= temp                           ' subtract table entry from "m"
            work += (work >> idx)               ' multiply work by the corresponding "nice" number

    { move result into mantissa }
    m := work

    { pack up result and deal with sign }
    e := pack(@s)

    if (s)
        return fdiv(-1.0, e)

DAT
' log2(1 + 2^-(array_idx+1)) expressed as a binary fraction over 2^29
exp_lut long      314049351 {0}
        long      172833830
        long       91227790
        long       46956255
        long       23833911
        long       12008628 {5}
        long        6027587
        long        3019657
        long        1511300
        long         756019
        long         378102 {10}
        long         189074
        long          94543
        long          47273
        long          23637
        long          11818 {15}
        long           5909
        long           2955
        long           1477
        long            739
        long            369 {20}
        long            185
        long             92
        long             46
        long             23
        long             12 {25}
        long              6
        long              3
        long              1 {28}

PUB exp10(singlea)
' Evaluate the base '10' exponential
'   Uses base 2 exponential and change of base identity
'   ((x^a)^b) = x^(a*b) with x = 2 and x^a = new_base then a = log2(new_base)
    return exp2( fmul(singlea, EXP_BASE2_BASE10) )

PUB fabs(singlea): single
' Absolute singlea
    return (singlea & $7FFF_FFFF)               ' clear sign bit

PUB fabsneg(singlea): single
' ABS singlea then negate singlea
    return (singlea | $8000_0000)               ' set sign bit

PUB fadd(singlea, singleb): single | sa, xa, ma, sb, xb, mb
' Add singlea and singleb
    unpack(@sa, singlea)                        ' unpack inputs
    unpack(@sb, singleb)

    if (sa)                                     ' handle mantissa negation
        -ma
    if (sb)
        -mb

    single := ||(xa - xb) <# 31                 ' get exponent difference
    if (xa > xb)                                ' shift lower-exponent mantissa down
        mb ~>= single
    else
        ma ~>= single
        xa := xb

    ma += mb                                    ' add mantissas
    sa := ma < 0                                ' get sign
    ||ma                                        ' absolutize result

    return pack(@sa)                            ' pack result

PUB fcmp(singlea, singleb): c | single
' Exactly compare two floating point values
'   Returns: integer containing the results of the comparison
'       1: if singlea > singleb
'       0: if singlea == singleb
'       -1: if singlea < singleb
    single := fsub(singlea, singleb)
    if (single & $8000_0000)                    ' if the sign bit is set
        c := -1                                 ' result of subtraction is negative
    else
        c := 1                                  ' result of subtraction is positive
    ifnot (single << 1)                         ' mask off sign bit (subtraction can be +-zero)
        c := 0                                  ' inputs are the same

PUB fdiv(singlea, singleb): single | sa, xa, ma, sb, xb, mb
' Divide singlea by singleb
    unpack(@sa, singlea)                        ' unpack inputs
    unpack(@sb, singleb)

    sa ^= sb                                    ' xor signs
    xa -= xb                                    ' subtract exponents

    repeat 30                                   ' divide mantissas
        single <<= 1
        if ma => mb
            ma -= mb
            single++
        ma <<= 1
    ma := single

    return pack(@sa)                            ' pack result

PUB ffloat(integer): single | s, x, m
'Convert integer to float
    if (m := ||(integer))                       ' absolutize mantissa, if 0, result 0
        s := (integer >> 31)                    ' get sign
        x := (>|m - 1)                          ' get exponent
        m <<= (31 - x)                          ' msb-justify mantissa
        m >>= 2                                 ' bit29-justify mantissa
        return pack(@s)                         ' pack result

PUB fmod(singlea, singleb): m | tempa
' [a - float(floor(a/b)) * b] calculation of mod function
    tempa := fdiv(singlea, singleb)
    tempa := ffloat(ftrunc(tempa))
    tempa := fneg(fmul(tempa, singleb))
    m := fadd(singlea, tempa)

    { correct the sign }
    if (fcmp(singlea, 0.0) == -1)
        return fabsneg(m)
    else
        return fabs(m)
  
PUB fmul(singlea, singleb): single | sa, xa, ma, sb, xb, mb
' Multiply singlea by singleb
    unpack(@sa, singlea)                        ' unpack inputs
    unpack(@sb, singleb)

    sa ^= sb                                    ' xor signs
    xa += xb                                    ' add exponents
    ma := (ma ** mb) << 3                       ' multiply mantissas and justify

    return pack(@sa)                            ' pack result

PUB fneg(singlea): single
' Negate singlea
    return (singlea ^ $8000_0000)               ' toggle sign bit

CON MASK29 = $1FFF_FFFF
PUB fract(singlea): single | s, x, m
' Extract the fractional portion of a floating point number
    unpack(@s, singlea)                         ' unpack the float
    if (x < 0)                                  ' if NaN do nothing
        return singlea                          ' if exponent < 0 there is no whole part,
                                                '   so input is already a fraction, return singlea

    x := x <# 23                                ' if exponent > 23, we have no fractional
                                                '   significant figures
    m <<= x                                     ' shift mantissa left by exponent
    m &= MASK29                                 ' mask off extra bits
    x := 0                                      ' update exponent for fraction
    s := 0
    single := pack(@s)                          ' pack up and return result

PUB fround(single): integer
' Convert float to rounded integer
    return finteger(single, 1)                  ' use 1/2 to round

PUB fsqrt(singlea): rt | s, x, m, root
' Compute square root of singlea
    if (singlea > 0)                            ' if a =< 0, result 0
        unpack(@s, singlea)                     ' unpack input

        m >>= !x & 1                            ' if exponent even, shift mantissa down
        x ~>= 1                                 ' get root exponent

        root := $4000_0000                      ' compute square root of mantissa
        repeat 31
            rt |= root
            if (rt ** rt) > m
                rt ^= root
            root >>= 1
        m := (rt >> 1)
        return pack(@s)                         ' pack result

    if (fcmp(singlea, 0.0) < 0)                 ' input is negative
        return NAN_CON

PUB fsub(singlea, singleb): single
' Subtract singleb from singlea
    return fadd(singlea, fneg(singleb))

PUB ftrunc(single): integer
' Convert float to truncated integer
    return finteger(single, 0)                  ' use 0 to round

PUB isinf(singlea): i | s, m
' Flag indicating float is infinity
'   Returns:
'       1 if singlea is +inf
'       0 if singlea is finite or NaN
'       -1 if singlea is -inf
    i := 0                                      ' set default answer
    if ((singlea & NAN_CON_MASK) == NAN_CON_MASK)' if exponent is $FF
        m := (singlea & $007F_FFFF)             ' unpack mantissa
        if (m == 0)                             ' and if mantissa is zero
            s := (singlea >> 31)                ' unpack sign
            if (s)                              ' if the sign is negative
                i := -1
            else                                ' if the sign is positive
                i := 1

PUB isnan(singlea): n | m
' Flag indicating float is NaN (not a number)
'   Returns:
'       True if singlea is NaN
'       False if singlea is a number
    n := false                                  ' set default answer
    if ((singlea & NAN_CON_MASK) == NAN_CON_MASK)' if exponent is $FF
        m := (singlea & $007F_FFFF)             ' unpack mantissa
        if (m <> 0)                             ' and if mantissa is nonzero
            n := true                           ' singlea is a NaN

PUB log(singlea): l
' Natural logarithim of singlea
'   Uses change of base identity and log2()
    return fmul(log2(singlea), LOG_BASE2_BASEE)

PUB log2(singlea) | s, x, m, temp, work, idx
' Evaluate the base 2 logarithim using an invariant, and successive approximation from a table of
'   "nice" numbers. Based on algorithm shown at http://www.quinapalus.com/efunc.html
'   Valid values: positive numbers above ~1e-38
    unpack(@s, singlea)                         ' unpack the floating point input
    if (s)                                      ' if the input is negative
        return NAN_CON                          ' the result is not a number (imaginary number)
    if (singlea == 0)                           ' trap error with zero input
        return NAN_CON                          ' should output -inf instead

    m ~>= 1                                     ' divide mantissa by 2 so it ranges from
                                                '   0.5 to .99999999999
    x += 1                                      ' adjust integer portion of result for the
                                                '   mantissa division

    work := 0                                   ' start with a fractional portion of zero
    repeat idx from 1 to 24
        temp := m + m ~> idx                    ' multiply 'm' by a "nice" number and temporarialy
                                                '   store the result
        if (temp < MANTISSA_ONE)                ' if temp is less than a mantissa of 1
            m := temp                           ' keep the updated value of 'm'
            work -= exp_lut[idx-1]              ' adjust work to match

    work += (m - MANTISSA_ONE)                  ' adjust for residual

    { add "x + work" }
    { check if integer portion is negative }
    if (x < 0)
        s := 1
    x := ||x                                    ' take the absolute value of the integer portion
    temp := (0 #> ((>|x) -1))                   ' what's the msb of "x"
    m := (x << (29-temp))                       ' justify x to bit_29
    work ~>= temp                               ' allign fractional part with x
    if (s)                                      ' if 'x' was negative, subtract fractional part
        m -= work
    else                                        ' if 'x' was positive add fractional part
        m += work                               ' add fractional portion to integer
    x := temp                                   ' update final exponent

    if (m < 0)                                  ' if mantissa is negative
        s := 1                                  ' change sign to negative
        ||m                                     ' absolute value the mantissa

    return pack(@s)                             ' pack and return result.

CON

    CORDIC_PRECIS = 23                          ' number of bits to keep when converting to
                                                '   cordic angles.  Lower numbers of bits allow
                                                '   +-2^(31-CORDIC_PRECIS) turns outside of the
                                                '   -pi to pi range.
    RAD_TO_SUBCOR = float(1 << CORDIC_PRECIS) / 2.0 / pi
    TRIG_VECT_BITS = 29                         ' number of bits long the CORDIC vector should be
    TRIG_VECT_INT = (1 << TRIG_VECT_BITS)
    TRIG_VECT_FLT = float(TRIG_VECT_INT)

CON

    CORDIC_TO_RAD = (pi / float(1 << 30))       ' re-scale cordic/2 angular units to radians

PUB log10(singlea)
' Base 10 logarithim of singlea
'   Uses change of base identity and log2()
    return fmul(log2(singlea), LOG_BASE2_BASE10)

PUB logb(singlea, singleb)
' Logarithim with base singlea of singleb
'   Uses change of base identity and log2()
  result := fdiv( log2(singleb), log2(singlea) )

PUB pow(singlea, singleb)
' Evaluate the base 'singleb' exponential (i.e. singlea^singleb)
'   Uses base 2 exponential and change of base identity. ((x^a)^b) = x^(a*b) with x = 2 and x^a = new_base then a = log2(new_base)
    singlea := log2(singlea)
    return exp2( fmul(singlea, singleb) )

PUB random
' Returns a random, uniformly distributed float within the range of -1 to 1
    repeat (((spud << 13) >> 30) + 1)              ' run LFSR 1-4x based on center bits of spud
        ?sprout
    repeat (((sprout << 23) >> 30) + 1)            ' run LFSR 1-4x based on center bits of sprout
        ?spud
    return fmul( ffloat(spud), LFSR_SCL)

PUB seed(inta, intb)
' Seed the pseudo-random number generator with two 32-bit integers
    sprout := inta
    spud := intb

PUB sin(singlea) | a, x, y
' Use cordic to calculate Sin(singlea) where singlea is the angle in radians
'   Valid values:
'       -(2^(31-CORDIC_PRECIS)-1)*2*pi .. (2^(31-CORDIC_PRECIS)-1)*2*pi
'       (default of -1605 to 1605 radians)

    { re-scale to cordic angles }
    singlea := fmul(singlea, RAD_TO_SUBCOR)

    { convert to integer }
    singlea := fround(singlea)

    { shift to complete conversion to cordic angle }
    singlea <<= 32-CORDIC_PRECIS

    { feed to cordic (use a LONG vector to rotate) }
    a := singlea
    x := TRIG_VECT_INT
    y := 0
    cordic(@a, 0)

    { convert back to a float }
    singlea := ffloat(y)

    { scale output to -1.0 to 1.0 range }
    return fmul(singlea, constant(1.0 / TRIG_VECT_FLT))

PUB tan(singlea) | a, x, y
' Use cordic to calculate tan(singlea) where singlea is the angle in radians
'   (uses tan(x) = sin(x)/cos(x) identity)
'   Valid values: -(2^(31-CORDIC_PRECIS)-1)*2*pi .. (2^(31-CORDIC_PRECIS)-1)*2*pi
'   (default of -1605 to 1605 radians)

    { re-scale to cordic angles }
    singlea := fmul(singlea, RAD_TO_SUBCOR)

    { convert to integer }
    singlea := fround(singlea)

    { shift to complete conversion to cordic angle }
    singlea <<= 32-CORDIC_PRECIS

    { feed to cordic (use a LONG vector to rotate) }
    a := singlea
    x := TRIG_VECT_INT
    y := 0
    cordic(@a, 0)

    { convert back to a float and calculate sin(x)/cos(x) }
    return fdiv(ffloat(y), ffloat(x))

PRI finteger(singlea, r) : integer | s, x, m
' Convert float to rounded/truncated integer
  unpack(@s, singlea)                           ' unpack input

    if ((x => -1) and (x =< 30))                ' if exponent not -1..30, result 0
        m <<= 2                                 ' msb-justify mantissa
        m >>= 30 - x                            ' shift down to 1/2-lsb
        m += r                                  ' round (1) or truncate (0)
        m >>= 1                                 ' shift down to lsb
        if s                                    ' handle negation
            -m
        return m                                ' return integer

PRI frac_int(singlea): int | s, x, m
' Extract the fractional portion of a floating point number
'   Returns: integer binary fraction for use in exp2() function
    unpack(@s, singlea)                         ' unpack the float
    if (x => 0)                                 ' input is greater than 1
        x := x <# 23                            ' if exponent is larger than 23,
                                                ' we have no fractional significant figures
        m <<= x                                 ' shift mantissa left by exponent
        m &= MASK29                             ' mask off extra bits
    else                                        ' input is less than one
        x := (x #> -29)                         ' no bits left in binary fraction if x < -29
        m >>= -x                                ' justify
    x := 0                                      ' update exponent for fraction
    s := 0
    int := m                                    ' return fraction of single A as a binary fraction
                                                '   (int / (1 << 29) = int / (2^29))

PRI unpack(pointer, single) | s, x, m
' Unpack floating-point into (sign, exponent, mantissa) at pointer
    s := (single >> 31)                         ' unpack sign
    x := single << 1 >> 24                      ' unpack exponent
    m := (single & $007F_FFFF)                  ' unpack mantissa

    if (x)                                      ' if exponent > 0,
        m := (m << 6) | $2000_0000              '   bit29-justify mantissa with leading 1
    else
        result := (>|m - 23)                    ' else, determine first 1 in mantissa
        x := result                             ' ..adjust exponent
        m <<= 7 - result                        ' ..bit29-justify mantissa

    x -= 127                                    ' unbias exponent

    longmove(pointer, @s, 3)                    ' write (s,x,m) structure from locals
  
PRI pack(pointer): single | s, x, m
' Pack floating-point from (sign, exponent, mantissa) at pointer
    longmove(@s, pointer, 3)                    ' get (s,x,m) structure into locals

    if (m)                                      ' if mantissa 0, result 0
        single := 33 - >|m                      ' determine magnitude of mantissa
        m <<= single                            ' msb-justify mantissa without leading 1
        x += 3 - single                         ' adjust exponent

        m += $00000100                          ' round up mantissa by 1/2 lsb
        ifnot (m & $FFFFFF00)                   ' if rounding overflow,
            x++                                 ' ..increment exponent

        x := x + 127 #> -23 <# 255              ' bias and limit exponent

        if (x < 1)                              ' if exponent < 1,
            m := $8000_0000 +  m >> 1           '..replace leading 1
            m >>= -x                            '..shift mantissa down by exponent
            x~                                  '..exponent is now 0

        return s << 31 | x << 23 | m >> 9       ' pack result

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

