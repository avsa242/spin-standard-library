{
    --------------------------------------------
    Filename: com.i2c.spin
    Author: Jesse Burt
    Description: PASM I2C Engine
        @ 80MHz Fsys, native code:
        100kHz:
        Write speed: 91.964kHz actual (48% duty - 5.2uS H : 5.6uS L)
        Read speed: 90.908kHz actual (47% duty - 5.2uS H : 5.7uS L)

        400kHz:
        Write speed: 312.422kHz actual (35% duty - 1.1uS H : 2.0 uS L)
        Read speed: 277.699kHz actual (45% duty - 1.6uS H : 1.9 uS L)

        1MHz:
        Write speed: 554.923kHz actual (35% duty - 0.6uS H : 1.1 uS L)
        Read speed: 454.483kHz actual (36% duty - 0.8uS H : 1.4 uS L)

    Started Mar 9, 2019
    Updated Oct 10, 2022
    See end of file for terms of use.

    NOTE: This is based on jm_i2c_fast_2018.spin, by
        Jon McPhalen
    --------------------------------------------
}

'   NOTE: Pull-up resistors are required on SDA _and_ SCL lines
'   This object doesn't drive either line (open-drain, not push-pull)
'
'   NOTE: Cog value stored in DAT table which is shared across all object uses;
'       all objects that use this object MUST use the same I2C bus pins

CON

    DEF_SDA = 29                                ' Default I2C I/O pins
    DEF_SCL = 28

    #0, ACK, NAK
    #1, I2C_START, I2C_WRITE_LE, I2C_WRITE_BE, I2C_READ_LE, I2C_READ_BE,{
}   I2C_STOP                                    ' PASM engine Commands

VAR

    long  _i2c_cmd
    long  _i2c_params
    long  _i2c_result
    long _cog

PUB null
' This is not a top-level object

PUB init_def(HZ): status
' Initialize I2C engine using default Propeller I2C pins
'   HZ: I2C bus speed, in Hz (1..approx 1_000_000)
'   NOTE: Aborts if cog is already running
    status := init(DEF_SCL, DEF_SDA, HZ)

PUB init(SCL, SDA, HZ): status
' Initialize I2C engine using custom I2C pins
'   SCL, SDA: 0..31 (each unique)
'   HZ: I2C bus speed, in Hz (1..approx 1_000_000)
'   NOTE: Aborts if cog is already running
    if (_cog)
        return

    ' passed to PASM I2C engine:
    _i2c_cmd.byte[0] := SCL
    _i2c_cmd.byte[1] := SDA
    _i2c_cmd.word[1] := clkfreq / hz            ' bus clock full cycle time

    _cog := cognew(@fast_i2c, @_i2c_cmd) + 1    ' start PASM engine

    return _cog

PUB deinit
' Deinitialize/stop PASM engine
    if (_cog)                                   ' check it's actually started
        cogstop(_cog-1)                         ' first, before trying to stop
        _cog := 0

    longfill(@_i2c_cmd, 0, 4)

PUB rdblock_lsbf(ptr_buff, nr_bytes, ack_last)
' Read nr_bytes from I2C bus to ptr_buff
'   Least-significant byte first
'   ack_last:
'       ACK (0): Acknowledge last byte read from bus
'       NAK (non-zero): Don't acknowledge last byte read from bus
'   NOTE: This method supports clock stretching;
'       waits while SCL pin is held low
    _i2c_params.word[0] := ptr_buff
    _i2c_params.word[1] := nr_bytes

    if (ack_last)
        ack_last := $80

    _i2c_cmd := I2C_READ_LE | ack_last
    repeat while (_i2c_cmd <> 0)

PUB rdblock_msbf(ptr_buff, nr_bytes, ack_last)
' Read nr_ytes from I2C bus to ptr_buff,
'   Most-significant byte first
'   ack_last:
'       ACK (0): Acknowledge last byte read from bus
'       NAK (non-zero): Don't acknowledge last byte read from bus
'   NOTE: This method supports clock stretching;
'       waits while SCL pin is held low
    _i2c_params.word[0] := ptr_buff
    _i2c_params.word[1] := nr_bytes

    if (ack_last)
        ack_last := $80

    _i2c_cmd := I2C_READ_BE | ack_last
    repeat while (_i2c_cmd <> 0)

PUB start
' Create I2C start/restart condition (S, Sr)
'   NOTE: This method supports clock stretching;
'       waits while SCL pin is held low
    _i2c_cmd := I2C_START
    repeat while (_i2c_cmd <> 0)

