{
    --------------------------------------------
    Filename: math.int.spin
    Author: Jesse Burt
    Description: Basic integer math functions
    Copyright (c) 2021
    Started Apr 11, 2021
    Updated Apr 11, 2021
    See end of file for terms of use.
    --------------------------------------------
}
VAR

    long _rndseed

PUB Null{}
' This is not a top-level object

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

