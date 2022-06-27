{
    --------------------------------------------
    Filename: com.i2c.nocog.spin
    Author: Jesse Burt
    Description: SPIN I2C Engine
        @ 80MHz Fsys, interpreted:
        Write speed: 27.472kHz (19% duty - 7.2uS H : 29.2uS L)
        Read speed: 29.411kHz (69% duty - 23.6uS H : 10.4uS L)
    Started Jun 9, 2019
    Updated Jun 27, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on jm_i2c.spin,
        originally by Jon McPhalen
}

' NOTE: Pull-up resistors are required on SDA _and_ SCL lines
'   This object doesn't drive either line (open-drain, not push-pull)

CON

    DEF_SDA = 29                                ' Default I2C I/O pins
    DEF_SCL = 28
    DEF_HZ  = 100_000

    HIGH    = 1

CON

    #0, ACK, NAK

VAR

    long _SCL                                   ' Bus pins
    long _SDA

PUB Null{}
' This is not a top-level object

PUB InitDef{}: status
' Initialize I2C engine using default Propeller I2C pins
    return init(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Init(SCL, SDA, I2C_HZ): status
' Initialize I2C engine using custom I2C pins
'   SCL, SDA: 0..31 (each unique)
'   Bus speed is approx 28-32kHz @80MHz system clock
'   NOTE: I2C_HZ is for compatibility with PASM I2C engine only,
'       and is ignored
    longmove(@_SCL, @SCL, 2)                    ' Copy pins
    dira[_SCL] := 0                             ' Float to pull-up
    outa[_SCL] := 0                             ' output low
    dira[_SDA] := 0
    outa[_SDA] := 0

    return cogid{}+1                            ' return current cog id

PUB DeInit{}
' Deinitialize - clear out hub vars
    longfill(@_SCL, 0, 2)

PUB RdBlock_LSBF(ptr_buff, nr_bytes, ackbit) | tmp, lastb, bnum
' Read nr_bytes from I2C bus into ptr_buff, LSByte-first
'   ptr_buff: pointer to buffer to read data into
'   nr_bytes: number of bytes to read from bus
'   ackbit: what the acknowledge bit for the last byte should be (ACK or NAK)
    tmp := 0
    lastb := (nr_bytes-1)
    { LSB-first byte loop }
    repeat bnum from 0 to lastb
        dira[_SDA] := 0
        waitclockstretch{}

        { bit loop }
        repeat 8
            dira[_SCL] := 0                     ' SCL high
            tmp := (tmp << 1) | ina[_SDA]       ' read the bit
            dira[_SCL] := 1                     ' SCL low

        { output ACK bit }
        dira[_SDA] := !((bnum == lastb) & ackbit)
        dira[_SCL] := 0
        dira[_SCL] := 1

        byte[ptr_buff][bnum] := tmp             ' copy to dest

PUB RdBlock_MSBF(ptr_buff, nr_bytes, ackbit) | tmp, lastb, bnum
' Read nr_bytes from I2C bus into ptr_buff, MSByte-first
'   ptr_buff: pointer to buffer to read data into
'   nr_bytes: number of bytes to read from bus
'   ackbit: what the acknowledge bit for the last byte should be (ACK or NAK)
    tmp := 0
    lastb := (nr_bytes-1)
    { MSB-first byte loop }
    repeat bnum from lastb to 0
        dira[_SDA] := 0
        waitclockstretch{}

        { bit loop }
        repeat 8
            dira[_SCL] := 0                     ' SCL high
            tmp := (tmp << 1) | ina[_SDA]       ' read the bit
            dira[_SCL] := 1                     ' SCL low

        { output ACK bit }
        dira[_SDA] := !((bnum == 0) & ackbit)
        dira[_SCL] := 0
        dira[_SCL] := 1

        byte[ptr_buff][bnum] := tmp             ' copy to dest

PUB Reset{}
' Reset I2C bus
    repeat 9                                    ' send up to 9 clock pulses
        dira[_SCL] := 1
        dira[_SCL] := 0
        if (ina[_SDA])                          ' if SDA is released,
            quit                                '   our work is done - return

PUB Start{}
' Create start or re-start condition (S, Sr)
'   NOTE: This method supports clock stretching;
'       waits while SDA pin is held low
    dira[_SDA] := 0                             ' Float SDA (1)
    waitclockstretch{}                          ' wait: clock stretching

    dira[_SDA] := 1                             ' SDA low (0)
    dira[_SCL] := 1                             ' SCL low (0)

PUB Stop{}
' Create I2C Stop condition (P)
'   NOTE: This method supports clock stretching;
'       waits while SDA pin is held low
    dira[_SDA] := 1                             ' SDA low
    waitclockstretch{}                          ' wait: clock stretching

    dira[_SDA] := 0                             ' Float SDA

PUB WaitClockStretch{}
' Wait for slave device using clock-stretching
    dira[_SCL] := 0                             ' let SCL float
    repeat until ina[_SCL] == HIGH              ' wait until slave releases it

PUB WrBlock_LSBF(ptr_buff, nr_bytes): ackbit | bnum, lastb, tmp
' Write nr_bytes to I2C bus from ptr_buff, LSByte-first
'   ptr_buff: pointer to buffer of data to write to bus
'   nr_bytes: number of bytes to write
'   Returns: ACK/NAK bit from device
    tmp := 0
    lastb := (nr_bytes-1)
    { LSB-first byte loop }
    repeat bnum from 0 to lastb
        tmp := (byte[ptr_buff][bnum] ^ $FF) << 24

        { bit loop }
        repeat 8
            dira[_SDA] := tmp <-= 1             ' MSBit first
            dira[_SCL] := 0                     ' float SCL
            dira[_SCL] := 1                     ' SCL low

        { read ACK bit }
        dira[_SDA] := 0                         ' float SDA
        waitclockstretch{}
        ackbit := ina[_SDA]
        dira[_SCL] := 1                         ' SCL low
    return ackbit

PUB WrBlock_MSBF(ptr_buff, nr_bytes): ackbit | tmp, lastb, bnum
' Write nr_bytes to I2C bus from ptr_buff, MSByte-first
    tmp := 0
    lastb := (nr_bytes-1)
    { MSB-first byte loop }
    repeat bnum from lastb to 0
        tmp := (byte[ptr_buff][bnum] ^ $FF) << 24

        { bit loop }
        repeat 8
            dira[_SDA] := tmp <-= 1             ' MSBit first
            dira[_SCL] := 0                     ' float SCL
            dira[_SCL] := 1                     ' SCL low

        { read ACK bit }
        dira[_SDA] := 0                         ' float SDA
        waitclockstretch{}
        ackbit := ina[_SDA]
        dira[_SCL] := 1                         ' SCL low
    return ackbit

#include "com.i2c-common.spinh"                 ' R/W methods common to all I2C engines

{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

