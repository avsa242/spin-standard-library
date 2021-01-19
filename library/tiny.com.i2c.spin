{
    --------------------------------------------
    Filename: tiny.com.i2c.spin
    Author: Jesse Burt
    Description: SPIN I2C Engine
    Started Jun 9, 2019
    Updated Jan 19, 2021
    See end of file for terms of use.

    NOTE: This is based on jm_i2c.spin, by
        Jon McPhalen
    --------------------------------------------
}

' NOTE: Pull-up resistors are required on SDA _and_ SCL lines
'   This object doesn't drive either line (open-drain, not push-pull)

CON

    DEF_SDA = 29                                ' Default I2C I/O pins
    DEF_SCL = 28

CON

    #0, ACK, NAK

VAR

    long _scl                                   ' Bus pins
    long _sda

PUB Null
' This is not a top-level object

PUB InitDef: status
' Initialize I2C engine using default Propeller I2C pins
    return init(DEF_SCL, DEF_SDA)

PUB Init(SCL, SDA): status
' Initialize I2C engine using custom I2C pins
'   SCL, SDA: 0..31 (each unique)
'   Bus speed is approx 28-32kHz @80MHz system clock
    longmove(@_scl, @SCL, 2)                    ' Copy pins
    dira[_scl] := 0                             ' Float to pull-up
    outa[_scl] := 0                             ' Write 0 to output reg
    dira[_sda] := 0
    outa[_sda] := 0

    return cogid{}+1                            ' return current cog id

PUB DeInit
' Deinitialize - clear out hub vars
    longfill(@_scl, 0, 2)

PUB Setup 'XXX
' Setup I2C using Propeller EEPROM pins
    setupx(DEF_SCL, DEF_SDA)

PUB Setupx(sclpin, sdapin)  'XXX
' Define I2C SCL (clock) and SDA (data) pins
    longmove(@_scl, @sclpin, 2)                 ' Copy pins
    dira[_scl] := 0                             ' Float to pull-up
    outa[_scl] := 0                             ' Write 0 to output reg
    dira[_sda] := 0
    outa[_sda] := 0

    repeat 9                                    ' Reset device
        dira[_scl] := 1
        dira[_scl] := 0
        if (ina[_sda])
            quit

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

PUB Rd_Long(ackbit): i2clong
' Read long from I2C bus
    rdblock_lsbf(@i2clong, 4, ackbit)

PUB Rd_Word(ackbit): i2cword
' Read word from I2C bus
    rdblock_lsbf(@i2cword, 2, ackbit)

PUB RdBlock_LSBF(ptr_buff, nr_bytes, ack_last) | bytenum, i2cbyte
' Read nr_bytes from I2C bus into ptr_buff, LSByte-first
    repeat bytenum from 0 to nr_bytes-1
        byte[ptr_buff][bytenum] := read(((bytenum == nr_bytes-1) & ack_last))

PUB RdBlock_MSBF(ptr_buff, nr_bytes, ack_last) | bytenum, i2cbyte
' Read nr_bytes from I2C bus into ptr_buff, MSByte-first
    repeat bytenum from nr_bytes-1 to 0
        byte[ptr_buff][bytenum] := read(((bytenum == 0) & ack_last))

PUB Read(ackbit): i2cbyte
' Read byte from I2C bus
'   Valid values (ackbit):
'       NAK (1): Send NAK to slave device after reading
'       ACK (0): Send ACK to slave device after reading
    dira[_sda] := 0                             ' Make SDA input

    repeat 8
        dira[_scl] := 0                         ' SCL high (float to p/u)
        i2cbyte := (i2cbyte << 1) | ina[_sda]   ' Read the bit
        dira[_scl] := 1                         ' SCL low

    dira[_sda] := !ackbit                       ' Output ack bit
    dira[_scl] := 0                             ' Clock it
    dira[_scl] := 1

    return (i2cbyte & $FF)

PUB Reset
' Reset I2C bus
    repeat 9                                    ' send up to 9 clock pulses
        dira[_scl] := 1
        dira[_scl] := 0
        if (ina[_sda])                          ' if SDA is released,
            quit                                '   our work is done - return

PUB Start
' Create start or re-start condition (S, Sr)
'   NOTE: This method supports clock stretching;
'       waits while SDA pin is held low
    dira[_sda] := 0                             ' Float SDA (1)
    dira[_scl] := 0                             ' Float SCL (1)
    repeat while (ina[_scl] == 0)               ' Wait: clock stretch

    dira[_sda] := 1                             ' SDA low (0)
    dira[_scl] := 1                             ' SCL low (0)

PUB Stop
' Create I2C Stop condition (P)
'   NOTE: This method supports clock stretching;
'       waits while SDA pin is held low
    dira[_sda] := 1                             ' SDA low
    dira[_scl] := 0                             ' Float SCL
    repeat until (ina[_scl] == 1)               ' Wait: clock stretch

    dira[_sda] := 0                             ' Float SDA

PUB Wait(slave_addr) | ackbit
' Waits for I2C device to be ready for new command
'   NOTE: This method will wait indefinitely,
'   if the device doesn't respond
    repeat
        start{}
        ackbit := write(slave_addr)
    until (ackbit == ACK)

PUB Waitx(slaveid, ms): t0
' Wait ms milliseconds for I2C device to be ready for new command
'   Returns:
'       ACK(0): device responded within specified time
'       NAK(1): device didn't respond
    ms *= clkfreq / 1000                        ' ms in Propeller system clocks

    t0 := cnt                                   ' Mark
    repeat
        if (present(slaveid))
            quit
        if ((cnt - t0) => ms)
            return NAK

    return ACK

PUB Wr_Byte(b): ackbit
' Write byte to I2C bus
    return wrblock_lsbf(@b, 1)

PUB Wr_Long(l): ackbit
' Write long to I2C bus
'   least-significant byte first
    return wrblock_lsbf(@l, 4)

PUB Wr_Word(w): ackbit
' Write word to I2C bus
'   least-significant byte first
    return wrblock_lsbf(@w, 2)

PUB WrBlock_LSBF(ptr_buff, nr_bytes): ackbit | bytenum, i2cbyte
' Write nr_bytes to I2C bus from ptr_buff, LSByte-first
    repeat bytenum from 0 to nr_bytes-1
        ackbit := write(byte[ptr_buff][bytenum])

PUB WrBlock_MSBF(ptr_buff, nr_bytes): ackbit | bytenum, i2cbyte
' Write nr_bytes to I2C bus from ptr_buff, MSByte-first
    repeat bytenum from nr_bytes-1 to 0
        ackbit := write(byte[ptr_buff][bytenum])

PUB Write(i2cbyte): ackbit
' Write byte to I2C bus
'   Returns:
'       1: NAK or no response from device
'       0: ACK from device
'   NOTE: This method leaves SCL low, when returning
    i2cbyte := (i2cbyte ^ $FF) << 24            ' MSB (bit7) to bit31
    repeat 8                                    ' Output eight bits
        dira[_sda] := i2cbyte <-= 1             ' Send msb first
        dira[_scl] := 0                         ' float SCL to p/u
        dira[_scl] := 1                         ' SCL low

    dira[_sda] := 0                             ' float SDA
    dira[_scl] := 0                             ' float SCL
    ackbit := ina[_sda]                         ' Read ack bit
    dira[_scl] := 1                             ' SCL low

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
