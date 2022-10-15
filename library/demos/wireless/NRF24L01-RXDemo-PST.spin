{                                                                                                                
    --------------------------------------------
    Filename: NRF24L01-RXDemo-PST.spin
    Author: Jesse Burt 
    Description: nRF24L01+ Receive demo
        (PST-compatible)
        Will display data from all 6 data pipes
    Copyright (c) 2021
    Started Nov 23, 2019
    Updated Mar 19, 2021
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

OBJ

    ser         : "com.serial.terminal"
    cfg         : "boardcfg.flip"
    time        : "time"
    nrf24       : "wireless.transceiver.nrf24l01"

VAR

    byte _payload[32]
    byte _payld_len
    byte _addr[5]

PUB Main{}

    setup{}

    nrf24.channel(CHANNEL)

    receive{}

PUB Receive{} | i, payld_cnt, recv_pipe, pipe_nr

    longfill(@i, 0, 4)
    _payld_len := 8                             ' 1..32 (_must_ match TX side)

    ' Set receive address (note: order in string() is LSB, ..., MSB)
    nrf24.rxaddr(string($e7, $e7, $e7, $e7, $e7), 0, nrf24#WRITE)

    ' choose a receive mode preset (2Mbps, with or without AutoAck/ShockBurst)
    nrf24.preset_rx2m{}                         ' receive mode, 2Mbps
'    nrf24.preset_rx2m_noaa{}                    ' receive mode, 2Mbps, no AA

    repeat pipe_nr from 0 to 5
        nrf24.payloadlen(_payld_len, pipe_nr)   ' Set all pipes the same len

    ser.clear{}
    ser.position(0, 0)
    ser.str(string("Receive mode (channel "))
    ser.dec(nrf24.channel(-2))
    ser.str(string(")", ser#NL))

    ser.str(string("Listening for transmitters..."))

    repeat
        bytefill(@_payload, $00, 32)            ' Clear RX local buffer
        repeat                                  ' Wait to proceed...
            ser.position(0, 5)
            ser.str(string("Packets received: "))
            ser.dec(payld_cnt)
        until nrf24.payloadready{}              ' ...until payload received

        recv_pipe := nrf24.rxpipepending{}      ' Which pipe is the data in?
        ' copy the address of the pipe the data was received in
        nrf24.rxaddr(@_addr, recv_pipe, nrf24#READ)
        nrf24.rxpayload(_payld_len, @_payload)  ' Retrieve it into _payload
        payld_cnt++                             ' Received payload counter

        ser.position(0, 8 + (recv_pipe * 4))    ' Use the pipe number for the
        ser.str(string("Received packet on pipe "))
        ser.dec(recv_pipe)
                                                '   payload display position

        ser.str(string(" ("))
        repeat i from 4 to 0                    ' Show the pipe's _address
            ser.hex(_addr[i], 2)                ' (2..4 are only 1-byte)
        ser.char(")")

        hexdump(@_payload, 0, _payld_len, _payld_len, 0, 9 + (recv_pipe * 4))

        nrf24.intclear(%100)                    ' Clear interrupt
        nrf24.flushrx{}                         ' Flush FIFO

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

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#NL))

    if nrf24.startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.str(string("nRF24L01+ driver started", ser#NL))
    else
        ser.str(string("nRF24L01+ driver failed to start - halting", ser#NL))
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
