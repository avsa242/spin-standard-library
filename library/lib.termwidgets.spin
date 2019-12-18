{
    --------------------------------------------
    Filename: lib.termwidgets.spin
    Author: Jesse Burt
    Description: Library of terminal widgets
    Copyright (c) 2019
    Started Dec 14, 2019
    Updated Dec 18, 2019
    See end of file for terms of use.
    --------------------------------------------
}

'   Must be included using the preprocessor #include directive
'   Requires:
'       An object with string.integer declared as a child object, defined with symbol name int
'       An object that has the following standard terminal methods:
'           Dec (param)
'           Char (param)
'           Str (param)
'           Hex (param)
'           Position (x, y)

PUB Frac(scaled, divisor) | whole[4], part[4], places, tmp
' Display a scaled up number in its natural form - scale it back down by divisor
    whole := scaled / divisor
    tmp := divisor
    places := 0

    repeat
        tmp /= 10
        places++
    until tmp == 1
    part := int.DecZeroed(||(scaled // divisor), places)

    Dec (whole)
    Char (".")
    Str (part)

PUB HexDump(buff_addr, base_addr, nr_bytes, columns, x, y) | digits, offset, col, hexcol, asccol, row, currbyte
' Display a hexdump of a region of memory
'   buff_addr: Start address of memory
'   base_addr: Address used to display as base address in hex dump (affects display only)
'   nr_bytes: Total number of bytes to display
'   columns: Number of bytes to display on each line
'   x, y: Terminal position to display start of hex dump
    digits := 5
    hexcol := asccol := col := 0
    row := y
    repeat offset from 0 to nr_bytes-1
        currbyte := byte[buff_addr][offset]
        if col > (columns - 1)
            row++
            col := 0

        if col == 0
            Position (x, row)
            Hex (base_addr+offset, digits)
            Str (string(": "))

        hexcol := x + (offset & (columns-1)) * 3 + (digits + 2) + 1
        asccol := x + (offset & (columns-1)) + (columns * 3) + (digits + 3)

        Position (hexcol, row)
        Hex (currbyte, 2)

        Position (asccol, row)
        case currbyte
            32..127:
                Char (currbyte)
            OTHER:
                Char (".")
        col++

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
