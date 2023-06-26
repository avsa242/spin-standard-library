{
    --------------------------------------------
    Filename: I2C-Scan.spin
    Author: Jesse Burt
    Description: Utility to scan for active devices on an I2C bus
    Copyright (c) 2023
    Started Jun 17, 2019
    Updated Jun 26, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg.LED1
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 100_000
' --

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    i2c     : "com.i2c"
    time    : "time"

VAR

    byte _fmt, _sr_supported

PUB main{} | slave_addr, flag, x, y, offsetx, offsety, ch

    setup{}
    ser.clear{}
    ser.strln(@"I2C Scanner")
    ser.newline{}

    offsetx := 3
    offsety := 6

    ser.printf1(@"Display format:        %d-bit (press 7 or 8 to choose)\n\r", _fmt)
    ser.printf1(@"I2C Rs while scanning: %c     (press r to toggle)", lookupz(_sr_supported: "N", "Y"))

    ser.reset{}
    ser.hide_cursor{}

    { probe all _legal_ addresses (write devices only) for a device;
        'reserved' addresses (0..6, 120..127) are not touched since it's possible doing so
        could cause issues for some devices }
    repeat
        ser.pos_xy(23, 2)
        ser.dec(_fmt)
        ser.pos_xy(23, 3)
        ser.char(lookupz(_sr_supported: "N", "Y"))
        repeat slave_addr from $08 to $77
            flag := i2c.present(slave_addr << 1)' probe this address for a device
            ifnot ( _sr_supported )             ' add a stop condition for devices that need it
                i2c.stop{}
            x := ((slave_addr & $f) * 3) + offsetx
            y := (slave_addr >> 4) + offsety
            show_addr(x, y, slave_addr, flag)
        if ( (ch := ser.rx_check{}) > 0 )
            { check for a keypress  in the terminal }
            case ch
                "7":
                    { 7-bit address display (the "un-shifted" format) }
                    _fmt := 7
                "8":
                    { 8-bit address display ("shifted" format; leaves the LSB clear }
                    _fmt := 8
                "r":
                    { toggle between two probe types:
                        1) S, W (address)
                        2) S, W (address), P
                        Some devices might not respond without the stop condition (P) after the probe
                        (or vice-versa) }
                    _sr_supported ^= 1
                "q":
                    { quit the scan and restore the cursor and terminal settings }
                    ser.show_cursor{}
                    ser.reset{}
                    ser.newline{}
                    ser.strln(@"halted")
                    repeat


PUB show_addr(x, y, slave_addr, flag)
' Show I2C device address
    if (_fmt == 7)                              ' 7-bit display format
        if (flag)
            ser.pos_xy(x, y)
            ser.color(ser#BLACK, ser#GREEN)
            ser.puthexs(slave_addr, 2)
            ser.reset{}
        else
            ser.pos_xy(x, y)
            ser.puthexs(slave_addr, 2)
    else                                        ' 8-bit display format
        if (flag)
            ser.pos_xy(x, y)
            ser.color(ser#BLACK, ser#GREEN)
            ser.puthexs(slave_addr << 1, 2)
            ser.reset{}
        else
            ser.pos_xy(x, y)
            ser.puthexs(slave_addr << 1, 2)

PUB setup{}|r

    ser.start(SER_BAUD)
    time.msleep(20)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    i2c.init(I2C_SCL, I2C_SDA, I2C_HZ)
    ser.strln(string("I2C driver started"))
    _fmt := 7

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
