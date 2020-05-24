{
    --------------------------------------------
    Filename: LCD-Serial-Demo.spin
    Author: Jon Williams, Jeff Martin
    Modified by: Jesse Burt
    Description: Demo of the serial LCD driver
    Started Apr 29, 2006
    Updated May 24, 2020
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is a derivative of Serial_Lcd.spin,
        originally by Jon Williams, Jeff Martin.
    The existing header is preserved within the display
        driver, display.lcd.serial.spin.
}

CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' -- User definable constants
    LCD_PIN     = 0
    LCD_BAUD    = 19_200
    LCD_LINES   = 4
' --

OBJ

    lcd     : "display.lcd.serial"
    time    : "time"

PUB Main | idx

    if lcd.Start(LCD_PIN, LCD_BAUD, LCD_LINES)              ' start lcd
        lcd.CursorMode(0)                                   ' cursor off
        lcd.EnableBacklight(true)                           ' backlight on (if available)
        lcd.DefineChars(0, @bullet)                         ' create custom character 0
        lcd.Clear
        lcd.Str(string("LCD DEBUG", 13))
        lcd.Char(0)                                         ' display custom bullet character
        lcd.Str(string(" Dec", 13))
        lcd.Char(0)
        lcd.Str(string(" Hex", 13))
        lcd.Char(0)
        lcd.Str(string(" Bin"))

        repeat
            repeat idx from 0 to 255
                UpdateLCD(idx)
                time.MSleep(200)                            ' pad with 1/5 sec

            repeat idx from -255 to 0
                UpdateLCD(idx)
                time.MSleep(200)

PRI UpdateLCD(value)

    lcd.Position(12, 1)
    lcd.DecUns(||value, 8)

    lcd.Position(12, 2)
    lcd.Hex(value, 8)

    lcd.Position(8, 3)
    lcd.Bin(value, 12)

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
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
