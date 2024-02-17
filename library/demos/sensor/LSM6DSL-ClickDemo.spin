{
---------------------------------------------------------------------------------------------------
    Filename:       LSM6DSL-ClickDemo.spin
    Description:    LSM6DSL driver demo (click-detection functionality)
    Author:         Jesse Burt
    Started:        Mar 7, 2021
    Updated:        Feb 17, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

' Uncomment these lines to use an SPI-connected sensor (default is I2C)
'#define LSM6DSL_SPI
'#pragma exportdef(LSM6DSL_SPI)

' Uncomment these lines (and the two above) to use an SPI-connected sensor
'   (uses the cogless bytecode SPI engine)
'#define LSM6DSL_SPI_BC
'#pragma exportdef(LSM6DSL_SPI_BC)

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq


OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.imu.6dof.lsm6dsl" | {I2C} SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=0, ...
                                        {SPI} CS=0, SCK=1, MOSI=2, MISO=3


PUB main() | click_src, int_act, dclicked, sclicked, z_clicked, y_clicked, x_clicked

    setup()
    sensor.preset_click_det()                   ' preset settings for click-detection

    ser.hide_cursor()                           ' hide terminal cursor

    repeat until (ser.rx_check() == "q")        ' press q to quit
        click_src := sensor.clicked_int()
        int_act := ((click_src >> 6) & 1)
        dclicked := ((click_src >> 4) & 1)
        sclicked := ((click_src >> 5) & 1)
        z_clicked := ((click_src >> 0) & 1)
        y_clicked := ((click_src >> 1) & 1)
        x_clicked := (click_src & 2)
        ser.pos_xy(0, 3)
        ser.printf1(@"Click interrupt: %s\n\r", yesno(int_act))
        ser.printf1(@"Double-clicked:  %s\n\r", yesno(dclicked))
        ser.printf1(@"Single-clicked:  %s\n\r", yesno(sclicked))
        ser.printf1(@"Z-axis clicked:  %s\n\r", yesno(z_clicked))
        ser.printf1(@"Y-axis clicked:  %s\n\r", yesno(y_clicked))
        ser.printf1(@"X-axis clicked:  %s\n\r", yesno(x_clicked))

    ser.show_cursor()                           ' restore terminal cursor
    repeat


PUB yesno(val): resp
' Return pointer to string "Yes" or "No" depending on value called with
    case val
        0:
            return @"No "
        1:
            return @"Yes"


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"LSM6DSL driver started")
    else
        ser.strln(@"LSM6DSL driver failed to start - halting")
        repeat


DAT
{
Copyright 2024 Jesse Burt

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
