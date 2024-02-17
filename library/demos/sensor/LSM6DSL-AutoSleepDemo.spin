{
---------------------------------------------------------------------------------------------------
    Filename:       LSM6DSL-AutoSleepDemo.spin
    Description:    LSM6DSL driver demo (Auto-sleep functionality)
    Author:         Jesse Burt
    Started:        Dec 27, 2021
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


' -- User-modifiable constants
    INT_PIN     = 24                            ' LSM6DSL INT_PIN pin
    LED1        = cfg.LED1                      ' LED used to indicate awake/sleep
' --


OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.imu.6dof.lsm6dsl" | {I2C} SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=0, ...
                                        {SPI} CS=0, SCK=1, MOSI=2, MISO=3


VAR

    long _isr_stack[50]                         ' stack for ISR core
    long _intflag                               ' interrupt flag

PUB main() | intsource, temp, sysmod

    setup()
    sensor.preset_active()                      ' default settings, but enable
                                                ' sensor power, and set
                                                ' scale factors

    sensor.accel_data_rate(208)
    sensor.accel_scale(2)
    sensor.gyro_data_rate(104)
    sensor.gyro_scale(250)

    sensor.inact_time(5_000)                    ' inactivity timeout ~5sec
    sensor.inact_thresh(0_250000)
    sensor.accel_slp_pwr_mode(sensor.LOPWR_GSLEEP)
    sensor.int1_mask(sensor.INACTIVE)

    dira[LED1] := 1

    ' The demo continuously displays the current accelerometer data.
    ' When the sensor goes to sleep after approx. 5 seconds, the change
    '   in data rate is visible as a slowed update of the display.
    ' To wake the sensor, shake it along the X and/or Y axes
    '   by at least 0.250g's.
    ' When the sensor is awake, the LED1 should be on.
    ' When the sensor goes to sleep, it should turn off.
    repeat
        ser.pos_xy(0, 3)
        show_accel_data()                       ' show accel data
        intsource := sensor.int_inactivity()
        if ( _intflag )                         ' interrupt triggered
            intsource := sensor.int_inactivity()
            if ( intsource )                    ' (in)activity event
                outa[LED1] := 0
            else
                outa[LED1] := 1
        if ( ser.getchar_noblock() == "c")      ' press the 'c' key in the demo
            cal_accel()                         ' to calibrate sensor offsets


PUB cog_isr() | pin
' Interrupt service routine
    dira[INT_PIN] := 0                          ' INT_PIN as input
    repeat
        waitpne(|< INT_PIN, |< INT_PIN, 0)      ' wait for INT_PIN (active low)
        _intflag := 1                           '   set flag
        waitpeq(|< INT_PIN, |< INT_PIN, 0)      ' now wait for it to clear
        _intflag := 0                           '   clear flag


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

    cognew(cog_isr(), @_isr_stack)              ' start ISR in another core


#include "acceldemo.common.spinh"               ' pull in code common to all accelerometer demos


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

