{
    --------------------------------------------
    Filename: oled-4DGL-Demo.spin
    Author: Beau Schwabe
    Modified by: Jesse Burt
    Description: Demo of the 4D Systems Goldelox series OLED display driver
    Copyright (c) 2019
    Started Jun 9, 2019
    Updated Jun 9, 2019
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This file is a derivative of the 4DGL oled driver object demo
        originally written by Beau Schwabe, oLED-128-G2_DEMO_v2.1b.spin.
        Original header preserved below
}

{{
*******************************************
* oLED-128-G2 display driver DEMO v2.1    *
* Author: Beau Schwabe                    *
* Copyright (c) 2013 Parallax             *
* See end of file for terms of use.       *
*******************************************
See end of file for terms of use:

File: oLED-128-G2_DEMO_v2.1.spin
}}
CON
   
    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

    OLED_RX     = 6
    OLED_TX     = 7
    OLED_RESET  = 9
    OLED_BAUD   = 115_200

VAR

    long _ser_cog

OBJ

    cfg     : "boardcfg.flip"
    oled    : "display.oled.4dgl.uart"
    ser     : "com.serial.terminal"                                 ''Used ONLY For DEBUGGING
    time    : "time"

PUB Main | i, j

    Setup
    '--------------------------------------------------------------------------------------------- Slide 1
    oled.image(0, 0, 28, 128, 0, @ParallaxIncLOGO)                  ''Display Parallax LOGO
    oled.image(0, 28, 50, 64, 1, @ChipGracey)                       ''Display Chip Gracey Picture
    time.Sleep (1)

    oled.ClearScreen                                                ''Clear the Display screen
    oled.image(0, 0, 28, 128, 0, @ParallaxIncLOGO)                  ''Display Parallax LOGO



    oled.choosecolor("b")                                           ''Chooses color blue
    'oled.RGB(0,255,0)                                              ''Another way to choose a color ; green

    oled.placestring(0, 4, string("          11111111"),0)          ''display some text at x,y
    oled.placestring(0, 5, string("012345678901234567"),0)
    time.Sleep(4)
    '--------------------------------------------------------------------------------------------- Slide 2
                                                                    ''Another way to display text
    oled.TextBackgroundColor(oled.RGB(0, 255, 0))                   ''Make text background color GREEN
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("This is hard to   ", oled#NL, oled#LF, "read with the     ", oled#NL, oled#LF, "background GREEN  "), 0)
    time.Sleep(4)
    '--------------------------------------------------------------------------------------------- Slide 3
    oled.TextBackgroundColor(oled.RGB(255, 0, 0))                   ''Make text background color RED
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("Much easier to    ", oled#NL, oled#LF, "read with the     ", oled#NL, oled#LF, "background RED    "), 0)
    time.Sleep(4)
    '--------------------------------------------------------------------------------------------- Slide 4
    oled.TextForegroundColor(oled.RGB(0, 0, 0))                     ''Make text foreground color BLACK
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("You can change the", oled#NL, oled#LF, "text foreground as", oled#NL, oled#LF, "well.             "), 0)
    time.Sleep(4)
    '--------------------------------------------------------------------------------------------- Slide 5
    oled.TextBackgroundColor(oled.RGB(0, 0, 0))                     ''Make text background color BLACK
    oled.TextForegroundColor(oled.RGB(0, 255, 0))                   ''Make text foreground color GREEN
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("But enough of that", oled#NL, oled#LF, "You can change the", oled#NL, oled#LF, "Width also...     "), 0)
    
    oled.TextBackgroundColor(oled.RGB(0, 0, 0))                     ''Make text background color BLACK
    oled.TextForegroundColor(oled.RGB(0, 0, 255))                   ''Make text foreground color BLUE
    repeat i from 1 to 16
        oled.TextWidth(i)                                           ''set width
        oled.placestring(0, 8, string("Width"), 0)                  ''display some text at x,y
        time.MSleep (250)
    repeat i from 16 to 1
        oled.TextWidth(i)                                           ''set width
        oled.placestring(0, 8, string("Width     "), 0)             ''display some text at x,y
        time.MSleep (250)
    oled.placestring(0, 8,   string("          "), 0)               ''display some text at x,y   
    '--------------------------------------------------------------------------------------------- Slide 6
    oled.TextBackgroundColor(oled.RGB(0, 0, 0))                     ''Make text background color BLACK
    oled.TextForegroundColor(oled.RGB(0, 255, 0))                   ''Make text foreground color GREENK
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("Ohh sure, you can ", oled#NL, oled#LF, "also change the   ", oled#NL, oled#LF, "Height...         "), 0)
    
    oled.TextBackgroundColor(oled.RGB(0, 0, 0))                     ''Make text background color BLACK
    oled.TextForegroundColor(oled.RGB(0, 0, 255))                   ''Make text foreground color BLUE
    repeat i from 1 to 16
        oled.TextHeight(i)                                          ''set height
        oled.placestring(0, 0, string("Height"), 0)                 ''display some text at x,y
        time.MSleep (250)
    repeat i from 16 to 1
        oled.TextHeight(i)                                          ''set height
        oled.placestring(0, 0, string("Height"), 0)                 ''display some text at x,y
        oled.placestring(0, 1, string("         "), 0)              ''display some text at x,y
        time.MSleep (250)
'--------------------------------------------------------------------------------------------- Slide 7

    oled.TextBackgroundColor(oled.RGB(0, 0, 0))                     ''Make text background color BLACK
    oled.TextForegroundColor(oled.RGB(0, 255, 0))                   ''Make text foreground color GREEN
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("Or even both of   ", oled#NL, oled#LF, "then at the same  ", oled#NL, oled#LF, "time...         "), 0)

    oled.TextBackgroundColor(oled.RGB(0, 0, 0))                     ''Make text background color BLACK
    oled.TextForegroundColor(oled.RGB(0, 0, 255))                   ''Make text foreground color BLUE
    repeat i from 1 to 16
        oled.TextHeight(i)                                          ''set height
        oled.TextWidth(i)                                           ''set width
        oled.placestring(0, 0, string("Both     "), 0)              ''display some text at x,y
        time.MSleep (250)
    time.Sleep (1)
'--------------------------------------------------------------------------------------------- Slide 8

    oled.ClearScreen                                                ''Clear the Display screen
    oled.image(0, 0, 28, 128, 0, @ParallaxIncLOGO)                  ''Display Parallax LOGO
    
    oled.TextBackgroundColor(oled.RGB(0, 0, 0))                     ''Make text background color BLACK
    oled.TextForegroundColor(oled.RGB(0, 255, 0))                   ''Make text foreground color GREEN
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("Plus a few other  ", oled#NL, oled#LF, "text functions... "), 0)
    
    oled.TextBackgroundColor(oled.RGB(0, 0, 0))                     ''Make text background color BLACK
    oled.TextForegroundColor(oled.RGB(0, 0, 255))                   ''Make text foreground color BLUE
    
    oled.TextXgap(3)                                                ''set X-gap  ; there is also a Y-gap
    oled.placestring(0, 7, string("X-gap"), 0)                      ''display some text at x,y
    oled.TextXgap(0)
    oled.TextBold(1)                                                ''set BOLD text
    oled.placestring(0, 8, string("Bold"), 0)                       ''display some text at x,y
    oled.TextBold(0)
    oled.TextInverse(1)                                             ''set INVERSE text
    oled.placestring(0, 9, string("Inverse"), 0)                    ''display some text at x,y
    oled.TextInverse(0)
    oled.TextItalic(1)                                              ''set ITALIC text
    oled.placestring(0, 10, string("Italic"), 0)                    ''display some text at x,y
    oled.TextItalic(0)
    oled.TextUnderline(1)                                           ''set UNDERLINE text
    oled.placestring(0, 11, string("Underline"), 0)                 ''display some text at x,y
    oled.TextUnderline(0)
    oled.TextPrintDelay(255)                                        ''set character print delay
    oled.placestring(0, 12, string("Text Print Delay"), 0)          ''display some text at x,y
    oled.TextPrintDelay(0)                                   
    time.Sleep (2)
    '--------------------------------------------------------------------------------------------- Slide 9
    oled.DrawFilledRectangle(0, 55, 127, 127, oled.RGB(0, 0, 0))    ''Draw a black filled rectangle ; partial erase
    oled.TextBackgroundColor(oled.RGB(0, 0, 0))                     ''Make text background color BLACK
    oled.TextForegroundColor(oled.RGB(0, 255, 0))                   ''Make text foreground color GREEN
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("Graphics are fun   ", oled#NL, oled#LF, "also. How about a  ", oled#NL, oled#LF, "circle...          "), 0)
    oled.DrawCircle(64, 64, 30 ,oled.RGB(255, 0, 0))                ''Draw a red Circle
    time.Sleep (4)
    '--------------------------------------------------------------------------------------------- Slide 10
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("Graphic lines...   ", oled#NL, oled#LF, "                   ", oled#NL, oled#LF, "                   "), 0)
    oled.DrawLine(0, 64, 127, 100, oled.RGB(0, 0, 255))             ''Draw a blue line
    time.Sleep (4)
    '--------------------------------------------------------------------------------------------- Slide 11
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("Graphic rectangle  ", oled#NL, oled#LF, "                   ", oled#NL, oled#LF, "                   "), 0)
    oled.DrawRectangle(30, 64, 127, 100, oled.RGB(255, 255, 0))     ''Draw a yellow rectangle
    time.Sleep (4)
    '--------------------------------------------------------------------------------------------- Slide 12
    oled.MoveCursor(4, 0)                                           ''Position Cursor at row and column
    oled.PutString(string("Graphic triangle   ", oled#NL, oled#LF, "                   ", oled#NL, oled#LF, "                   "), 0)
    oled.DrawTriangle(30, 64, 60, 35, 90, 100, oled.RGB(255, 255, 255)) ''Draw a white triangle
    time.Sleep (4)
    '--------------------------------------------------------------------------------------------- Slide 13
    oled.MoveCursor(4, 0)                                               ''Position Cursor at row and column
    oled.PutString(string("We can control the ", oled#NL, oled#LF, "screen contrast    ", oled#NL, oled#LF,"and turn it off... "), 0)
    repeat i from 15 to 0                           
        oled.Contrast(i)
        time.MSleep (250)
    oled.Contrast (1)
    oled.MoveCursor(4, 0)                                               ''Position Cursor at row and column
    oled.PutString(string("...and back on     ", oled#NL, oled#LF, "                  ", oled#NL, oled#LF, "                   "), 0)
    time.MSleep (250)
    repeat i from 2 to 15
        oled.Contrast(i)
        time.MSleep (250)
    time.Sleep (4)

    oled.MoveCursor(4, 0)                                               ''Position Cursor at row and column
    oled.PutString(string("Not to mention    ", oled#NL, oled#LF, "many other things ", oled#NL, oled#LF, "you can do with   "), 0)
    oled.MoveCursor(7, 0)                                               ''Position Cursor at row and column
    oled.PutString(string("a uOLED-128-G2    ", oled#NL, oled#LF, "display sold at...", oled#NL, oled#LF, "www.parallax.com  "), 0)
    time.Sleep (4)
    '--------------------------------------------------------------------------------------------- Slide 14
    oled.ClearScreen                                                    ''Clear the Display screen

    repeat 2
        repeat i from 0 to 255 step 10
            oled.BARgraph(0, 0, 0, 20, 14, oled.RGB(0, 255, 0), oled.RGB(0, 32, 0), i, 1)
            oled.BARgraph(100, 0, 0, 20, 14, oled.RGB(255, 0, 0), oled.RGB(32, 0, 0), 255-i, 2)
            oled.Gauge(40, 64, 15, 0, oled.RGB(255, 255, 255), 255-i, 1)
            oled.Gauge(80, 64, 15, 0, oled.RGB(255, 255, 255), i, 2)

    repeat i from 255 to 0 step 10
        oled.BARgraph(0, 0, 0, 20, 14, oled.RGB(0, 255, 0), oled.RGB(0, 32, 0), i, 1)
        oled.BARgraph(100, 0, 0, 20, 14, oled.RGB(255, 0, 0), oled.RGB(32, 0, 0), 255-i, 2)
        oled.Gauge(40, 64, 15, 0, oled.RGB(255, 255, 255), 255-i, 1)
        oled.Gauge(80, 64, 15, 0, oled.RGB(255, 255, 255), i, 2)

    '--------------------------------------------------------------------------------------------- Slide 15    
    oled.image(0, 0, 28, 128, 0, @ParallaxIncLOGO)                      ''Display Parallax LOGO
    oled.image(0, 28, 50, 64, 1, @ChipGracey)                           ''Display Chip Gracey Picture
    oled.ScreenSaverTimeout(1)                                          ''Start Screensaver
    repeat


PUB Debug                                                               ''Useful for tracking the "undocumented" output from

    ser.Dec(oled.ACK)                                                   ''some of the Display commands.
    repeat 10                                                           ''Note: Only displays the first 10 bytes, ideally if
        ser.Char("-")                                                   ''      the Display command goes well you will only 
        ser.Dec(oled.NextAck)                                           ''      see one "Ack" BYTE on the DEBUG output "6-"
    repeat                                                              ''If you read MORE bytes then just the 'Ack' there is a
                                                                        ''buffer leak and eventually you will overflow which can
                                                                        ''cause unpredictable Display behavior
PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#NL))
    oled.start (OLED_RX, OLED_TX, OLED_RESET, OLED_BAUD)
    ser.Str (string("OLED object started", ser#NL))

DAT

    xArray
    byte 10, 50, 20
    yArray   
    byte 10, 40, 120 

    ParallaxIncLOGO
'------------------------ 256 color BMP Image Data below ---------------------------
        byte $42, $4D, $36, $12, $00, $00, $00, $00, $00, $00, $36, $04, $00, $00, $28, $00, $00, $00, $80, $00, $00, $00, $1C, $00
        byte $00, $00, $01, $00, $08, $00, $00, $00, $00, $00, $00, $0E, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $26, $26, $26, $00, $41, $3D, $3C, $00, $49, $40
        byte $3F, $00, $6B, $55, $53, $00, $A2, $A2, $A2, $00, $F7, $F7, $F7, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $02, $02, $02, $02, $02, $02, $02
        byte $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $02, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $02, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $08, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
        byte $07, $02, $04, $05, $05, $05, $05, $05, $05, $02, $02, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $03, $02, $02, $05, $05, $05, $05, $05, $02, $02, $05, $05, $05, $05, $05, $02, $02, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $02, $02, $02, $02
        byte $02, $02, $02, $02, $02, $02, $02, $02, $02, $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $02, $02, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $05, $08, $02, $05, $05, $05, $05, $02, $07, $06, $02, $05, $05, $05
        byte $02, $06, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $08, $08, $05, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $05, $08, $08, $05, $05, $05, $05
        byte $05, $02, $08, $07, $02, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05, $05, $05, $02, $05, $02, $05, $05, $05, $05
        byte $05, $05, $05, $02, $05, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $05, $05, $02, $05, $05, $05
        byte $05, $05, $05, $02, $05, $02, $02, $05, $02, $05, $02, $05, $05, $05, $05, $05, $05, $05, $02, $05, $02, $05, $05, $02
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $08, $08, $05, $05, $05, $05, $05, $02, $05, $02, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $02, $05, $05, $02, $06, $08, $08, $05, $02, $05, $05, $05, $05, $05, $05, $05, $05, $02
        byte $05, $08, $08, $05, $02, $05, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05, $05
        byte $05, $02, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $02, $02, $08, $07, $02, $05, $05, $05, $05
        byte $05, $05, $06, $08, $05, $05, $02, $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08
        byte $06, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $02, $05, $08, $08, $05, $02
        byte $05, $05, $05, $05, $05, $05, $02, $05, $08, $08, $05, $02, $05, $05, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05
        byte $02, $08, $07, $02, $05, $05, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05, $05, $05, $05, $02, $07, $08, $07, $02
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $02, $06, $08, $08, $05
        byte $02, $08, $07, $02, $05, $05, $05, $05, $05, $05, $06, $08, $05, $05, $02, $06, $08, $06, $05, $05, $05, $05, $05, $05
        byte $05, $08, $08, $05, $05, $05, $05, $02, $02, $07, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $08
        byte $08, $02, $05, $02, $05, $08, $08, $05, $02, $05, $05, $05, $05, $02, $05, $08, $08, $05, $02, $05, $05, $05, $05, $05
        byte $05, $02, $08, $07, $02, $02, $02, $02, $02, $08, $07, $02, $05, $05, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05
        byte $05, $05, $05, $05, $02, $07, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05
        byte $05, $05, $05, $05, $02, $05, $08, $08, $05, $08, $07, $02, $05, $05, $05, $05, $05, $05, $06, $08, $05, $05, $02, $06
        byte $08, $02, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $05, $05, $02, $07, $08, $07, $02, $05, $05
        byte $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $02, $05, $08, $08, $05, $02, $05, $05, $02, $05, $08, $08
        byte $05, $02, $05, $05, $05, $05, $05, $05, $05, $02, $08, $08, $08, $08, $08, $08, $08, $08, $07, $02, $05, $05, $05, $05
        byte $05, $02, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $02, $07, $08, $07, $02, $05, $05, $05, $05, $05, $05
        byte $05, $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $02, $05, $08, $08, $08, $07, $02, $05, $05, $05, $05
        byte $05, $05, $06, $08, $05, $05, $02, $06, $08, $02, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $05
        byte $05, $05, $01, $07, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $02, $05, $08
        byte $08, $05, $02, $02, $05, $08, $08, $05, $02, $05, $05, $05, $05, $05, $05, $05, $05, $02, $07, $07, $07, $07, $07, $07
        byte $07, $07, $06, $02, $05, $05, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $07
        byte $08, $07, $02, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $05
        byte $08, $08, $07, $02, $05, $05, $05, $05, $05, $05, $06, $08, $05, $05, $02, $06, $08, $02, $05, $05, $05, $05, $05, $05
        byte $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $02, $07, $08, $07, $02, $05, $05, $05, $05, $05, $05, $02, $08
        byte $08, $02, $05, $05, $05, $05, $02, $05, $08, $08, $05, $05, $08, $08, $05, $02, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $02, $06, $06, $06, $06, $06, $06, $06, $06, $06, $02, $05, $05, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $02, $07, $08, $07, $02, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $02, $07, $08, $08, $05, $02, $05, $05, $05, $05, $05, $06, $08, $05, $05, $02, $06
        byte $08, $02, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $02, $07, $08, $07
        byte $02, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $05, $05, $02, $05, $08, $07, $07, $08, $05, $02, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $08, $08, $08, $08, $08, $08, $08, $07, $02, $05, $05, $05, $05
        byte $05, $02, $08, $07, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $02, $07, $08, $07, $05, $05, $05, $05
        byte $05, $05, $08, $08, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $07, $08, $07, $08, $08, $05, $05, $05, $05
        byte $05, $05, $06, $08, $05, $05, $02, $06, $08, $02, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $01, $07, $08, $07, $05, $05, $05, $05, $05, $05, $08, $08, $02, $05, $05, $05, $05, $05, $05
        byte $02, $05, $02, $02, $05, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $05, $08, $08, $06, $02, $02
        byte $02, $02, $02, $05, $05, $05, $05, $05, $05, $02, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08
        byte $02, $02, $07, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08
        byte $07, $02, $05, $08, $08, $08, $08, $08, $08, $08, $08, $08, $05, $05, $02, $06, $08, $02, $05, $05, $05, $05, $05, $05
        byte $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $07, $08, $08, $08, $08, $08, $08, $08, $08
        byte $08, $02, $05, $05, $05, $05, $05, $02, $05, $08, $07, $07, $08, $05, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $02, $05, $08, $08, $06, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $07, $06, $06, $06, $06
        byte $06, $06, $06, $06, $06, $06, $06, $08, $08, $02, $02, $06, $08, $08, $06, $06, $06, $06, $08, $08, $06, $06, $06, $06
        byte $06, $06, $06, $06, $06, $06, $06, $08, $08, $06, $02, $05, $08, $08, $07, $06, $06, $06, $07, $08, $05, $05, $02, $06
        byte $08, $02, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02
        byte $07, $08, $08, $06, $06, $06, $06, $08, $08, $02, $05, $05, $05, $05, $02, $06, $08, $08, $02, $05, $08, $08, $06, $02
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $05, $08, $08, $06, $02, $05, $05, $05, $05, $05, $05, $05
        byte $05, $02, $08, $07, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $06, $08, $08, $02, $02, $06, $08, $07, $02
        byte $02, $02, $08, $08, $02, $02, $02, $02, $02, $02, $02, $02, $02, $03, $02, $02, $08, $08, $06, $02, $05, $08, $08, $05
        byte $02, $02, $05, $08, $05, $05, $02, $06, $08, $02, $05, $05, $05, $05, $05, $05, $02, $08, $08, $02, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $02, $06, $08, $07, $02, $02, $02, $08, $08, $02, $05, $05, $05, $02, $06, $08
        byte $08, $05, $02, $02, $05, $08, $08, $06, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $03, $02, $08, $08
        byte $06, $02, $05, $05, $05, $05, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02
        byte $07, $08, $02, $05, $02, $06, $08, $07, $02, $02, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $02, $08, $07, $02, $02, $05, $08, $08, $05, $02, $06, $08, $05, $05, $02, $06, $08, $02, $05, $05, $05, $05, $05, $05
        byte $02, $07, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $07, $08, $07, $02, $02, $08
        byte $08, $02, $05, $05, $02, $06, $08, $08, $02, $03, $05, $05, $02, $05, $08, $08, $06, $02, $05, $05, $05, $05, $05, $05
        byte $05, $05, $03, $02, $02, $02, $02, $08, $08, $06, $02, $05, $05, $05, $05, $05, $05, $02, $08, $07, $02, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $02, $06, $08, $02, $05, $05, $02, $06, $08, $07, $02, $08, $08, $02, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $07, $02, $05, $02, $05, $08, $08, $06, $05, $08, $05, $05, $02, $06
        byte $08, $02, $05, $05, $05, $05, $05, $05, $05, $02, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $02, $06, $08, $07, $02, $08, $08, $02, $05, $02, $06, $08, $08, $02, $03, $05, $05, $05, $05, $02, $02, $08
        byte $08, $06, $02, $05, $05, $05, $05, $05, $05, $02, $06, $06, $06, $06, $06, $07, $08, $08, $06, $02, $05, $05, $05, $05
        byte $05, $02, $08, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $03, $02, $07, $08, $02, $05, $05, $05, $02, $06
        byte $08, $07, $07, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $07, $08, $07, $02, $05, $05, $02, $05
        byte $08, $08, $07, $08, $05, $05, $02, $06, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $06, $08, $07, $08, $08, $02, $02, $06, $08, $08, $02, $03
        byte $05, $05, $05, $05, $05, $05, $02, $02, $08, $08, $06, $02, $05, $05, $05, $05, $05, $02, $08, $08, $08, $08, $08, $08
        byte $08, $08, $07, $02, $05, $05, $05, $05, $05, $02, $08, $07, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $08
        byte $08, $06, $02, $05, $05, $05, $05, $02, $06, $08, $08, $08, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $07
        byte $08, $08, $02, $05, $05, $05, $05, $02, $02, $08, $08, $08, $05, $05, $02, $06, $08, $02, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $07, $08, $08
        byte $08, $02, $06, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $08, $08, $06, $02, $05, $05, $05
        byte $05, $02, $02, $05, $05, $05, $05, $05, $05, $05, $02, $03, $05, $05, $05, $05, $05, $02, $08, $08, $08, $08, $08, $08
        byte $08, $08, $08, $08, $08, $08, $08, $08, $06, $02, $05, $05, $05, $05, $05, $05, $02, $06, $08, $08, $08, $08, $08, $08
        byte $08, $08, $08, $08, $08, $08, $08, $08, $08, $02, $05, $05, $05, $05, $05, $05, $02, $02, $08, $08, $05, $05, $02, $06
        byte $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $02, $06, $08, $08, $05, $08, $08, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $02, $02, $08, $08, $05, $05, $05, $05, $05, $02, $07, $08, $08, $08, $08, $08, $08, $08, $07, $02, $05, $05, $05, $05
        byte $05, $02, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $06, $02, $05, $05, $05, $05, $05, $05, $05
        byte $05, $02, $06, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $02, $05, $05, $05, $05, $05, $05, $05
        byte $05, $02, $02, $07, $02, $05, $05, $05, $07, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $06, $06, $02, $07, $02, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $07, $02, $05, $05, $05, $05, $02, $07, $07, $07, $07, $07, $07
        byte $07, $07, $06, $02, $05, $05, $05, $05, $05, $05, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $05, $05, $05, $02, $02, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02
        byte $02, $05, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $02, $05, $05, $05, $05
        byte $05, $05, $02, $02, $02, $02, $02, $02, $02, $02, $02, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
        byte $05, $05, $05, $05, $05, $05

    ChipGracey
'------------------------ 256 color BMP Image Data below ---------------------------
        byte $42, $4D, $B6, $10, $00, $00, $00, $00, $00, $00, $36, $04, $00, $00, $28, $00, $00, $00, $40, $00, $00, $00, $32, $00
        byte $00, $00, $01, $00, $08, $00, $00, $00, $00, $00, $80, $0C, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $06, $03, $01, $00, $06, $07, $09, $00, $07, $08, $0A, $00, $0B, $04
        byte $02, $00, $09, $0B, $0D, $00, $0B, $0E, $12, $00, $0D, $11, $15, $00, $0E, $13, $1A, $00, $14, $08, $04, $00, $11, $0E
        byte $17, $00, $11, $15, $1A, $00, $0E, $14, $24, $00, $14, $1A, $25, $00, $15, $1C, $36, $00, $1B, $23, $2C, $00, $1D, $26
        byte $35, $00, $26, $0E, $06, $00, $2C, $12, $08, $00, $34, $0F, $05, $00, $39, $13, $08, $00, $3B, $1F, $12, $00, $21, $26
        byte $2B, $00, $23, $29, $34, $00, $2B, $33, $3B, $00, $17, $1F, $43, $00, $19, $1E, $55, $00, $1B, $24, $45, $00, $1B, $26
        byte $58, $00, $23, $2A, $49, $00, $23, $2D, $5C, $00, $2E, $3A, $4D, $00, $2B, $37, $56, $00, $36, $3E, $47, $00, $34, $3B
        byte $5B, $00, $21, $2A, $65, $00, $28, $34, $69, $00, $2C, $39, $79, $00, $33, $3A, $69, $00, $32, $3D, $78, $00, $3B, $44
        byte $4C, $00, $3C, $44, $56, $00, $38, $44, $6B, $00, $39, $45, $77, $00, $48, $18, $08, $00, $58, $1A, $07, $00, $5B, $21
        byte $0B, $00, $47, $28, $22, $00, $64, $1F, $06, $00, $70, $1C, $04, $00, $68, $23, $09, $00, $68, $2E, $11, $00, $64, $35
        byte $1B, $00, $78, $26, $07, $00, $79, $32, $0B, $00, $74, $35, $13, $00, $69, $30, $2B, $00, $67, $3D, $3A, $00, $7A, $36
        byte $39, $00, $4C, $38, $41, $00, $5E, $43, $30, $00, $40, $47, $4C, $00, $45, $4D, $56, $00, $49, $56, $5F, $00, $43, $47
        byte $68, $00, $43, $4A, $77, $00, $4C, $58, $66, $00, $47, $53, $79, $00, $54, $5D, $66, $00, $54, $54, $74, $00, $59, $62
        byte $6B, $00, $5C, $68, $71, $00, $63, $6D, $78, $00, $69, $73, $7B, $00, $75, $65, $63, $00, $77, $6F, $74, $00, $76, $78
        byte $7C, $00, $37, $46, $86, $00, $3D, $4B, $92, $00, $43, $4D, $83, $00, $42, $4E, $99, $00, $4B, $57, $88, $00, $4B, $5A
        byte $98, $00, $51, $5F, $9A, $00, $49, $5A, $A6, $00, $53, $5B, $B3, $00, $4E, $62, $8D, $00, $54, $61, $87, $00, $59, $67
        byte $99, $00, $5F, $70, $9D, $00, $4F, $61, $A0, $00, $4D, $60, $B1, $00, $56, $66, $A7, $00, $59, $69, $B5, $00, $5E, $74
        byte $A4, $00, $7A, $5A, $80, $00, $64, $6B, $88, $00, $67, $66, $92, $00, $6E, $7A, $88, $00, $6C, $77, $97, $00, $78, $66
        byte $85, $00, $78, $6B, $9C, $00, $77, $7E, $84, $00, $74, $7C, $9B, $00, $61, $6D, $A8, $00, $60, $6D, $B7, $00, $67, $76
        byte $A8, $00, $67, $77, $B6, $00, $74, $7C, $A4, $00, $73, $7F, $B5, $00, $68, $6B, $C4, $00, $6B, $7A, $C5, $00, $74, $7E
        byte $CA, $00, $7A, $7D, $D0, $00, $7D, $84, $8A, $00, $7E, $8B, $96, $00, $6E, $83, $B6, $00, $78, $84, $AD, $00, $78, $87
        byte $B9, $00, $7C, $92, $BB, $00, $6E, $82, $C3, $00, $78, $88, $C8, $00, $79, $88, $D1, $00, $7D, $92, $CA, $00, $7F, $90
        byte $D6, $00, $87, $2C, $07, $00, $8C, $33, $0A, $00, $8A, $3D, $16, $00, $96, $2E, $06, $00, $99, $38, $0A, $00, $97, $3E
        byte $10, $00, $83, $3F, $29, $00, $A7, $3B, $0A, $00, $AE, $3D, $12, $00, $B3, $3E, $09, $00, $89, $43, $11, $00, $9A, $45
        byte $16, $00, $8A, $44, $27, $00, $9B, $4C, $25, $00, $9F, $4E, $37, $00, $97, $58, $39, $00, $AB, $42, $0D, $00, $A9, $48
        byte $13, $00, $A9, $51, $1C, $00, $B6, $45, $0C, $00, $B4, $4B, $12, $00, $BA, $54, $17, $00, $AA, $57, $25, $00, $A7, $5B
        byte $32, $00, $BB, $4C, $20, $00, $AC, $60, $2C, $00, $AA, $62, $35, $00, $BD, $63, $23, $00, $84, $5B, $52, $00, $99, $56
        byte $49, $00, $93, $64, $4C, $00, $9E, $6D, $57, $00, $9E, $72, $5B, $00, $8C, $6B, $7A, $00, $9A, $7F, $6D, $00, $95, $7E
        byte $74, $00, $A6, $6A, $4C, $00, $A5, $76, $5E, $00, $A5, $7C, $64, $00, $C3, $4A, $0C, $00, $C1, $4F, $13, $00, $C4, $54
        byte $0E, $00, $C3, $58, $15, $00, $C5, $64, $1F, $00, $C6, $67, $22, $00, $C4, $7B, $57, $00, $8D, $80, $7D, $00, $95, $82
        byte $7C, $00, $82, $88, $8D, $00, $84, $8D, $93, $00, $85, $8F, $99, $00, $89, $8F, $94, $00, $87, $90, $97, $00, $85, $91
        byte $9B, $00, $8A, $91, $96, $00, $8C, $94, $9B, $00, $8F, $98, $9F, $00, $99, $8A, $89, $00, $95, $93, $96, $00, $90, $96
        byte $9B, $00, $92, $99, $9E, $00, $9C, $9A, $9D, $00, $83, $8A, $A2, $00, $82, $8D, $BB, $00, $8D, $98, $A4, $00, $84, $93
        byte $BE, $00, $93, $9C, $A3, $00, $93, $9E, $A8, $00, $9A, $9E, $A2, $00, $98, $9E, $A9, $00, $95, $9C, $BE, $00, $97, $A0
        byte $A6, $00, $96, $A1, $AA, $00, $99, $A1, $A6, $00, $9B, $A5, $AB, $00, $9F, $A8, $AE, $00, $9D, $A8, $B2, $00, $B5, $95
        byte $81, $00, $A1, $A9, $AE, $00, $A3, $AC, $B3, $00, $A3, $AF, $B8, $00, $A8, $AF, $B4, $00, $A7, $B2, $BA, $00, $BE, $AF
        byte $A5, $00, $81, $8E, $CB, $00, $84, $8D, $D5, $00, $87, $97, $C8, $00, $88, $98, $D7, $00, $92, $9E, $DA, $00, $93, $9F
        byte $E1, $00, $8B, $A1, $CB, $00, $8D, $A4, $D3, $00, $96, $A6, $DB, $00, $9C, $B2, $DF, $00, $8F, $A1, $E0, $00, $9C, $A9
        byte $E2, $00, $9F, $B0, $E7, $00, $A3, $AB, $CE, $00, $A0, $AA, $DD, $00, $AB, $B8, $C1, $00, $A7, $B3, $DB, $00, $B2, $BD
        byte $C4, $00, $A3, $AD, $E4, $00, $A9, $B3, $E7, $00, $B2, $BA, $EA, $00, $BC, $C2, $EE, $00, $CE, $A4, $89, $00, $C4, $C8
        byte $C8, $00, $C5, $C8, $D7, $00, $C0, $C6, $EE, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF
        byte $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $84, $91
        byte $8E, $84, $92, $90, $90, $A7, $90, $86, $90, $84, $90, $A7, $81, $A4, $A7, $A7, $81, $90, $A7, $A7, $91, $92, $93, $88
        byte $34, $81, $AA, $E9, $E9, $E9, $E9, $E8, $E7, $9B, $36, $37, $14, $7E, $81, $90, $A8, $31, $84, $91, $84, $7D, $8D, $90
        byte $90, $92, $86, $90, $90, $90, $90, $8E, $35, $90, $81, $84, $84, $81, $90, $91, $81, $90, $90, $92, $90, $A7, $A7, $91
        byte $91, $84, $A7, $A7, $84, $92, $A7, $A4, $81, $A4, $A7, $92, $91, $84, $89, $8C, $2F, $D0, $D9, $D3, $BC, $76, $6D, $6A
        byte $61, $CA, $8B, $13, $37, $2C, $7D, $84, $90, $35, $84, $90, $8D, $7D, $84, $90, $90, $90, $90, $90, $90, $91, $90, $92
        byte $32, $84, $90, $7D, $84, $81, $92, $81, $92, $91, $90, $90, $90, $A7, $A7, $84, $92, $84, $90, $A6, $91, $86, $A7, $A7
        byte $80, $90, $A7, $81, $80, $90, $8F, $3C, $60, $D3, $D3, $D3, $D3, $BC, $76, $6B, $58, $41, $A0, $83, $2D, $12, $32, $7D
        byte $8E, $35, $81, $91, $80, $7D, $84, $91, $90, $90, $8D, $90, $91, $86, $91, $A4, $2C, $84, $84, $84, $81, $81, $8E, $8D
        byte $90, $92, $91, $92, $90, $A4, $90, $8E, $90, $8E, $84, $A7, $86, $84, $A7, $A6, $8D, $A4, $90, $35, $A7, $A7, $90, $0A
        byte $6B, $D3, $D3, $D3, $D3, $BC, $76, $6B, $53, $4F, $26, $99, $34, $2C, $11, $7D, $81, $35, $7D, $84, $8E, $35, $8E, $91
        byte $91, $91, $84, $91, $86, $91, $90, $A7, $2D, $8D, $81, $8D, $81, $7E, $8E, $8E, $90, $92, $92, $92, $90, $A9, $84, $A6
        byte $A7, $90, $81, $A4, $92, $84, $A4, $A7, $84, $90, $98, $30, $A7, $92, $A4, $38, $6B, $D3, $D3, $D3, $D3, $BC, $76, $68
        byte $52, $2B, $24, $39, $88, $35, $09, $32, $7D, $35, $7D, $8E, $80, $35, $84, $8D, $91, $90, $91, $86, $91, $90, $91, $91
        byte $36, $81, $81, $8D, $81, $82, $93, $8E, $84, $90, $91, $90, $91, $A7, $8E, $A7, $90, $92, $81, $90, $A7, $84, $A7, $A6
        byte $84, $90, $84, $7D, $91, $A7, $90, $8A, $79, $D3, $76, $75, $75, $75, $6A, $58, $4F, $26, $1E, $1C, $2E, $35, $14, $11
        byte $7D, $35, $35, $81, $7D, $7D, $84, $84, $90, $91, $84, $91, $8D, $91, $8D, $90, $88, $35, $81, $81, $81, $88, $4B, $8E
        byte $8E, $91, $90, $98, $90, $92, $91, $8E, $8D, $91, $84, $84, $A7, $90, $90, $A9, $91, $90, $84, $35, $A7, $91, $95, $68
        byte $D3, $75, $6C, $63, $60, $60, $60, $57, $43, $26, $1D, $19, $0D, $32, $2D, $09, $2D, $32, $35, $7D, $35, $35, $81, $84
        byte $8D, $8E, $84, $8D, $8D, $8D, $84, $91, $84, $7E, $7D, $81, $8E, $8E, $49, $4A, $8E, $8D, $8E, $90, $92, $90, $A7, $81
        byte $8D, $8D, $91, $81, $A7, $92, $90, $A7, $90, $86, $8D, $7E, $A7, $A5, $5F, $D3, $75, $6C, $63, $6A, $76, $76, $6D, $6A
        byte $57, $40, $20, $0E, $0C, $14, $32, $14, $11, $32, $30, $35, $32, $35, $80, $84, $84, $84, $81, $84, $84, $8D, $84, $91
        byte $8E, $81, $35, $81, $8E, $94, $4C, $49, $4C, $8E, $8E, $8E, $92, $92, $A7, $7D, $8D, $8D, $92, $8D, $A7, $91, $91, $A7
        byte $90, $92, $84, $7F, $A7, $9A, $7B, $BC, $63, $60, $76, $76, $76, $79, $76, $6B, $58, $58, $29, $20, $06, $09, $32, $2C
        byte $01, $2D, $2D, $35, $30, $35, $7E, $81, $84, $81, $81, $81, $8E, $81, $81, $81, $8E, $93, $93, $8F, $93, $B6, $4C, $4C
        byte $72, $AD, $94, $8E, $8E, $91, $81, $81, $8E, $90, $90, $90, $92, $92, $86, $A7, $92, $90, $8E, $87, $A7, $78, $76, $63
        byte $63, $76, $BE, $D3, $D3, $D1, $79, $68, $58, $59, $51, $29, $1D, $02, $2E, $2D, $01, $2C, $2E, $2D, $2D, $35, $35, $7E
        byte $81, $81, $7D, $81, $81, $81, $81, $81, $8E, $93, $93, $97, $B7, $BD, $66, $66, $72, $72, $73, $9D, $92, $8F, $8F, $81
        byte $8D, $91, $91, $8D, $8E, $90, $92, $90, $A7, $A5, $81, $87, $8C, $79, $63, $76, $76, $77, $D7, $D7, $D3, $BC, $76, $6A
        byte $6A, $6A, $57, $43, $40, $0D, $14, $2D, $04, $11, $2D, $32, $2C, $30, $35, $35, $7E, $81, $7E, $81, $81, $81, $81, $81
        byte $8E, $93, $A1, $C0, $BD, $BD, $72, $72, $72, $AE, $AE, $73, $AB, $97, $8E, $8F, $8D, $8D, $91, $8E, $84, $91, $91, $A7
        byte $90, $A8, $80, $36, $9E, $6C, $D3, $D3, $77, $D3, $D3, $D9, $BE, $76, $6A, $6A, $74, $5E, $56, $57, $43, $29, $12, $35
        byte $09, $09, $2D, $2D, $2C, $2D, $30, $35, $7D, $7E, $7E, $7E, $81, $81, $81, $81, $8E, $B6, $C9, $BD, $BD, $BD, $AD, $AE
        byte $72, $AE, $AE, $72, $73, $BD, $9D, $84, $92, $8E, $8F, $8D, $81, $91, $92, $A7, $A9, $A4, $37, $81, $64, $D3, $D3, $D7
        byte $D3, $D8, $D9, $D9, $D5, $D4, $D3, $6F, $68, $5C, $52, $58, $5E, $43, $1D, $7F, $04, $09, $11, $2E, $2C, $2C, $2D, $35
        byte $7D, $35, $7E, $81, $81, $88, $88, $9A, $BF, $C5, $BF, $B4, $B4, $B4, $AE, $AE, $AE, $AD, $AE, $AD, $AE, $B5, $B2, $AD
        byte $94, $8D, $8F, $8E, $84, $90, $91, $92, $90, $A7, $2D, $89, $79, $D3, $D7, $D7, $D7, $D9, $7A, $D2, $D2, $71, $70, $6E
        byte $55, $52, $5C, $5E, $76, $51, $2B, $7F, $01, $09, $11, $33, $14, $2C, $2C, $30, $35, $7F, $88, $88, $96, $A3, $B8, $BD
        byte $BD, $BF, $B4, $B2, $AF, $B4, $AE, $AD, $72, $72, $72, $72, $72, $BD, $AE, $AE, $B2, $AC, $96, $8E, $8D, $90, $90, $92
        byte $91, $91, $32, $65, $D3, $D3, $D9, $D7, $6B, $79, $70, $70, $6F, $7A, $6F, $55, $50, $23, $52, $74, $79, $58, $2A, $3B
        byte $01, $09, $11, $32, $11, $14, $2C, $36, $8A, $93, $8F, $A3, $C2, $BD, $BD, $B4, $BD, $BD, $B4, $B4, $AF, $B4, $AD, $72
        byte $72, $72, $66, $72, $72, $BF, $B1, $AE, $B1, $B2, $BD, $AC, $85, $86, $90, $90, $8D, $91, $3A, $79, $D3, $D9, $D9, $D3
        byte $77, $76, $D3, $D3, $D3, $6D, $BE, $74, $5C, $58, $2A, $6A, $76, $6B, $41, $40, $05, $09, $12, $2E, $14, $12, $14, $88
        byte $93, $9C, $C7, $C9, $C5, $C0, $BD, $B4, $BD, $BD, $BD, $B4, $B4, $B4, $AD, $72, $72, $72, $72, $72, $72, $BF, $BF, $AE
        byte $B4, $B4, $B4, $B2, $B8, $9C, $93, $90, $8D, $90, $64, $76, $D3, $D9, $D9, $D8, $D7, $D3, $D3, $76, $BC, $75, $75, $51
        byte $41, $51, $52, $58, $7B, $6B, $43, $41, $17, $04, $11, $2C, $14, $15, $8C, $9F, $C0, $C9, $C9, $C7, $C7, $C5, $BF, $BD
        byte $BF, $BF, $BD, $B4, $AF, $B4, $72, $AD, $AD, $AE, $72, $72, $AE, $BF, $BF, $B3, $B1, $B4, $B4, $B4, $BF, $C0, $BD, $B7
        byte $A2, $92, $6B, $76, $D3, $D9, $DC, $D9, $D4, $D9, $D5, $D4, $D9, $D3, $52, $24, $27, $5C, $6B, $7B, $D1, $6B, $51, $41
        byte $22, $34, $AC, $BA, $C1, $CF, $C9, $C5, $C5, $C9, $C9, $C7, $BF, $BF, $BF, $BD, $BF, $BF, $BF, $B4, $B4, $BF, $4C, $72
        byte $AE, $AE, $72, $AE, $AE, $B4, $BF, $B4, $B4, $B4, $B4, $B4, $BF, $BF, $C7, $C7, $C5, $BD, $6B, $79, $D4, $D4, $DC, $E3
        byte $D5, $DB, $D9, $6F, $D4, $E3, $D4, $25, $4E, $50, $D4, $D4, $79, $6B, $51, $41, $45, $E0, $C9, $C7, $C9, $C7, $C9, $C5
        byte $C5, $C5, $C5, $C0, $BF, $BD, $BF, $BD, $BD, $BF, $BF, $BF, $BF, $C7, $4C, $72, $AE, $AE, $AE, $B1, $B3, $B3, $B4, $B4
        byte $B1, $B4, $B4, $B4, $B4, $B4, $C5, $C7, $C5, $BB, $6B, $D4, $D4, $D6, $E4, $E5, $E3, $DC, $D5, $D5, $DC, $E5, $7A, $54
        byte $52, $5C, $D4, $D4, $7A, $6F, $52, $41, $40, $CF, $C7, $C5, $C9, $C7, $C7, $C9, $C7, $C5, $C5, $BF, $BF, $BF, $BF, $BF
        byte $BD, $BF, $BF, $BF, $BF, $BF, $72, $72, $AE, $AE, $B4, $B4, $B4, $AE, $AE, $AE, $AE, $B1, $B4, $B5, $BF, $BF, $C5, $C7
        byte $C3, $76, $6B, $D4, $D4, $D6, $E5, $E5, $E4, $E3, $DC, $D4, $D4, $DC, $6F, $4D, $4E, $7A, $D4, $D2, $7A, $6F, $5C, $2B
        byte $40, $51, $CF, $CC, $CD, $C9, $C9, $C9, $C9, $C5, $C5, $C5, $C0, $C5, $BF, $BD, $BD, $BF, $C5, $BF, $BF, $BF, $AD, $AE
        byte $AE, $B3, $B5, $BD, $B4, $72, $72, $AD, $AE, $AE, $B4, $B4, $B5, $BF, $C5, $BF, $D5, $76, $6F, $D2, $D5, $E3, $E4, $DC
        byte $E3, $E4, $DC, $D4, $D4, $DC, $5D, $4D, $5C, $79, $D4, $D4, $7A, $6F, $5C, $4F, $41, $23, $BD, $CF, $CF, $CF, $CD, $CD
        byte $CC, $C9, $C7, $C5, $C5, $C7, $BF, $BD, $BF, $BF, $BF, $BF, $BF, $BF, $B4, $B4, $B3, $AE, $B4, $B4, $AE, $AE, $72, $72
        byte $AE, $AE, $AE, $B1, $B4, $BF, $C4, $BD, $D9, $43, $70, $D4, $DC, $DC, $DC, $E4, $E4, $E3, $DC, $D4, $D4, $D4, $5D, $4D
        byte $5C, $79, $D4, $D4, $D4, $6F, $5D, $51, $26, $41, $67, $E0, $CF, $CF, $CF, $CC, $CC, $C9, $C7, $C7, $C7, $C7, $BF, $BF
        byte $BF, $BD, $BF, $BF, $BF, $BF, $C6, $C7, $B9, $B3, $B3, $AE, $AE, $AE, $AD, $AD, $AE, $AE, $AE, $AE, $B1, $B4, $B9, $BC
        byte $76, $1D, $70, $D9, $DC, $DD, $E4, $E5, $E4, $DC, $DC, $D9, $D4, $7C, $5B, $4E, $5C, $D4, $D4, $D4, $D4, $79, $6B, $53
        byte $1D, $1B, $41, $E2, $E0, $CF, $CD, $CC, $CC, $C9, $C7, $C7, $C7, $C5, $C5, $BF, $BF, $BD, $BD, $BF, $BF, $BF, $C7, $C7
        byte $B9, $B4, $B3, $AE, $AD, $AD, $AE, $B4, $B4, $B4, $B4, $B4, $AE, $AE, $B3, $D3, $2A, $1D, $7A, $E1, $DA, $E1, $D9, $DF
        byte $D5, $79, $D5, $D9, $D9, $D4, $5C, $4D, $BC, $D4, $D4, $D3, $6B, $5C, $6B, $5C, $0E, $05, $1C, $CF, $CF, $CF, $CC, $C9
        byte $C9, $C9, $C9, $C7, $C7, $C7, $C7, $C5, $C5, $BF, $C7, $C7, $C0, $C5, $BF, $BF, $B4, $B4, $B4, $B4, $B4, $AE, $AD, $BF
        byte $BF, $BF, $B4, $B4, $B4, $B4, $BF, $D3, $0E, $10, $79, $D3, $D9, $54, $E1, $63, $67, $DE, $79, $E1, $DC, $DC, $5C, $2B
        byte $5C, $E1, $6C, $6C, $6B, $4D, $58, $58, $0E, $0B, $1A, $C9, $CD, $CD, $C9, $CC, $CC, $C9, $C9, $C9, $C7, $C7, $C7, $C7
        byte $C7, $C7, $CD, $CC, $C7, $C7, $BF, $B4, $B4, $B9, $B4, $BF, $B5, $B3, $AE, $BF, $BF, $BF, $B9, $B5, $B4, $B4, $B9, $79
        byte $03, $10, $79, $79, $D3, $76, $58, $42, $20, $5C, $6B, $D3, $D9, $DC, $78, $2B, $4D, $BD, $29, $1F, $62, $51, $51, $2B
        byte $0E, $07, $1E, $BD, $CC, $C7, $C7, $CD, $CF, $CC, $C9, $C7, $C7, $C7, $C7, $C7, $C7, $C7, $CC, $CC, $C9, $C7, $BF, $B4
        byte $B9, $B9, $B4, $B4, $B4, $B3, $B4, $B9, $B4, $BF, $BF, $B4, $B4, $B4, $C7, $22, $02, $0B, $79, $76, $2B, $2A, $43, $2B
        byte $2B, $4D, $6A, $76, $D9, $D9, $D4, $79, $5A, $25, $51, $5C, $5C, $68, $2B, $2A, $0D, $07, $0B, $BD, $CC, $BF, $C7, $CC
        byte $CC, $CF, $CC, $C9, $C7, $C7, $C7, $C7, $C5, $C7, $C9, $C9, $C7, $C5, $B4, $B4, $B4, $B4, $B3, $B3, $AE, $B3, $B3, $B4
        byte $B4, $B4, $B4, $B4, $B4, $BF, $44, $06, $02, $03, $6B, $79, $79, $58, $58, $6A, $6A, $6A, $76, $D3, $D9, $DF, $D9, $79
        byte $52, $2A, $20, $22, $20, $20, $20, $24, $08, $06, $05, $47, $CF, $C7, $C7, $C9, $C9, $CC, $CD, $CC, $CC, $C9, $C9, $C7
        byte $C7, $C7, $C5, $C5, $C7, $BF, $B0, $B4, $B4, $AE, $B0, $AE, $AE, $AE, $B3, $B3, $B4, $AE, $72, $AE, $AE, $B4, $07, $02
        byte $05, $05, $41, $79, $D4, $D9, $E3, $E5, $EA, $E6, $E4, $DC, $D9, $DC, $DC, $DF, $D3, $6A, $5C, $58, $51, $20, $22, $24
        byte $06, $0B, $0B, $16, $CF, $C9, $C9, $C9, $C9, $CC, $CF, $CF, $CC, $CC, $C9, $C7, $CC, $C7, $C7, $BF, $BF, $BF, $AE, $B3
        byte $B3, $AE, $B4, $B0, $AE, $66, $72, $B0, $AE, $72, $66, $66, $AD, $AE, $07, $05, $05, $06, $10, $D3, $D4, $D9, $DC, $E3
        byte $E4, $E3, $E3, $E3, $DC, $E3, $D9, $D9, $D4, $D2, $79, $6F, $5D, $53, $2B, $1D, $05, $03, $06, $07, $BD, $C7, $C7, $C9
        byte $C9, $CC, $CC, $CC, $CC, $C9, $C9, $C7, $C7, $C7, $C5, $BF, $BF, $BF, $AD, $B3, $B0, $B3, $B4, $AE, $B3, $72, $66, $AE
        byte $72, $72, $72, $AE, $AE, $B4, $16, $05, $05, $06, $17, $D3, $D9, $E3, $DC, $E4, $E4, $E4, $E4, $E3, $E3, $DC, $D9, $D4
        byte $D4, $7A, $79, $6F, $69, $5C, $2B, $0D, $05, $03, $0B, $16, $BF, $C7, $C4, $C7, $C7, $CC, $CC, $CC, $C9, $C7, $C7, $C7
        byte $C7, $C5, $BF, $BF, $BF, $BF, $AE, $B4, $B4, $B3, $B4, $B3, $B0, $AE, $AD, $AE, $AD, $72, $AD, $AE, $B3, $BF, $3D, $05
        byte $07, $0B, $1F, $7B, $D4, $DC, $E3, $E3, $E4, $E5, $E4, $E4, $DC, $DC, $D4, $7C, $D4, $6B, $69, $6B, $6B, $52, $2B, $0B
        byte $06, $05, $07, $18, $C0, $C7, $C5, $C7, $C7, $CC, $CC, $C9, $C7, $C7, $C7, $BF, $BF, $BF, $BF, $B4, $B5, $B4, $B4, $B9
        byte $BF, $B8, $B8, $B3, $B3, $AE, $AE, $AE, $B4, $B0, $AD, $72, $B0, $C1, $18, $03, $0B, $0F, $40, $7B, $D4, $DC, $DC, $DC
        byte $E5, $E5, $E5, $E4, $DC, $D9, $D4, $79, $4D, $25, $24, $25, $24, $27, $24, $08, $06, $05, $0B, $17, $BD, $C7, $C7, $C7
        byte $C7, $C7, $C7, $C7, $C7, $C7, $C5, $BF, $BF, $BD, $BF, $BD, $B4, $B4, $B9, $C6, $BF, $B9, $B4, $B4, $B4, $B4, $B3, $B3
        byte $B4, $B3, $AE, $AD, $B3, $BF, $16, $03, $07, $0F, $43, $D3, $D4, $D9, $D9, $E3, $E4, $E5, $E4, $D9, $D4, $79, $79, $2B
        byte $24, $1C, $1B, $0C, $0C, $0E, $1B, $06, $05, $07, $0B, $3E, $BF, $C5, $C7, $C7, $C8, $C7, $C7, $C7, $C7, $C7, $BF, $BD
        byte $B4, $AE, $B2, $B4, $B4, $B4, $BF, $BF, $B8, $B4, $B8, $B4, $BF, $B4, $B4, $B4, $BF, $B4, $B4, $B4, $B4, $BF, $0F, $06
        byte $06, $0D, $20, $7A, $7C, $D4, $D4, $D9, $D9, $D4, $D3, $D3, $79, $6F, $5C, $24, $23, $0E, $08, $0C, $0E, $0E, $0C, $07
        byte $0B, $07, $0B, $3E, $C7, $C9, $C7, $C7, $C8, $C7, $C9, $C7, $C7, $C7, $BF, $BD, $B4, $B4, $B4, $B4, $AE, $B2, $BF, $B9
        byte $B4, $B3, $B4, $B4, $B4, $B4, $B4, $BF, $BF, $B9, $BF, $B4, $B4, $B4, $18, $06, $0B, $0B, $0D, $50, $78, $7A, $D4, $D4
        byte $79, $D3, $D1, $D3, $5D, $54, $2A, $25, $1B, $0C, $0D, $0D, $0C, $08, $06, $05, $07, $0B, $0B, $46, $CF, $C8, $C7, $CC
        byte $C8, $CC, $CC, $C7, $C7, $BF, $BF, $BF, $B4, $B4, $BF, $B5, $B9, $B4, $B9, $B4, $B0, $AE, $AD, $B0, $B3, $B4, $B4, $B9
        byte $BF, $BF, $C7, $C6, $B9, $B4, $0B, $05, $07, $07, $0B, $1E, $25, $6F, $6F, $6F, $5D, $5D, $6B, $6B, $54, $25, $1E, $1E
        byte $0D, $08, $06, $06, $06, $05, $02, $05, $05, $0B, $07, $72, $CF, $CC, $CB, $CC, $C8, $CC, $CC, $C7, $C6, $BF, $BF, $BF
        byte $B4, $B4, $B5, $BF, $C7, $C7, $B4, $B4, $B3, $B0, $AD, $AE, $B3, $B8, $B4, $BF, $BF, $BF, $BF, $C6, $B4, $66, $28, $06
        byte $06, $07, $0B, $0D, $1B, $54, $5D, $54, $4E, $4D, $24, $24, $19, $0E, $0D, $08, $07, $05, $06, $07, $0B, $0B, $0D, $07
        byte $05, $07, $17, $CF, $C9, $C8, $C7, $C7, $C7, $C9, $C7, $C7, $C7, $C7, $C7, $C7, $BF, $BF, $BF, $BF, $C7, $C7, $B0, $B3
        byte $B9, $B0, $AD, $AE, $B4, $B9, $BF, $C6, $C7, $BF, $B9, $C6, $B4, $49, $28, $06, $08, $07, $0B, $0D, $0D, $1B, $24, $1C
        byte $1B, $1D, $10, $0D, $0D, $0D, $0B, $06, $06, $06, $0B, $0D, $0B, $0B, $08, $06, $07, $0D, $3E, $CF, $C7, $C7, $C7, $C7
        byte $C7, $C8, $C7, $C7, $C8, $C8, $C7, $CB, $C7, $C6, $BF, $BF, $C4, $C7, $B0, $B3, $B9, $B3, $B3, $B3, $B3, $B8, $BF, $C6
        byte $C7, $C1, $C6, $CB, $C7, $C7, $BF, $17, $07, $06, $07, $0B, $0B, $08, $08, $06, $08, $0D, $10, $10, $0D, $0B, $06, $07
        byte $07, $08, $07, $07, $07, $05, $05, $07, $06, $0D, $44, $CC, $BF, $BF, $C7, $C7, $C7, $CC, $CC, $CC, $C8, $C7, $C7, $C7
        byte $C8, $C7, $BF, $B9, $BF, $BF, $B4, $B3, $B9, $B3, $B3, $B3, $B3, $B4, $BF, $C6, $C7, $C7, $CB, $CB, $C7, $C7, $C7, $62
        byte $08, $06, $07, $06, $0B, $08, $0D, $08, $06, $08, $0B, $0D, $0D, $0B, $0B, $08, $07, $07, $06, $06, $0B, $0B, $07, $08
        byte $08, $0D, $66, $C7, $C6, $C7, $C7, $C7, $CB, $CC, $CC, $CB, $C7, $C7, $C7, $C7, $C7, $C8, $C4, $BF, $BF, $BF, $B8, $B4
        byte $B8, $B3, $B3, $B3, $B3, $B9, $C6, $C7, $CB, $CB, $CB, $CB, $CB, $CB, $CC, $AF, $0F, $07, $06, $07, $07, $05, $06, $07
        byte $06, $05, $06, $0B, $0B, $0B, $0D, $07, $07, $07, $07, $08, $06, $08, $07, $0D, $0F, $17, $BF, $C7, $C7, $C7, $C7, $C7
        byte $CB, $CC, $CB, $C8, $C8, $C7, $CB, $C7, $CC, $CC, $C7, $BF, $BF, $BF, $B8, $B4, $B8, $B3, $B3, $B3, $B8, $B9, $C6, $C6
        byte $C7, $CB, $CB, $CC, $CC, $CC, $CC, $BD, $17, $0D, $06, $08, $07, $03, $05, $05, $05, $06, $06, $08, $0D, $10, $0D, $0B
        byte $0B, $07, $07, $05, $06, $0D, $0D, $0F, $17, $72, $C7, $C4, $C7, $C7, $C7, $C8, $CB, $CB, $CB, $CC, $CC, $C8, $CC, $CB
        byte $C7, $C7, $C6, $BD, $BF, $BF, $B4, $B4, $B3, $B8, $B3, $B3, $B8, $B9, $B9, $BF, $C7, $C7, $CE, $CF, $CC, $CC, $CC, $CF
        byte $62, $3E, $17, $06, $05, $05, $03, $06, $07, $06, $06, $08, $0D, $17, $0F, $08, $07, $0B, $0D, $0B, $0D, $0F, $0F, $21
        byte $AE, $C6, $C6, $C7, $C7, $C7, $C7, $C8, $C8, $CB, $C7, $CC, $CC, $CB, $CB, $C7, $C7, $C6, $C6, $BF, $C7, $C7, $B4, $B3
        byte $B4, $B4, $B3, $B4, $B3, $B4, $B9, $C6, $C7, $C7, $CB, $CC, $CC, $CC, $CE, $CF, $CC, $42, $47, $29, $0D, $05, $03, $03
        byte $06, $08, $05, $05, $06, $0B, $16, $0F, $0B, $07, $08, $0D, $0F, $17, $3E, $B5, $C7, $C4, $C7, $C4, $BF, $C4, $C7, $C7
        byte $C8, $C7, $C7, $CC, $CC, $CB, $C8, $C7, $CB, $C8, $C7, $C6, $C7, $C6, $B0, $B3, $B4, $B4, $B3, $B4, $B4, $B9, $B9, $BF
        byte $C7, $CB, $CC, $CC, $CC, $CC, $CC, $CF, $CC, $CF, $44, $49, $47, $42, $46, $16, $05, $05, $05, $03, $06, $0D, $0F, $0B
        byte $07, $07, $06, $0D, $18, $49, $C7, $C7, $C7, $BF, $B5, $B4, $B9, $BF, $C7, $CB, $C8, $C8, $CC, $CC, $CC, $CB, $CB, $CB
        byte $CC, $CB, $C8, $C7, $C7, $C6, $AD, $AE, $B8, $B8, $B4, $B9, $B8, $B9, $BF, $C6, $C7, $CC, $CC, $CC, $CB, $CB, $CC, $CC
        byte $CC, $CC, $CC, $72, $48, $49, $48, $47, $72, $06, $02, $05, $07, $0D, $0F, $0D, $08, $0D, $0D, $10, $72, $CB, $C7, $C7
        byte $C7, $C6, $BF, $B4, $BF, $C4, $C7, $C8, $CC, $CC, $CC, $CC, $CC, $CB, $CB, $C8, $CB, $CB, $CB, $C7, $C7, $C6, $B0, $AD
        byte $B3, $B4, $B4, $B9, $C6, $BF, $C6, $C7, $CB, $CC, $CC, $CC, $CC, $CC, $CC, $CC, $CC, $CC, $CB, $CC, $BF, $BF, $BF, $C7
        byte $66, $72, $21, $0D, $0D, $0D, $0D, $0F, $0F, $0D, $29, $BD, $BF, $C7, $C7, $C7, $C7, $C7, $C7, $C7, $C7, $C7, $C8, $CB
        byte $CC, $CC, $CC, $CC, $CC, $CC, $CC, $C8, $C7, $C8, $CB, $C7, $C6, $BF, $B3, $B3, $B3, $B3, $B9, $C4, $C7, $C6, $C6, $C7
        byte $CB, $CF, $CC, $CC, $CB, $CC, $CC, $CC, $CC, $CC, $CB, $CB, $C7, $C7, $C7, $C7, $BF, $73, $C5, $C7, $62, $47, $42, $3F
        byte $46, $72, $C7, $C7, $C7, $C7, $C7, $C8, $CC, $C7, $C7, $C7, $C7, $C7, $CB, $CC, $CC, $CC, $CC, $CC, $CB, $C8, $C8, $C7
        byte $C8, $C7, $C7, $C4, $BF, $BF

DAT
{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, publish, distribute, sub license, and/or sell copies of the Software, and to permit persons to whom the       │
│Software is furnished to do so, subject to the following conditions:                                                         │         
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}      
