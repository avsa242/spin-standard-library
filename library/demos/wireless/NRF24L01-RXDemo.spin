{                                                                                                                
    --------------------------------------------
    Filename: NRF24L01-RXDemo.spin
    Author: Jesse Burt 
    Description: nRF24L01+ Receive demo
        Will display data from all 6 data pipes
    Copyright (c) 2021
    Started Nov 23, 2019
    Updated May 15, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _xinfreq        = cfg#_xinfreq
    _clkmode        = cfg#_clkmode

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    CS_PIN          = 3
    SCK_PIN         = 1
    MOSI_PIN        = 4
    MISO_PIN        = 0
    CE_PIN          = 2

    CHANNEL         = 2                         ' 0..125
' --

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    time        : "time"
    nrf24       : "wireless.transceiver.nrf24l01.spi"

VAR

    byte _payload[32]
    byte _payld_len
    byte _addr[5]

PUB Main{} | i, payld_cnt, recv_pipe, pipe_nr

    setup{}                                     ' start serial term. and nRF24

' -- User-modifiable settings
    nrf24.channel(CHANNEL)

    _payld_len := 8                             ' 1..32 (_must_ match TX side)

    ' Set receive address (note: order in string() is LSB, ..., MSB)
    nrf24.rxaddr(string($e7, $e7, $e7, $e7, $e7), 0, nrf24#WRITE)

    ' choose a receive mode preset (250kbps, 1Mbps, 2Mbps)
    '   with optional Auto-Ack/ShockBurst  (power-on default)
'    nrf24.preset_rx250k{}                       ' 250kbps
'    nrf24.preset_rx250k_noaa{}                  ' 250kbps, No Auto-Ack
'    nrf24.preset_rx1m{}                         ' 1Mbps
'    nrf24.preset_rx1m_noaa{}                    ' 1Mbps, No Auto-Ack
    nrf24.preset_rx2m{}                         ' 2Mbps
'    nrf24.preset_rx2m_noaa{}                    ' 2Mbps, No Auto-Ack
' --

    repeat pipe_nr from 0 to 5
        nrf24.payloadlen(_payld_len, pipe_nr)   ' Set all pipes the same len

    ser.clear{}
    ser.position(0, 0)
    ser.printf1(string("Receive mode (channel %d)\n"), nrf24.channel(-2))
    ser.str(string("Listening for transmitters..."))

    payld_cnt := 0
    repeat
        bytefill(@_payload, $00, 32)            ' Clear RX local buffer
        repeat                                  ' Wait to proceed...
            ser.position(0, 5)
            ser.printf1(string("Packets received: %d "), payld_cnt)
        until nrf24.payloadready{}              ' ...until payload received

        recv_pipe := nrf24.rxpipepending{}      ' Which pipe is the data in?
        ' copy the address of the pipe the data was received in
        nrf24.rxaddr(@_addr, recv_pipe, nrf24#READ)
        nrf24.rxpayload(_payld_len, @_payload)  ' Retrieve payload into hub
        payld_cnt++                             ' Received payload counter

        ser.position(0, 8 + (recv_pipe * 4))    ' Use the pipe number for the
        ser.printf1(string("Received packet on pipe %d "), recv_pipe)
                                                '   payload display position

        ser.char("(")
        repeat i from 4 to 0                    ' Show the pipe's address
            ser.hex(_addr[i], 2)                ' (2..4 are only 1-byte)
        ser.char(")")

        ser.position(0, 9 + (recv_pipe * 4))
        ser.hexdump(@_payload, 0, 4, _payld_len, _payld_len)

        nrf24.intclear(%100)                    ' Clear interrupt
        nrf24.flushrx{}                         ' Flush FIFO

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if nrf24.startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("nRF24L01+ driver started"))
    else
        ser.strln(string("nRF24L01+ driver failed to start - halting"))
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
