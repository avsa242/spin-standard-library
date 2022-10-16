{
    --------------------------------------------
    Filename: VCNL4200-ALSIntDemo.spin
    Author: Jesse Burt
    Description: Demo of the VCNL4200 driver
        ALS sensor interrupt functionality
    Copyright (c) 2022
    Started Feb 10, 2021
    Updated Oct 16, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
    INT_PIN     = 24
' --

    DAT_COL     = 5

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    vcnl    : "sensor.light.vcnl4200"

VAR

    long _isr_stack[50], _interrupt

PUB main{}

    setup{}

    vcnl.preset_als{}                           ' set to prox. sensor
                                                ' operating mode

    vcnl.als_int_ena(TRUE)
    vcnl.int_clr{}                              ' ensure ints are cleared
    vcnl.als_set_int_lo_thresh(55_000)          ' set low and high thresholds
    vcnl.als_set_int_hi_thresh(75_000)          '   (in milli-lux)

    ser.position(0, 3)
    ser.printf2(string("Thresh  low: %d high: %d"), vcnl.als_int_lo_thresh{}, vcnl.als_int_hi_thresh{})

    repeat
        ser.position(0, 5)
        ser.str(string("Lux: "))
        ser.position(DAT_COL, 5)
        ser.dec(vcnl.lux{})
        if (_interrupt)
            ser.str(string("   INTERRUPT (press c to clear)"))

        ser.clearline{}
        if (ser.rxcheck{} == "c")
            vcnl.int_clr{}

PUB cog_isr{}
' Interrupt service routine
    dira[INT_PIN] := 0
    dira[LED] := 1

    repeat
        if (ina[INT_PIN] == 0)                  ' interrupt is active low
            outa[LED] := 1
            _interrupt := TRUE
        else
            outa[LED] := 0
            _interrupt := FALSE

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if vcnl.startx(SCL_PIN, SDA_PIN, I2C_FREQ)
        ser.strln(string("VCNL4200 driver started"))
    else
        ser.strln(string("VCNL4200 driver failed to start - halting"))
        repeat

    cognew(cog_isr{}, @_isr_stack)              ' start the ISR in another cog

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

