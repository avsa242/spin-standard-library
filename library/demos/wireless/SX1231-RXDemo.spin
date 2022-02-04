{
    --------------------------------------------
    Filename: SX1231-RXDemo.spin2
    Author: Jesse Burt
    Description: Simple receive demo of the SX1231 driver (P2 version)
    Copyright (c) 2021
    Started Dec 15, 2020
    Updated Aug 22, 2021
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
    RESET_PIN       = 4                         ' use is recommended
                                                '   (-1 to disable)
' --

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    time        : "time"
    int         : "string.integer"
    sx1231      : "wireless.transceiver.sx1231"

VAR

    byte _buffer[256]

PUB Main{} | sw[2], payld_len

    setup{}
    ser.position(0, 3)
    ser.strln(string("Receive mode"))
    sx1231.preset_rx4k8{}                       ' 4800bps, use Automodes to
                                                ' handle transition between
                                                ' RX-sleep-RX opmodes

' -- TX/RX settings
    sx1231.carrierfreq(902_300_000)             ' US 902.3MHz
    sx1231.payloadlen(8)                        ' test packet size
    payld_len := sx1231.payloadlen(-2)          ' read back from radio
    sx1231.fifothreshold(payld_len-1)           ' trigger int at payld len-1
    sw[0] := $E7E7E7E7                          ' sync word bytes
    sw[1] := $E7E7E7E7
    sx1231.syncwordlength(8)                    ' 1..8
    sx1231.syncword(sx1231#SW_WRITE, @sw)
' --

' -- RX-specific settings
    sx1231.rxmode{}

    ' change these if having difficulty with reception
    sx1231.lnagain(0)                           ' -6, -12, -24, -26, -48 dB
                                                ' or LNA_AGC (0), LNA_HIGH (1)
    sx1231.rssithresh(-80)                      ' set rcvd signal level thresh
                                                '   considered a valid signal
                                                ' -127..0 (dBm)
' --

    repeat
        bytefill(@_buffer, 0, 256)              ' clear local RX buffer
        ' if the FIFO fill level reaches the set threshold,
        '   read the payload in from the radio
        if sx1231.interrupt{} & sx1231#FIFO_THR
            sx1231.rxpayload(payld_len, @_buffer)
        ' display the received payload on the terminal
        ser.position(0, 5)
        ser.hexdump(@_buffer, 0, 4, payld_len, 16 <# payld_len)
        repeat until sx1231.opmode(-2) == sx1231#OPMODE_SLEEP

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if sx1231.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, RESET_PIN)
        ser.strln(string("SX1231 driver started"))
    else
        ser.strln(string("SX1231 driver failed to start - halting"))
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

