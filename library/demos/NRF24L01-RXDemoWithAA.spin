{                                                                                                                
    --------------------------------------------
    Filename: NRF24L01-RXWithAA.spin2
    Author: Jesse Burt 
    Description: nRF24L01+ Receive demo that uses the radio's
        auto-acknowledge function (Enhanced ShockBurst - (TM) Nordic Semi)
        Will display data from all 5 data pipes
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

    CE_PIN          = 5
    CSN_PIN         = 4
    SCK_PIN         = 1
    MOSI_PIN        = 2
    MISO_PIN        = 0

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
    ser.str(string("Press any key to begin receiving", ser#CR, ser#LF))
    ser.CharIn

    Receive

    FlashLED(LED, 100)

PUB Receive | tmp, from_node, addr[2], i, count, recv_pipe

    _pktlen := 10

    nrf24.AddressWidth(5)                                   ' Configure for 5-byte long addresses   

    bytefill(@addr, 0, 8)
    repeat i from 0 to 4
        addr.byte[i] := $E7
    nrf24.RXAddr (@addr, 0, nrf24#WRITE)                    ' Set pipe 0 address

    bytefill(@addr, 0, 8)
    repeat i from 0 to 4
        addr.byte[i] := $C2
    nrf24.RXAddr (@addr, 1, nrf24#WRITE)                    ' Set pipe 1 address

    bytefill(@addr, 0, 8)
    addr.byte[0] := $C3
    nrf24.RXAddr (@addr, 2, nrf24#WRITE)                    ' Set pipe 2 address

    bytefill(@addr, 0, 8)
    addr.byte[0] := $C4
    nrf24.RXAddr (@addr, 3, nrf24#WRITE)                    ' Set pipe 3 address

    bytefill(@addr, 0, 8)
    addr.byte[0] := $C5
    nrf24.RXAddr (@addr, 4, nrf24#WRITE)                    ' Set pipe 4 address

    bytefill(@addr, 0, 8)
    addr.byte[0] := $C6
    nrf24.RXAddr (@addr, 5, nrf24#WRITE)                    ' Set pipe 5 address


    nrf24.RX(0)                                             ' Set transceiver to receive mode (0 = stay in RX mode)
    nrf24.FlushRX                                           ' Empty the receive FIFO
    nrf24.CRCCheckEnabled(TRUE)                             ' TRUE, FALSE (enable CRC generation, checking)
    nrf24.CRCLength(2)                                      ' 1, 2 bytes (CRC length)
    nrf24.DataRate(2000)                                    ' 250, 1000, 2000 (kbps)
    nrf24.TXPower(-18)                                      ' -18, -12, -6, 0 (dBm)
    nrf24.PipesEnabled(%111111)                             ' %000000..%111111 (enable data pipes per bitmask)
    nrf24.PowerUp (TRUE)
    nrf24.PayloadReady (CLEAR)                              ' Clear interrupt
    repeat tmp from 0 to 5
        nrf24.PayloadLen (_pktlen, tmp)                     ' Payload length 0..32 (bytes), 0..5 (pipe number)

    ser.Clear
    ser.Position(0, 0)
    ser.str(string("Receive mode - "))
    ser.Dec(nrf24.CarrierFreq(-2))
    ser.str(string("MHz", ser#CR, ser#LF))

    ser.str(string("Listening for traffic on node address $"))
    bytefill(@addr, 0, 8)
    nrf24.RXAddr(@addr, 0, nrf24#READ)                      ' Read pipe 0 address
    repeat i from 4 to 0
        ser.Hex(addr.byte[i], 2)
    ser.Newline

    repeat
        bytefill (@_fifo, $00, 64)                          ' Clear RX local buffer
        repeat                                              ' Wait to proceed
            ser.Position(0, 5)                              ' .
            ser.str(string("RSSI: "))                       ' .
            ser.str(int.DecPadded(nrf24.RSSI, 4))           ' .
            ser.newline                                     ' .
            ser.str(string("Packets received: "))           ' .
            ser.dec(count)                                  ' .
        until nrf24.PayloadReady(-2)                        ' until we've received at least _pktlen bytes

        recv_pipe := nrf24.RXPipePending                    ' In which pipe is the received data waiting?
        nrf24.RXPayload(_pktlen, @_fifo)                    ' Retrieve it into our local buffer
        count++                                             ' Increment received payload counter

        from_node := _fifo.byte[1]                          ' Node we've received a packet from
        ser.Position(0, 8 + (recv_pipe * 4))                ' Display the payload in a terminal position
        ser.str(string("Received packet on pipe "))         '   based on the pipe number it was
        ser.dec(recv_pipe)                                  '   received on
        ser.str(string(" from node $"))
        ser.Hex(from_node, 2)

        ser.Hexdump(@_fifo, 0, _pktlen, _pktlen, 0, 9 + (recv_pipe * 4))

        nrf24.PayloadReady(CLEAR)                           ' Clear interrupt
        nrf24.FlushRX                                       ' Flush FIFO

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if _nrf24_cog := nrf24.Startx (CE_PIN, CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.str(string("nRF24L01+ driver started", ser#CR, ser#LF))
    else
        ser.str(string("nRF42L01+ driver failed to start - halting", ser#CR, ser#LF))
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
