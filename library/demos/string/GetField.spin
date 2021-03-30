{
    --------------------------------------------
    Filename: GetField.spin
    Author: Jesse Burt
    Description: Demo of the GetField() and GetFieldCount()
        functions
    Copyright (c) 2021
    Started Mar 30, 2021
    Updated Mar 30, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    str     : "string"

DAT

    ' some example strings with different lengths and/or delimiter characters
    ' first field number is 0, last field is (number of fields-1)
    ' strings must be zero-terminated for correct behavior
    csv     byte "1,7,210,6444,27,856,100_000,123_456_789", 0
    fruits  byte "apples,bananas,coconuts,dates,grapefruits,limes,mangoes,nectarines,oranges,pineapples", 0
    macaddr byte "00:70:72:6f:70:31", 0

PUB Main{} | field_nr, delimiter, nr_fields, ptr_fieldstr, ipv4addr

    setup{}

    ser.newline{}

    field_nr := 0                               ' choose a field number to read

    delimiter := ","                            ' character the data are separated by

    ' using the strings declared in the DAT block above,
    ' find the total number of fields, then extract the chosen field data
    nr_fields := str.getfieldcount(@csv, delimiter)
    ptr_fieldstr := str.getfield(@csv, field_nr, delimiter)
    ser.printf2(string("csv total number of fields: %d (0-%d)\n"), nr_fields, nr_fields-1)
    ser.printf2(string("csv field number %d is %s\n\n"), field_nr, ptr_fieldstr)

    field_nr := 0

    delimiter := ","
    nr_fields := str.getfieldcount(@fruits, delimiter)
    ptr_fieldstr := str.getfield(@fruits, field_nr, delimiter)
    ser.printf2(string("fruits total number of fields: %d (0-%d)\n"), nr_fields, nr_fields-1)
    ser.printf2(string("fruits field number %d is %s\n\n"), field_nr, ptr_fieldstr)

    field_nr := 0

    delimiter := ":"
    nr_fields := str.getfieldcount(@macaddr, delimiter)
    ptr_fieldstr := str.getfield(@macaddr, field_nr, delimiter)
    ser.printf2(string("macaddr total number of fields: %d (0-%d)\n"), nr_fields, nr_fields-1)
    ser.printf2(string("macaddr field number %d is %s\n\n"), field_nr, ptr_fieldstr)

    ' a different example that uses an in-line string constant
    '   as the data source instead of the DAT block
    field_nr := 0

    delimiter := "."
    ipv4addr := string("192.168.101.123")
    nr_fields := str.getfieldcount(ipv4addr, delimiter)
    ptr_fieldstr := str.getfield(ipv4addr, field_nr, delimiter)
    ser.printf2(string("ipv4addr total number of fields: %d (0-%d)\n"), nr_fields, nr_fields-1)
    ser.printf2(string("ipv4addr field number %d is %s\n"), field_nr, ptr_fieldstr)

    repeat

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

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
