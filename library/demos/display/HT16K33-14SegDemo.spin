{
    --------------------------------------------
    Filename: HT16K33-14SegDemo.spin
    Description: Demo of the HT16K33 14-segment driver
    Author: Jesse Burt
    Copyright (c) 2022
    Created: Jun 22, 2021
    Updated: Oct 30, 2022
    See end of file for terms of use.
    --------------------------------------------
}


CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants:
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
    ADDR_BITS   = %000                          ' %000..%111

    ' number of digits/characters width and height the display has
    ' NOTE: The demo is written to work best with a 4x1 display
    WIDTH       = 4
    HEIGHT      = 1
' --


OBJ

    cfg : "boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    disp: "display.led-seg.ht16k33"
    fs  : "string.float"
    
PUB main{} | i, b

    setup{}

    disp.blink_rate(2)
    demo_msg(string("DEMO"))
    time.sleep(2)
    disp.blink_rate(0)
    time.sleep(1)

    demo_msg(string("CHAR"))                    ' display printable ASCII chars

    repeat i from 32 to 126
        disp.pos_xy(0, 0)
        disp.putchar(i)
        time.msleep(100)
    time.sleep(2)


    demo_msg(string("STR"))                     ' display strings

    disp.puts(string("This"))
    time.sleep(1)
    disp.clear{}
    disp.puts(string("is"))
    time.sleep(1)
    disp.clear{}
    disp.puts(string("the"))
    time.sleep(1)
    disp.clear{}
    disp.puts(string("STR"))
    time.sleep(1)
    disp.clear{}
    disp.puts(string("demo"))
    time.sleep(2)


    demo_msg(string("HEX"))                     ' display hexadecimal numbers

    repeat i from 0 to $1ff
        disp.pos_xy(0, 0)
        disp.puthex(i, 4)
    time.sleep(2)

    demo_msg(string("BIN"))                     ' display binary numbers

    repeat i from 0 to %1111
        disp.pos_xy(0, 0)
        disp.printf1(string("%04.4b"), i)
        time.msleep(200)
    time.sleep(2)

    demo_msg(string("DEC"))                     ' display decimal numbers

    repeat i from 0 to 1000
        disp.pos_xy(0, 0)
        disp.printf1(string("%4.4d"), i)
    time.sleep(2)

    demo_msg(string("FLT"))

    disp.puts(fs.float_str(3.141))
    time.sleep(1)
    disp.puts(fs.float_str(31.41))
    time.sleep(1)
    disp.puts(fs.float_str(314.1))
    time.sleep(1)
    disp.puts(fs.float_str(3141.0))
    time.sleep(2)

    demo_msg(string("TYPE"))                    ' echo characters typed into the serial terminal

    repeat
        b := ser.charin{}
        disp.char(b)

PRI demo_msg(ptr_str)
' Clear the display, show a message, wait 2 seconds, then clear again
    disp.clear{}
    disp.puts(ptr_str)
    time.sleep(2)
    disp.clear

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if disp.startx(I2C_SCL, I2C_SDA, I2C_FREQ, ADDR_BITS, WIDTH, HEIGHT)
        ser.strln(string("HT16K33 driver started"))
        disp.defaults{}
    else
        ser.str(string("HT16K33 driver failed to start - halting"))
        repeat

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

