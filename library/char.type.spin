{
    --------------------------------------------
    Filename: char.type.new
    Author: Jesse Burt
    Description: Character processing and formatting routines
    Copyright (c) 2022
    Started Dec 14, 2019
    Updated May 29, 2022
    See end of file for terms of use.
    --------------------------------------------
}

#ifndef TERMCODES_H
#include "termcodes.spinh"
#endif

PUB IsAlpha(ch): flag
' Test if character is alphabetic
'   Returns: TRUE if alphabetic, FALSE otherwise
    return (lookdown(ch: "A".."Z", "a".."z") <> 0)

PUB IsAlphanumeric(ch): flag
' Test if character is alphanumeric
'   Returns: TRUE if alphanumeric, FALSE otherwise
    return (lookdown(ch: "0".."9", "A".."Z", "a".."z") <> 0)

PUB IsDigit(ch): flag
' Test if character is a digit
'   Returns: TRUE if ch is a digit, FALSE otherwise
    return (lookdown(ch: "0".."9") <> 0)

PUB IsLower(ch): flag
' Test if character is lowercase
'   Returns: TRUE if lowercase, FALSE otherwise
    return (lookdown(ch: "a".."z") <> 0)

PUB IsSpace(ch): flag
' Test if character is a space (0x20), tab (\t) or newline (\n)
'   ch: Character to be tested
'   Returns: TRUE if ch is a space, tab or line-feed
    return (lookdown(ch: " ", TB, LF) <> 0)

PUB IsUpper(ch): flag
' Test if character is uppercase
    return (lookdown(ch: "A".."Z") <> 0)

PUB IsXDigit(ch): flag
' Test if character is a hexadecimal digit
'   ch: Character to be tested
'   Returns: TRUE if ch is a hex digit
    return (lookdown(ch: "0".."9", "A".."F", "a".."f") <> 0)

PUB ToLower(ch): lc
' Convert character to lowercase
    if isupper(ch)
        return (ch + 32)
    else
        return ch

PUB ToUpper(ch): uc
' Convert character to uppercase
    if islower(ch)
        return (ch - 32)
    else
        return ch

