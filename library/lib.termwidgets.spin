' Library of terminal widgets
'   Must be included using the preprocessor #include directive
'   Requires:
'       A compatible serial terminal with object symbol name 'ser'

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
            ser.Position (x, row)
            ser.Hex (base_addr+offset, digits)
            ser.Str (string(": "))

        hexcol := x + (offset & (columns-1)) * 3 + (digits + 2) + 1
        asccol := x + (offset & (columns-1)) + (columns * 3) + (digits + 3)

        ser.Position (hexcol, row)
        ser.Hex (currbyte, 2)

        ser.Position (asccol, row)
        case currbyte
            32..127:
                ser.Char (currbyte)
            OTHER:
                ser.Char (".")
        col++

