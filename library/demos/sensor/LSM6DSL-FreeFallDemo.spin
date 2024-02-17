{
---------------------------------------------------------------------------------------------------
    Filename:       LSM6DSL-FreeFall-Demo.spin
    Description:    Demo of the LSM6DSL driver: Free-fall detection functionality
    Author:         Jesse Burt
    Started:        Sep 6, 2021
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


PUB main()

    setup()
    sensor.preset_freefall()                    ' default settings, but enable
                                                ' sensors, set scale factors,
                                                ' and free-fall parameters
    ser.pos_xy(0, 3)
    ser.str(@"Sensor stable       ")
    repeat
        ser.pos_xy(0, 3)
        ' check if sensor detects free-fall condition
        ' Note that calling in_freefall() reads the WAKE_UP_SRC register, which also
        '   clears the interrupt. This is necessary when routing the free-fall
        '   interrupt to one of the sensor's INT pins, if interrupts are being
        '   latched
        if ( sensor.in_freefall() )
            ser.strln(@"Sensor in free-fall!")
            ser.str(@"Press any key to reset")
            ser.getchar()                       ' wait for keypress
            ser.pos_x(0)
            ser.clear_line()
            ser.pos_xy(0, 3)
            ser.str(@"Sensor stable       ")
        if ( ser.getchar_noblock() == "c" )     ' press the 'c' key in the demo
            calibrate()                         ' to calibrate sensor offsets


PUB calibrate()

    ser.pos_xy(0, 7)
    ser.str(@"Calibrating...")
    sensor.calibrate_accel()
    ser.pos_x(0)
    ser.clear_line()


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"LSM6DSL driver started (SPI)")
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
