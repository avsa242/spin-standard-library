{
    --------------------------------------------
    Filename: colors.24bpp.spin
    Description:
        Named constants for common colors
        suitable for use on 24bpp displays
    Author: Jesse Burt
    Copyright (c) 2023
    Started: May 30, 2023
    Updated: May 30, 2023
    See end of file for terms of use.
    --------------------------------------------
}
CON

    BLACK   = $00_00_00

    RED     = $ff_00_00
    RED75   = $bf_00_00
    RED50   = $7f_00_00
    RED25   = $3f_00_00
    RED1    = $01_00_00

    GREEN   = $00_ff_00
    GREEN75 = $00_bf_00
    GREEN50 = $00_7f_00
    GREEN25 = $00_3f_00
    GREEN1  = $00_01_00

    BLUE    = $00_00_ff
    BLUE75  = $00_00_bf
    BLUE50  = $00_00_7f
    BLUE25  = $00_00_3f
    BLUE1   = $00_00_01


    CYAN    = GREEN + BLUE
    CYAN75  = GREEN75 + BLUE75
    CYAN50  = GREEN50 + BLUE50
    CYAN25  = GREEN25 + BLUE25
    CYAN1   = GREEN1 + BLUE1

    GREY    = RED + GREEN + BLUE
    GREY75  = RED75 + GREEN75 + BLUE75
    GREY50  = RED50 + GREEN50 + BLUE50
    GREY25  = RED25 + GREEN25 + BLUE25
    GREY1   = RED1 + GREEN1 + BLUE1

    ORANGE  = RED + GREEN50

    VIOLET  = RED + BLUE
    VIOLET75= RED75 + BLUE75
    VIOLET50= RED50 + BLUE50
    VIOLET25= RED25 + BLUE25
    VIOLET1 = RED1 + BLUE1

    WHITE   = RED + GREEN + BLUE
    WHITE75 = RED75 + GREEN75 + BLUE75
    WHITE50 = RED50 + GREEN50 + BLUE50
    WHITE25 = RED25 + GREEN25 + BLUE25
    WHITE1  = RED1 + GREEN1 + BLUE1

    YELLOW  = RED + GREEN
    YELLOW75= RED75 + GREEN75
    YELLOW50= RED50 + GREEN50
    YELLOW25= RED25 + GREEN25
    YELLOW1 = RED1 + GREEN1

PUB null{}
' This is not a top-level object

DAT
{
Copyright 2023 Jesse Burt

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

