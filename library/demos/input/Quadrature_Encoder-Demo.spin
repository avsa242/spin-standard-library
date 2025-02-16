{
----------------------------------------------------------------------------------------------------
    Filename:       Quadrature_Encoder-Demo.spin
    Description:    Demo of the 1..16 quadrature encoder input driver
    Author:         Jesse Burt
    Started:        Aug 30, 2021
    Updated:        Feb 16, 2025
    Copyright (c) 2025 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    time:       "time"
    ser:        "com.serial.terminal.ansi" | SER_BAUD=115_200
    encoder:    "input.encoder.quadrature" | BASEPIN=6, NUM_ENC=4, NUM_DELTA=2


PUB main() | enc_num

    setup()
    repeat
        ser.pos_xy(0, 3)
        repeat enc_num from 0 to encoder.NUM_ENC-1
            ser.printf(@"Encoder %d absolute position: %d  ",   enc_num, ...
                                                                encoder._enc_posbuff[enc_num] / 4)
            if (enc_num < encoder.NUM_DELTA)
                ser.printf(@"(delta %d)  \n\r", encoder.pos_delta(enc_num) )
            else
                ser.strln(@"(delta N/A)   ")


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    encoder.start()
    ser.strln(@"Quadrature encoder driver started")


DAT
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