PUB stop
' Create I2C stop condition (P)
'   NOTE: This method supports clock stretching;
'       waits while SCL pin is held low
    _i2c_cmd := I2C_STOP
    repeat while (_i2c_cmd <> 0)

PUB wrblock_lsbf(ptr_buff, nr_bytes): ackbit
' Write block of nr_bytes bytes from ptr_buff to I2C bus,
'   Least-Significant byte first
    _i2c_params.word[0] := ptr_buff
    _i2c_params.word[1] := nr_bytes

    _i2c_cmd := I2C_WRITE_LE
    repeat while (_i2c_cmd <> 0)

    return _i2c_result                          ' Return ACK or NAK

PUB wrblock_msbf(ptr_buff, nr_bytes): ackbit
' Write block of nr_bytes bytes from ptr_buff to I2C bus,
'   Most-significant byte first
    _i2c_params.word[0] := ptr_buff
    _i2c_params.word[1] := nr_bytes

    _i2c_cmd := I2C_WRITE_BE
    repeat while (_i2c_cmd <> 0)

    return _i2c_result                          ' Return ACK or NAK

#include "com.i2c.common.spinh"                 ' R/W methods common to all I2C engines

DAT

                        org     0

fast_i2c                mov     outa, #0                        ' Clear outputs
                        mov     dira, #0
                        rdlong  t1, par                         ' Read pins and delaytix
                        mov     t2, t1                          ' Copy for scl pin
                        and     t2, #$1F                        ' Isolate scl
                        mov     sclmask, #1                     ' Create mask
                        shl     sclmask, t2
                        mov     t2, t1                          ' Copy for sda pin
                        shr     t2, #8                          ' Isolate scl
                        and     t2, #$1F
                        mov     sdamask, #1                     ' Create mask
                        shl     sdamask, t2
                        mov     delaytix, t1                    ' Copy for delaytix
                        shr     delaytix, #16

                        mov     t1, #9                          ' Reset device
:loop                   or      dira, sclmask
                        call    #hdelay
                        andn    dira, sclmask
                        call    #hdelay
                        test    sdamask, ina            wc      ' Sample sda
        if_c            jmp     #cmd_exit                       ' If high, exit
                        djnz    t1, #:loop
                        jmp     #cmd_exit                       ' Clear parameters

get_cmd                 rdlong  t1, par                 wz      ' Check for command
        if_z            jmp     #get_cmd

                        mov     tcmd, t1                        ' Copy to save data
                        and     t1, #%111                       ' Isolate command

                        cmp     t1, #I2C_START          wz
        if_e            jmp     #cmd_start

                        cmp     t1, #I2C_WRITE_LE       wz
        if_e            jmp     #cmd_write_le

                        cmp     t1, #I2C_WRITE_BE       wz
        if_e            jmp     #cmd_write_be

                        cmp     t1, #I2C_READ_LE        wz
        if_e            jmp     #cmd_read_le

                        cmp     t1, #I2C_READ_BE        wz
        if_e            jmp     #cmd_read_be

                        cmp     t1, #I2C_STOP           wz
        if_e            jmp     #cmd_stop

cmd_exit                mov     t1, #0                          ' Clear old command
                        wrlong  t1, par
                        jmp     #get_cmd



cmd_start               andn    dira, sdamask                   ' Float SDA (1)
                        andn    dira, sclmask                   ' Float SCL (1, input)
                        nop
:loop                   test    sclmask, ina            wz      ' SCL -> Z
        if_z            jmp     #:loop                          ' Wait while low
                        call    #hdelay
                        or      dira, sdamask                   ' SDA low
                        call    #hdelay
                        or      dira, sclmask                   ' SCL low
                        call    #hdelay
                        jmp     #cmd_exit



cmd_write_le            mov     t1, par                         ' Address of command
                        add     t1, #4                          ' Address of parameters
                        rdlong  thubsrc, t1                     ' Read parameters
                        mov     tcount, thubsrc                 ' Copy
                        and     thubsrc, HX_FFFF                ' Isolate p_src
                        shr     tcount, #16                     ' Isolate count
                        mov     tackbit, #ACK                   ' Assume okay

:byteloop               rdbyte  t2, thubsrc                     ' Get byte
                        add     thubsrc, #1                     ' Increment source pointer
                        shl     t2, #24                         ' Position msb
                        mov     tbits, #8                       ' Prep for 8 bits out

