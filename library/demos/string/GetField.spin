{
---------------------------------------------------------------------------------------------------
    Filename:       GetField.spin
    Description:    Demo of the string object getfield() and getfieldcount() functions
    Author:         Jesse Burt
    Started:        Mar 30, 2021
    Updated:        Jan 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"
    str:    "string"


DAT

    ' some example strings with different lengths and/or delimiter characters
    ' first field number is 0, last field is (number of fields-1)
    ' strings must be zero-terminated for correct behavior
    csv     byte "1,7,210,6444,27,856,100_000,123_456_789", 0
    fruits  byte "apples,bananas,coconuts,dates,grapefruits,limes,mangoes,nectarines,oranges,pineapples", 0
    macaddr byte "00:70:72:6f:70:31", 0


PUB main() | field_nr, delimiter, nr_fields, ptr_fieldstr, ipv4addr

    setup()

    ser.newline()

    field_nr := 0                               ' choose a field number to read

    delimiter := ","                            ' character the data are separated by

    ' using the strings declared in the DAT block above,
    ' find the total number of fields, then extract the chosen field data
    nr_fields := str.getfieldcount(@csv, delimiter)
    ptr_fieldstr := str.getfield(@csv, field_nr, delimiter)
    ser.printf2(@"csv total number of fields: %d (0-%d)\n\r", nr_fields, nr_fields-1)
    ser.printf2(@"csv field number %d is %s\n\r\n\r", field_nr, ptr_fieldstr)

    field_nr := 0

    delimiter := ","
    nr_fields := str.getfieldcount(@fruits, delimiter)
    ptr_fieldstr := str.getfield(@fruits, field_nr, delimiter)
    ser.printf2(@"fruits total number of fields: %d (0-%d)\n\r", nr_fields, nr_fields-1)
    ser.printf2(@"fruits field number %d is %s\n\r\n\r", field_nr, ptr_fieldstr)

    field_nr := 0

    delimiter := ":"
    nr_fields := str.getfieldcount(@macaddr, delimiter)
    ptr_fieldstr := str.getfield(@macaddr, field_nr, delimiter)
    ser.printf2(@"macaddr total number of fields: %d (0-%d)\n\r", nr_fields, nr_fields-1)
    ser.printf2(@"macaddr field number %d is %s\n\r\n\r", field_nr, ptr_fieldstr)

    ' a different example that uses an in-line string constant
    '   as the data source instead of the DAT block
    field_nr := 0

    delimiter := "."
    ipv4addr := @"192.168.101.123"
    nr_fields := str.getfieldcount(ipv4addr, delimiter)
    ptr_fieldstr := str.getfield(ipv4addr, field_nr, delimiter)
    ser.printf2(@"ipv4addr total number of fields: %d (0-%d)\n\r", nr_fields, nr_fields-1)
    ser.printf2(@"ipv4addr field number %d is %s\n\r", field_nr, ptr_fieldstr)

    repeat


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

DAT
{
Copyright 2024 Jesse Burt

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
