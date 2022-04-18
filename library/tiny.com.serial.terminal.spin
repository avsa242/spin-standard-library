{
    --------------------------------------------
    Filename: tiny.com.serial.terminal.spin
    Author: Jesse Burt
    Description: UART/serial engine (SPIN-based)
        with extended terminal I/O
        (based on Simple_Serial.spin, originally by
        Chip Gracey, Phil Pilgrim, Jon Williams, Jeff Martin)
    Started May 31, 2021
    Updated May 31, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Simple_Serial.spin,
        originally by Chip Gracey, Phil Pilgrim,
        Jon Williams, Jeff Martin
}

' NOTE: Maximum bitrate is approx 19.2kbps at 80MHz system clock
' NOTE: TX/RX methods operate block the calling method.
'   For concurrent operation with application code,
'   use com.serial.terminalspin, instead (multi-core/cog)

CON

    SER_RX_DEF      = 31
    SER_TX_DEF      = 30

VAR

    long  _rx_pin, _tx_pin, _inverted, _bit_time, _rx_okay, _tx_okay

PUB Null{}
' This is not a top-level object

PUB Start(bps): okay
' Start using standard serial I/O pins
    startrxtx(SER_RX_DEF, SER_TX_DEF, bps)

PUB StartRXTX(rx_pin, tx_pin, bps): okay
' Start using custom I/O pins and baud rate
'   NOTE: For true mode (start bit = 0), use positive baud value.
'       Ex: serial.startrxtx(0, 1, 9600)

'   NOTE: For inverted mode (start bit = 1), use negative baud value.
'       Ex: serial.startrxtx(0, 1, -9600)

'   NOTE: Specify -1 for "unused" rx_pin or tx_pin if only one-way
'       communication desired.

'   NOTE: Specify same value for rx_pin and tx_pin for bi-directional
'       communication on that pin and connect a pull-up/pull-down resistor
'       to that pin (depending on true/inverted mode) since pin will set
'       it to hi-z (input) at the end of transmission to avoid
'       electrical conflicts.  See "Same-Pin (Bi-Directional)" examples, below.
{
EXAMPLES:

Standard Two-Pin Bi-Directional True/Inverted Modes

Ex: serial.startrxtx(0, 1, 9600)

    Propeller P0|<-------------|I/O Device
              P1|------------->|


Standard One-Pin Uni-Directional True/Inverted Mode
Ex: serial.startrxtx(0, -1, 9600)  -or-  serial.startrxtx(-1, 0, 9600)
    serial.startrxtx(0, -1, -9600) -or-  serial.startrxtx(-1, 0, -9600)

    Propeller P0|--------------|I/O Device


Same-Pin (Bi-Directional) True Mode
Ex: serial.startrxtx(0, 0, 9600)

                       3.3v
                        |
                        /
                        \ 4.7k
                        /
                        |
    Propeller P0|<>----------<>|I/O Device


Same-Pin (Bi-Directional) Inverted Mode
Ex: serial.startrxtx(0, 0, -9600)

    Propeller P0|<>----------<>|I/O Device
}

    stop{}                                              ' clean-up if restart

    _rx_okay := rx_pin > -1                             ' receiving?
    _tx_okay := tx_pin > -1                             ' transmitting?

    _rx_pin := rx_pin & $1F                             ' set rx pin
    _tx_pin := tx_pin & $1F                             ' set tx pin

    _inverted := bps < 0                                ' set _inverted flag
    _bit_time := clkfreq / ||(bps)                      ' calculate bit time

    return _rx_okay | _tx_okay

PUB Stop{}
' Stop UART engine (release transmit pin, deinitialize hub variables)
    if _tx_okay                                         ' if tx enabled
        dira[_tx_pin] := 0                              '   float tx pin
    _rx_okay := _tx_okay := false

PUB Char(txbyte) | t
' Transmit a byte
'   NOTE: blocks caller until byte transmitted
    if _tx_okay
        outa[_tx_pin] := !_inverted                     ' set idle state
        dira[_tx_pin] := 1                              ' make tx pin an output
        txbyte := ((txbyte | $100) << 2) ^ _inverted    ' add stop bit, set mode
        t := cnt                                        ' sync
        repeat 10                                       ' start + 8 data + stop
            waitcnt(t += _bit_time)                 ' wait bit time
            outa[_tx_pin] := (txbyte >>= 1) & 1     ' output bit (true mode)

        if _tx_pin == _rx_pin
            dira[_tx_pin] := 0                          ' float tx pin

PUB CharIn{}: rxbyte | t
' Receive a byte
'   NOTE: blocks caller until byte received
    if _rx_okay
        dira[_rx_pin] := 0                              ' make rx pin an input
        waitpeq(_inverted & |< _rx_pin, |< _rx_pin, 0)  ' wait for start bit
        t := cnt + _bit_time >> 1                       ' sync + 1/2 bit
        repeat 8
            waitcnt(t += _bit_time)                     ' wait for middle of bit
            rxbyte := ina[_rx_pin] << 7 | rxbyte >> 1   ' sample bit
        waitcnt(t + _bit_time)                          ' allow for stop bit

        rxbyte := (rxbyte ^ _inverted) & $FF            ' adjust for mode and
                                                        '  strip off high bits

#include "lib.terminal.spin"

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

