{
    --------------------------------------------
    Filename: LSM6DSL-ClickDemo.spin
    Author: Jesse Burt
    Description: Demo of the LSM6DSL driver
        click-detection functionality
    Copyright (c) 2021
    Started Mar 7, 2021
    Updated Mar 7, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_PIN      = 0                             ' SPI
    SCL_PIN     = 28                            ' SPI, I2C
    SDA_PIN     = 29                            ' SPI, I2C
    SDO_PIN     = 3                             ' SPI
    I2C_HZ      = 400_000                       ' I2C
    ADDR_BITS   = 0                             ' I2C
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    imu     : "sensor.imu.6dof.lsm6dsl"

PUB Main{} | click_src, int_act, dclicked, sclicked, z_clicked, y_clicked, x_clicked

    setup{}
    imu.preset_clickdet{}                     ' preset settings for
                                                ' click-detection

    ser.hidecursor{}                            ' hide terminal cursor

    repeat until ser.rxcheck{} == "q"           ' press q to quit
        click_src := imu.clickedint{}
        int_act := ((click_src >> 6) & 1)
        dclicked := ((click_src >> 4) & 1)
        sclicked := ((click_src >> 5) & 1)
        z_clicked := ((click_src >> 0) & 1)
        y_clicked := ((click_src >> 1) & 1)
        x_clicked := (click_src & 2)
        ser.position(0, 3)
        ser.printf1(string("Click interrupt: %s (%d)\n"), yesno(int_act))
        ser.printf1(string("Double-clicked:  %s (%d)\n"), yesno(dclicked))
        ser.printf1(string("Single-clicked:  %s (%d)\n"), yesno(sclicked))
        ser.printf1(string("Z-axis clicked:  %s\n"), yesno(z_clicked))
        ser.printf1(string("Y-axis clicked:  %s\n"), yesno(y_clicked))
        ser.printf1(string("X-axis clicked:  %s\n"), yesno(x_clicked))

    ser.showcursor{}                            ' restore terminal cursor
    repeat

PRI YesNo(val): resp
' Return pointer to string "Yes" or "No" depending on value called with
    case val
        0:
            return string("No ")
        1:
            return string("Yes")

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
#ifdef LSM6DSL_SPI
    if imu.startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.strln(string("LSM6DSL driver started (SPI)"))
#elseifdef LSM6DSL_I2C
    if imu.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS)
        ser.strln(string("LSM6DSL driver started (I2C)"))
#endif
    else
        ser.strln(string("LSM6DSL driver failed to start - halting"))
        time.msleep(5)
        ser.stop{}
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
