{
    --------------------------------------------
    Filename: OLED-US2066-Demo.spin
    Description: Demo of the US2066 driver
    Author: Jesse Burt
    Copyright (c) 2022
    Created Dec 30, 2017
    Updated Dec 3, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

' uncomment one of the below pairs, depending on your display size
    WIDTH       = 20
    HEIGHT      = 4
'    WIDTH       = 16
'    HEIGHT      = 2

    SCL_PIN     = 28
    SDA_PIN     = 29
    RESET_PIN   = 25                            ' optional (-1 to disable)
    I2C_FREQ    = 400_000
    ADDR_BITS   = 0                             ' 0, 1
' --

    DEMO_DELAY  = 2_000                         ' seconds between demos
    MODE_DELAY  = 1_000                         ' seconds between sub-demos

OBJ

    cfg : "boardcfg.flip"
    time: "time"
    oled: "display.oled-alpha.us2066"
    ser : "com.serial.terminal.ansi"

PUB main{}

    setup{}

    greet_demo{}
    time.msleep(DEMO_DELAY)
    oled.clear{}

    count_demo{}
    time.msleep(DEMO_DELAY)
    oled.clear{}

    dbl_height_demo{}
    time.msleep(DEMO_DELAY)
    oled.clear{}

    contrast_demo{}
    time.msleep(DEMO_DELAY)
    oled.clear{}

    position_demo{}
    time.msleep(DEMO_DELAY)
    oled.clear{}

    cursor_demo{}
    time.msleep(DEMO_DELAY)
    oled.clear{}

    invert_demo{}
    time.msleep(DEMO_DELAY)
    oled.clear{}

    fnt_width_demo{}
    time.msleep(DEMO_DELAY)
    oled.clear{}

    mirror_demo{}
    time.msleep(DEMO_DELAY)
    oled.clear{}

    oled.stop{}
    repeat

PUB contrast_demo{} | i

    oled.pos_xy(0, 0)
    oled.printf1(string("Change contrast\n\rlevel:"), 0)
    case HEIGHT
        2:
            repeat i from -255 to 255 step 1
                oled.pos_xy(7, 1)
                oled.contrast(||(i))
                oled.printf2(string("%03.3d %02.2x"), ||(i), ||(i))
                time.msleep(10)
        4:
            oled.newline{}
            oled.dbl_height(1)

            repeat i from -255 to 255 step 1
                oled.pos_xy(0, 2)
                oled.contrast(||(i))
                oled.printf3(string("%03.3d %02.2x %08.8b"), ||(i), ||(i), ||(i))
                time.msleep(10)

    oled.dbl_height(0)

PUB count_demo{} | i

    case HEIGHT
        2:
            oled.pos_xy(0, 0)
            oled.strln(string("Rapidly changing"))
            oled.strln(string("display contents"))
            time.msleep(3)
            oled.clear{}
            oled.strln(string("Compare to LCD!"))

            repeat i from 0 to 3000
                oled.pos_xy(0, 1)
                oled.printf1(string("i = %d"), i)
        4:
            oled.pos_xy(0, 0)
            oled.strln(string("Rapidly changing"))
            oled.strln(string("display contents"))
            oled.strln(string("(compare to LCD!)"))
            repeat i from 0 to 3000
                oled.pos_xy(0, 3)
                oled.printf1(string("i = %d"), i)

PUB cursor_demo{} | delay, dbl_mode

    delay := 25                                 ' milliseconds
    case HEIGHT
        2:
            repeat dbl_mode from 0 to 3 step 3
                oled.clear{}
                oled.dbl_height(dbl_mode)
                oled.cursor_mode(0)
                oled.pos_xy(0, 0)
                strdelay(string("No cursor  (0)"), delay)
                time.msleep(DEMO_DELAY)
                oled.clear_line(0)

                oled.cursor_mode(1)
                oled.pos_xy(0, 0)
                strdelay(string("Block/blink(1)"), delay)
                time.msleep(DEMO_DELAY)
                oled.clear_line(0)

                oled.cursor_mode(2)
                oled.pos_xy(0, 0)
                strdelay(string("Underscore (2)"), delay)
                time.msleep(DEMO_DELAY)
                oled.clear_line(0)

                oled.cursor_mode(3)
                oled.pos_xy(0, 0)
                strdelay(string("Under./blink(3)"), delay)
                time.msleep(DEMO_DELAY)
        4:
            repeat dbl_mode from 0 to 2 step 2
                oled.clear{}
                oled.dbl_height(dbl_mode)
                oled.cursor_mode(0)
                oled.pos_xy(0, 0)
                strdelay(string("Cursor:"), delay)

                oled.pos_xy(0, 1)
                strdelay(string("None           (0)"), delay)
                time.msleep(DEMO_DELAY)
                oled.clear_line(1)

                oled.cursor_mode(1)
                oled.pos_xy(0, 1)
                strdelay(string("Block/blink    (1)"), delay)
                time.msleep(DEMO_DELAY)
                oled.clear_line(1)

                oled.cursor_mode(2)
                oled.pos_xy(0, 1)
                strdelay(string("Underscore     (2)"), delay)
                time.msleep(DEMO_DELAY)
                oled.clear_line(1)

                oled.cursor_mode(3)
                oled.pos_xy(0, 1)
                strdelay(string("Underscore/blink(3)"), delay)
                time.msleep(DEMO_DELAY)

    oled.dbl_height(0)
    oled.cursor_mode(0)

PUB dbl_height_demo{} | mode, line

    case HEIGHT
        2:
            mode := 0
            repeat 6
                oled.dbl_height(mode)
                repeat line from 0 to 1
                    oled.pos_xy(0, line)
                    oled.str(string("Double-height"))
                time.msleep(MODE_DELAY)
                mode += 3
                if mode > 3
                    mode  := 0
            oled.dbl_height(0)
        4:
            repeat mode from 0 to 4
                oled.dbl_height(mode)
                oled.pos_xy(14, 0)
                oled.printf1(string("Mode %d"), mode)
                repeat line from 0 to 3
                    oled.pos_xy(0, line)
                    oled.str(string("Double-height"))
                time.msleep(MODE_DELAY)

PUB fnt_width_demo{} | px, dbl_mode

    oled.clear{}

    repeat dbl_mode from 0 to 3 step 3
        oled.dbl_height(dbl_mode)
        repeat 2
            repeat px from 6 to 5
                oled.fnt_width(px)
                oled.pos_xy(0, 0)
                oled.printf1(string("%d-pixel width"), px)
                time.msleep(MODE_DELAY)

    oled.fnt_width(5)
    oled.dbl_height(0)

PUB greet_demo{}

    case HEIGHT
        2:
            oled.pos_xy(0, 0)
            oled.str(@w16l1)
            oled.str(@w16l2)
        4:
            oled.pos_xy(0, 0)
            oled.str(@w20l1)
            oled.str(@w20l2)
            oled.str(@w20l3)
            oled.str(@w20l4)

PUB invert_demo{} | i

    oled.clear{}
    oled.pos_xy(0, 0)
    oled.str(string("Display"))

    repeat i from 1 to 3
        oled.invert_colors(TRUE)
        oled.pos_xy(WIDTH-8, HEIGHT-1)
        oled.str(string("INVERTED"))
        time.msleep(MODE_DELAY)
        oled.invert_colors(FALSE)
        oled.pos_xy(WIDTH-8, HEIGHT-1)
        oled.str(string("NORMAL  "))
        time.msleep(MODE_DELAY)

PUB mirror_demo{} | row, col

    oled.clear{}

    case HEIGHT
        2:
            row := 2
            col := WIDTH-12
        4:
            row := 0
            col := WIDTH-13

    oled.mirror_h(FALSE)
    oled.mirror_v(FALSE)
    oled.clear_line(0)
    oled.pos_xy(0, 0)
    oled.str(string("Mirror OFF"))
    time.msleep(DEMO_DELAY)

    oled.mirror_h(TRUE)
    oled.mirror_v(FALSE)
    oled.clear_line(0)
    oled.pos_xy(col, 0)
    oled.str(string("Mirror HORIZ."))
    time.msleep(DEMO_DELAY)

    oled.mirror_h(FALSE)
    oled.mirror_v(TRUE)
    oled.clear_line(0)
    oled.pos_xy(0, row)
    oled.str(string("Mirror VERT."))
    time.msleep(DEMO_DELAY)

    oled.mirror_h(TRUE)
    oled.mirror_v(TRUE)
    oled.clear_line(0)
    oled.pos_xy(col, row)
    oled.str(string("Mirror BOTH"))
    time.msleep(DEMO_DELAY)

    oled.clear{}
    oled.mirror_h(FALSE)
    oled.mirror_v(FALSE)

PUB position_demo{} | x, y

    repeat y from 0 to HEIGHT-1
        repeat x from 0 to WIDTH-1
            oled.pos_xy(0, 0)
            oled.printf2(string("Position %d,%d "), x, y)
            oled.pos_xy((x-1 #> 0), y)
            oled.char(" ")
            oled.char("-")
            time.msleep(25)

PRI strdelay(stringptr, delay)
' Display zero-terminated string with inter-character delay, in ms
    repeat strsize(stringptr)
        oled.char(byte[stringptr++])
        time.msleep(delay)

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    ' use default Propeller I2C pins and 100kHz. Specify reset pin
'    if oled.start(RESET_PIN)

    ' use all custom settings
    if oled.startx(SCL_PIN, SDA_PIN, RESET_PIN, I2C_FREQ, ADDR_BITS, HEIGHT)
        ser.strln(string("US2066 driver started"))
    else
        ser.strln(string("US2066 driver failed to start - halting"))
        repeat

    oled.mirror_h(FALSE)
    oled.mirror_v(FALSE)
    oled.clear{}
    oled.pos_xy(0, 0)
    oled.visibility(oled#NORM)
    oled.char_attrs(oled#CHAR_PROC)              ' _interpret_ control chars, don't draw them

DAT
' Greet text
'                  0|    |    |    |15
    w16l1   byte{0}"Parallax P8X32A", 0
    w16l2   byte{1}"(US2066 2x16)  ", 0

'                  0|    |    |    |   |19
    w20l1   byte{0}"  Parallax P8X32A   ", 0
    w20l2   byte{1}"       on the       ", 0
    w20l3   byte{2}"    US2066 OLED     ", 0
    w20l4   byte{3}"        4x20        ", 0


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

