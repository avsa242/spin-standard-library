{                                                                                                                
    --------------------------------------------
    Filename: NRF24L01-RXDemo.spin
    Author: Jesse Burt 
    Description: nRF24L01+ Receive demo
        Will display data from all 6 data pipes
    Copyright (c) 2021
    Started Nov 23, 2019
    Updated Jan 16, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _xinfreq        = cfg#_xinfreq
    _clkmode        = cfg#_clkmode

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    CS_PIN          = 9
    SCK_PIN         = 10
    MOSI_PIN        = 11
    MISO_PIN        = 12
    CE_PIN          = 8

    CHANNEL         = 2                         ' 0..125
' --

    CLEAR           = 1

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    time        : "time"
    nrf24       : "wireless.transceiver.nrf24l01.spi"

VAR

    byte _payload[32]
    byte _payld_len
    byte _addr[5]

PUB Main{}

    setup{}

    nrf24.channel(CHANNEL)

    receive{}

PUB Receive{} | i, payld_cnt, recv_pipe, pipe_nr

    longfill(@i, 0, 5)
    _payld_len := 8                             ' 1..32 (_must_ match TX side)

    ' Set receive address (note: order is LSB, ..., MSB)
    bytemove(@_addr, string($e7, $e7, $e7, $e7, $e7), 5)
    nrf24.rxaddr(@_addr, 0, nrf24#WRITE)

    nrf24.rxmode{}                              ' Set to receive mode
    nrf24.flushrx{}                             ' Empty the receive FIFO
    nrf24.powered(TRUE)
    nrf24.intclear(%111)                        ' Clear interrupt
    nrf24.pipesenabled(%111111)                 ' Pipe enable mask (5..0)
    nrf24.autoackenabledpipes(%000000)          ' Auto-ack/Shockburst per pipe

    repeat pipe_nr from 0 to 5
        nrf24.payloadlen(_payld_len, pipe_nr)   ' Set all pipes the same len

    ser.clear{}
    ser.position(0, 0)
    ser.printf1(string("Receive mode (channel %d)\n"), nrf24.channel(-2))
    ser.str(string("Listening for transmitters..."))

    repeat
        bytefill(@_payload, $00, 32)            ' Clear RX local buffer
        repeat                                  ' Wait to proceed...
            ser.position(0, 5)
            ser.printf1(string("Packets received: %d "), payld_cnt)
        until nrf24.payloadready{}              ' ...until payload received

        recv_pipe := nrf24.rxpipepending{}      ' Which pipe is the data in?
        nrf24.rxaddr(@_addr, recv_pipe, nrf24#READ) ' Copy it into a variable
        nrf24.rxpayload(_payld_len, @_payload)  ' Retrieve it into _payload
        payld_cnt++                             ' Received payload counter

        ser.position(0, 8 + (recv_pipe * 4))    ' Use the pipe number for the
        ser.printf1(string("Received packet on pipe %d "), recv_pipe)
                                                '   payload display position

        ser.char("(")
        repeat i from 4 to 0                    ' Show the pipe's _address
            ser.hex(_addr[i], 2)                ' (2..4 are only 1-byte)
        ser.char(")")

        ser.hexdump(@_payload, 0, _payld_len, _payld_len, 0, 9 + (recv_pipe * 4))

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
