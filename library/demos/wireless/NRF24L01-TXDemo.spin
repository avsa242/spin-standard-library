{
    --------------------------------------------
    Filename: NRF24L01-TXDemo.spin
    Author: Jesse Burt
    Description: nRF24L01+ Transmit demo
    Copyright (c) 2021
    Started Nov 23, 2019
    Updated Mar 20, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    CS_PIN          = 1
    SCK_PIN         = 2
    MOSI_PIN        = 3
    MISO_PIN        = 4
    CE_PIN          = 0

    CHANNEL         = 2                         ' 0..125
' --

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

PUB Main{} | payld_cnt, tmp[2], i, max_retrans, pkts_retrans, lost_pkts

    setup{}

' -- User-modifiable settings
    nrf24.channel(CHANNEL)

    ' choose a transmit mode preset (250kbps, 1Mbps, 2Mbps)
    '   with optional Auto-Ack/ShockBurst (power-on default)
'    nrf24.preset_tx250k{}                       ' 250kbps
'    nrf24.preset_tx250k_noaa{}                  ' 250kbps, no Auto-Ack
'    nrf24.preset_tx1m{}                         ' 1Mbps
'    nrf24.preset_tx1m_noaa{}                    ' 1Mbps, no Auto-Ack
    nrf24.preset_tx2m{}                         ' 2Mbps
'    nrf24.preset_tx2m_noaa{}                    ' 2Mbps, no Auto-Ack

    nrf24.txpower(0)                            ' -18, -12, -6, 0 (dBm)

    _payld_len := 8                             ' 1..32 (_must_ match RX side)

    ' Set transmit/receive address (note: order in string() is LSB, ..., MSB)
    nrf24.nodeaddress(string($e7, $e7, $e7, $e7, $e7))

    _payload[0] := "T"                          ' Start of payload
    _payload[1] := "E"
    _payload[2] := "S"
    _payload[3] := "T"

' --

    nrf24.payloadlen(_payld_len, 0)
    nrf24.txaddr(@_addr, nrf24#READ)

    ser.clear{}
    ser.position(0, 0)
    ser.printf1(string("Transmit mode (channel %d)\n"), nrf24.channel(-2))
    ser.str(string("Transmitting..."))

    longfill(@payld_cnt, 0, 6)
    repeat
        ' Collect some packet statistics
        max_retrans := nrf24.maxretransreached{}
        pkts_retrans := nrf24.packetsretransmitted{}
        lost_pkts := nrf24.lostpackets{}

        ser.position(0, 5)
        ser.str(string("Max retransmissions reached? "))
        ser.str(lookupz(||(max_retrans): string("No "), string("Yes")))
        ser.newline{}

        ser.printf1(string("Packets retransmitted: %s"), int.decpadded(pkts_retrans, 2))
        ser.printf1(string("\nLost packets: %s"), int.decpadded(lost_pkts, 2))

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
