{
---------------------------------------------------------------------------------------------------
    Filename:       Hexdump-Demo.spin
    Description:    Demo of the hexdump() method
    Author:         Jesse Burt
    Started:        May 15, 2021
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


PUB main() | ptr_buff, base_addr, adr_digits, nr_bytes, columns, hd_s, hd_e

    setup()

    nr_bytes := 128                             ' number of bytes to show per 'page'
    hd_s := $0000                               ' hexdump start
    hd_e := $ffff-nr_bytes                      '   and end addresses
    columns := 16                               ' number of columns to display per line
    adr_digits := 5                             ' number of digits used to display addresses

    repeat ptr_buff from hd_s to hd_e step nr_bytes
        base_addr := ptr_buff                   ' can be anything; used for display purposes only
        ser.pos_xy(0, 3)
        ser.hexdump(ptr_buff, base_addr, adr_digits, nr_bytes, columns)

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

