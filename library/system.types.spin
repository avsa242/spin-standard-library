{
    --------------------------------------------
    Filename: system.types.spin
    Description: Utility methods for converting
        between signed and unsigned numbers
    Author: Jesse Burt
    Copyright (c) 2022
    Started: Aug 19, 2018
    Updated: Oct 29, 2022
    See end of file for terms of use.
    --------------------------------------------
}

PUB null{}
' This is not a top-level object

PUB s16(msb, lsb): signed16
' Pack two bytes, MSB and LSB into a signed word
    signed16 := (msb << 8) | lsb
    return ~~signed16

PUB u16(msb, lsb): uns16
' Pack two bytes, MSB and LSB into an unsigned word
    return ((msb << 8) | lsb)

PUB u16_s16(unsigned16): signed16
' Convert unsigned word to signed word
    return ~~unsigned16

PUB s8(byte_val): signed8
' Convert unsigned byte to signed byte
    return ~byte_val

DAT
{
Copyright 2022 Jesse Burt

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
}

