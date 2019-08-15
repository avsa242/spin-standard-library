{
    --------------------------------------------
    Filename: tiny.com.i2c.spin
    Author: Jon McPhalen
    Modified by: Jesse Burt
    Description: SPIN I2C Driver
    Started Jun 9, 2019
    Updated Jun 9, 2019
    See end of file for terms of use.

    NOTE: This is a derivative of jm_i2c.spin, by
        Jon McPhalen (original header preserved below)
    --------------------------------------------
}

'' =================================================================================================
''
''   File....... jm_i2c.spin
''   Purpose.... Low-level I2C routines (requires pull-ups on SCL and SDA)
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2009-2014 Jon McPhalen
''               -- elements inspired by code from Mike Green
''   E-mail.....
''   Started.... 28 JUL 2009
''   Updated.... 06 APR 2014
''
'' =================================================================================================

'  IMPORTANT Note: This code requires pull-ups on the SDA _and_ SCL lines -- it does not drive
'  the SCL line high.

CON

    DEF_SDA = 29                                                    ' Default Propeller I2C I/O pins
    DEF_SCL = 28

CON

    #0, ACK, NAK

VAR

    long _scl                                                       ' Bus pins
    long _sda

PUB Null
'' This is not a top-level object

PUB Setup
'' Setup I2C using Propeller EEPROM pins
    setupx(DEF_SCL, DEF_SDA)

PUB Setupx(sclpin, sdapin)
'' Define I2C SCL (clock) and SDA (data) pins
    longmove(@_scl, @sclpin, 2)                                     ' Copy pins
    dira[_scl] := 0                                                 ' Float to pull-up
    outa[_scl] := 0                                                 ' Write 0 to output reg
    dira[_sda] := 0
    outa[_sda] := 0

    repeat 9                                                        ' Reset device
        dira[_scl] := 1
        dira[_scl] := 0
        if (ina[_sda])
            quit

PUB Present(ctrl)
'' Pings device, returns true if ACK
    Start

    return (write(ctrl) == ACK)

PUB Wait(ctrl) | ackbit
'' Waits for I2C device to be ready for new command
    repeat
        Start
        ackbit := write(ctrl)
    until (ackbit == ACK)

PUB Start
'' Create I2C start sequence                                        (S, Sr)
'' -- will wait if I2C buss SDA pin is held low
    dira[_sda] := 0                                                 ' Float SDA (1)
    dira[_scl] := 0                                                 ' Float SCL (1)
    repeat
    while (ina[_scl] == 0)                                          ' Allow "clock stretching"

    dira[_sda] := 1                                                 ' SDA low (0)
    dira[_scl] := 1                                                 ' SCL low (0)

PUB Write(i2cbyte) | ackbit
'' Write byte to I2C buss
'' -- leaves SCL low
    i2cbyte := (i2cbyte ^ $FF) << 24                                ' Move msb (bit7) to bit31
    repeat 8                                                        ' Output eight bits
        dira[_sda] := i2cbyte <-= 1                                 ' Send msb first
        dira[_scl] := 0                                             ' SCL high (float to p/u)
        dira[_scl] := 1                                             ' SCL low

    dira[_sda] := 0                                                 ' Relase SDA to read ack bit
    dira[_scl] := 0                                                 ' SCL high (float to p/u)
    ackbit := ina[_sda]                                             ' Read ack bit
    dira[_scl] := 1                                                 ' SCL low

    return ackbit

PUB Read(ackbit) | i2cbyte
'' Read byte from I2C buss
    dira[_sda] := 0                                                 ' Make SDA input

    repeat 8
        dira[_scl] := 0                                             ' SCL high (float to p/u)
        i2cbyte := (i2cbyte << 1) | ina[_sda]                       ' Read the bit
        dira[_scl] := 1                                             ' SCL low

    dira[_sda] := !ackbit                                           ' Output ack bit
    dira[_scl] := 0                                                 ' Clock it
    dira[_scl] := 1

    return (i2cbyte & $FF)

PUB Stop
'' Create I2C stop sequence                                         (P)
    dira[_sda] := 1                                                 ' SDA low
    dira[_scl] := 0                                                 ' Float SCL
    repeat
    until (ina[_scl] == 1)                                          ' Hold for clock stretch

    dira[_sda] := 0                                                 ' Float SDA

DAT { License }

{{

  Copyright (c) 2009-2014 Jon McPhalen

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}
