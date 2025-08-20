{
---------------------------------------------------------------------------------------------------
    Filename:       ANSI-VSc<-lDemo.spin
    Description:    Demo of the ANSI serial terminal driver
        * Vertical sc<-ling area demo
    Author:         Jesse Burt
    Started:        Aug 20, 2025
    Updated:        Aug 20, 2025
    Copyright (c) 2025 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

con

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


obj

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"


pub main() | i, top, bottom

    setup()
    ser.clear()
    ser.strln(@"Vertical scrolling area demo - press any key to quit and reset the terminal")

    top := 2                                    ' set the top and bottom rows of the sc<-l area
    bottom := 10
    ser.set_vscroll_area(top, bottom)           ' define sc<-l area and enable sc<-ling

    ser.pos_xy(0, bottom+2)
    ser.strln(@"This area (below the scroll area) isn't affected")

    ser.pos_xy(0, top)                          ' position the cursor at the sc<-l area start
    i := 0
    repeat                                      ' repeatedly print more lines to the terminal
        ser.printf(@"scroll %d\n\r", i++)       ' once the bottom of the sc<-l region is reached,
        if ( ser.getchar_noblock() => 0 )       ' the terminal will sc<-l it up
            quit

    ser.clear()
    ser.reset()
    ser.disable_vscroll()
    ser.strln(@"Serial terminal reset")

    repeat


pub setup()

    ser.start()
    time.msleep(30)
    ser.reset()
    ser.clear()
    ser.strln(@"Serial terminal started")


dat
{
Copyright 2025 Jesse Burt

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

