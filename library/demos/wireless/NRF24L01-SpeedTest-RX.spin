{
    --------------------------------------------
    Filename: NRF24L01-SpeedTest-RX.spin
    Author: Jesse Burt
    Description: Speed test for nRF24L01+ modules
        RX Mode
    Copyright (c) 2021
    Started Apr 30, 2020
    Updated Oct 16, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CE_PIN      = 8
    CS_PIN      = 9
    SCK_PIN     = 10
    MOSI_PIN    = 11
    MISO_PIN    = 12

    PKTLEN      = 32                            ' 1..32 (bytes)
    CHANNEL     = 2                             ' 0..125 (2.400..2.525GHz)
' --

    CLEAR       = 1

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    nrf24   : "wireless.transceiver.nrf24l01"

VAR

    long _ctr_stack[50]
    long _iteration, _timer_set
    byte _rxdata[PKTLEN]
    byte _addr[5]

PUB main{} | i, iteration, testtime, pipe_nr

    setup{}
    testtime := 1_000                           ' mSec

    bytemove(@_addr, string($E7, $E7, $E7, $E7, $E7), 5)
    nrf24.rx_addr(@_addr, 0, nrf24#WRITE)       ' set receiver address

    nrf24.powered(true)
    nrf24.channel(CHANNEL)
    nrf24.rx_mode{}

' Experiment with these to observe effect on throughput
'   NOTE: The transmitter's settings _must_ match these
    nrf24.data_rate(2_000_000)                  ' 250_000, 1_000_000, 2_000_000
    nrf24.auto_ack_pipes_ena(%000011)
    nrf24.tx_pwr(0)                             ' -18, -12, -6, 0 (dBm)
                                                ' (for auto-ack, if enabled)
    nrf24.crc_check_ena(true)
    nrf24.crc_len(1)                            ' 1, 2 (bytes)

    repeat pipe_nr from 0 to 5                  ' set pipe payload sizes
        nrf24.payld_len(PKTLEN, pipe_nr)        ' _must_ match TX

    ser.position(0, 4)
    ser.str(string("Waiting for transmitters on "))
    repeat i from 4 to 0                        ' show address receiving on
        ser.hex(_addr[i], 2)
    ser.newline

    nrf24.flush_rx{}                            ' clear rx fifo
    nrf24.int_clr(%100)                       ' clear interrupt
    repeat
        iteration := 0
        _timer_set := testtime                  ' trigger the timer

        repeat while _timer_set                 ' loop while timer is >0
            repeat until nrf24.payld_rdy{}      ' wait for rx data
            nrf24.int_clr(%100)               ' _must_ clear interrupt
            nrf24.rx_payld(PKTLEN, @_rxdata)    ' retrieve payload
            iteration++                         ' tally up # payloads rx'd

        ser.position(0, 6)
        report(testtime, iteration)             ' show the results

PRI cog_counter | time_left
' Millisecond timer
    repeat
        repeat until _timer_set                 ' wait for trigger
        time_left := _timer_set

        repeat                                  ' ~1ms loop
            time_left--
            time.msleep(1)
        while (time_left > 0)
        _timer_set := 0                         ' reset timer

PRI report(testtime, iterations) | rate_iterations, rate_bytes, rate_kbits
' Show results of test
    rate_iterations := iterations / (testtime/1000)         ' # payloads/sec
    rate_bytes := (iterations * PKTLEN) / (testtime/1000)   ' # bytes/sec
    rate_kbits := (rate_bytes * 8) / 1024                   ' # kbits/sec

    ser.printf4(string("Total iterations: %d, iterations/sec: %d, Bps: %d (%dkbps)"), iterations, {
}   rate_iterations, rate_bytes, rate_kbits)
    ser.clearline{}

PUB setup

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear
    ser.strln(string("Serial terminal started"))

    if nrf24.startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("nRF24L01+ driver started"))
    else
        ser.strln(string("nRF24L01+ driver failed to start - halting"))
        repeat

    cognew(cog_counter{}, @_ctr_stack)

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

