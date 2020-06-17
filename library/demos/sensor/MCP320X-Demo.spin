{
    --------------------------------------------
    Filename: MCP320X-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the MCP320x driver that continuously shows
        either the raw ADC counts or Voltage sampled by the ADC
    Copyright (c) 2020
    Started Nov 26, 2019
    Updated Jun 17, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    CS_PIN      = 3                                         ' CSn/SHDN
    SCK_PIN     = 2                                         ' CLK
    MOSI_PIN    = 0                                         ' DIN
    MISO_PIN    = 1                                         ' DOUT
    SCK_DELAY   = 1
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    adc     : "signal.adc.mcp320x.spi"
    int     : "string.integer"

VAR

    byte _ser_cog, _ch

PUB Main | dispmode

    Setup
    _ch := 0                                                ' ADC channel:  0..1 (MCP3202)

    ser.HideCursor
    dispmode := 0

    repeat
        case ser.RxCheck
            "q", "Q":                                       ' Quit the demo
                ser.Position(0, 15)
                ser.str(string("Halting"))
                adc.Stop
                time.MSleep(5)
                ser.Stop
                quit
            "r", "R":                                       ' Change display mode: raw/calculated
                ser.Position(0, 10)
                repeat 2
                    ser.ClearLine(ser#CLR_CUR_TO_END)
                    ser.Newline
                dispmode ^= 1

        ser.Position (0, 10)
        case dispmode
            0:
                ADCRaw
            1:
                ADCmV

    ser.ShowCursor
    FlashLED(LED, 100)

    repeat
        ser.Position (0, 5)
        ser.Str(string("ADC: "))
        ser.Str(int.DecPadded (adc.Voltage(0), 5))

PUB ADCRaw | tmp

    tmp := adc.ReadADC(_ch)
    ser.Str (string("ADC raw word: "))
    ser.Str (int.DecPadded (tmp, 4))
    ser.clearline(ser#CLR_CUR_TO_END)
    ser.Newline

PUB ADCmV | tmp

    tmp := adc.Voltage(_ch)
    ser.Str (string("ADC mV: "))
    ser.Str (int.DecPadded (tmp, 4))
    ser.clearline(ser#CLR_CUR_TO_END)
    ser.Newline

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if adc.Start (CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, SCK_DELAY)
        ser.Str(string("MCP320x driver started", ser#CR, ser#LF))
    else
        ser.Str(string("MCP320x driver failed to start - halting", ser#CR, ser#LF))
        time.MSleep (500)
        ser.Stop
        FlashLED (LED, 500)

#include "lib.utility.spin"

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
