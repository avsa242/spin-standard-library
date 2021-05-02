{
    --------------------------------------------
    Filename: CANBus-RXDemo.spin
    Description: Demo of the bi-directional CANbus engine
        (RX mode)
    Author: Jesse Burt
    Created: May 2, 2021
    Updated: May 2, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on CANbus Loopback demo.spin,
        originally by Chris Gadd

    NOTE: This requires the use of a CANbus transceiver
        (e.g., MCP2551, TJA1051, etc) to connect the Propeller
        to the bus
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CAN_RX      = 0
    CAN_TX      = 1
    CAN_BPS     = 500_000                       ' max is 500_000
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    canbus  : "com.can.txrx"                    ' RX/TX, 500Kbps max, req 1 cog

PUB Main{} | a

    setup{}

    repeat
        if canbus.id{}                          ' check if an ID was received
            if canbus.id{} > $7FF
                ser.hex(canbus.id{}, 8)
            else
                ser.hex(canbus.id{}, 3)
            ser.char(ser#TB)
            if canbus.checkrtr{}
                ser.str(string("Remote transmission request"))
            else
                a := canbus.dataaddress{}       ' pointer to str of data bytes
                repeat byte[a++]                ' first byte contains str len
                    ser.hex(byte[a++], 2)       '  Display bytes
                    ser.char(" ")
            ser.newline
            canbus.nextid{}                     ' clear ID buffer, adv to next

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

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
