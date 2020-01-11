{
    --------------------------------------------
    Filename: system.types.spin
    Author: Jesse Burt
    Description: Utility methods for converting
        between signed and unsigned numbers
    Copyright (c) 2020
    Started: Aug 19, 2018
    Updated: Jan 11, 2020
    See end of file for terms of use.
    --------------------------------------------
}

PUB Null
'This is not a top-level object

PUB s16(msb, lsb): signed16
' Pack two bytes, MSB and LSB into a signed word
    signed16 := (msb << 8) | lsb
    if signed16 > 32767
        signed16 := signed16 - 65536
    return signed16 & $FFFF

PUB s16e(msb, lsb): signed16
' Pack two bytes, MSB and LSB into a signed word, with sign extended
    signed16 := (msb << 8) | lsb
    if signed16 > 32767
        signed16 := signed16 - 65536
    return ~~signed16

PUB u16(msb, lsb)
' Pack two bytes, MSB and LSB into an unsigned word
    return ((msb << 8) | lsb)

PUB s16_u16(signed16): unsigned16
' Convert signed word to unsigned word      'XXX Needs further research to define behavior according to 'best practices'
'   Returns:
'   signed16 is:        Result:
'   -32768..-1:         Unsigned word
'   less than -32768:   0
'   0 or greater:       Unchanged
    unsigned16 := signed16
    if unsigned16 => -32768 and unsigned16 < 0
        unsigned16 += 65536
    return 0 #> unsigned16 <# 65535

PUB u16_s16(unsigned16): signed16
' Convert unsigned word to signed word
    if unsigned16 > 32767
        signed16 := unsigned16 - 65536
    else
        signed16 := unsigned16
    return signed16 & $FFFF

PUB u16_s16e(unsigned16): signed16
' Convert unsigned word to signed word, with sign extended
    if unsigned16 > 32767
        signed16 := unsigned16 - 65536
    else
        signed16 := unsigned16
    return ~~signed16

PUB s8(byte_val)
' Convert unsigned byte to signed byte
    if byte_val > 127
        byte_val := byte_val - 128
    return byte_val

PUB s8e(byte_val)
' Convert unsigned byte to signed byte
    if byte_val > 127
        byte_val := byte_val - 128
    return ~byte_val

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
