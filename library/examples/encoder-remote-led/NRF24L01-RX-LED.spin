{
---------------------------------------------------------------------------------------------------
    Filename:       NRF24L01-RX-LED.spin
    Description:    Example application showing wireless control of a Smart LED (receiver)
    Author:         Jesse Burt
    Started:        Aug 29, 2022
    Updated:        Jan 27, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    Additional devices required:
    * nRF24L01+
    * 1x Smart LED (aka NeoPixel; can be any model supported by display.led.smart.spin)
}

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq

' -- User-modifiable constants
    COLOR       = RED                           ' choose from below
' --

    RED         = 24
    GREEN       = 16
    BLUE        = 8
    WHITE       = 0                             ' not all models have this


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    nrf24:  "wireless.transceiver.nrf24l01" | CE=0, CS=1, SCK=2, MOSI=3, MISO=4
    led:    "display.led.smart" | LED_PIN=5, MODEL=$2812


VAR

    long _led


PUB main() | bright, last, payload

    setup()

    bright := 0
    last := 0

' -- User-modifiable settings (NOTE: These settings _must_ match the transmit side) }
    nrf24.channel(2)                            ' 0..125 (2.400 .. 2.525GHz)

    { set syncword (note: order in string() is LSB, ..., MSB) }
    nrf24.set_syncwd(string($e7, $e7, $e7, $e7, $e7))
' --

    ser.clear()
    ser.pos_xy(0, 0)
    ser.printf1(@"Receive mode (channel %d)\n\r", nrf24.channel(-2))

    repeat
        { clear local buffer and wait until a payload is received }
        payload := 0
        repeat until nrf24.payld_rdy()
        nrf24.rx_payld(4, @payload)

        { Only allow changes of up to +/- 5 from the last encoder reading received, so
            possible transmission glitches causing reception of bad values like 256
            don't cause the LED to suddenly go full-brightness.
            Also, clamp the brightness to the range 0..255 }
        if (||(last-payload) =< 5)
            last := payload
            bright := 0 #> (bright + payload) <# 255
            led.plot(0, 0, bright << COLOR)
            led.show()

        { clear interrupt and receive buffer for next loop }
        nrf24.int_clear(nrf24.INT_PAYLD_RDY)
        nrf24.flush_rx()


PUB setup()

    ser.start()
    ser.clear()
    if ( nrf24.start() )
        ser.strln(@"nRF24L01+ driver started")
        nrf24.preset_rx2m_noaa()                ' 2Mbps, No Auto-Ack
        nrf24.crc_check_ena(true)
        nrf24.crc_len(2)
        nrf24.payld_len(4)
    else
        ser.strln(@"nRF24L01+ driver failed to start - halting")
        repeat

    led.start()
    led.clear()
    led.show()


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

