{
    --------------------------------------------
    Filename: CANBus-Loopback-Demo.spin
    Description: Demo of the bi-directional CANbus engine (500kbps)
    Author: Chris Gadd
    Modified by: Jesse Burt
    Created: 2015
    Updated: May 11, 2020
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is a modified version of CANbus Loopback demo.spin, originally by Chris Gadd
        The original header is preserved below.

  ┌────────────────────────────────────┐
  │ CANbus loopback demos              │
  │ Author: Chris Gadd                 │
  │ Copyright (c) 2015 Chris Gadd      │
  │ See end of file for terms of use.  │
  └────────────────────────────────────┘
  For this demo, place a pull-up resistor on the Tx_pin, and connect the Tx_pin to the Rx_pin - also works with loopback through a MCP2551
   The writer object transmits a bitstream containing ID, data length, and data to the reader.
   The reader object receives and decodes the bitstream, and displays it on a serial terminal at 115_200bps
}

CON
    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' User-modifiable constants
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    CAN_RX      = 25
    CAN_TX      = 24
    CAN_BPS     = 500_000

VAR

    long    _ident
    byte    _ser_cog, _can_cog
    byte    _dlc, _tx_data[8]                                   ' String of bytes to send

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    io      : "io"
    time    : "time"
    canbus  : "com.can.txrx"                                    ' Unified reader/writer, good up to 500Kbps, requires 1 cog

PUB Main | i, n

    Setup

    time.Sleep(1)
    _ident := $001                                              ' $000 is invalid and will cause reader to hang
    _dlc := 0
    n := 0

    repeat
        time.msleep(50)
        SendCAN
        CheckCAN
        _ident++
        if ++_dlc == 9
            _dlc := 0
        if _dlc
            repeat i from 0 to _dlc - 1
                _tx_data[i] := n++

PUB SendCAN

    if _dlc == 0
        canbus.SendRTR(_ident)                                  ' Send either a remote-transmission request
    else                                                        '   or a normal message
        canbus.Sendstr(_ident, @_dlc)

PUB CheckCAN | a

    if canbus.ID                                                ' Check if an ID was received
        if canbus.ID > $7FF
            ser.hex(canbus.ID, 8)
        else
            ser.hex(canbus.ID, 3)
        ser.char(ser#TB)
        if canbus.CheckRTR
            ser.str(string("Remote transmission request"))
        else
            a := canbus.DataAddress                             ' DataAddress returns the address of a string of data bytes
            repeat byte[a++]                                    '  The first byte contains the string length
                ser.hex(byte[a++],2)                            '  Display bytes
                ser.char(" ")
        ser.newline
        canbus.NextID                                           ' Clear current ID buffer and advance to next
        return TRUE

PUB Setup

    repeat until _ser_cog := ser.StartRXTX(SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.str(string("Serial terminal started", ser#CR, ser#LF))

    canbus.Loopback(TRUE)
    if _can_cog := canbus.Start(CAN_RX, CAN_TX, CAN_BPS)
        ser.str(string("CANbus engine started", ser#CR, ser#LF))
    else
        ser.str(string("CANbus engine failed to start - halting", ser#CR, ser#LF))
        canbus.Stop
        time.msleep(500)
        ser.Stop
        FlashLED(LED, 500)

#include "lib.utility.spin"

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
