{
    --------------------------------------------
    Filename: NES-Gamepad-Demo.spin
    Author: Jesse Burt
    Description: Demo of the NES gamepad input driver
    Copyright (c) 2023
    Started Apr 16, 2023
    Updated Apr 16, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200

    { NES gamepad I/O connections }
    LATCH       = 0
    CLK         = 1
    DATA1       = 2                             ' first gamepad input
    DATA2       = 3                             ' second gamepad input (optional; see driver)
' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    time:   "time"
    nes:    "input.gamepad.nes"

PUB main{}

    setup{}

    { choose one of the below }
    gamepad_nocog_demo{}                       ' no extra cog required
'    gamepad_cog_demo{}                         ' 1 extra cog required

PUB gamepad_nocog_demo{}

    nes.startx(LATCH, CLK, DATA1, DATA2)

    repeat
        ser.pos_xy(0, 3)
        nes.read_both{}
        if ( nes.ctrl1_connected{} )
            ser.printf1(@"Player 1 A: %d         \n\r", nes.ctrl1_a{})
            ser.printf1(@"Player 1 B: %d         \n\r", nes.ctrl1_b{})
            ser.printf1(@"Player 1 Select: %d    \n\r", nes.ctrl1_select{})
            ser.printf1(@"Player 1 Start: %d     \n\r", nes.ctrl1_start{})
            ser.printf1(@"Player 1 Up: %d        \n\r", nes.ctrl1_up{})
            ser.printf1(@"Player 1 Down: %d      \n\r", nes.ctrl1_down{})
            ser.printf1(@"Player 1 Left: %d      \n\r", nes.ctrl1_left{})
            ser.printf1(@"Player 1 Right: %d     \n\r", nes.ctrl1_right{})
        else
            ser.str(@"Player 1 not connected")
            repeat 8
                ser.clearline{}
                ser.newline{}

        if ( nes.ctrl2_connected{} )
            ser.printf1(@"Player 2 A: %d         \n\r", nes.ctrl2_a{})
            ser.printf1(@"Player 2 B: %d         \n\r", nes.ctrl2_b{})
            ser.printf1(@"Player 2 Select: %d    \n\r", nes.ctrl2_select{})
            ser.printf1(@"Player 2 Start: %d     \n\r", nes.ctrl2_start{})
            ser.printf1(@"Player 2 Up: %d        \n\r", nes.ctrl2_up{})
            ser.printf1(@"Player 2 Down: %d      \n\r", nes.ctrl2_down{})
            ser.printf1(@"Player 2 Left: %d      \n\r", nes.ctrl2_left{})
            ser.printf1(@"Player 2 Right: %d     \n\r", nes.ctrl2_right{})
        else
            ser.str(@"Player 2 not connected")
            repeat 8
                ser.clearline{}
                ser.newline{}

PUB gamepad_cog_demo{}

    nes.startx_cog(LATCH, CLK, DATA1, DATA2)

    repeat
        ser.pos_xy(0, 3)
        if ( nes.ctrl1_connected{} )
            ser.printf1(@"Player 1 A: %d         \n\r", nes.ctrl1_a{})
            ser.printf1(@"Player 1 B: %d         \n\r", nes.ctrl1_b{})
            ser.printf1(@"Player 1 Select: %d    \n\r", nes.ctrl1_select{})
            ser.printf1(@"Player 1 Start: %d     \n\r", nes.ctrl1_start{})
            ser.printf1(@"Player 1 Up: %d        \n\r", nes.ctrl1_up{})
            ser.printf1(@"Player 1 Down: %d      \n\r", nes.ctrl1_down{})
            ser.printf1(@"Player 1 Left: %d      \n\r", nes.ctrl1_left{})
            ser.printf1(@"Player 1 Right: %d     \n\r", nes.ctrl1_right{})
        else
            ser.str(@"Player 1 not connected")
            repeat 8
                ser.clear_line{}
                ser.newline{}

        if ( nes.ctrl2_connected{} )
            ser.printf1(@"Player 2 A: %d         \n\r", nes.ctrl2_a{})
            ser.printf1(@"Player 2 B: %d         \n\r", nes.ctrl2_b{})
            ser.printf1(@"Player 2 Select: %d    \n\r", nes.ctrl2_select{})
            ser.printf1(@"Player 2 Start: %d     \n\r", nes.ctrl2_start{})
            ser.printf1(@"Player 2 Up: %d        \n\r", nes.ctrl2_up{})
            ser.printf1(@"Player 2 Down: %d      \n\r", nes.ctrl2_down{})
            ser.printf1(@"Player 2 Left: %d      \n\r", nes.ctrl2_left{})
            ser.printf1(@"Player 2 Right: %d     \n\r", nes.ctrl2_right{})
        else
            ser.str(@"Player 2 not connected")
            repeat 8
                ser.clear_line{}
                ser.newline{}

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear
    ser.strln(string("Serial terminal started"))

DAT
{
Copyright 2023 Jesse Burt

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

