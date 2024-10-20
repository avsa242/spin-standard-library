{
    --------------------------------------------
    Filename: string.float.spin2
    Author: Chip Gracey
    Modified by: Jesse Burt
    Description: IEEE-754 Floating point to/from string conversion
    Started 2006
    Updated Oct 20, 2022
    See end of file for terms of use.
    --------------------------------------------

    This is based on FloatString.spin, originally
        by Chip Gracey
}

VAR

  long  _ptr_str, _digits, _exponent, _integer, _tens, _zeroes, _precision
  long  _pos_ch, _dec_ch, _thous_ch, _thousths_ch
  byte  _float_str[20]


OBJ

  math : "math.float.nocog"

PUB strtofloat = str_float
PUB str_float(strptr): f | int, sign, dmag, mag, get_exp, b
' Convert string representation of a floating point number to an IEEE-754 float
    longfill(@int, 0, 5)
    { get all the digits as if this is an integer (but track the exponent) }
    repeat
        case b := byte[strptr++]
            "-":
                sign := $8000_0000
            "+":                                ' allow, but ignore
            "0".."9":
                int := (int * 10) + b - "0"
                mag += dmag
            ".":
                dmag := -1
            other:                              ' either done, or about to do exponent
                if (get_exp)
                    { just finished processing the exponent }
                    if (sign)
                        int := -int
                    mag += int
                    quit
                else
                    { convert int to a (signed) float }
                    f := math.ffloat(int) | sign
                    if (b == "E") or (b == "e") ' should we continue?
                        longfill(@int, 0, 3)
                        get_exp := 1
                    else
                        quit
                        ' exp10 is the weak link...uses the Log table in P1 ROM
                        ' f := fmul(f, exp10(ffloat(mag)))
                        ' use these loops for more precision (slower for large exponents,
                        '   positive or negative)
    b := 0.1
    if (mag > 0)
        b := 10.0
    repeat ||(mag)
        f := math.fmul(f, b)