:bitloop                rcl     t2, #1                  wc      ' Bit31 -> carry
                        muxnc   dira, sdamask                   ' Carry -> SDA
                        call    #hdelay                         ' Hold a quarter period
                        andn    dira, sclmask                   ' Clock high
                        call    #hdelay
                        or      dira, sclmask                   ' Clock low
                        djnz    tbits, #:bitloop

                        ' Read ack/nak

                        andn    dira, sdamask                   ' Make SDA input
                        call    #hdelay
                        andn    dira, sclmask                   ' SCL high
#ifdef QUIRK_SCD30
:wrle_waitack           test    sclmask, ina            wz      ' wait: clock stretch
        if_z            jmp     #:wrle_waitack
#endif
                        call    #hdelay
                        test    sdamask, ina            wc      ' Test ackbit
        if_c            mov     tackbit, #NAK                   ' Mark if NAK
                        or      dira, sclmask                   ' SCL low
                        call    #hdelay
                        call    #hdelay
                        djnz    tcount, #:byteloop

                        mov     thubdest, par
                        add     thubdest, #8                    ' Point to _i2c_result
                        wrlong  tackbit, thubdest               ' Write ack/nak bit
                        jmp     #cmd_exit

cmd_write_be            mov     t1, par                         ' Address of command
                        add     t1, #4                          ' Address of parameters
                        rdlong  thubsrc, t1                     ' Read parameters
                        mov     tcount, thubsrc                 ' Copy
                        and     thubsrc, HX_FFFF                ' Isolate p_src
                        shr     tcount, #16                     ' Isolate count
                        mov     tackbit, #ACK                   ' Assume okay
                        add     thubsrc, tcount                 ' start at the top addr
                        sub     thubsrc, #1                     '   minus 1

:byteloop               rdbyte  t2, thubsrc                     ' Get byte
                        sub     thubsrc, #1                     ' Decrement source pointer
                        shl     t2, #24                         ' Position msb
                        mov     tbits, #8                       ' Prep for 8 bits out

:bitloop                rcl     t2, #1                  wc      ' Bit31 -> carry
                        muxnc   dira, sdamask                   ' Carry -> SDA
                        call    #hdelay                         ' Hold a quarter period
                        andn    dira, sclmask                   ' Clock high
                        call    #hdelay
                        or      dira, sclmask                   ' Clock low
                        djnz    tbits, #:bitloop

                        ' Read ack/nak

                        andn    dira, sdamask                   ' Make SDA input
                        call    #hdelay
                        andn    dira, sclmask                   ' SCL high
#ifdef QUIRK_SCD30
:wrbe_waitack           test    sclmask, ina            wz      ' wait: clock stretch
        if_z            jmp     #:wrbe_waitack
#endif
                        call    #hdelay
                        test    sdamask, ina            wc      ' Test ackbit
        if_c            mov     tackbit, #NAK                   ' Mark if NAK
                        or      dira, sclmask                   ' SCL low
                        djnz    tcount, #:byteloop

                        mov     thubdest, par
                        add     thubdest, #8                    ' Point to _i2c_result
                        wrlong  tackbit, thubdest               ' Write ack/nak bit
                        jmp     #cmd_exit

cmd_read_be             mov     tackbit, tcmd                   ' (tackbit := tcmd.bit[7])
                        shr     tackbit, #7                     ' Remove cmd
                        and     tackbit, #1                     ' Isolate
                        mov     t1, par                         ' Address of command
                        add     t1, #4                          ' Address of parameters
                        rdlong  thubdest, t1                    ' Read parameters
                        mov     tcount, thubdest                ' Copy
                        and     thubdest, HX_FFFF               ' Isolate p_dest
                        shr     tcount, #16                     ' Isolate count
                        add     thubdest, tcount                ' start at the top addr
                        sub     thubdest, #1                    '   minus 1

:byteloop               andn    dira, sdamask                   ' Make SDA input
                        andn    dira, sclmask                   ' let SCL float
:rdbe_pre_waitcs        test    sclmask, ina            wz      ' wait for slave
        if_z            jmp     #:rdbe_pre_waitcs               '   to release it
                        mov     t2, #0                          ' Clear result
                        mov     tbits, #8                       ' Prep for 8 bits

:bitloop                call    #qdelay
                        andn    dira, sclmask                   ' SCL high
                        call    #hdelay
                        shl     t2, #1                          ' Prep for new bit
                        test    sdamask, ina            wc      ' Sample SDA
                        muxc    t2, #1                          ' New bit to t2.bit0
                        or      dira, sclmask                   ' SCL low
                        call    #qdelay
                        djnz    tbits, #:bitloop

                        ' write ack/nak

                        cmp     tcount, #1              wz      ' Last byte?
        if_nz           jmp     #:ack                           ' If no, do ACK
                        xor     tackbit, #1             wz      ' Test user test ackbit
