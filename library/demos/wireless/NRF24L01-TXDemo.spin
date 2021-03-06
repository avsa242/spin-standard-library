{
    --------------------------------------------
    Filename: NRF24L01-TXDemo.spin
    Author: Jesse Burt
    Description: nRF24L01+ Transmit demo
    Copyright (c) 2020
    Started Nov 23, 2019
    Updated Oct 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    CS_PIN          = 9
    SCK_PIN         = 10
    MOSI_PIN        = 11
    MISO_PIN        = 12
    CE_PIN          = 8

    CHANNEL         = 2                         ' 0..127
' --

    CLEAR           = 1

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    time        : "time"
    int         : "string.integer"
    nrf24       : "wireless.transceiver.nrf24l01.spi"

VAR

    byte _payload[32]
    byte _payld_len
    byte _addr[5]

PUB Main{}

    setup{}

    nrf24.channel(CHANNEL)
    transmit{}

PUB Transmit{} | payld_cnt, tmp, i, max_retrans, pkts_retrans, lost_pkts

    _payld_len := 8
    longfill(@payld_cnt, 0, 8)

    ' Set transmit address (note: order is LSB, ..., MSB)
    bytemove(@_addr, string($e7, $e7, $e7, $e7, $e7), 5)
    nrf24.nodeaddress(@_addr)                   ' Set TX/RX address to the same
                                                ' (RX pipe 0 used for auto-ack)
    nrf24.txmode{}                              ' Set to transmit mode and
    nrf24.flushtx{}                             '   empty the transmit FIFO
    nrf24.txpower(0)                            ' -18, -12, -6, 0 (dBm)
    nrf24.powered(TRUE)
    nrf24.autoackenabledpipes(%000000)          ' Auto-ack/Shockburst, per pipe

    nrf24.intclear(%111)                        ' Clear interrupts
    nrf24.payloadlen(_payld_len, 0)             ' 1..32 (len), 0..5 (pipe #)

    ser.clear{}
    ser.position(0, 0)
    ser.str(string("Transmit mode (channel "))
    ser.dec(nrf24.channel(-2))
    ser.strln(string(")"))
    ser.str(string("Transmitting..."))

    _payload[0] := "T"                          ' Start of payload
    _payload[1] := "E"
    _payload[2] := "S"
    _payload[3] := "T"

    repeat
        ' Collect some packet statistics
        max_retrans := nrf24.maxretransreached{}
        pkts_retrans := nrf24.packetsretransmitted{}
        lost_pkts := nrf24.lostpackets{}

        ser.position(0, 5)
        ser.str(string("Max retransmissions reached? "))
        ser.str(lookupz(||(max_retrans): string("No "), string("Yes")))

        ser.str(string(ser#CR, ser#LF, "Packets retransmitted: "))
        ser.str(int.decpadded(pkts_retrans, 2))

        ser.str(string(ser#CR, ser#LF, "Lost packets: "))
        ser.str(int.decpadded(lost_pkts, 2))

        if max_retrans == TRUE                  ' Max retransmissions reached?
            nrf24.intclear(%001)                '   If yes, clear the int

        if lost_pkts => 15                      ' Packets lost exceeds 15?
            nrf24.channel(CHANNEL)              '   If yes, clear the int

        tmp := int.deczeroed(payld_cnt++, 4)    ' Tack a counter onto the
        bytemove(@_payload[4], tmp, 4)          '   end of the payload
        ser.position(0, 10)
        ser.str(string("Transmitting packet "))

        ser.char("(")
        repeat i from 4 to 0                    ' Show address transmitting to
            ser.hex(_addr[i], 2)
        ser.strln(string(")"))

        ' Show what will be transmitted
        ser.hexdump(@_payload, 0, _payld_len, _payld_len, 0, 11)

        nrf24.txpayload(_payld_len, @_payload)

        time.msleep(1000)                       ' Optional inter-packet delay

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if nrf24.startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("NRF24L01+ driver started"))
    else
        ser.strln(string("NRF24L01+ driver failed to start - halting"))
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
