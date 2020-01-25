{
    --------------------------------------------
    Filename: NRF24L01-TXDemoWithAA.spin2
    Author: Jesse Burt
    Description: nRF24L01+ Transmit demo that uses the radio's
        auto-acknowledge function (Enhanced ShockBurst - (TM) Nordic Semi)
    Copyright (c) 2020
    Started Nov 23, 2019
    Updated Jan 25, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

    LED             = cfg#LED1
    SER_RX          = 31
    SER_TX          = 30
    SER_BAUD        = 115_200

    CS_PIN          = 22
    SCK_PIN         = 21
    MOSI_PIN        = 20
    MISO_PIN        = 19
    CE_PIN          = 23

    CLEAR           = 1
    CHANNEL         = 2

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    io          : "io"
    time        : "time"
    int         : "string.integer"
    nrf24       : "wireless.transceiver.nrf24l01.spi"

VAR

    long _ser_cog, _nrf24_cog
    long _fifo[16]
    byte _pktlen

PUB Main | choice

    Setup

    nrf24.Channel(CHANNEL)
    ser.str(string("Press any key to begin transmitting", ser#CR, ser#LF))
    ser.CharIn

    Transmit

PUB Transmit | count, tmp, addr[2], to_node, i, max_retrans, pkts_retrans, lost_pkts, countdown

    _pktlen := 10

    nrf24.AddressWidth(5)
    bytefill(@addr, 0, 8)
    repeat i from 4 to 0
        addr.byte[i] := $E7                                 ' Set the first 4 octets of the address
    addr.byte[0] := $E7                                     '   and the last can be different (for pipes 2..5)
    nrf24.NodeAddress (@addr)                               ' Set TX and RX address to the same
                                                            ' (RX pipe is used for receipt of Auto-Acknowledgement)

    nrf24.TX                                                ' Set to Transmit mode and
    nrf24.FlushTX                                           '   empty the transmit FIFO
    nrf24.CRCCheckEnabled(TRUE)                             ' TRUE, FALSE (enable CRC generation, checking)
    nrf24.CRCLength (2)                                     ' 1, 2 bytes (CRC length)
    nrf24.DataRate(2000)                                    ' 250, 1000, 2000 (kbps)
    nrf24.TXPower(0)                                        ' -18, -12, -6, 0 (dBm)
    nrf24.PipesEnabled(%000011)                             ' %000000..%111111 (enable data pipes per bitmask)
    nrf24.PowerUp (TRUE)
    nrf24.PayloadReady (CLEAR)                              ' Clear interrupts
    nrf24.PayloadSent (CLEAR)                               '
    nrf24.MaxRetransReached (CLEAR)                         '
    nrf24.PayloadLen (_pktlen, 0)                           ' Payload length 0..32 (bytes), 0..5 (pipe number)

    ser.Clear
    ser.Position(0, 0)
    ser.str(string("Transmit mode - "))
    ser.dec(nrf24.CarrierFreq(-2))
    ser.str(string("MHz", ser#CR, ser#LF))
    ser.str(string("Transmitting to node $"))
    repeat i from 4 to 0
        ser.Hex(addr.byte[i], 2)

    to_node := $E7
    _fifo.byte[0] := to_node                                ' Address LSB of node we're sending to
    _fifo.byte[1] := addr.byte[0]                           ' This node's address
    _fifo.byte[2] := "T"                                    ' Start of payload
    _fifo.byte[3] := "E"
    _fifo.byte[4] := "S"
    _fifo.byte[5] := "T"

    countdown := 20
    count := 0
    repeat
        max_retrans := nrf24.MaxRetransReached(-2)          '
        pkts_retrans := nrf24.PacketsRetransmitted          ' Collect some packet statistics
        lost_pkts := nrf24.LostPackets                      '
        ser.position(0, 5)
        ser.str(string("Max retrans: "))
        ser.dec(max_retrans)
        ser.str(string(ser#CR, ser#LF, "Packets retransmitted: "))
        ser.dec(pkts_retrans)
        ser.str(string(ser#CR, ser#LF, "Lost packets: "))
        ser.dec(lost_pkts)

        if max_retrans == TRUE                              ' If max number of retransmissions reached,
            nrf24.MaxRetransReached(CLEAR)                  '   clear the interrupt so we can continue to TX

        if lost_pkts => 15                                  ' If number of packets lost exceeds 15
            nrf24.Channel(CHANNEL)                          '   clear the interrupt so we can continue to TX

        if countdown == 20                                  ' Transmit, if it's the start of the countdown
            tmp := int.DecZeroed(count++, 4)                ' Tack a counter onto the
            bytemove(@_fifo.byte[6], tmp, 4)                '   end of the payload
            ser.position(0, 10)
            ser.str(string("Sending"))
            ser.Hexdump(@_fifo, 0, _pktlen, _pktlen, 0, 11)
            nrf24.TXPayload (_pktlen, @_fifo, FALSE)        ' Transmit _fifo contents immediately

        time.MSleep(50)                                     ' Don't abuse the airwaves - wait between packets
        if countdown-- < 0
            countdown := 20

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if _nrf24_cog := nrf24.Startx (CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.str(string("NRF24L01+ driver started", ser#CR, ser#LF))
    else
        ser.str(string("NRF24L01+ driver failed to start - halting", ser#CR, ser#LF))
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
