{
    --------------------------------------------
    Filename: gui.button.spin
    Author: Jesse Burt
    Description: Generic object for manipulating GUI button structures
    Copyright (c) 2023
    Started Jul 18, 2022
    Updated Feb 4, 2023
    See end of file for terms of use.
    --------------------------------------------
}

con

    { button states }
    UP          = 0
    DOWN        = 1
    PUSHED      = 1

    { button attributes structure (longs) }
    { button id (should match tag ID for EVE)
      state (UP, DOWN/PUSHED)
      x coord
      y coord
      width
      height
      text size/font
      pointer to button text
      text color
    }
    #0, ID, ST, SX, SY, WD, HT, TSZ, OPT, PSTR, TCOLOR
    STRUCTSZ    = (TCOLOR+1)

var

    long _ptr_btns, _nr_btns
    byte _spacing_x, _spacing_y

pub init(ptr_btnbuff, nr_btns)
' Initialize
'   ptr_btnbuff: point to button(s) buffer
    _ptr_btns := ptr_btnbuff
    _nr_btns := nr_btns

pub deinit{}
' Deinitialize
    _ptr_btns := 0
    _nr_btns := 0

pub above(btn_nr): y
' Get coordinate immediately to the right of a button (including inter-button spacing)
'   btn_nr: button to read coordinate of
    return get_sy(btn_nr) - _spacing_y

pub below(btn_nr): y
' Get coordinate immediately to the right of a button (including inter-button spacing)
'   btn_nr: button to read coordinate of
    return get_ey(btn_nr) + _spacing_y

pub destroy(btn_idx)
' Destroy a button definition
    longfill(ptr(btn_idx), 0, STRUCTSZ)
    
pub get_attr(btn_idx, param): val
' Get button attribute
'   btn_idx: button number
'   param: attribute to modify
'   Returns: value for attribute
    if (btn_idx => 1 and btn_idx =< _nr_btns) ' button idx 1-based so it maps 1:1 with tag #
        return long[ptr(btn_idx)][param]

pub get_ex(btn_idx): c
' Get the ending X coordinate of the button, based on its starting coord and width
    return (get_attr(btn_idx, SX) + get_attr(btn_idx, WD))

pub get_ey(btn_idx): c
' Get the ending Y coordinate of the button, based on its starting coord and height
    return (get_attr(btn_idx, SY) + get_attr(btn_idx, HT))

pub get_sx(btn_idx): c
' Get the ending X coordinate of the button, based on its starting coord and width
    return (get_attr(btn_idx, SX))

pub get_sy(btn_idx): c
' Get the ending X coordinate of the button, based on its starting coord and width
    return (get_attr(btn_idx, SY))

pub left_of(btn_nr): x
' Get coordinate immediately to the left of a button (including inter-button spacing)
'   btn_nr: button to read coordinate of
    return get_sx(btn_nr) - _spacing_x

pub min_height(btn_nr): w
' Get the minimum height of a button, considering its font size
    return (get_attr(btn_nr, TSZ))

pub min_width(btn_nr): w
' Get the minimum width of a button, considering its font size and length of text
    return (text_len(btn_nr) * (get_attr(btn_nr, TSZ)/2))

pub ptr(btn_nr): p
' Get pointer to start of btn_nr's structure in button buffer
    return _ptr_btns + ( ((btn_nr-1) * STRUCTSZ) * 4)

pub ptr_e(btn_nr): p
' Get pointer to start of btn_nr's structure in button buffer
'   Directly compatible with EVE ButtonPtr()
    return _ptr_btns + ( ((btn_nr-1) * STRUCTSZ) * 4) + 8

pub right_of(btn_nr): x
' Get coordinate immediately to the right of a button (including inter-button spacing)
'   btn_nr: button to read coordinate of
    return get_ex(btn_nr) + _spacing_x

pub set_attr_all(param, val) | b
' Set attribute of ALL buttons
'   param: attribute to modify
'   val: new value for attribute
    repeat b from 1 to _nr_btns
        set_attr(b, param, val)

pub set_attr(btn_idx, param, val)
' Set button attribute
'   btn_idx: button number
'   param: attribute to modify
'   val: new value for attribute
    if (btn_idx => 1 and btn_idx =< _nr_btns) ' button idx 1-based so it maps 1:1 with tag #
        long[ptr(btn_idx)][param] := val

pub set_pos(btn_idx, x, y)
' Set button position
'   btn_idx: button number
'   x, y: coordinates of upper-left button corner
    set_attr(btn_idx, SX, x)
    set_attr(btn_idx, SY, y)

pub set_spacing(x, y)
' Set inter-button spacing
    _spacing_x := 0 #> x
    _spacing_y := 0 #> y

pub set_sx(btn_idx, x)
' Set starting X coordinate of button
    set_attr(btn_idx, SX, x)

pub set_sy(btn_idx, y)
' Set starting Y coordinate of button
    set_attr(btn_idx, SY, y)

pub set_id_all(st_nr) | b
' Set ID attribute of all buttons in ascending order
'   st_nr: starting ID number to use
    repeat b from 0 to _nr_btns-1
        set_attr((st_nr+b), ID, (st_nr+b))

pub text_len(btn_idx): len
' Get the length of the text string pointed to by the button definition
'   btn_idx: button number
    return strsize(get_attr(btn_idx, PSTR))

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