PUB float_str = float_str
PUB float_str(single) : ptr_str
' Convert floating-point number to string
'   single: floating-point number
'
'   Returns: pointer to resultant z-string
'
'  Magnitudes below 1e+12 and within 1e-12 will be expressed directly;
'  otherwise, scientific notation will be used.
'
'  examples                 results
'  -----------------------------------------
'  float_str(0.0)       "0"
'  float_str(1.0)       "1"
'  float_str(-1.0)      "-1"
'  float_str(^^2.0)     "1.414214"
'  float_str(2.34e-3)   "0.00234"
'  float_str(-1.5e-5)   "-0.000015"
'  float_str(2.7e+6)    "2700000"
'  float_str(1e11)      "100000000000"
'  float_str(1e12)      "1.000000e+12"
'  float_str(1e-12)     "0.000000000001"
'  float_str(1e-13)     "1.000000e-13"

    ptr_str := setup(single)                    ' perform initial setup

    { eliminate trailing zeroes }
    if (_integer)
        repeat until (_integer // 10)
            _integer /= 10
            _tens /= 10
            _digits--
    else
        _digits := 0

    { express number according to exponent }
    case _exponent
        11..0:                                  ' in range left of decimal
            add_digits(_exponent + 1)
        -1.._digits - 13:                       ' in range right of decimal
            _zeroes := -_exponent
            add_digits(1)
        other:                                  ' out of range; do sci notation
            do_sci{}

    byte[_ptr_str] := 0                         ' terminate string

PUB floattoscientific = float_sci
PUB float_sci(single): ptr_str
' Convert floating-point number to scientific-notation string
'   single: floating-point number
'
'   Returns: pointer to resultant z-string
'
'  examples                           results
'  -------------------------------------------------
'  float_sci(1e-9)            "1.000000e-9"
'  float_sci(^^2.0)           "1.414214e+0"
'  float_sci(0.00251)         "2.510000e-3"
'  float_sci(-0.0000150043)   "-1.500430e-5"
    ptr_str := setup(single)                    ' perform initial setup
    do_sci{}                                    ' do scientific notation
    byte[_ptr_str] := 0                         ' terminate string

PUB floattometric = float_metric
PUB float_metric(single, suff_ch): ptr_str | x, y
'Convert floating-point number to metric string
'   single: floating-point number
'   suff_ch: optional ending character (0 = none)
'
'   Returns:
'       pointer to resultant z-string
'
'  Magnitudes within the metric ranges will be expressed in metric
'  terms; otherwise, scientific notation will be used.
'
'  range   name     symbol
'  -----------------------
'  1e24    yotta    Y
'  1e21    zetta    Z
'  1e18    exa      E
'  1e15    peta     P
'  1e12    tera     T
'  1e9     giga     G
'  1e6     mega     M
'  1e3     kilo     k
'  1e0     -        -
'  1e-3    milli    m
'  1e-6    micro    u
'  1e-9    nano     n
'  1e-12   pico     p
'  1e-15   femto    f
'  1e-18   atto     a
'  1e-21   zepto    z
'  1e-24   yocto    y
'
'  examples               results
'  ------------------------------------
'  float_metric(2000.0, "m")    "2.000000km"
'  float_metric(-4.5e-5, "A")   "-45.00000uA"
'  float_metric(2.7e6, 0)       "2.700000M"
'  float_metric(39e31, "W")     "3.9000e+32W"

    { perform initial setup }
    ptr_str := setup(single)

    x := (_exponent + 45) / 3 - 15               ' determine thousands exponent and
    y := (_exponent + 45) // 3                   '   relative tens exponent

    if (||(x) =< 8)                             ' if in metric range, do metric
        add_digits(y + 1)                       ' add digits with possible decimal
        byte[_ptr_str++] := " "                 ' space
        if (x)                                  ' if thousands exp not 0, add metric indicator
            byte[_ptr_str++] := metric[x]
    else                                        ' if out of metric range, do scientific notation
        do_sci{}

    if (suff_ch)                                ' if suff_ch not 0, add suff_ch
        byte[_ptr_str++] := suff_ch

    byte[_ptr_str] := 0                         ' terminate string 

PUB setprecision = set_precision
PUB set_precision(nr_digits)
' Set precision to express floating-point numbers in
'  nr_digits: Number of digits to round to, limited to 1..7 (7=default)
'
'  examples          results
'  -------------------------------
'  set_precision(1)   "1e+0"
'  set_precision(4)   "1.000e+0"
'  set_precision(7)   "1.000000e+0"
    _precision := nr_digits

PUB setpositivechr = set_pos_ch
PUB set_pos_ch(pos_ch)
' Set lead character for positive numbers
'  pos_ch = 0: no character will lead positive numbers (default)
'  non-0: pos_ch will lead positive numbers (ie " " or "+")
'
'  examples              results
'  ----------------------------------------
'  set_pos_ch(0)     "20.07"   "-20.07"
'  set_pos_ch(" ")   " 20.07"  "-20.07"
'  set_pos_ch("+")   "+20.07"  "-20.07"
    _pos_ch := pos_ch

PUB setdecimalchr
PUB set_dec_ch(dec_ch)
' Set decimal point character
'  dec_ch = 0: "." will be used (default)
'  non-0: dec_ch will be used (e.g., "," for Europe)
'
'  examples             results
'  ----------------------------
'  set_dec_ch(0)     "20.49"
'  set_dec_ch(",")   "20,49"
    _dec_ch := dec_ch

PUB setseparatorchrs = set_sep_ch
PUB set_sep_ch(thous_ch, thousths_ch)
' Set thousands and thousandths separator characters
'  thous_ch:
'        0: no character will separate thousands (default)
'    non-0: thous_ch will separate thousands
'
'  thousths_ch:
'        0: no character will separate thousandths (default)
'    non-0: thousths_ch will separate thousandths
'
'  examples                     results
'  -----------------------------------------------------------
'  set_sep_ch(0, 0)       "200000000"    "0.000729345"
'  set_sep_ch(0, "_")     "200000000"    "0.000_729_345"
'  set_sep_ch(",", 0)     "200,000,000"  "0.000729345"
'  set_sep_ch(",", "_")   "200,000,000"  "0.000_729_345"
    _thous_ch := thous_ch
    _thousths_ch := thousths_ch

PRI setup(single): ptr_str | tmp

    if (_precision)
        _digits := (1 #> _precision <# 7)       ' limit digits to 1..7
    else
        _digits := 7

    _ptr_str := @_float_str                     ' init string pointer

    if (single & $80000000)                     ' add '-' if negative
        byte[_ptr_str++] := "-"
    elseif (_pos_ch)                            ' otherwise, add positive lead char
        byte[_ptr_str++] := _pos_ch

    if (single &= $7FFFFFFF)                    ' clear sign and check for 0
        { not 0, estimate exponent }
        _exponent := ((single << 1 >> 24 - 127) * 77) ~> 8
        if (_exponent < -32)                    ' if very small, bias up
            single := math.FMul(single, 1e13)
            _exponent += tmp := 13

        { determine exact exponent and integer }
        repeat
            _integer := math.fround(math.fmul(single, tenf[_exponent - _digits + 1]))
            if (_integer < teni[_digits - 1])
                _exponent--
            elseif (_integer => teni[_digits])
                _exponent++
            else
                _exponent -= tmp
            quit

    { if 0, reset exponent and integer }
    else
        _exponent := 0
        _integer := 0

    { set initial tens and clear zeroes }
    _tens := teni[_digits - 1]
    _zeroes := 0

    return @_float_str

PRI do_sci

    add_digits(1)                               ' add digits with possible decimal
    byte[_ptr_str++] := "e"                     ' add exponent indicator
    if (_exponent => 0)                         ' add exponent sign
        byte[_ptr_str++] := "+"
    else
        byte[_ptr_str++] := "-"
        ||_exponent
    if (_exponent => 10)                        ' add exponent digits
        byte[_ptr_str++] := ((_exponent / 10) + "0")
        _exponent //= 10
    byte[_ptr_str++] := _exponent + "0"

PRI add_digits(leading) | i

    repeat i := leading                         ' add leading digits
        add_digit{}
        if (_thous_ch)                          ' add thousands separator between thousands
            i--
            if (i and not (i // 3))
                byte[_ptr_str++] := _thous_ch
    if (_digits)                                ' if trailing digits, add decimal char
        add_dec{}
        repeat while _digits                    ' then add trailing digits
            if (_thousths_ch)                   ' add thousandths separator between thousandths
                if (i and not (i // 3))
                    byte[_ptr_str++] := _thousths_ch
            i++
            add_digit{}


PRI add_digit{}

    if (_zeroes)                                ' if leading zeroes, add "0"
        byte[_ptr_str++] := "0"
        _zeroes--
    elseif (_digits)                            ' if more digits, add current digit and prep next
        byte[_ptr_str++] := ((_integer / _tens) + "0")
        _integer //= _tens
        _tens /= 10
        _digits--
    else                                        ' if no more digits, add "0"
        byte[_ptr_str++] := "0"

PRI add_dec{}

    if (_dec_ch)
        byte[_ptr_str++] := _dec_ch
    else
        byte[_ptr_str++] := "."


DAT
        long                1e+38, 1e+37, 1e+36, 1e+35, 1e+34, 1e+33, 1e+32, 1e+31
        long  1e+30, 1e+29, 1e+28, 1e+27, 1e+26, 1e+25, 1e+24, 1e+23, 1e+22, 1e+21
        long  1e+20, 1e+19, 1e+18, 1e+17, 1e+16, 1e+15, 1e+14, 1e+13, 1e+12, 1e+11
        long  1e+10, 1e+09, 1e+08, 1e+07, 1e+06, 1e+05, 1e+04, 1e+03, 1e+02, 1e+01
tenf    long  1e+00, 1e-01, 1e-02, 1e-03, 1e-04, 1e-05, 1e-06, 1e-07, 1e-08, 1e-09
        long  1e-10, 1e-11, 1e-12, 1e-13, 1e-14, 1e-15, 1e-16, 1e-17, 1e-18, 1e-19
        long  1e-20, 1e-21, 1e-22, 1e-23, 1e-24, 1e-25, 1e-26, 1e-27, 1e-28, 1e-29
        long  1e-30, 1e-31, 1e-32, 1e-33, 1e-34, 1e-35, 1e-36, 1e-37, 1e-38

teni    long  1, 10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000

        byte "yzafpnum"
metric  byte 0
        byte "kMGTPEZY"

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

