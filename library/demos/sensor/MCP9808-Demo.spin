{
    --------------------------------------------
    Filename: MCP9808-Demo.spin
    Author: Jesse Burt
    Description: Demo of the MCP9808 driver
    Copyright (c) 2020
    Started Jul 26, 2020
    Updated Jul 26, 2020
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _xinfreq    = cfg#_xinfreq
    _clkmode    = cfg#_clkmode

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 100_000
' --

    C           = mcp9808#C
    F           = mcp9808#F

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    io          : "io"
    time        : "time"
    int         : "string.integer"
    mcp9808     : "sensor.temperature.mcp9808.i2c"

PUB Main{} | t

    Setup{}
    mcp9808.tempscale(C)                                    ' C (0), F (1)
    mcp9808.tempres(0_0625)                                 ' 0_0625, 0_1250, 0_2500, 0_5000 (Resolution: 0.0625C, 0.125, 0.25, 0.5)
    ser.hidecursor{}
    repeat
        t := mcp9808.temperature{}
        ser.position(0, 5)
        ser.str(string("Temperature: "))
        decimaldot(t, 100)
        ser.char(lookupz(mcp9808.tempscale(-2): "C", "F"))
    until ser.rxcheck{} == "q"
    ser.showcursor{}
    FlashLED(LED, 100)     ' Signal execution finished

PRI DecimalDot(scaled, divisor) | whole[4], part[4], places, tmp
' Display a fixed-point scaled up number in decimal-dot notation - scale it back down by divisor
'   e.g., Decimal (314159, 100000) would display 3.14159 on the terminal
'   scaled: Fixed-point scaled up number
'   divisor: Divide scaled-up number by this amount
    whole := scaled / divisor
    tmp := divisor
    places := 0

    repeat
        tmp /= 10
        places++
    until tmp == 1
    part := int.deczeroed(||(scaled // divisor), places)

    ser.dec (whole)
    ser.char (".")
    ser.str (part)
    ser.clearline(ser#CLR_CUR_TO_END)

PUB Setup{}

    repeat until ser.startrxtx (SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if mcp9808.start(I2C_SCL, I2C_SDA, I2C_HZ)
        mcp9808.defaults{}
        ser.str(string("MCP9808 driver started", ser#CR, ser#LF))
    else
        ser.str(string("MCP9808 driver failed to start - halting", ser#CR, ser#LF))
        flashled(LED, 500)

#include "lib.utility.spin"

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
