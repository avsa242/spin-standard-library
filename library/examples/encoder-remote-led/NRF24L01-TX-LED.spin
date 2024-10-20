{
---------------------------------------------------------------------------------------------------
    Filename:       NRF24L01-TX-LED.spin
    Description:    Example application showing wireless control of a Smart LED (transmitter)
    Author:         Jesse Burt
    Started:        Aug 29, 2022
    Updated:        Jan 27, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    Additional devices required:
    * nRF24L01+
    * Quadrature encoder
}

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq


OBJ

    cfg:        "boardcfg.flip"
    ser:        "com.serial.terminal.ansi" | SER_BAUD=115_200
    nrf24:      "wireless.transceiver.nrf24l01" | CE=0, CS=1, SCK=2, MOSI=3, MISO=4
    encoder:    "input.encoder.quadrature" | BASEPIN=5, NUM_ENC=1, NUM_DELTA=1
    'NOTE: Two consecutive pins are used starting with encoder.BASEPIN


PUB main() | delta

    setup()

    delta := 0

' -- User-modifiable settings (NOTE: These settings _must_ match the receive side) }
    nrf24.channel(2)                            ' 0..125 (2.400 .. 2.525GHz)
    nrf24.tx_pwr(0)                             ' -18, -12, -6, 0 (dBm)

    { set syncword (note: order in string() is LSB, ..., MSB) }
    nrf24.set_syncwd(string($e7, $e7, $e7, $e7, $e7))

' --

    ser.clear()
    ser.position(0, 0)
    ser.printf1(@"Transmit mode (channel %d)\n\r", nrf24.channel(-2))

    repeat
        repeat
            delta := encoder.pos_delta(0)       ' wait for a change in encoder position
        until (delta)
        ser.printf1(@"delta: %d\n\r", delta)
        nrf24.tx_payld(4, @delta)


PUB setup()

    ser.start()
    ser.clear()

    if ( nrf24.start() )
        ser.strln(@"nRF24L01+ driver started")
        nrf24.preset_tx2m_noaa()                ' 2Mbps, no Auto-Ack
        nrf24.crc_check_ena(true)
        nrf24.crc_len(2)
        nrf24.payld_len(4)
    else
        ser.strln(@"nRF24L01+ driver failed to start - halting")
        repeat

    if ( encoder.start() )
        ser.strln(@"Quadrature encoder driver started")
    else
        ser.strln(@"Quadrature encoder driver failed to start - halting")
        repeat


DAT
{
Copyright 2024 Jesse Burt

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

