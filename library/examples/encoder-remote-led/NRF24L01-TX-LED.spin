{
    --------------------------------------------
    Filename: NRF24L01-TX-LED.spin
    Author: Jesse Burt
    Description: Wireless control of a Smart LED (transmitter)
        Uses:
        * nRF24L01+
        * Quadrature encoder
    Copyright (c) 2022
    Started Aug 29, 2022
    Updated Nov 13, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    { SPI configuration - nRF24L01+ }
    CE_PIN      = 0
    CS_PIN      = 1
    SCK_PIN     = 2
    MOSI_PIN    = 3
    MISO_PIN    = 4

    { encoder basepin (uses 2 pins) }
    ENC_BASEPIN = 24
' --

OBJ

    ser     : "com.serial.terminal.ansi"
    cfg     : "boardcfg.flip"
    radio   : "wireless.transceiver.nrf24l01"
    time    : "time"
    encoder : "input.encoder.quadrature"

VAR

    long _encoders[2]                           ' [0]: position + [1]: delta

PUB main{} | delta

    setup{}

    delta := 0

' -- User-modifiable settings (NOTE: These settings _must_ match the receive side) }
    radio.channel(2)                            ' 0..125 (2.400 .. 2.525GHz)
    radio.tx_pwr(0)                             ' -18, -12, -6, 0 (dBm)

    { set syncword (note: order in string() is LSB, ..., MSB) }
    radio.set_syncwd(string($e7, $e7, $e7, $e7, $e7))

' --

    ser.clear{}
    ser.position(0, 0)
    ser.printf1(string("Transmit mode (channel %d)\n\r"), radio.channel(-2))

    repeat
        repeat
            delta := encoder.readdelta(0)       ' wait for a change in encoder position
        until (delta)
        radio.tx_payld(4, @delta)

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(20)
    ser.clear{}

    if (radio.startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
        ser.strln(string("nRF24L01+ driver started"))
        radio.preset_tx2m_noaa{}                ' 2Mbps, no Auto-Ack
        radio.crc_check_ena(true)
        radio.crc_len(2)
        radio.payld_len(4)
    else
        ser.strln(string("nRF24L01+ driver failed to start - halting"))
        repeat

    if (encoder.start(ENC_BASEPIN, 1, 1, @_encoders))
        ser.strln(@"encoders started")
    else
        ser.strln(@"encoders failed to start - halting")
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

