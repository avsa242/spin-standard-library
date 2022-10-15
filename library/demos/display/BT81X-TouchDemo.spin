{
    --------------------------------------------
    Filename: BT81X-TouchDemo.spin
    Author: Jesse Burt
    Description: Demo of the BT81x driver touchscreen functionality
    Copyright (c) 2022
    Started Sep 30, 2019
    Updated Jul 17, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_PIN      = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2
    MISO_PIN    = 3
    RST_PIN     = 4                             ' optional; pull high if unused
    BRIGHTNESS  = 100                           ' Initial brightness (0..128)

' --

    BUTTON_W    = 100
    BUTTON_H    = 50

' Uncomment one of the following, depending on your display size/resolution
'   NOTE: WIDTH, HEIGHT, XMAX, YMAX, CENTERX, CENTERY symbols are defined
'   in the display timings file.
#include "eve3-lcdtimings.800x480.spinh"
'#include "eve3-lcdtimings.480x272.spinh"
'#include "eve3-lcdtimings.320x240.spinh"
'#include "eve3-lcdtimings.320x102.spinh"

OBJ

    cfg         : "boardcfg.flip"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    eve         : "display.lcd.bt81x"

PUB Main{} | count, idle, state, x, y, t1, t2, t3, t4

    setup{}
    eve.brightness(BRIGHTNESS)
    eve.clearcolor(0, 0, 0)                     ' clear screen black
    eve.clear{}

    updatebutton(0)                             ' set initial button state
    idle := TRUE
    count := 0

    repeat
        state := eve.tagactive{}                ' get state of button
        if state == 1                           ' pushed
            if idle == TRUE                     ' mark not idle so only one
                idle := FALSE                   '   push is registered if held
                updatebutton(1)                 '   down
                count++
                if count == 3                   ' if pressed 3 times, exit the
                    quit                        '   loop

        elseif state == 0                       ' not pushed
            if idle == FALSE                    ' mark idle
                idle := TRUE
                updatebutton(0)                 ' redraw button up

    updatescrollbar(0)                          ' set initial scrollbar state
    repeat
        state := eve.tagactive{}
        if state == 1                           ' only update the scrollbar pos
            x := eve.touchxy{} >> 16            '   if it's being touched
            updatescrollbar(x)
            if x > WIDTH-20                     ' if pulled near the right edge
                quit                            '   of the screen, exit loop

    t1 := t2 := t3 := t4 := 0
    idle := TRUE
    updatetoggle(0, 0, 0, 0)                    ' set toggles' initial state
    repeat
        case state := eve.tagactive{}           ' which toggle was touched?
            1:                                  ' toggle #1
                if idle == TRUE
                    idle := FALSE
                    t1 ^= $FFFF                 ' flip all bits to change state
                    updatetoggle(t1, t2, t3, t4)
            2:                                  ' toggle #2
                if idle == TRUE
                    idle := FALSE
                    t2 ^= $FFFF
                    updatetoggle(t1, t2, t3, t4)
            3:                                  ' toggle #3
                if idle == TRUE
                    idle := FALSE
                    t3 ^= $FFFF
                    updatetoggle(t1, t2, t3, t4)
            4:                                  ' toggle #4
                if idle == TRUE
                    idle := FALSE
                    t4 ^= $FFFF
                    updatetoggle(t1, t2, t3, t4)
            other:
                if idle == FALSE
                    idle := TRUE

        if t1 == $FFFF and t2 == $FFFF and t3 == $FFFF and t4 == $FFFF
            quit                                ' if all toggles are switched
                                                '   on, end the demo

    eve.brightness(0)
    eve.powered(FALSE)
    repeat

PUB UpdateButton(state) | btn_cx, btn_cy

    btn_cx := CENTERX - (BUTTON_W / 2)
    btn_cy := CENTERY - (BUTTON_H / 2)

    eve.waitready{}                              ' wait for EVE to be ready
    eve.dlstart{}                               ' begin list of graphics cmds
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.widgetbgcolor($ff_ff_ff)                ' button colors (r_g_b)
    eve.widgetfgcolor($55_55_55)                '
    if state                                    ' button pressed
        eve.colorrgb(255, 255, 255)             ' button text color (pressed)
        eve.tagattach(1)                        ' tag or id# for this button
        eve.button(btn_cx, btn_cy, 100, 50, 30, 0, string("TEST"))
    else
        eve.colorrgb(0, 0, 192)                 ' button text color (up)
        eve.tagattach(1)
        eve.button(btn_cx, btn_cy, 100, 50, 30, 0, string("TEST"))
    eve.dlend{}                                 ' end list; display everything

PUB UpdateScrollbar(val) | w, h, x, y, sz

    sz := 10                                    ' scrollbar size
    w := WIDTH-(sz << 1)-1                      '   width
    h := 20                                     '   height
    x := 0+sz
    y := HEIGHT-h-1

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.widgetbgcolor($55_55_55)
    eve.widgetfgcolor($00_00_C0)
    eve.tagattach(1)
    eve.scrollbar(x, y, w, h, 0, x #> val <# w, sz, w)
    eve.dlend{}

PUB UpdateToggle(t1, t2, t3, t4) | tag, tmp, x, y, w, sw, h

    w := 60                                     ' toggle switch width
    h := 24                                     '   and height
    x := CENTERX-(w/2)                          ' x and y
    y := CENTERY-(h*4)                          '   coords

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.widgetbgcolor($55_55_55)
    eve.widgetfgcolor($00_00_C0)
    eve.tagattach(1)                            ' different
    eve.toggle(x, y + (1 * (h*2)), w, h, 0, t1, string("OFF", $FF, "ON"))
    eve.tagattach(2)                            ' tag
    eve.toggle(x, y + (2 * (h*2)), w, h, 0, t2, string("OFF", $FF, "ON"))
    eve.tagattach(3)                            ' for each
    eve.toggle(x, y + (3 * (h*2)), w, h, 0, t3, string("OFF", $FF, "ON"))
    eve.tagattach(4)                            ' button
    eve.toggle(x, y + (4 * (h*2)), w, h, 0, t4, string("OFF", $FF, "ON"))
    eve.dlend{}

PRI TS_Cal{}
' Calibrate the touchscreen (resistive only)
    eve.touchsens(1200)                         ' typical value, per BRT_AN_033
    eve.waitready{}
    eve.dlstart{}
    eve.clear{}
    eve.str(80, 30, 27, eve#OPT_CENTER, string("Please tap on the dot"))
    eve.touchcal{}
    eve.dlend{}
    eve.waitready{}
    ser.str(string("Press any key to continue, once touchscreen calibration is complete"))
    ser.charin{}

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if eve.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, RST_PIN, @_disp_setup)
        ser.strln(string("BT81x driver started"))
    else
        ser.str(string("BT81x driver failed to start - halting"))
        repeat

    if (eve.modelid{} == eve#BT816)             ' resistive TS?
        ts_cal{}

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

