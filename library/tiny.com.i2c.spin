{
    --------------------------------------------
    Filename: tiny.com.i2c.spin
    Author: Jesse Burt
    Description: SPIN I2C Engine
    Started Jun 9, 2019
    Updated May 23, 2022
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

PUB Present(slave_addr): status
' Check for slave device presence on bus
'   Returns:
'       FALSE (0): Device not acknowledging or in error state
'       TRUE (-1): Device acknowledges
    start{}
    return (write(slave_addr) == ACK)

PUB Rd_Byte(ackbit): i2cbyte
' Read byte from I2C bus
    rdblock_lsbf(@i2cbyte, 1, ackbit)

PUB RdBlock_LSBF(ptr_buff, nr_bytes, ack_last) | bytenum
' Read nr_bytes from I2C bus into ptr_buff, LSByte-first
    repeat bytenum from 0 to nr_bytes-1
        byte[ptr_buff][bytenum] := read(((bytenum == nr_bytes-1) & ack_last))

PUB RdBlock_MSBF(ptr_buff, nr_bytes, ack_last) | bytenum
' Read nr_bytes from I2C bus into ptr_buff, MSByte-first
    repeat bytenum from nr_bytes-1 to 0
        byte[ptr_buff][bytenum] := read(((bytenum == 0) & ack_last))

PUB RdLong_LSBF(ackbit): i2c2long
' Read long from I2C bus, least-significant byte first
    rdblock_lsbf(@i2c2long, 4, ackbit)

PUB RdLong_MSBF(ackbit): i2c2long
' Read long from I2C bus, least-significant byte first
    rdblock_msbf(@i2c2long, 4, ackbit)

PUB RdWord_LSBF(ackbit): i2c2word
' Read word from I2C bus, least-significant byte first
    rdblock_lsbf(@i2c2word, 2, ackbit)

PUB RdWord_MSBF(ackbit): i2c2word
' Read word from I2C bus, least-significant byte first
    rdblock_msbf(@i2c2word, 2, ackbit)

PUB Read(ackbit): i2cbyte
' Read byte from I2C bus
'   Valid values (ackbit):
'       NAK (1): Send NAK to slave device after reading
'       ACK (0): Send ACK to slave device after reading
    dira[_SDA] := 0                             ' Make SDA input
    waitclockstretch{}

    repeat 8
        dira[_SCL] := 0                         ' SCL high (float to p/u)
        i2cbyte := (i2cbyte << 1) | ina[_SDA]   ' Read the bit
        dira[_SCL] := 1                         ' SCL low

    dira[_SDA] := !ackbit                       ' Output ack bit
    dira[_SCL] := 0                             ' Clock it
    dira[_SCL] := 1
    return (i2cbyte & $FF)

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

PUB Wait(slave_addr) | ackbit
' Waits for I2C device to be ready for new command
'   NOTE: This method will wait indefinitely,
'   if the device doesn't respond
    repeat
        start{}
        ackbit := write(slave_addr)
    until (ackbit == ACK)

PUB WaitClockStretch{}
' Wait for slave device using clock-stretching
    dira[_SCL] := 0                             ' let SCL float
    repeat until ina[_SCL] == HIGH              ' wait until slave releases it

PUB Waitx(slaveid, ms): ackbit | tmp
' Wait ms milliseconds for I2C device to be ready for new command
'   Returns:
'       ACK(0): device responded within specified time
'       NAK(1): device didn't respond
    ms *= clkfreq / 1000                        ' ms in Propeller system clocks

    tmp := cnt                                  ' timestamp before wait loop
    repeat
        if (present(slaveid))                   ' if the device responds,
            quit                                '   exit immediately
        if ((cnt - tmp) => ms)                  ' if time limit elapses,
            return NAK                          '   exit and return No-ACK

    return ACK

PUB Wr_Byte(b): ackbit
' Write byte to I2C bus
    return wrblock_lsbf(@b, 1)

PUB WrBlock_LSBF(ptr_buff, nr_bytes): ackbit | bytenum
' Write nr_bytes to I2C bus from ptr_buff, LSByte-first
    repeat bytenum from 0 to nr_bytes-1
        ackbit := write(byte[ptr_buff][bytenum])

PUB WrBlock_MSBF(ptr_buff, nr_bytes): ackbit | bytenum
' Write nr_bytes to I2C bus from ptr_buff, MSByte-first
    repeat bytenum from nr_bytes-1 to 0
        ackbit := write(byte[ptr_buff][bytenum])

PUB WrLong_LSBF(long2i2c): ackbit
' Write long to I2C bus, least-significant byte first
    return wrblock_lsbf(@long2i2c, 4)

PUB WrLong_MSBF(long2i2c): ackbit
' Write long to I2C bus, most-significant byte first
    return wrblock_msbf(@long2i2c, 4)

PUB WrWord_LSBF(word2i2c): ackbit
' Write word to I2C bus, least-significant byte first
    return wrblock_lsbf(@word2i2c, 2)

PUB WrWord_MSBF(word2i2c): ackbit
' Write word to I2C bus, most-significant byte first
    return wrblock_msbf(@word2i2c, 2)

PUB Write(i2cbyte): ackbit
' Write byte to I2C bus
'   Returns:
'       1: NAK or no response from device
'       0: ACK from device
'   NOTE: This method leaves SCL low, when returning
    i2cbyte := (i2cbyte ^ $FF) << 24            ' MSB (bit7) to bit31
    repeat 8                                    ' Output eight bits
        dira[_SDA] := i2cbyte <-= 1             ' Send msb first
        dira[_SCL] := 0                         ' float SCL to p/u
        dira[_SCL] := 1                         ' SCL low

    dira[_SDA] := 0                             ' float SDA
#ifdef QUIRK_SCD30
    waitclockstretch{}
#endif
    ackbit := ina[_SDA]
    dira[_SCL] := 1                             ' SCL low
    return ackbit

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
