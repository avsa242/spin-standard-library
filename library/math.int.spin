{
    --------------------------------------------
    Filename: math.int.spin
    Author: Jesse Burt
    Description: Basic integer math functions
    Copyright (c) 2022
    Started Apr 11, 2021
    Updated May 2, 2022
    See end of file for terms of use.
    --------------------------------------------
}
' Used by Atan2()
    K1          = 5701
    K2          = -1645
    K3          = 446

VAR

    long _rndseed

PUB Null{}
' This is not a top-level object

PUB Atan(iy, ix): iangle | iratio, itmp
' Arctangent
    if (ix == 0) and (iy == 0)
        return 0
    if (ix == 0) and (iy <> 0)
        return 90_00

    if (iy =< ix)
        iratio := div(iy, ix)
    else
        iratio := div(ix, iy)

    iangle := K1 * iratio
    itmp := (iratio >> 5) * (iratio >> 5) * (iratio >> 5)
    iangle += (itmp >> 15) * K2
    itmp := (itmp >> 20) * (iratio >> 5) * (iratio >> 5)
    iangle += (itmp >> 15) * K3
    iangle := iangle >> 15

    if (iy > ix)
        iangle := (90_00 - iangle)
    if (iangle < 0)
        iangle := 0
    if (iangle > 90_00)
        iangle := 90_00

    return iangle

PUB Atan2(iy, ix): iresult
' 2-argument arctangent
    if (ix == -32768)
        ix := -32767
    if (iy == -32768)
        iy := -32767

    if ((ix => 0) and (iy => 0))
        iresult := atan(iy, ix)
    elseif ((ix =< 0) and (iy => 0))
        iresult := (180_00 - atan(iy, -ix))
    elseif ((ix =< 0) and (iy =< 0))
        iresult := (-180_00 + atan(-iy, -ix))
    else
        iresult := (-atan(-iy, ix))

    return iresult

PUB Cos(angle): cosine
' Return the cosine of angle
    return sin(angle + $800)

PUB Log2(num): l2
' Return base-2 logarithm of num
    l2 := 0
    if num > 1
        repeat
            num >>= 1
            l2++
        until num == 1
    return

PUB Pow(base, exp): r
' Return base raised to the power of exp
    r := base
    exp--
    repeat exp
        r *= base
    return

PUB RNDSeed(val)
' Set seed for random number generator
    _rndseed := val

PUB RND(maxval): r
' Return random unsigned number up to maxval
    return ||(? _rndseed) // maxval

PUB RNDS(maxval): r
' Return random signed number up to maxval
    return (? _rndseed) // maxval

PUB RNDi(maxval): r
' Return random unsigned number up to maxval, inclusive
    return ||(? _rndseed) // (maxval+1)

PUB RNDSi(maxval): r
' Return random signed number up to maxval, inclusive
    return (? _rndseed) // (maxval+1)

PUB Sin(angle): sine
' Return the sine of angle
    sine := angle << 1 & $FFE
    if angle & $800
       sine := word[$F000 - sine]               ' ROM Sine table
    else
       sine := word[$E000 + sine]
    if angle & $1000
       -sine

CON

    MINDELTADIV = 1
    MINDELTATRIG= 1

PRI Div(iy, ix): ir | itmp, idelta

    ir := 0
    idelta := 16384

    repeat while (ix < 16384) and (iy < 16384)
        ix := (ix + ix)
        iy := (iy + iy)

    repeat
        itmp := (ir + idelta)
        itmp := ((itmp * ix) >> 15)
        if (itmp =< iy)
            ir += idelta
        idelta := (idelta >> 1)
    while (idelta => MINDELTADIV)

    return ir

