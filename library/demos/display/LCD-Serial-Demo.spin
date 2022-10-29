{
    --------------------------------------------
    Filename: LCD-Serial-Demo.spin
    Description: Demo of the serial LCD driver
    Author: Jesse Burt
    Started Apr 29, 2006
    Updated Oct 29, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Serial_Lcd.spin,
        originally by Jon Williams, Jeff Martin.
}

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' -- User definable constants
    LCD_PIN     = 0
    LCD_BAUD    = 19_200                        ' 2400, 9600, 19200 (must match DIP switches)
    LCD_LINES   = 4
' --

OBJ

    lcd     : "display.lcd.serial"
    time    : "time"

PUB main{} | idx

    lcd.start(LCD_PIN, LCD_BAUD, LCD_LINES)     ' start lcd
    time.msleep(1_000)
    lcd.curs_mode(0)                            ' cursor off
    lcd.backlight_ena(true)                     ' backlight on (if available)
    lcd.def_chars(0, @bullet)                   ' create custom character 0
    lcd.clear{}
    lcd.strln(string("LCD DEBUG"))
    lcd.putchar(0)                              ' display custom bullet character
    lcd.strln(string(" Dec"))
    lcd.putchar(0)
    lcd.strln(string(" Hexs"))
    lcd.putchar(0)
    lcd.strln(string(" Bin"))

    repeat
        repeat idx from 0 to 255
            update_lcd(idx)
            time.msleep(200)                    ' pad with 1/5 sec

        lcd.disp_vis_ena(false)                 ' turn off the LCD for 2secs
        time.msleep(2000)
        lcd.disp_vis_ena(true)                  ' then back on - contents should still be there

        repeat idx from -255 to 0
            update_lcd(idx)
            time.msleep(200)

PRI update_lcd(value)

    lcd.pos_xy(12, 1)
    lcd.putdec(||value)

    lcd.pos_xy(12, 2)
    lcd.puthexs(value, 8)

    lcd.pos_xy(8, 3)
    lcd.putbin(value, 12)

DAT

    bullet  byte    %00000000
            byte    %00000100
            byte    %00001110
            byte    %00011111
            byte    %00001110
            byte    %00000100
            byte    %00000000
            byte    %00000000

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

