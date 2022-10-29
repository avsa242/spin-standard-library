{
    --------------------------------------------
    Filename: input.keypad.4x4.spin
    Author: Jesse Burt
    Description: 4x4 keypad reader
        Parallax #27899
    Started 2007
    Updated Oct 29, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on 4x4 Keypad Reader.spin,
    originally by Beau Schwabe

    Rear view of 4x4 keypad:

       P7         P0 (connect directly to I/O pins; no external components needed)
         ││││││││
┌─────── ││││││││ ───────┐
│     oo ││││││││ o      │
│                        │
│  O    O    O    O    O │
│                        │
│  O    O    O    O    O │
│         (LABEL)        │
│  O    O    O    O    O │
│                        │
│  O    O    O    O    O │
│                        │
│  O    O    O    O    O │
│             o    o     │
└────────────────────────┘
}
VAR

    word _keypad

PUB readkeypad = rd_keypad
PUB rd_keypad{}
' Read keypad data
    _keypad := 0                                ' initialize

    read_row(3)                                 ' read row 0
    _keypad <<= 4
    read_row(2)                                 ' row 1
    _keypad <<= 4
    read_row(1)                                 ' row 2
    _keypad <<= 4
    read_row(0)                                 ' row 3
    return _keypad

PUB ptr_keypad{}: p
' Get pointer to keypad data
    return @_keypad

PRI read_row(n)
' Principle of operation:

' This object uses a capacitive pin approach to reading the keypad. To do so, ALL pins are
'   driven low to "discharge" the I/O pins. Then, ALL pins are allowed to float (input)
'   At this point, only one pin is made driven high at a time. If the switch is closed,
'   then a HIGH will be read on the input, otherwise a LOW will be returned.

' Multiple button presses are allowed with the understanding that “BOX" entries can be confused.
'   Examples of box entries: 1,2,4,5 or 1,4,3,6 or 4,6,*,# etc., where any 3 of the 4 buttons
'   pressed will evaluate the non pressed button as being pressed, even when they are not.
'   NOTE: There is no danger of any physical or electrical damage

    { discharge all pins ("capacitors"): output low }
    outa[0..7]~
    dira[0..7]~~

    { charge all pins: set all as inputs }
    dira[0..7]~

    { charge specific pin if switch is closed }
    outa[n] := 1
    dira[n] := 1

    { read row: if a switch is open, the pin will remain discharged }
    _keypad += ina[4..7]
    dira[n] := 0

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

