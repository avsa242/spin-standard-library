{
    --------------------------------------------
    Filename: Hexdump-Demo.spin
    Author: Jesse Burt
    Description: Demo of the hexdump() method
    Copyright (c) 2022
    Started May 15, 2021
    Updated Oct 26, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

' --

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"

VAR

PUB main{} | ptr_buff, base_addr, adr_digits, nr_bytes, columns, start, end

    setup{}

    nr_bytes := 128                             ' # bytes to show per 'page'
    start := $0000
    end := $ffff-nr_bytes                       ' last address to dump
    columns := 16                               ' # columns output per line
    base_addr := 0                              ' offset used in address disp.
                                                '   (useful for EE/Flash, etc)
    adr_digits := 4                             ' # digits used in addr. disp.

    repeat ptr_buff from start to end step nr_bytes
        base_addr := ptr_buff
        ser.pos_xy(0, 3)
        ser.hexdump(ptr_buff, base_addr, adr_digits, nr_bytes, columns)

    repeat

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

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
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

