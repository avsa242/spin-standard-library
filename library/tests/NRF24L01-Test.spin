{
    --------------------------------------------
    Filename: NRF24L01-Test.spin
    Author: Jesse Burt
    Description: Test harness for the NRF24L01+ driver
    Copyright (c) 2019
    Started Jan 6, 2019
    Updated May 29, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    COL_REG     = 0
    COL_SET     = 12
    COL_READ    = 24
    COL_PF      = 40

    CE_PIN      = 0
    CSN_PIN     = 1
    SCK_PIN     = 2
    MOSI_PIN    = 3
    MISO_PIN    = 4

    LED         = cfg#LED1

OBJ

    cfg   : "core.con.boardcfg.flip"
    ser   : "com.serial.terminal"
    time  : "time"
    nrf24 : "wireless.transceiver.nrf24l01.spi"
    int   : "string.integer"

VAR

    long _fails, _expanded
    byte _ser_cog, _row

PUB Main

    Setup
    ser.NewLine
    _row := 1

    RF_PWR (1)
    RF_DR (1)
    ARC (1)
    ARD (1)
    DYNPD (1)
    ENAA (1)
    EN_ACK_PAY (1)
    EN_DPL (1)
    EN_DYN_ACK (1)
    EN_RXADDR (1)
    CRCO (1)
    CW (1)
    INTMASK (1)
    SETUP_AW (1)
    RF_CH (1)
    EN_CRC (1)
    RPD (1)

    Flash (cfg#LED1, 100)

PUB RF_PWR(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from -18 to 0 step 6
            nrf24.RFPower (tmp)
            read := nrf24.RFPower (-2)
            Message (string("RF_PWR"), tmp, read)

PUB RF_DR(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 2
            nrf24.Rate (lookupz(tmp: 250, 1000, 2000))
            read := nrf24.Rate (-2)
            Message (string("RF_DR"), lookupz(tmp: 250, 1000, 2000), read)

PUB ARC(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 15
            nrf24.AutoRetransmitCount (tmp)
            read := nrf24.AutoRetransmitCount (-2)
            Message (string("ARC"), tmp, read)

PUB ARD(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 250 to 4000 step 250
            nrf24.AutoRetransmitDelay (tmp)
            read := nrf24.AutoRetransmitDelay (-2)
            Message (string("ARD"), tmp, read)

PUB DYNPD(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from %000_000 to %111_111
            nrf24.DynamicPayload (tmp)
            read := nrf24.DynamicPayload (-2)
            Message (string("DYNPD"), tmp, read)

PUB ENAA(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from %000_000 to %111_111
            nrf24.EnableAuto_Ack (tmp)
            read := nrf24.EnableAuto_Ack (-2)
            Message (string("ENAA"), tmp, read)

PUB EN_ACK_PAY(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            nrf24.EnableACK (tmp)
            read := nrf24.EnableACK (-2)
            Message (string("EN_ACK_PAY"), tmp, read)

PUB EN_DPL(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            nrf24.EnableDynPayload (tmp)
            read := nrf24.EnableDynPayload (-2)
            Message (string("EN_DPL"), tmp, read)

PUB EN_DYN_ACK(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            nrf24.DynamicACK (tmp)
            read := nrf24.DynamicACK (-2)
            Message (string("EN_DYN_ACK"), tmp, read)

PUB EN_RXADDR(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from %000_000 to %111_111
            nrf24.EnablePipe (tmp)
            read := nrf24.EnablePipe (-2)
            Message (string("EN_RXADDR"), tmp, read)

PUB CRCO(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 1 to 2
            nrf24.CRCEncoding (tmp)
            read := nrf24.CRCEncoding (-2)
            Message (string("CRCO"), tmp, read)

PUB CW(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            nrf24.CW (tmp)
            read := nrf24.CW (-2)
            Message (string("CW"), tmp, read)

PUB INTMASK(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from %000 to %111
            nrf24.IntMask (tmp)
            read := nrf24.IntMask (-2)
            Message (string("INTMASK"), tmp, read)

PUB SETUP_AW(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 3 to 5
            nrf24.AddressWidth (tmp)
            read := nrf24.AddressWidth (-2)
            Message (string("SETUP_AW"), tmp, read)

PUB RF_CH(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 127
            nrf24.Channel (tmp)
            read := nrf24.Channel (-2)
            Message (string("RF_CH"), tmp, read)

PUB EN_CRC(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to -1
            nrf24.EnableCRC (tmp)
            read := nrf24.EnableCRC (-2)
            Message (string("EN_CRC"), tmp, read)

PUB RPD(reps) | tmp, read

    _row++
    repeat reps
        tmp := nrf24.RPD
        read := nrf24.RPD
        Message (string("RPD"), tmp, read)

PUB RX_ADDR | pipe, addr[2], tmp, status

    _row++
    repeat pipe from 0 to 5
        nrf24.RXAddr (pipe, @addr)
        status := nrf24.Status
        ser.Str (string("Pipe "))
        ser.Dec (pipe)
        ser.Str (string(" address = "))
        repeat tmp from 0 to 4
            ser.Hex (addr.byte[tmp], 2)
        ser.Str (string("  status = "))
        ser.Hex (status, 8)
        ser.NewLine
    ser.NewLine

PUB TX_ADDR| addr[2], tmp

    _row++
    nrf24.TXAddr (@addr)
    ser.Str (string("TX address = "))
    repeat tmp from 0 to 4
        ser.Hex (addr.byte[tmp], 2)
    ser.Str (string("  status = "))
    ser.Hex (nrf24.Status, 8)
    ser.NewLine

PUB TrueFalse(num)

    case num
        0: ser.Str (string("FALSE"))
        -1: ser.Str (string("TRUE"))
        OTHER: ser.Str (string("???"))

PUB Message(field, arg1, arg2)

   case _expanded
        TRUE:
            ser.PositionX (COL_REG)
            ser.Str (field)

            ser.PositionX (COL_SET)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

            ser.PositionX (COL_READ)
            ser.Str (string("READ: "))
            ser.Dec (arg2)
            ser.Chars (32, 3)
            ser.PositionX (COL_PF)
            PassFail (arg1 == arg2)
            ser.NewLine

        FALSE:
            ser.Position (COL_REG, _row)
            ser.Str (field)

            ser.Position (COL_SET, _row)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

            ser.Position (COL_READ, _row)
            ser.Str (string("READ: "))
            ser.Dec (arg2)

            ser.Position (COL_PF, _row)
            PassFail (arg1 == arg2)
            ser.NewLine
        OTHER:
            ser.Str (string("DEADBEEF"))

PUB PassFail(num)

    case num
        0: ser.Str (string("FAIL"))
        -1: ser.Str (string("PASS"))
        OTHER: ser.Str (string("???"))

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL, ser#LF))
    if nrf24.Startx (CE_PIN, CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.Str(string("nRF24L01+ driver started", ser#NL, ser#LF))
    else
        ser.Str(string("nRF24L01+ driver failed to start - halting", ser#NL, ser#LF))
        nrf24.Stop
        time.MSleep (500)
        Flash(LED, 500)

PUB Flash(led_pin, delay_ms)

    dira[led_pin] := 1
    repeat
        !outa[led_pin]
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
