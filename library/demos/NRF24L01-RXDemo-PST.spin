{                                                                                                                
    --------------------------------------------
    Filename: NRF24L01-RXDemo.spin
    Author: Jesse Burt 
    Description: nRF24L01+ Receive demo (no ShockBurst/Auto Acknowledgement)
    Copyright (c) 2020
    Started Nov 23, 2019
    Updated Feb 3, 2020
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

    ser         : "com.serial.terminal"
    cfg         : "core.con.boardcfg.flip"
    io          : "io"
    time        : "time"
    int         : "string.integer"
    nrf24       : "wireless.transceiver.nrf24l01.spi"

VAR

    long _ser_cog, _nrf24_cog
    long _fifo[8]
    byte _payloadlen

PUB Main

    Setup

    ser.str(string("Press any key to begin receiving", ser#NL, ser#LF))
    ser.CharIn

    Receive

    FlashLED(LED, 100)

PUB Receive | tmp, addr[2], i, count, CD

    _payloadlen := 8                                        ' Payload length. MUST match the TX side for
    nrf24.PayloadLen (_payloadlen, 0)                       '   successful reception

    nrf24.RXMode                                            ' Start active receive mode
    nrf24.PowerUp (TRUE)
    nrf24.Channel (2)                                       ' Set receive channel. MUST match the TX side for
                                                            '   successful reception

    nrf24.AutoAckEnabledPipes(%000000)
    nrf24.PayloadReady (CLEAR)                              ' Clear Payload Ready interrupt

    addr := string($E7, $E7, $E7, $E7, $E7)                 ' Set the address
    nrf24.RXAddr (addr, 0, nrf24#WRITE)                     '   for receive pipe 0
                                                            '   MUST match TXAddr on TX side
    ser.Clear
    ser.Position(0, 0)
    ser.str(string("Receive mode: Channel "))               ' Show the currently set
    ser.Dec(nrf24.Channel(-2))                              '   channel
    ser.newline

    ser.str(string("Listening for traffic on node address $"))
    nrf24.RXAddr(@addr, 0, nrf24#READ)                      ' Read back receive pipe 0 address
    repeat i from 4 to 0                                    ' ...
        ser.Hex(addr.byte[i], 2)                            '   and show it
    ser.Newline

    count := 0                                              ' Zero the received packets counter
    repeat
        bytefill (@_fifo, $00, 32)                          ' Clear RX local buffer
        repeat                                              ' Wait to proceed
            ser.Position(0, 5)                              ' .
            ser.str(string("Carrier: "))                    ' .
            CD := ||(nrf24.RSSI == -64)                     ' . While we're waiting, 
            ser.dec(CD)                                     ' .     show the carrier detect flag
            ser.newline                                     ' .
            ser.str(string("Packets received: "))           ' .     and also the number of packets received
            ser.dec(count)                                  ' .
        until nrf24.PayloadReady(-2)                        ' until we've received at least _payloadlen bytes

        ser.position(0, 8)
        ser.str(string("Receiving"))
        nrf24.RXPayload(_payloadlen, @_fifo)                ' Retrieve it into our local buffer
        count++                                             ' Increment received payload counter

        Hexdump(@_fifo, 0, _payloadlen, _payloadlen, 0, 9)

        nrf24.PayloadReady(CLEAR)                           ' Clear interrupt
        nrf24.FlushRX                                       '   and Flush FIFO. Ready for the next packet

PRI HexDump(buff_addr, base_addr, nr_bytes, columns, x, y) | maxcol, maxrow, digits, hexoffset, ascoffset, offset, hexcol, asccol, row, col, currbyte
' Display a hexdump of a region of memory
'   buff_addr: Start address of memory
'   base_addr: Address used to display as base address in hex dump (affects display only)
'   nr_bytes: Total number of bytes to display
'   columns: Number of bytes to display on each line
'   x, y: Terminal position to display start of hex dump
    maxcol := columns-1
    maxrow := nr_bytes / columns
    digits := 5                                                 ' Number of digits used to display offset
    hexoffset := digits + 2
    ascoffset := hexoffset + (columns * 3)
    offset := 0

    repeat row from y to y+maxrow
        ser.Position (x, row)
        ser.Hex (base_addr+offset, digits)                          ' Show offset address of row in 'digits'
        ser.Str (string(": "))
        repeat col from 0 to maxcol
            currbyte := byte[buff_addr][offset]
            offset++
            hexcol := x + (col * 3) + hexoffset                 ' Compute the terminal X position of the hex byte
            asccol := x + col + ascoffset                       ' and the ASCII character

            ser.Position (hexcol, row)                              ' Show the ASCII value in hex
            ser.Hex (currbyte, 2)                                   '   of the current byte

            ser.Position (asccol, row)                              ' Show the ASCII character
            case currbyte                                       '   of the current byte
                32..127:                                        '   IF it's a printable character
                    ser.Char (currbyte)
                OTHER:                                          '   Otherwise, just show a period
                    ser.Char (".")
            if offset > nr_bytes-1
                return

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.str(string("Serial terminal started", ser#NL, ser#LF))
    if _nrf24_cog := nrf24.Startx (CE_PIN, CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.str(string("nRF24L01+ driver started", ser#NL, ser#LF))
    else
        ser.str(string("nRF24L01+ driver failed to start - halting", ser#NL, ser#LF))
        FlashLED (LED, 500)

PUB FlashLED(led_pin, delay_ms)

    io.Output(led_pin)
    repeat
        io.Toggle (led_pin)
        time.MSleep (delay_ms)

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
