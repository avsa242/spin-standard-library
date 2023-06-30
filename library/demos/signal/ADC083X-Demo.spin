{
    --------------------------------------------
    Filename: ADC083x-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADC083x ADC driver
    Copyright (c) 2023
    Started Jun 21, 2023
    Updated Jun 24, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200

    { SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1
    MISO_PIN    = 2
' --


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    time:   "time"
    adc:    "signal.adc.adc083x"

PUB main()

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    adc.startx(CS_PIN, SCK_PIN, -1, MISO_PIN, 400_000)
    ser.strln(@"ADC083x driver started")

    show_adc_data()

#include "adcdemo.common.spinh"

DAT
{
Copyright (c) 2023 Jesse Burt

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

