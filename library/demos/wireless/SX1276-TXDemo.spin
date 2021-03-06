{
    --------------------------------------------
    Filename: SX1276-TXDemo.spin
    Author: Jesse Burt
    Description: Transmit demo of the SX1276 driver (LoRa mode)
    Copyright (c) 2020
    Started Dec 12, 2020
    Updated Dec 13, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD        = 115_200
    LED             = cfg#LED1

    CS_PIN          = 0
    SCK_PIN         = 1
    MOSI_PIN        = 2
    MISO_PIN        = 3
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    lora    : "wireless.transceiver.sx1276.spi"
    int     : "string.integer"
    sf      : "string.format"

VAR

    byte _buffer[256]

PUB Main{} | count

    setup{}

    ser.position(0, 3)
    ser.strln(string("Transmit mode"))

' -- TX/RX settings
    lora.presetlora{}                           ' factory defaults + LoRa mode
    lora.channel(0)                             ' US 902.3MHz + (chan# * 200kHz)
    lora.intclear(lora#INT_ALL)                 ' clear _all_ interrupts
    lora.fifotxbaseptr($00)                     ' use the whole 256-byte FIFO
                                                '   for TX
    lora.payloadlength(8)                       ' the test packets are
' --                                            '   8 bytes

' -- TX-specific settings
    lora.txsigrouting(lora#PABOOST)             ' RFO, PABOOST (board-depend.)
    lora.txpower(5)                             ' -1..14 (RFO) 5..23 (PABOOST)
    lora.intmask(lora#TX_DONE)                  ' interrupt on transmit done
    lora.txcontinuous(lora#TXMODE_NORMAL)
' --

    count := 0
    repeat
        bytefill(@_buffer, 0, 256)              ' clear temp TX buffer

        ' payload is the string 'TEST' with hexadecimal counter after
        sf.sprintf1(@_buffer, string("TEST%s"), int.hex(count, 4))
        lora.opmode(lora#STDBY)

        ' make sure the data is placed at the start of the TX FIFO
        lora.fifoaddrpointer($00)
        lora.txpayload(8, @_buffer)             ' queue the data
        lora.txmode{}                           ' finally, transmit it

        ' wait until sending is complete, then clear the interrupt
        repeat until lora.interrupt{} & lora#TX_DONE
        lora.intclear(lora#TX_DONE)

        count++
        ser.position(0, 5)
        ser.str(string("Sending: "))
        ser.str(@_buffer)
        time.msleep(5000)                       ' wait in between packets
                                                ' (don't abuse the airwaves)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if lora.start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("sx1276 driver started"))
    else
        ser.strln(string("sx1276 driver failed to start - halting"))
        lora.stop{}
        time.msleep(500)
        ser.stop{}
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
