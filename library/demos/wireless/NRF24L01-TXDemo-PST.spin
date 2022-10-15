{
    --------------------------------------------
    Filename: NRF24L01-TXDemo-PST.spin
    Author: Jesse Burt
    Description: nRF24L01+ Transmit demo
        (PST-compatible)
    Copyright (c) 2021
    Started Nov 23, 2019
    Updated Mar 19, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

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
    int         : "string.integer"
    nrf24       : "wireless.transceiver.nrf24l01"

VAR

    byte _payload[32]
    byte _payld_len
    byte _addr[5]

PUB Main{}

    setup{}

    nrf24.channel(CHANNEL)
    transmit{}

PUB Transmit{} | payld_cnt, tmp, i, max_retrans, pkts_retrans, lost_pkts

    _payld_len := 8
    longfill(@payld_cnt, 0, 6)

    ' Set transmit/receive address (note: order in string() is LSB, ..., MSB)
    nrf24.nodeaddress(string($e7, $e7, $e7, $e7, $e7))
    nrf24.txaddr(@_addr, nrf24#READ)            ' read it back

    ' choose a transmit mode preset (2Mbps, with or without AutoAck/ShockBurst)
    nrf24.preset_tx2m{}                         ' transmit mode, 2Mbps
'    nrf24.preset_tx2m_noaa{}                    ' transmit mode, 2Mbps, no AA
    nrf24.txpower(0)                            ' -18, -12, -6, 0 (dBm)

    nrf24.payloadlen(_payld_len, 0)             ' 1..32 (len), 0..5 (pipe #)

    ser.clear{}
    ser.position(0, 0)
    ser.str(string("Transmit mode (channel "))
    ser.dec(nrf24.channel(-2))
    ser.str(string(")", ser#NL))
    ser.str(string("Transmitting..."))

    _payload[0] := "T"                          ' Start of payload
    _payload[1] := "E"
    _payload[2] := "S"
    _payload[3] := "T"

    repeat
        ' Collect some packet statistics
        max_retrans := nrf24.maxretransreached{}
        pkts_retrans := nrf24.packetsretransmitted{}
        lost_pkts := nrf24.lostpackets{}

        ser.position(0, 5)
        ser.str(string("Max retransmissions reached? "))
        ser.str(lookupz(||(max_retrans): string("No "), string("Yes")))

        ser.str(string(ser#NL, "Packets retransmitted: "))
        ser.str(int.decpadded(pkts_retrans, 2))

        ser.str(string(ser#NL, "Lost packets: "))
        ser.str(int.decpadded(lost_pkts, 2))

        if max_retrans == TRUE                  ' Max retransmissions reached?
            nrf24.intclear(%001)                '   If yes, clear the int

        if lost_pkts => 15                      ' Packets lost exceeds 15?
            nrf24.channel(CHANNEL)              '   If yes, clear the int

        tmp := int.deczeroed(payld_cnt++, 4)    ' Tack a counter onto the
        bytemove(@_payload[4], tmp, 4)          '   end of the payload
        ser.position(0, 10)
        ser.str(string("Transmitting packet "))

        ser.char("(")
        repeat i from 4 to 0                    ' Show address transmitting to
            ser.hex(_addr[i], 2)
        ser.str(string(")", ser#NL))

        ' Show what will be transmitted
        hexdump(@_payload, 0, _payld_len, _payld_len, 0, 11)

        nrf24.txpayload(_payld_len, @_payload)

        time.msleep(1000)                       ' Optional inter-packet delay

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
        ser.str(string("NRF24L01+ driver started", ser#NL))
    else
        ser.str(string("NRF24L01+ driver failed to start - halting", ser#NL))
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
