{
    --------------------------------------------
    Filename: CANBus-Loopback-Demo.spin
    Description: Demo of the bi-directional CANbus engine (500kbps)
    Author: Chris Gadd
    Modified by: Jesse Burt
    Created: 2015
    Updated: May 2, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on CANbus Loopback demo.spin,
        originally by Chris Gadd

    For this demo, place a pull-up resistor on the Tx_pin, and connect
        the Tx_pin to the Rx_pin - also works with loopback through a MCP2551
    The writer object transmits a bitstream containing
        ID, data length, and data to the reader.
    The reader object receives and decodes the bitstream,
        and displays it on a serial terminal
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CAN_RX      = 25
    CAN_TX      = 24
    CAN_BPS     = 500_000
' --

VAR

    long    _ident
    byte    _dlc, _tx_data[8]                   ' string of bytes to send

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    canbus  : "com.canbus.txrx"                 ' RX/TX, 500Kbps max, req 1 cog

PUB Main{} | i, n

    setup{}

    time.sleep(1)
    _ident := $001                              ' $000 is invalid and will cause reader to hang
    _dlc := 0
    n := 0

    repeat
        time.msleep(50)
        sendcan{}
        checkcan{}
        _ident++
        if ++_dlc == 9
            _dlc := 0
        if _dlc
            repeat i from 0 to _dlc - 1
                _tx_data[i] := n++

PUB SendCAN{}

    if _dlc == 0
        canbus.sendrtr(_ident)                  ' send a remote-trans. request
    else                                        '   or a normal message
        canbus.sendstr(_ident, @_dlc)

PUB CheckCAN{} | a

    if canbus.id{}                              ' check if an ID was received
        if canbus.id{} > $7FF
            ser.hex(canbus.id{}, 8)
        else
            ser.hex(canbus.id{}, 3)
        ser.char(ser#TB)
        if canbus.checkrtr{}
            ser.str(string("Remote transmission request"))
        else
            a := canbus.dataaddress{}            ' pointer to str of data bytes
            repeat byte[a++]                     ' first byte contains str len
                ser.hex(byte[a++], 2)            '  Display bytes
                ser.char(" ")
        ser.newline
        canbus.nextid{}                          ' clear ID buffer, adv to next

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

'    canbus.loopback(TRUE)
    canbus.start(CAN_RX, CAN_TX, CAN_BPS)
    ser.strln(string("CANbus engine started"))

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
