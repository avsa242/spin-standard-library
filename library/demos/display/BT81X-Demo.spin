{
    --------------------------------------------
    Filename: BT81X-Demo.spin
    Author: Jesse Burt
    Description: Demo of the BT81x driver
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

    INTER_DELAY = 2_000                         ' wait ms between demos

' Uncomment one of the following, depending on your display size/resolution
'   NOTE: WIDTH, HEIGHT, XMAX, YMAX, CENTERX, CENTERY symbols are defined
'   in the display timings file.
#include "eve3-lcdtimings.800x480.spinh"
'#include "eve3-lcdtimings.480x272.spinh"
'#include "eve3-lcdtimings.320x240.spinh"
'#include "eve3-lcdtimings.320x102.spinh"

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    eve     : "display.lcd.bt81x"

PUB Main{}

    setup{}

    eve.preset_highperf{}                       ' defaults, but max clock
    eve.brightness(BRIGHTNESS)

    demolines{}
    demoboxes{}
    demospinner{}
    demobutton{}
    demogauge{}
    demogradient{}
    demogradienttransparency{}
    demokeys{}
    demoprogressbar{}
    demoscrollbar{}
    demoslider{}
    demodial{}
    demotoggle{}
    demotextwrap{}
    demonumbers{}
    demorotatescreen{}

    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.dlend{}
    fadeout(30)
    eve.powered(FALSE)
    repeat

PUB DemoBoxes{} | i

    ser.strln(string("Box()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.linewidth(1)
    repeat i from 10 to CENTERY step 20
        eve.colorrgb(0, i/4, 128)
        eve.box(i, CENTERY-i, XMAX-i, CENTERY+i, true)
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoButton{} | i, btn_w, btn_h

    ser.strln(string("Button()"))
    btn_w := 78
    btn_h := 32
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 48)
    eve.clear{}
    eve.widgetfgcolor($40_40_40)
    eve.button(400-btn_w, 240-btn_h, btn_w, btn_h, 16, eve#OPT_3D, string("A button!"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoDial{}

    ser.strln(string("Dial()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.dial(80, 60, 55, 0, $8000)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.dial(80, 60, 55, eve#OPT_FLAT, $8000)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.dial(28, 60, 24, 0, $0000)
    eve.str(28, 100, 26, eve#OPT_CENTER, string("0%"))
    eve.dial(80, 60, 24, 0, $5555)
    eve.str(80, 100, 26, eve#OPT_CENTER, string("33%"))
    eve.dial(132, 60, 24, 0, $AAAA)
    eve.str(132, 100, 26, eve#OPT_CENTER, string("66%"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoGauge{} | i

    ser.strln(string("Gauge()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 48)
    eve.clear{}
    eve.gauge(CENTERX, CENTERY, 100, eve#OPT_FLAT, 10, 5, i, 100)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    repeat i from 0 to 100
        eve.waitready{}
        eve.dlstart{}
        eve.clear{}
        eve.gauge(CENTERX, CENTERY, 50, eve#OPT_3D, 10, 5, i, 100)
        eve.dlend{}
        time.msleep(10)
    time.msleep(INTER_DELAY)
    repeat i from 100 to 0
        eve.waitready{}
        eve.dlstart{}
        eve.clear{}
        eve.gauge(CENTERX, CENTERY, 50, eve#OPT_3D, 10, 5, i, 100)
        eve.dlend{}
        time.msleep(10)

    time.msleep(INTER_DELAY)

PUB DemoGradient{}

    ser.strln(string("Gradient()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.gradient(0, 0, $0000FF, XMAX, 0, $FF0000)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.Gradient (0, 0, $808080, XMAX, 0, $80FF40)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.gradient(0, 0, $808080, XMAX, YMAX, $80FF40)
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoGradientTransparency{}

    ser.strln(string("GradientTransparency()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.str(80, 60, 30, eve#OPT_CENTER, string("background"))
    eve.gradienttransparency(0, 0, $FF00FF00, 160, 0, $0000FF00)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.str(80, 30, 30, eve#OPT_CENTER, string("background"))
    eve.str(80, 60, 30, eve#OPT_CENTER, string("background"))
    eve.str(80, 90, 30, eve#OPT_CENTER, string("background"))
    eve.gradienttransparency(0, 20, $40FF0000, 0, 100, $FF0000FF)
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoKeys{} | k

    ser.strln(string("Keys()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.keys(10, 10, 140, 30, 26, 0, string("12345"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.keys(10, 10, 140, 30, 26, eve#OPT_FLAT, string("12345"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.keys(10, 10, 140, 30, 26, 0, string("12345"))
    eve.keys(10, 60, 140, 30, 26, eve#OPT_CENTER, string("12345"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.keys(10, 10, 140, 30, 26, $32, string("12345"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.keys(22, 1, 116, 28, 29, 0, string("789"))
    eve.keys(22, 31, 116, 28, 29, 0, string("456"))
    eve.keys(22, 61, 116, 28, 29, 0, string("123"))
    eve.keys(22, 91, 116, 28, 29, 0, string("0."))
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.keys(2, 2, 156, 21, 20, eve#OPT_CENTER, string("qwertyuiop"))
    eve.keys(2, 26, 156, 21, 20, eve#OPT_CENTER, string("asdfghjkl"))
    eve.keys(2, 50, 156, 21, 20, eve#OPT_CENTER, string("zxcvbnm"))
    eve.button(2, 74, 156, 21, 20, 0, string(" "))
    eve.dlend{}
    time.msleep(INTER_DELAY)

    k := $66
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.keys(2, 2, 156, 21, 20, k | eve#OPT_CENTER, string("qwertyuiop"))
    eve.keys(2, 26, 156, 21, 20, k | eve#OPT_CENTER, string("asdfghjkl"))
    eve.keys(2, 50, 156, 21, 20, k | eve#OPT_CENTER, string("zxcvbnm"))
    eve.button(2, 74, 156, 21, 20, 0, string(" "))
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoLines{} | i

    ser.strln(string("Line()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    repeat i from 10 to XMAX-10 step 10
        eve.colorrgb(0, i/4, 128)
        eve.line(i, 10, XMAX-10-i, YMAX-10)
    repeat i from 10 to YMAX-10 step 10
        eve.colorrgb(0, 128, i/4)
        eve.line(XMAX-10, i, 10, YMAX-10-i)
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoNumbers{}

    ser.strln(string("Num()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.num(20, 60, 31, 0, 42)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.num(80, 60, 31, eve#OPT_CENTER, 42)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.num(20, 20, 31, eve#OPT_SIGNED, 42)
    eve.num(20, 60, 31, eve#OPT_SIGNED, -42)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.num(150, 20, 31, eve#OPT_RIGHTX | 3, 42)
    eve.num(150, 60, 31, eve#OPT_SIGNED | eve#OPT_RIGHTX | 3, -1)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.num(80, 30, 28, eve#OPT_CENTER, 123456)
    eve.setbase(16)
    eve.num(80, 60, 28, eve#OPT_CENTER, 123456)
    eve.setbase(2)
    eve.num(80, 90, 26, eve#OPT_CENTER, 123456)

    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoProgressBar{}

    ser.strln(string("ProgressBar()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.progressbar(20, 50, 120, 12, 0, 50, 100)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.progressbar(20, 50, 120, 12, eve#OPT_FLAT, 50, 100)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.widgetbgcolor($402000)
    eve.progressbar(20, 50, 120, 4, 0, 9000, 65535)
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoRotateScreen{} | r

    ser.strln(string("RotateScreen()"))
    repeat r from 0 to 7
        eve.waitready{}
        eve.dlstart{}
        eve.clearcolor(0, 0, 0)
        eve.clear{}
        eve.rotatescreen(r)
        eve.str(CENTERX, CENTERY, 31, eve#OPT_CENTER, string("Screen rotation"))
        eve.dlend{}
        time.msleep(INTER_DELAY)
    time.msleep(INTER_DELAY)

PUB DemoScrollbar{}

    ser.strln(string("Scrollbar()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.scrollbar(20, 50, 120, 8, 0, 10, 40, 100)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.scrollbar(20, 50, 120, 8, eve#OPT_FLAT, 10, 40, 100)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.widgetbgcolor($402000)
    eve.widgetfgcolor($703800)
    eve.scrollbar(140, 10, 8, 100, 0, 10, 40, 100)
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoSlider{}

    ser.strln(string("Slider()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.slider(20, 50, 120, 8, 0, 50, 100)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.slider(20, 50, 120, 8, eve#OPT_FLAT, 50, 100)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.widgetbgcolor($402000)
    eve.widgetfgcolor($703800)
    eve.slider(76, 10, 8, 100, 0, 20000, 65535)
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoSpinner{} | i

    ser.strln(string("Spinner()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 48)
    eve.clear{}
    eve.str(CENTERX, CENTERY-30, 27, eve#OPT_CENTER, string("Please wait..."))
    eve.spinner(CENTERX, CENTERY, eve#SPIN_CIRCLE_DOTS, 0)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 48)
    eve.clear{}
    eve.str(CENTERX, CENTERY-30, 27, eve#OPT_CENTER, string("Please wait..."))
    eve.spinner(CENTERX, CENTERY, eve#SPIN_LINE_DOTS, 0)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 48)
    eve.clear{}
    eve.str(CENTERX, CENTERY-40, 27, eve#OPT_CENTER, string("Please wait..."))
    eve.spinner(CENTERX, CENTERY, eve#SPIN_CLOCKHAND, 0)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 48)
    eve.clear{}
    eve.str(CENTERX, CENTERY-30, 27, eve#OPT_CENTER, string("Please wait..."))
    eve.spinner(CENTERX, CENTERY, eve#SPIN_ORBIT_DOTS, 0)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 48)
    eve.clear{}
    eve.spinner(CENTERX, CENTERY, eve#SPIN_CIRCLE_DOTS, 1)
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 48)
    eve.clear{}
    eve.spinner(CENTERX, CENTERY, eve#SPIN_CIRCLE_DOTS, 2)
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoTextWrap{}

    ser.strln(string("TextWrap(), Str()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.textwrap(160)
    eve.str(0, 0, 30, eve#OPT_FILL, string("This text doesn't fit on one line"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB DemoToggle{}

    ser.strln(string("Toggle()"))
    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.toggle(60, 20, 33, 27, 0, 0, string("no", $FF, "yes"))
    eve.toggle(60, 60, 33, 27, 0, 65535, string("no", $FF, "yes"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.toggle(60, 20, 33, 27, eve#OPT_FLAT, 0, string("no", $FF, "yes"))
    eve.toggle(60, 60, 33, 27, eve#OPT_FLAT, 65535, string("no", $FF, "yes"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

    eve.waitready{}
    eve.dlstart{}
    eve.clearcolor(0, 0, 0)
    eve.clear{}
    eve.widgetbgcolor($402000)
    eve.widgetfgcolor($703800)
    eve.toggle(60, 20, 33, 27, 0, 0, string("no", $FF, "yes"))
    eve.toggle(60, 60, 33, 27, 0, 65535, string("no", $FF, "yes"))
    eve.dlend{}
    time.msleep(INTER_DELAY)

PUB FadeOut(delay_ms) | i

    ser.strln(string("Brightness"))
    repeat i from BRIGHTNESS to 0
        eve.brightness(i)
        time.msleep(delay_ms)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if eve.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, RST_PIN, @_disp_setup)
        ser.strln(string("BT81x driver started"))
    else
        ser.strln(string("BT81x driver failed to start - halting"))
        repeat

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

