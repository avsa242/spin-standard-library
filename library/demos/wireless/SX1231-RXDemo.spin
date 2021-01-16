{
    --------------------------------------------
    Filename: SX1231-RXDemo.spin
    Author: Jesse Burt
    Description: Simple receive demo of the sx1231 driver
    Copyright (c) 2020
    Started Dec 15, 2020
    Updated Dec 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    CS_PIN          = 0
    SCK_PIN         = 1
    MOSI_PIN        = 2
    MISO_PIN        = 3
' --

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    time        : "time"
    int         : "string.integer"
    sf          : "string.format"
    sx1231      : "wireless.transceiver.sx1231.spi"

VAR

    byte _buffer[256]

PUB Main{} | count

    setup{}

    ser.position(0, 3)
    ser.strln(string("Receive mode"))

' -- TX/RX settings
    sx1231.idle{}
    sx1231.carrierfreq(902_300_000)             ' US 902.3MHz
    sx1231.payloadlen(8)                        ' the test packets are
' --                                            '   8 bytes

' -- RX-specific settings
    sx1231.rxmode{}
    sx1231.fifothreshold(8)                     ' 8 bytes to trigger interrupt

    ' change these if having difficulty with reception
    sx1231.lnagain(0)                           ' -6, -12, -24, -26, -48 dB
                                                ' or LNA_AGC (0), LNA_HIGH (1)
    sx1231.rxbandwidth(10_400)                  ' 2_600..500_000 (see driver method)
' --

    count := 0
    repeat
        ser.position(0, 20)
        ser.printf1(string("AFC offset: %dHz       \n"), sx1231.afcoffset)
        ser.clearline{}
        repeat until sx1231.interrupt{} & sx1231#PAYLD_RDY
        sx1231.rxpayload(8, @_buffer)           ' get the data from the radio

        ' display the received payload on the terminal
        ser.position(0, 5)
        ser.str(string("Received: "))
        ser.str(@_buffer)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if sx1231.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        sx1231.defaults{}
        ser.strln(string("SX1231 driver started"))
    else
        ser.strln(string("SX1231 driver failed to start - halting"))
        sx1231.stop{}
        time.msleep(500)
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

