{
    --------------------------------------------
    Filename: com.i2c.spin
    Author: Jesse Burt
    Description: PASM I2C Engine
    Started Mar 9, 2019
    Updated Jan 19, 2021
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

CON

    #0, ACK, NAK
    #1, I2C_START, I2C_WRITE_LE, I2C_WRITE_BE, I2C_READ_LE, I2C_READ_BE,{
}   I2C_STOP                                    ' PASM engine Commands

VAR

    long  _i2c_cmd
    long  _i2c_params
    long  _i2c_result

DAT

    _cog long      0                            ' Not connected

PUB Null
' This is not a top-level object

PUB InitDef(HZ): status
' Initialize I2C engine using default Propeller I2C pins
'   HZ: I2C bus speed, in Hz (1..approx 1_000_000)
'   NOTE: Aborts if cog is already running
    status := init(DEF_SCL, DEF_SDA, HZ)

PUB Init(SCL, SDA, HZ): status
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

PUB DeInit
' Deinitialize/stop PASM engine
    if (_cog)
        cogstop(_cog-1)
        _cog := 0

    longfill(@_i2c_cmd, 0, 4)

PUB Setup(hz) ' XXX
' Start I2C cog on default Propeller I2C bus
' -- aborts if cog already running
' -- example: i2c.setup(400_000)
    if (_cog)
        return

    setupx(DEF_SCL, DEF_SDA, hz)                ' Use default Propeller I2C pins

PUB Setupx(sclpin, sdapin, hz) ' XXX
' Start i2c cog on any set of pins
' -- aborts if cog already running
' -- example: i2c.setupx(SCL, SDA, 400_000)
    if (_cog)
        return

    _i2c_cmd.byte[0] := sclpin                  ' Setup pins
    _i2c_cmd.byte[1] := sdapin
    _i2c_cmd.word[1] := clkfreq / hz            ' Ticks in full cycle

    _cog := cognew(@fast_i2c, @_i2c_cmd) + 1    ' Start the cog

    return _cog

PUB Terminate ' XXX
' Kill i2c cog
    if (_cog)
        cogstop(_cog-1)
        _cog := 0

    longfill(@_i2c_cmd, 0, 4)

PUB Present(slave_addr): status
' Check for slave device presence on bus
'   Returns:
'       FALSE (0): Device not acknowledging or in error state
'       TRUE (-1): Device acknowledges
    _i2c_cmd := I2C_START
    repeat while (_i2c_cmd <> 0)

    return (wrblock_lsbf(@slaveid, 1) == ACK)

PUB Rd_Byte(ackbit): i2cbyte
' Read byte from I2C bus
    rdblock_lsbf(@i2cbyte, 1, ackbit)
    return i2cbyte & $FF

PUB Rd_Long(ackbit): i2clong
' Read long from I2C bus
    rdblock_lsbf(@i2clong, 4, ackbit)

PUB Rd_Word(ackbit): i2cword
' Read word from I2C bus
    rdblock_lsbf(@i2cword, 2, ackbit)
    return i2cword & $FFFF

PUB Rd_Block(p_dest, count, ackbit) ' XXX
' Read block of count bytes from I2C bus to p_dest
    _i2c_params.word[0] := p_dest
    _i2c_params.word[1] := count

    if (ackbit)
        ackbit := $80

    _i2c_cmd := I2C_READ_LE | ackbit
    repeat while (_i2c_cmd <> 0)

PUB RdBlock_LSBF(ptr_buff, nr_bytes, ack_last)
' Read nr_bytes from I2C bus to ptr_buff
'   Least-significant byte first
'   ack_last:
'       ACK (0): Acknowledge last byte read from bus
'       NAK (non-zero): Don't acknowledge last byte read from bus
    _i2c_params.word[0] := ptr_buff
    _i2c_params.word[1] := nr_bytes

    if (ack_last)
        ack_last := $80

    _i2c_cmd := I2C_READ_LE | ack_last
    repeat while (_i2c_cmd <> 0)

PUB RdBlock_MSBF(ptr_buff, nr_bytes, ack_last)
' Read nr_ytes from I2C bus to ptr_buff,
'   Most-significant byte first
'   ack_last:
'       ACK (0): Acknowledge last byte read from bus
'       NAK (non-zero): Don't acknowledge last byte read from bus
    _i2c_params.word[0] := ptr_buff
    _i2c_params.word[1] := nr_bytes

    if (ack_last)
        ack_last := $80

    _i2c_cmd := I2C_READ_BE | ack_last
    repeat while (_i2c_cmd <> 0)

PUB Read(ackbit): i2cbyte
' Read byte from I2C bus
    rdblock_lsbf(@_i2c_result, 1, ackbit)

    return _i2c_result & $FF

PUB Start
' Create I2C start/restart condition (S, Sr)
'   NOTE: This method supports clock stretching;
'       waits while SDA pin is held low
    _i2c_cmd := I2C_START
    repeat while (_i2c_cmd <> 0)

PUB Stop
' Create I2C stop condition (P)
    _i2c_cmd := I2C_STOP
    repeat while (_i2c_cmd <> 0)

PUB Wait(slave_addr)
' Waits for I2C device to be ready for new command
'   NOTE: This method will wait indefinitely,
'   if the device doesn't respond
    repeat
        if (present(slaveid))
            quit

    return ACK

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

PUB Wr_Block(p_src, count) | cmd    ' XXX
' Write block of count bytes from p_src to I2C bus
    _i2c_params.word[0] := p_src
    _i2c_params.word[1] := count

    _i2c_cmd := I2C_WRITE_LE
    repeat while (_i2c_cmd <> 0)

    return _i2c_result                            ' Return ACK or NAK

PUB WrBlock_LSBF(ptr_buff, nr_bytes): ackbit
' Write block of nr_bytes bytes from ptr_buff to I2C bus,
'   Least-Significant byte first
    _i2c_params.word[0] := ptr_buff
    _i2c_params.word[1] := nr_bytes

    _i2c_cmd := I2C_WRITE_LE
    repeat while (_i2c_cmd <> 0)

    return _i2c_result                            ' Return ACK or NAK

PUB WrBlock_MSBF(ptr_buff, nr_bytes): ackbit
' Write block of nr_bytes bytes from ptr_buff to I2C bus,
'   Most-significant byte first
    _i2c_params.word[0] := ptr_buff
    _i2c_params.word[1] := nr_bytes

    _i2c_cmd := I2C_WRITE_BE
    repeat while (_i2c_cmd <> 0)

    return _i2c_result                            ' Return ACK or NAK

PUB Write(b): ackbit
' Write byte to I2C bus
    return wrblock_lsbf(@b, 1)

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
:loop                   test    sclmask, ina            wz      ' SCL -> C
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
                        call    #hdelay
                        test    sdamask, ina            wc      ' Test ackbit
        if_c            mov     tackbit, #NAK                   ' Mark if NAK
                        or      dira, sclmask                   ' SCL low
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

                        wrbyte  t2, thubdest                    ' Write result to p_dest
                        sub     thubdest, #1                    ' Increment p_dest pointer
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

                        wrbyte  t2, thubdest                    ' Write result to p_dest
                        add     thubdest, #1                    ' Increment p_dest pointer
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

' --------------------------------------------------------------------------------------------------

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
