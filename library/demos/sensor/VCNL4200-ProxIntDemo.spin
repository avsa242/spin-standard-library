{
    --------------------------------------------
    Filename: VCNL4200-Demo.spin
    Author: Jesse Burt
    Description: Demo of the VCNL4200 driver
        Proximity sensor interrupt functionality
    Copyright (c) 2022
    Started Feb 10, 2021
    Updated Dec 3, 2022
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

    { IMPORTANT NOTE:
        Ensure you power the VCNL4200's IR LED from a high current 5V source (>800mA); powering it
        via some boards' 5V outputs (e.g., from a Parallax FLiP's USB5V when connected to a PC USB
        port) isn't recommended. The high current draw can cause strange serial behavior and failure
        to load code to the Propeller.

        On the MikroE Click board (Parallax #64211), this is the 5V pin. }

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

    vcnl.preset_prox_long_range{}               ' set to proximity sensor mode

    { clear interrupts, and set low and high thresholds }
    vcnl.int_clear{}
    vcnl.prox_int_set_lo_thresh(100)
    vcnl.prox_int_set_hi_thresh(200)
    { interrupt mask:
        INT_NEAR: trigger when proximity < prox_int_set_lo_thresh()
        INT_FAR: trigger when proximity > prox_int_set_hi_thresh()
    }
    vcnl.prox_int_mask(vcnl#INT_NEAR)
    ser.pos_xy(0, 3)
    ser.printf2(string("Thresh  low: %d high: %d"), vcnl.prox_int_lo_thresh{}, {
}                                                   vcnl.prox_int_hi_thresh{})

    repeat
        ser.pos_xy(0, 5)
        ser.str(string("Proximity ADC: "))
        ser.pos_xy(DAT_COL, 5)
        ser.dec(vcnl.prox_data{})
        if (_interrupt)
            ser.str(string("   INTERRUPT (press c to clear)"))

        ser.clear_line{}
        if (ser.rx_check{} == "c")
            vcnl.int_clear{}

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

