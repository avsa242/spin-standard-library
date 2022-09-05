{
    --------------------------------------------
    Filename: HT16K33-14SegDemo.spin
    Description: Demo of the HT16K33 14-segment driver
    Author: Jesse Burt
    Copyright (c) 2022
    Created: Jun 22, 2021
    Updated: Sep 3, 2022
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
    I2C_HZ      = 400_000                       ' max is 400_000
    ADDR_BITS   = %000                          ' %000..%111

    ' number of digits/characters width and height the display has
    ' NOTE: The demo is written to work best with a 4x1 display
    WIDTH       = 4
    HEIGHT      = 1
' --


OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    disp: "display.led-seg.ht16k33"
    fs  : "string.float"
    
PUB Main{} | i, b

    setup{}

    disp.blinkrate(2)
    demomsg(string("DEMO"))
    time.sleep(2)
    disp.blinkrate(0)
    time.sleep(1)

    demomsg(string("CHAR"))

    repeat i from 32 to 126
        disp.position(0, 0)
        disp.char(i)
        time.msleep(100)
    time.sleep(2)


    demomsg(string("STR"))

    disp.str(string("This"))
    time.sleep(1)
    disp.clear{}
    disp.str(string("is"))
    time.sleep(1)
    disp.clear{}
    disp.str(string("the"))
    time.sleep(1)
    disp.clear{}
    disp.str(string("STR"))
    time.sleep(1)
    disp.clear{}
    disp.str(string("demo"))
    time.sleep(2)


    demomsg(string("HEX"))

    repeat i from 0 to $1ff
        disp.position(0, 0)
        disp.hex(i, 4)
    time.sleep(2)

    demomsg(string("BIN"))

    repeat i from 0 to %1111
        disp.position(0, 0)
        disp.printf1(string("%04.4b"), i)
        time.msleep(200)
    time.sleep(2)

    demomsg(string("DEC"))

    repeat i from 0 to 1000
        disp.position(0, 0)
        disp.printf1(string("%4.4d"), i)
    time.sleep(2)


    demomsg(string("FLT"))

    disp.str(fs.floattostring(3.141))
    time.sleep(1)
    disp.str(fs.floattostring(31.41))
    time.sleep(1)
    disp.str(fs.floattostring(314.1))
    time.sleep(1)
    disp.str(fs.floattostring(3141.0))
    time.sleep(2)


    demomsg(string("TYPE"))

    repeat
        b := ser.charin
        disp.char(b)

PRI DemoMsg(ptr_str)
' Clear the display, show a message, wait 2 seconds, then clear again
    disp.clear{}
    disp.str(ptr_str)
    time.sleep(2)
    disp.clear

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if disp.startx(I2C_SCL, I2C_SDA, I2C_HZ, ADDR_BITS, WIDTH, HEIGHT)
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