:ack    if_nz           or      dira, sdamask                   ' ACK (SDA low)
:nak    if_z            andn    dira, sdamask                   ' NAK (SDA high)
                        call    #qdelay
                        andn    dira, sclmask                   ' SCL high
                        call    #hdelay
                        or      dira, sclmask                   ' SCL low
                        call    #qdelay

                        andn    dira, sdamask                   ' float SDA
                        wrbyte  t2, thubdest                    ' Write result to p_dest
                        sub     thubdest, #1                    ' Increment p_dest pointer
                        call    #qdelay
                        djnz    tcount, #:byteloop
                        jmp     #cmd_exit

cmd_read_le             mov     tackbit, tcmd                   ' (tackbit := tcmd.bit[7])
                        shr     tackbit, #7                     ' Remove cmd
                        and     tackbit, #1                     ' Isolate
                        mov     t1, par                         ' Address of command
                        add     t1, #4                          ' Address of parameters
                        rdlong  thubdest, t1                    ' Read parameters
                        mov     tcount, thubdest                ' Copy
                        and     thubdest, HX_FFFF               ' Isolate p_dest
                        shr     tcount, #16                     ' Isolate count

:byteloop               andn    dira, sdamask                   ' Make SDA input
                        andn    dira, sclmask                   ' let SCL float
:rdle_pre_waitcs        test    sclmask, ina            wz      ' wait for slave
        if_z            jmp     #:rdle_pre_waitcs               '   to release it
                        mov     t2, #0                          ' Clear result
                        mov     tbits, #8                       ' Prep for 8 bits

:bitloop                call    #qdelay
                        andn    dira, sclmask                   ' SCL high
                        call    #hdelay
                        shl     t2, #1                          ' Prep for new bit
                        test    sdamask, ina            wc      ' Sample SDA
                        muxc    t2, #1                          ' New bit to t2.bit0
                        or      dira, sclmask                   ' SCL low
                        call    #qdelay
                        djnz    tbits, #:bitloop

                        ' write ack/nak

                        cmp     tcount, #1              wz      ' Last byte?
        if_nz           jmp     #:ack                           ' If no, do ACK
                        xor     tackbit, #1             wz      ' Test user test ackbit
:ack    if_nz           or      dira, sdamask                   ' ACK (SDA low)
:nak    if_z            andn    dira, sdamask                   ' NAK (SDA high)
                        call    #qdelay
                        andn    dira, sclmask                   ' SCL high
                        call    #hdelay
                        or      dira, sclmask                   ' SCL low
                        call    #qdelay
                        andn    dira, sdamask                   ' float SDA
                        wrbyte  t2, thubdest                    ' Write result to p_dest
                        add     thubdest, #1                    ' Increment p_dest pointer
                        call    #qdelay
                        djnz    tcount, #:byteloop
                        jmp     #cmd_exit


cmd_stop                or      dira, sdamask                   ' SDA low
                        call    #hdelay
                        andn    dira, sclmask                   ' Float SCL
                        call    #hdelay
:loop                   test    sclmask, ina            wz      ' Check SCL for "stretch"
        if_z            jmp     #:loop                          ' Wait while low
                        andn    dira, sdamask                   ' Float SDA
                        call    #hdelay
                        jmp     #cmd_exit


hdelay                  mov     t1, delaytix                    ' Delay half period
                        shr     t1, #1
                        add     t1, cnt
                        waitcnt t1, #0
hdelay_ret              ret


qdelay                  mov     t1, delaytix                    ' Delay quarter period
                        shr     t1, #2
                        add     t1, cnt
                        waitcnt t1, #0
qdelay_ret              ret


' Initialized and uninitialized data
HX_FFFF                 long    $FFFF                           ' Low word mask

sclmask                 res     1                               ' Pin masks
sdamask                 res     1
delaytix                res     1                               ' Ticks in 1/2 cycle

t1                      res     1                               ' Temp vars
t2                      res     1
tcmd                    res     1                               ' Command
tcount                  res     1                               ' Bytes to read/write
thubsrc                 res     1                               ' Hub address for write
thubdest                res     1                               ' Hub address for read
tackbit                 res     1
tbits                   res     1

                        fit     496

DAT
{
Copyright 2022 Jesse Burt

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

