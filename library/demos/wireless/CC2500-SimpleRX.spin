{
    --------------------------------------------
    Filename: CC2500-SimpleRX.spin
    Author: Jesse Burt
    Description: Simple receive demo of the cc2500 driver
    Copyright (c) 2021
    Started Nov 29, 2020
    Updated Jan 11, 2021
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

' CC2500 I/O pins
    CS_PIN          = 0
    SCK_PIN         = 1
    MOSI_PIN        = 2
    MISO_PIN        = 3

    NODE_ADDRESS    = $01                       ' this node's address (1..254)
' --

    MAX_PAYLD       = 255

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    time        : "time"
    int         : "string.integer"
    str         : "string"
    cc2500      : "wireless.transceiver.cc2500.spi"

VAR

    byte _pkt_tmp[MAX_PAYLD]
    byte _recv[MAX_PAYLD]
    byte _pktlen

PUB Main{} | tmp, rxbytes

    setup{}

    cc2500.presetrobust1{}                      ' use preset settings
    cc2500.carrierfreq(2_401_000)               ' set carrier frequency
    cc2500.nodeaddress(NODE_ADDRESS)            ' this node's address

    ser.clear{}
    ser.position(0, 0)
    ser.printf1(string("Receive mode - %dkHz\n"), cc2500.carrierfreq(-2))

    repeat
        bytefill(@_pkt_tmp, $00, MAX_PAYLD)     ' clear out buffers 
        bytefill(@_recv, $00, MAX_PAYLD)

        cc2500.rxmode{}                         ' set to receive mode
        repeat until cc2500.fiforxbytes{} => 1  ' wait for first recv'd bytes
        cc2500.rxpayload(1, @rxbytes)           ' get length of recv'd payload
                                                ' (1st byte of packet in
                                                '   default variable-length
                                                '   packet mode)

        repeat until cc2500.fiforxbytes{} => rxbytes
        cc2500.rxpayload(rxbytes, @_pkt_tmp)    ' now, read that many bytes
        cc2500.flushrx{}                        ' flush receive buffer

        ser.position(0, 3)
        ser.printf2(string("Received (%d): %s"), strsize(@_pkt_tmp), @_pkt_tmp)
        ser.clearline{}
        ser.newline{}

        repeat tmp from 0 to strsize(@_pkt_tmp)-1' show the packet received as
            ser.hex(_pkt_tmp[tmp], 2)           '   a simple hex dump
            ser.char(" ")
        ser.clearline{}
        ser.newline{}

        ser.strln(string("|  |"))
        ser.strln(string("|  *- start of payload/data"))
        ser.strln(string("*---- address packet was sent to"))

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if cc2500.start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("CC2500 driver started"))
    else
        ser.strln(string("CC2500 driver failed to start - halting"))
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

