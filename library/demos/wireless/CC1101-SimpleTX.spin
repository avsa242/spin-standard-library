{
    --------------------------------------------
    Filename: CC1101-SimpleTX.spin
    Author: Jesse Burt
    Description: Simple transmit demo of the cc1101 driver
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

    TO_NODE         = $01                       ' address to send to (01..FE)
' --

    POS_PKTLEN      = 0
    POS_TONODE      = 1
    POS_PAYLD       = 2
    MAX_PAYLD       = 251                       ' 255 - pktlen - addr - CRC
                                                '       (1byte, 1byte, 2bytes)

OBJ

    ser     : "com.serial.terminal.ansi"
    cfg     : "boardcfg.flip"
    time    : "time"
    cc1101  : "wireless.transceiver.cc1101"
    str     : "string"

VAR

    byte _pkt_tmp[MAX_PAYLD]
    long _user_str[8]

PUB main{} | counter, i, pktlen

    setup{}

    _user_str := string("TEST")                 ' any string up to 251 bytes

    cc1101.preset_robust1{}                     ' use preset settings
    cc1101.carrier_freq(433_900_000)            ' freq. to transmit on
    cc1101.tx_pwr(0)                            ' -30, -20, -15, -10, 0, 5, 7, 10

    ser.clear{}
    ser.pos_xy(0, 0)
    ser.printf1(string("Transmit mode - %dHz\n\r"), cc1101.carrier_freq(-2))

    counter := 0
    repeat
        bytefill(@_pkt_tmp, 0, MAX_PAYLD)       ' clear out buffer

        { assemble the payload and copy it to the temporary buffer }
        str.sprintf2(@_pkt_tmp[POS_PAYLD], string("%s%04.4d"), _user_str, counter++)

        { payload size is user string, the counter digits, and the address }
        pktlen := strsize(@_pkt_tmp[POS_PAYLD]) + 1
        _pkt_tmp[POS_PKTLEN] := pktlen          ' 1st byte is payload length
        _pkt_tmp[POS_TONODE] := TO_NODE         ' 2nd byte is destination addr

        ser.pos_xy(0, 3)
        ser.printf2(string("Sending (%d): %s\n\r"), pktlen, @_pkt_tmp[POS_PAYLD])

        { show hexdump of the packet, including non-payload data (length) }
        ser.hexdump(@_pkt_tmp, 0, 2, (pktlen+1), 16 <# (pktlen+1))
        ser.strln(string("    |  |  |"))
        ser.strln(string("    |  |  *- start of payload/data"))
        ser.strln(string("    |  *---- node address to transmit to"))
        ser.strln(string("    *------- length of payload (including address byte)"))

        cc1101.flush_tx{}                       ' flush transmit buffer
        cc1101.tx_mode{}                        ' set to transmit mode
        cc1101.tx_payld(pktlen+1, @_pkt_tmp)    ' transmit the data

        time.msleep(1_000)                      ' delay between packets to
                                                '   avoid abusing the airwaves

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

