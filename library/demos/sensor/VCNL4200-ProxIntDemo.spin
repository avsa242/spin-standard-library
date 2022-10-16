{
    --------------------------------------------
    Filename: VCNL4200-Demo.spin
    Author: Jesse Burt
    Description: Demo of the VCNL4200 driver
        Proximity sensor interrupt functionality
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

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
    INT_PIN     = 24
' --

    DAT_COL     = 20

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    vcnl    : "sensor.light.vcnl4200"

VAR

    long _isr_stack[50], _interrupt

PUB main{}

    setup{}

    vcnl.preset_prox_long_range{}               ' set to prox. sensor
                                                ' operating mode

    vcnl.int_clr{}                              ' ensure ints are cleared
    vcnl.prox_set_int_lo_thresh(100)            ' set low and high thresholds
    vcnl.prox_set_int_hi_thresh(200)
    vcnl.prox_int_mask(vcnl#INT_NEAR)           ' INT_NEAR, INT_FAR

    ser.position(0, 3)
    ser.printf2(string("Thresh  low: %d high: %d"), vcnl.prox_int_lo_thresh{}, vcnl.prox_int_hi_thresh{})

    repeat
        ser.position(0, 5)
        ser.str(string("Proximity ADC: "))
        ser.position(DAT_COL, 5)
        ser.dec(vcnl.prox_data{})
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

    if vcnl.startx(I2C_SCL, I2C_SDA, I2C_FREQ)
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

