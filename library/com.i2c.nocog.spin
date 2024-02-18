{
---------------------------------------------------------------------------------------------------
    Filename:       com.i2c.nocog.spin
    Description:    Cogless I2C engine
    Author:         Jesse Burt
    Started:        Jun 9, 2019
    Updated:        Feb 18, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    Timings:
        @ 80MHz Fsys, interpreted:
            Write speed: 27.472kHz (19% duty - 7.2uS H : 29.2uS L)
            Read speed: 29.411kHz (69% duty - 23.6uS H : 10.4uS L)
        @ 80MHz Fsys, native/PASM, 100kHz target speed:
            Write speed: 94.340kHz (46% duty - 4.9uS H : 5.7uS L)
            Read speed: 100kHz (50% duty - 5.0uS H : 5.0uS L)
        @ 80MHz Fsys, native/PASM, 400kHz target speed:
            Write speed: 333.333kHz (40% duty - 1.2uS H : 1.8uS L)
            Read speed: 384.615kHz (53% duty - 1.4uS H : 1.2uS L)

    NOTE: This is based on jm_i2c.spin,
        originally by Jon McPhalen

    NOTE: Pull-up resistors are required on SDA _and_ SCL lines
        This object doesn't drive either line (open-drain, not push-pull)
}


CON

    DEF_SDA = 29                                ' Default I2C I/O pins
    DEF_SCL = 28
    DEF_HZ  = 100_000

    HIGH    = 1

CON

    #0, ACK, NAK

VAR

    long _SCL, _SDA                             ' Bus pins
    long _bittm_base


PUB null()
' This is not a top-level object


PUB init_def(): status
' Initialize I2C engine using default Propeller I2C pins
    return init(DEF_SCL, DEF_SDA, DEF_HZ)


PUB init(SCL, SDA, I2C_HZ): status
' Initialize I2C engine using custom I2C pins
'   SCL, SDA: 0..31 (each unique)
'   I2C_HZ: When built as bytecode, this is ignored.
'           When built as PASM, this is the desired target bus speed.
'           (the closest achievable speed will be set)
    longmove(@_SCL, @SCL, 2)                    ' Copy pins
    dira[_SCL] := 0                             ' Float to pull-up
    outa[_SCL] := 0                             ' output low
    dira[_SDA] := 0
    outa[_SDA] := 0

    calc_bit_time(I2C_HZ)
    return cogid()+1                            ' return current cog id


PUB deinit()
' Deinitialize - clear out hub vars
    longfill(@_SCL, 0, 2)


pub calc_bit_time(bus_speed)
' Calculate bit time based on _current_ system clock frequency
'   NOTE: This must be called again if the system clock frequency is changed during runtime
    _bittm_base := (clkfreq / bus_speed) / 2    ' calculate bit time based on system clock freq


PUB rdblock_lsbf(ptr_buff, nr_bytes, ackbit) | tmp, lastb, bnum, bh, bl
' Read nr_bytes from I2C bus into ptr_buff, LSByte-first
'   ptr_buff: pointer to buffer to read data into
'   nr_bytes: number of bytes to read from bus
'   ackbit: what the acknowledge bit for the last byte should be (ACK or NAK)
    bh := _bittm_base-51                        ' copy to locals and account for overhead
    bl := _bittm_base-51
    tmp := 0
    lastb := (nr_bytes-1)
    { LSB-first byte loop }
    repeat bnum from 0 to lastb
        dira[_SDA] := 0
        wait_clk_stretch()

        { bit loop }
        repeat 8
            dira[_SCL] := 0                     ' SCL high
            tmp := (tmp << 1) | ina[_SDA]       ' read the bit
#ifdef __OUTPUT_ASM__
            waitcnt(cnt+bh)
            dira[_SCL] := 1                     ' SCL low
            waitcnt(cnt+bl)

        { output ACK bit }
        dira[_SDA] := !((bnum == lastb) & ackbit)
        dira[_SCL] := 0
        waitcnt(cnt+bh)
        dira[_SCL] := 1
        waitcnt(cnt+bl)
#else
            dira[_SCL] := 1

        { output ACK bit }
        dira[_SDA] := !((bnum == lastb) & ackbit)
        dira[_SCL] := 0
        dira[_SCL] := 1
#endif

        byte[ptr_buff][bnum] := tmp             ' copy to dest


PUB rdblock_msbf(ptr_buff, nr_bytes, ackbit) | tmp, lastb, bnum, bh, bl
' Read nr_bytes from I2C bus into ptr_buff, MSByte-first
'   ptr_buff: pointer to buffer to read data into
'   nr_bytes: number of bytes to read from bus
'   ackbit: what the acknowledge bit for the last byte should be (ACK or NAK)
    bh := _bittm_base-51
    bl := _bittm_base-51
    tmp := 0
    lastb := (nr_bytes-1)
    { MSB-first byte loop }
    repeat bnum from lastb to 0
        dira[_SDA] := 0
        wait_clk_stretch()

        { bit loop }
        repeat 8
            dira[_SCL] := 0                     ' SCL high
            tmp := (tmp << 1) | ina[_SDA]       ' read the bit
#ifdef __OUTPUT_ASM__
            waitcnt(cnt+bh)
            dira[_SCL] := 1                     ' SCL low
            waitcnt(cnt+bl)

        { output ACK bit }
        dira[_SDA] := !((bnum == 0) & ackbit)
        dira[_SCL] := 0
        waitcnt(cnt+bh)
        dira[_SCL] := 1
        waitcnt(cnt+bl)
        dira[_SCL] := 1
