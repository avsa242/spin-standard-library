{
    --------------------------------------------
    Filename: CC1101-SimpleRX.spin
    Author: Jesse Burt
    Description: Simple receive demo of the cc1101 driver
    Copyright (c) 2022
    Started Nov 29, 2020
    Updated Nov 13, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    { SPI configuration }
    CS_PIN          = 0
    SCK_PIN         = 1
    MOSI_PIN        = 2
    MISO_PIN        = 3

    NODE_ADDRESS    = $01                       ' this node's address (1..254)
' --

    POS_TONODE      = 0
    POS_PAYLD       = 1
    MAX_PAYLD       = 255

OBJ

    ser     : "com.serial.terminal.ansi"
    cfg     : "boardcfg.flip"
    time    : "time"
    str     : "string"
    cc1101  : "wireless.transceiver.cc1101"

VAR

    byte _pkt_tmp[MAX_PAYLD]
    byte _recv[MAX_PAYLD]
    byte _pktlen

PUB main{} | tmp, rxbytes

    setup{}

    cc1101.preset_robust1{}                     ' use preset settings
    cc1101.carrier_freq(433_900_000)            ' set carrier frequency
    cc1101.node_addr(NODE_ADDRESS)              ' this node's address

    ser.clear{}
    ser.pos_xy(0, 0)
    ser.printf1(string("Receive mode - %dHz\n\r"), cc1101.carrier_freq(-2))

    repeat
        bytefill(@_pkt_tmp, $00, MAX_PAYLD)     ' clear out buffers 
        bytefill(@_recv, $00, MAX_PAYLD)

        cc1101.rx_mode{}                        ' set to receive mode
        repeat until cc1101.fifo_rx_bytes{} => 1' wait for first recv'd bytes
        cc1101.rx_payld(1, @rxbytes)            ' get length of recv'd payload
                                                ' (1st byte of packet in
                                                '   default variable-length
                                                '   packet mode)

        repeat until cc1101.fifo_rx_bytes{} => rxbytes
        cc1101.rx_payld(rxbytes, @_pkt_tmp)     ' now, read that many bytes
        cc1101.flush_rx{}                       ' flush receive buffer

        ser.pos_xy(0, 3)
        ser.printf2(string("Received (%d): %s"), strsize(@_pkt_tmp), @_pkt_tmp)
        ser.clear_line{}
        ser.newline{}

        { show the packet received as a simple hex dump }
        ser.hexdump(@_pkt_tmp, 0, 2, strsize(@_pkt_tmp), 16 <# strsize(@_pkt_tmp))

        ser.strln(string("    |  |"))
        ser.strln(string("    |  *- start of payload/data"))
        ser.strln(string("    *---- address packet was sent to"))

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if cc1101.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("CC1101 driver started"))
    else
        ser.strln(string("CC1101 driver failed to start - halting"))
        repeat

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

