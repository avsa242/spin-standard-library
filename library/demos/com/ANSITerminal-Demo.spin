{
    --------------------------------------------
    Filename: ANSITerminal-Demo.spin
    Description: Demo of the ANSI serial terminal driver
    Author: Jesse Burt
    Copyright (c) 2022
    Created: Jun 18, 2019
    Updated: Oct 29, 2022
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

    ser         : "com.serial.terminal.ansi"
    cfg         : "boardcfg.demoboard"
    time        : "time"

PUB main{} | fg, bg

    setup{}

    ser.strln(string("ANSI serial terminal demo"))
    ser.strln(string("NOTE: Not all attributes supported by all terminals."))

    ser.bold{}
    demo_text(string("BOLD"))

    ser.faint{}
    demo_text(string("FAINT"))

    ser.italic{}
    demo_text(string("ITALIC (or INVERSE)"))

    ser.underline{}
    demo_text(string("UNDERLINED"))
 
    ser.underline_dbl{}
    demo_text(string("DOUBLE UNDERLINED"))

    ser.blink{}
    demo_text(string("SLOW BLINKING"))

    ser.blink_fast{}
    demo_text(string("FAST BLINKING"))

    ser.inverse{}
    demo_text(string("INVERSE"))

    ser.conceal{}
    demo_text(string("CONCEALED"))

    ser.strikethru{}
    demo_text(string("STRIKETHROUGH"))

    ser.framed{}
    demo_text(string("FRAMED"))

    ser.encircle{}
    demo_text(string("ENCIRCLED"))

    ser.overline{}
    demo_text(string("OVERLINED"))

    repeat bg from 0 to 7
        repeat fg from 0 to 7
            ser.color(fg, bg)
            ser.str(string(" COLORED "))
        ser.newline
    ser.color(ser#GREY, ser#BLACK)

    repeat 5
        ser.move_up{}
        time.sleep(1)
    repeat 5
        ser.move_down{}
        time.sleep(1)

    ser.strln(@"Hide Cursor")
    ser.hide_cursor{}
    time.msleep(3000)

    ser.strln(@"Show cursor")
    ser.show_cursor{}
    time.msleep(3000)

    repeat 5
        ser.scroll_up{}
        time.msleep(500)

    repeat 5
        ser.scroll_down{}
        time.msleep(500)

    ser.newline{}
    repeat

PUB demo_text(inp_text)

    ser.printf1(string("This is %s text\n\r"), inp_text)
    ser.reset()

PUB setup

    ser.start(SER_BAUD)
    time.msleep(100)
    ser.reset{}
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
