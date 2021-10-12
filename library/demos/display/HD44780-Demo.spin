{
    --------------------------------------------
    Filename: HD44780-Demo.spin
    Author: Jesse Burt
    Description: Demo of the HD44780 LCD driver
    Copyright (c) 2021
    Started Sep 08, 2021
    Updated Oct 12, 2021
    See end of file for terms of use.
    --------------------------------------------
}
' Uncomment one of the lines below to choose the PASM or SPIN-based I2C engine
'   for the PCF8574 driver, utilized by the HD44780 driver.
#define PCF8574_PASM
'#define PCF8574_SPIN

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 100_000                       ' max is 100_000
    ADDR_BITS   = %111                          ' %000 (def) .. %111
' --

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    lcd : "display.lcd.hd44780.multi"

PUB Main{}

    setup{}
    lcd.reset{}

    lcd.enablebacklight(1)
    lcd.str(string("Testing 1 2 3"))
    time.sleep(2)
    lcd.clear{}
    lcd.str(string("Backlight"))
    repeat 10
        lcd.enablebacklight(0)
        time.msleep(100)
        lcd.enablebacklight(1)
        time.msleep(100)

    repeat

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if lcd.startx(I2C_SCL, I2C_SDA, I2C_HZ, ADDR_BITS)
        ser.strln(string("HD44780 driver started (I2C)"))
    else
        ser.strln(string("HD44780 driver failed to start - halting"))
        repeat

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
