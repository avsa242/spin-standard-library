{
    --------------------------------------------
    Filename: MCP320X-Demo.spin
    Author: Jesse Burt
    Description: Demo of the MCP320X driver
        * Voltage data output
    Copyright (c) 2023
    Started Nov 26, 2019
    Updated Jul 23, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    adc:    "signal.adc.mcp320x" | CS=0, SCK=1, MOSI=2, MISO=3
    time:   "time"

PUB main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if ( adc.start() )
        ser.strln(string("MCP320X driver started"))
    else
        ser.strln(string("MCP320X driver failed to start - halting"))
        repeat

    adc.defaults{}
    adc.set_model(3002)                         ' 10bit: 3001, 2, 4, 8; 12bit: 3201, 2, 4, 8
    adc.set_adc_channel(0)                      ' select channel (# available is model-dependent)
    adc.set_ref_voltage(3_300_000)              ' set voltage ADC is supplied by (= ref. voltage)
    show_adc_data{}

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

