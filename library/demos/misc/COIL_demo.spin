{
    --------------------------------------------
    Filename: COIL_demo.spin
    Author: Beau Schwabe
    Modified by: Jesse Burt
    Description: Demo of the coilread driver
        * Composite video
    Started 2007
    Updated Apr 27, 2021
    See end of file for terms of use.
    --------------------------------------------
}

{{
*****************************************
* COILREAD Demo v1.0                    *
* Author: Beau Schwabe                  *
* Copyright (c) 2007 Parallax           *
* See end of file for terms of use.     *
*****************************************
}}

''
''                               3.3V
''                                
''                           ┌──┳─┫
''         220Ω 500Ω      ┌┳┌680pF
''Ping I/O ────┳────└─┻┘ └─╋─────── Read I/O
''               R1 │     │       │
''                  │     220Ω   1M
''                  │ D1  │       │             NPN = 2n3904
''Coil I/O ──────╋─|<──┻───────┫             PNP = 2n3906 (best results when matched)
''                                              D1 = 1n914  (not critical - back EMF protect)
''Coil I/O ─ ─ ─ ┤            GND             R1 = sensitivity adjustment
''
''Coil I/O ─ ─ ─ ┘ (optional Coils)


''Test Case:  ( detection starts at about 1 inch )
''
''Coil - 75 Turns around a 1/2" diameter form.  approximate inductance = 119µH
''
''
''Typical Coil return values range from 0% to 97%


CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000
    _stack      = ($3000 + $3000 + 100) >> 2   'accomodate display memory and stack

' -- User-modifiable constants
    PING_PIN    = 1
    READ_PIN    = 0

    COIL_PIN    = 2
' NOTE: Multiple coils are possible, but you must only read one at a time
' --

    X_TILES     = 16
    Y_TILES     = 12

    PARAMCOUNT  = 14
    PTR_BITMAP  = $2000
    PTR_DISPLAY = $5000

    LINES       = 5

VAR

    long _tv_status     '0/1/2 = off/visible/invisible            read-only
    long _tv_enable     '0/? = off/on                            write-only
    long _tv_pins       '%ppmmm = pins                           write-only
    long _tv_mode       '%ccinp = chroma,interlace,ntsc/pal,swap write-only
    long _tv_screen     'pointer to _screen (words)               write-only
    long _tv_colors     'pointer to _colors (longs)               write-only
    long _tv_hc         'horizontal cells                        write-only
    long _tv_vc         'vertical cells                          write-only
    long _tv_hx         'horizontal cell expansion               write-only
    long _tv_vx         'vertical cell expansion                 write-only
    long _tv_ho         'horizontal offset                       write-only
    long _tv_vo         'vertical offset                         write-only
    long _tv_broadcast  'broadcast frequency (Hz)                write-only
    long _tv_auralcog   'aural fm cog                            write-only

    long _colors[64]

    word _screen[X_TILES * Y_TILES]

    byte _x[LINES]
    byte _y[LINES]
    byte _xs[LINES]
    byte _ys[LINES]

    byte _int_string[20]

OBJ

    tv   : "display.tv"
    gr   : "display.tv.graphics"
    coil : "misc.coilread"

PUB Start{} | i, dx, dy, coilvalue

    ' start tv
    longmove(@_tv_status, @_tvparams, PARAMCOUNT)
    _tv_screen := @_screen
    _tv_colors := @_colors
    tv.start(@_tv_status)

    ' init colors
    repeat i from 0 to 64
        _colors[i] := $00001010 * (i+4) & $F + $2B060C02

    ' init tile screen
    repeat dx from 0 to _tv_hc - 1
        repeat dy from 0 to _tv_vc - 1
            _screen[dy * _tv_hc + dx] := PTR_DISPLAY >> 6 + dy + dx * _tv_vc + ((dy & $3F) << 10)

    ' start and setup graphics
    gr.start{}
    gr.setup(16, 12, 128, 96, PTR_BITMAP)


    ' start coilread
    coil.start(PING_PIN, COIL_PIN, READ_PIN, @coilvalue)

    repeat
        ' clear bitmap
        gr.clear

        ' draw text
        gr.textmode(1, 1, 7, 5)
        gr.colorwidth(1, 0)
        gr.color(6)
        gr.text(0, 90, string("Parallax Propeller COILREAD demo"))

        ' convert integer value into a string; place result in '_int_string'
        intstring(coilvalue)
        ' display text of coilvalue
        gr.text(0, 60, @_int_string)

        ' display analog meter
        gr.color(1)
        gr.width(0)
        gr.arc(0, 0, 50, 50, 0, 409, 11, 3)
        gr.arc(0, 0, 45, 45, 204, 409, 10, 3)
        gr.color(0)
        gr.width(2)
        gr.arc(0, 0, 42, 42, 0, 204, 21, 3)
        gr.color(1)
        gr.width(0)
        gr.arc(0, 0, 40, 40, 4096-((coilvalue * 4096) / 100), 1, 1, 3)

        ' display bargraph
        gr.color(2)
        gr.plot(-99, -91)
        gr.line(101, -91)
        gr.line(101, -85)
        gr.line(-99, -85)
        gr.line(-99, -91)
        gr.color(3)
        gr.box(-98, -90, coilvalue * 2, 5)

        ' copy bitmap to display
        gr.copy(PTR_DISPLAY)

PUB IntString(integer) | int_tmp, p
' Convert integer to string
    p := 0                                      ' clear string pointer
    int_tmp := (integer / 10)                   ' find number of digits
    repeat while int_tmp <> 0
        p := p + 1
        int_tmp := (int_tmp / 10)
    _int_string[p + 1] := 0                     ' set end of string
    int_tmp := (integer / 10)                   ' put digits into string
    repeat while int_tmp <> 0
        _int_string[p] := (integer - (int_tmp * 10)) + "0"
        p := p - 1
        integer := int_tmp
        int_tmp := (integer / 10)
    _int_string[p] := integer + "0"

DAT

_tvparams               long    0               'status
                        long    1               'enable

                        long    %001_0101       'pins

                        long    %0000           'mode
                        long    0               'screen
                        long    0               'colors
                        long    X_TILES         'hc
                        long    Y_TILES         'vc
                        long    10              'hx
                        long    1               'vx
                        long    0               'ho
                        long    0               'vo
                        long    60_000_000      'broadcast
                        long    0               'auralcog

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