#else
            dira[_SCL] := 1

        { output ACK bit }
        dira[_SDA] := !((bnum == lastb) & ackbit)
        dira[_SCL] := 0
        dira[_SCL] := 1
#endif
        byte[ptr_buff][bnum] := tmp             ' copy to dest


PUB reset() | bh, bl
' Reset I2C bus
    bh := _bittm_base
    bl := _bittm_base
    repeat 9                                    ' send up to 9 clock pulses
#ifdef __OUTPUT_ASM__
        dira[_SCL] := 1
        waitcnt(cnt+bh)
        dira[_SCL] := 0
        waitcnt(cnt+bl)
#else
        dira[_SCL] := 1
        dira[_SCL] := 0
#endif
        if (ina[_SDA])                          ' if SDA is released,
            quit                                '   our work is done - return


PUB start() | bt
' Create start or re-start condition (S, Sr)
'   NOTE: This method supports clock stretching;
'       waits while SDA pin is held low
    dira[_SDA] := 0                             ' Float SDA (1)
    wait_clk_stretch()                          ' wait: clock stretching
    bt := _bittm_base
#ifdef __OUTPUT_ASM__
    waitcnt(cnt+bt)
    dira[_SDA] := 1                             ' SDA low (0)
    waitcnt(cnt+bt)
    dira[_SCL] := 1                             ' SCL low (0)
    waitcnt(cnt+bt)
#else
    dira[_SDA] := 1                             ' SDA low (0)
    dira[_SCL] := 1                             ' SCL low (0)

#endif

PUB stop() | bt
' Create I2C Stop condition (P)
'   NOTE: This method supports clock stretching;
'       waits while SDA pin is held low
    dira[_SDA] := 1                             ' SDA low
#ifdef __OUTPUT_ASM__
    bt := _bittm_base
    waitcnt(cnt+bt)
    wait_clk_stretch()                          ' wait: clock stretching
    dira[_SDA] := 0                             ' Float SDA
    waitcnt(cnt+bt)
#else
    wait_clk_stretch()                          ' wait: clock stretching
    dira[_SDA] := 0                             ' Float SDA
#endif

PUB wait_clk_stretch()
' Wait for slave device using clock-stretching
    dira[_SCL] := 0                             ' let SCL float
    repeat until ina[_SCL] == HIGH              ' wait until slave releases it

PUB wrblock_lsbf(ptr_buff, nr_bytes): ackbit | bnum, lastb, tmp, bh, bl
' Write nr_bytes to I2C bus from ptr_buff, LSByte-first
'   ptr_buff: pointer to buffer of data to write to bus
'   nr_bytes: number of bytes to write
'   Returns: ACK/NAK bit from device
    bh := _bittm_base-10
    bl := _bittm_base-51
    tmp := 0
    lastb := (nr_bytes-1)
    { LSB-first byte loop }
    repeat bnum from 0 to lastb
        tmp := (byte[ptr_buff][bnum] ^ $FF) << 24

        { bit loop }
        repeat 8
            dira[_SDA] := tmp <-= 1             ' MSBit first
#ifdef __OUTPUT_ASM__
            waitcnt(cnt+bl)
            dira[_SCL] := 0                     ' float SCL
            waitcnt(cnt+bh)
            dira[_SCL] := 1                     ' SCL low

        { read ACK bit }
        dira[_SDA] := 0                         ' float SDA

        waitcnt(cnt+bl)
        wait_clk_stretch()
        waitcnt(cnt+bh)
        ackbit := ina[_SDA]
        dira[_SCL] := 1                         ' SCL low

        waitcnt(cnt+bl)
#else
            dira[_SCL] := 0                     ' float SCL
            dira[_SCL] := 1                     ' SCL low

        { read ACK bit }
        dira[_SDA] := 0                         ' float SDA
        wait_clk_stretch()
        ackbit := ina[_SDA]
        dira[_SCL] := 1                         ' SCL low
#endif
    return ackbit

PUB wrblock_msbf(ptr_buff, nr_bytes): ackbit | tmp, lastb, bnum, bh, bl
' Write nr_bytes to I2C bus from ptr_buff, MSByte-first
    bh := _bittm_base-10
    bl := _bittm_base-51
    tmp := 0
    lastb := (nr_bytes-1)
    { MSB-first byte loop }
    repeat bnum from lastb to 0
        tmp := (byte[ptr_buff][bnum] ^ $FF) << 24

        { bit loop }
        repeat 8
            dira[_SDA] := tmp <-= 1             ' MSBit first
#ifdef __OUTPUT_ASM__
            waitcnt(cnt+bl)
            dira[_SCL] := 0                     ' float SCL
            waitcnt(cnt+bh)
            dira[_SCL] := 1                     ' SCL low

        { read ACK bit }
        dira[_SDA] := 0                         ' float SDA

        waitcnt(cnt+bl)
        wait_clk_stretch()
        waitcnt(cnt+bh)
        ackbit := ina[_SDA]
        dira[_SCL] := 1                         ' SCL low

        waitcnt(cnt+bl)
#else
            dira[_SCL] := 0                     ' float SCL
            dira[_SCL] := 1                     ' SCL low

        { read ACK bit }
        dira[_SDA] := 0                         ' float SDA
        wait_clk_stretch()
        ackbit := ina[_SDA]
        dira[_SCL] := 1                         ' SCL low

#endif
    return ackbit

#include "com.i2c.common.spinh"                 ' R/W methods common to all I2C engines

DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

