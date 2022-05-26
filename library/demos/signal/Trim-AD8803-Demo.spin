{
    --------------------------------------------
    Filename: Trim-AD8803-Demo.spin
    Author: Beau Schwabe
    Modified by: Jesse Burt
    Description: AD8803 Octal 8-bit trim DAC demo
    Started 2007
    Updated May 26, 2022
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is a derivative of AD8803_DEMO.spin,
        by Beau Schwabe.
        The original header is preserved below
}

{{
*****************************************
* AD8803 Octal 8-Bit Trim DAC Demo v1.0 *
* Author: Beau Schwabe                  *
* Copyright (c) 2007 Parallax           *
* See end of file for terms of use.     *
*****************************************
}}
{


        H  G  F  E    CLK
    Vdd │  │  │  │ SDI │ Vss
    ┌┴──┴──┴──┴──┴──┴──┴──┴┐
    │                      │
     ]        AD8803       │
    │o                     │
    └┬──┬──┬──┬──┬──┬──┬──┬┘
    Vdd │  │  │  │ Vdd │ Vss
        A  B  C  D    CS

A - DAC0 output
B - DAC1 output
C - DAC2 output
D - DAC3 output
E - DAC4 output
F - DAC5 output
G - DAC6 output
H - DAC7 output


Note: This object does not start a new COG, it simply runs within the COG which calls it.
      In your code, reference the 'AD8803' object and pass the appropriate parameters when
      calling the 'Set(CS,SDI,CLK,DACaddress,DACvalue)' command.

}
CON

    _CLKMODE    = XTAL1 + PLL16X
    _XINFREQ    = 5_000_000

' -- User-modifiable constants
    CS          = 0                                             ' AD8803 pin 7
    SDI         = 1                                             ' AD8803 pin 11
    CLK         = 2                                             ' AD8803 pin 10
' --

OBJ

    dac     : "signal.dac.ad8803.nocog"          ' Octal 8-Bit Trim DAC

VAR

    byte DACaddress, DACvalue

PUB Demo

    DACaddress := 0                                             ' 0-7
    DACvalue   := 127                                           ' 0-255

    DAC.Set(CS, SDI, CLK, DACaddress, DACvalue)

    repeat

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

