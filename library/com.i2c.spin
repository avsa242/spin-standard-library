{
    --------------------------------------------
    Filename: com.i2c.spin
    Author: Jesse Burt
    Description: PASM I2C Driver
    Started Mar 9, 2019
    Updated May 27, 2019
    See end of file for terms of use.

    NOTE: This is a derivative of jm_i2c_fast_2018.spin, by
        Jon McPhalen (original header preserved below)
    --------------------------------------------
}

'' =================================================================================================
''
''   File....... jm_i2c_fast_2018.spin
''   Purpose.... Low-level I2C routines (requires pull-ups on SCL and SDA)
''   Author..... Jon "JonnyMac" McPhalen
''               -- Copyright (c) 2009-2018 Jon McPhalen
''               -- see below for terms of use
''               -- elements inspired by code from Mike Green
''   E-mail.....
''   Started.... 28 JUL 2009
''   Updated.... 22 JUL 2018
''
'' =================================================================================================

'  IMPORTANT Note: This code requires pull-ups on the SDA _and_ SCL lines -- it does not drive
'  the SCL line high.
'
'  Cog value stored in DAT table which is shared across all object uses; all objects that use
'  this object MUST use the same I2C bus pins

CON { fixed io pins }

    SDA1 = 29                                                   ' Default I2C I/O pins
    SCL1 = 28

CON

    #0, ACK, NAK
    #1, I2C_START, I2C_WRITE, I2C_READ, I2C_STOP                  ' Commands

VAR

    long  i2ccmd
    long  i2cparams
    long  i2cresult

DAT

    cog         long      0                                       ' Not connected

PUB Null
' This is not a top-level object


PUB Setup(hz)
'' Start I2C cog on default Propeller I2C bus
'' -- aborts if cog already running
'' -- example: i2c.setup(400_000)
    if (cog)
        return

    setupx(SCL1, SDA1, hz)                                        ' Use default Propeller I2C pins

PUB Setupx(sclpin, sdapin, hz)
'' Start i2c cog on any set of pins
'' -- aborts if cog already running
'' -- example: i2c.setupx(SCL, SDA, 400_000)
    if (cog)
        return

    i2ccmd.byte[0] := sclpin                                      ' Setup pins
    i2ccmd.byte[1] := sdapin
    i2ccmd.word[1] := clkfreq / hz                                ' Ticks in full cycle

    cog := cognew(@fast_i2c, @i2ccmd) + 1                         ' Start the cog

    return cog

PUB Terminate
'' Kill i2c cog
    if (cog)
        cogstop(cog-1)
        cog := 0

    longfill(@i2ccmd, 0, 4)

PUB Present(ctrl) | tmp
'' Pings device, returns true it ACK
    i2ccmd := I2C_START
    repeat while (i2ccmd <> 0)

    return (wr_block(@ctrl, 1) == ACK)

PUB Wait(slaveid)
'' Waits for I2C device to be ready for new command
    repeat
        if (present(slaveid))
            quit

    return ACK

PUB Waitx(slaveid, toms): t0
'' Waits toms milliseconds for I2C device to be ready for new command
    toms *= clkfreq / 1000                                        ' Convert to system ticks

    t0 := cnt                                                     ' Mark
    repeat
        if (present(slaveid))
            quit
        if ((cnt - t0) => toms)
            return NAK

    return ACK

PUB Start
'' Create I2C start sequence                                        (S, Sr)
'' -- will wait if I2C bus SDA pin is held low
    i2ccmd := I2C_START
    repeat while (i2ccmd <> 0)

PUB Write(b)
'' Write byte to I2C bus
    return Wr_Block(@b, 1)

PUB Wr_Byte(b)
'' Write byte to I2C bus
    return Wr_Block(@b, 1)

PUB Wr_Word(w)
'' Write word to I2C bus
'' -- Little Endian
    return Wr_Block(@w, 2)

PUB Wr_Long(l)
'' Write long to I2C bus
'' -- Little Endian
    return Wr_Block(@l, 4)

PUB Wr_Block(p_src, count) | cmd
'' Write block of count bytes from p_src to I2C bus
    i2cparams.word[0] := p_src
    i2cparams.word[1] := count

    i2ccmd := I2C_WRITE
    repeat while (i2ccmd <> 0)

    return i2cresult                                              ' Return ACK or NAK

PUB Read(ackbit)
'' Read byte from I2C bus
    Rd_Block(@i2cresult, 1, ackbit)

    return i2cresult & $FF

PUB Rd_Byte(ackbit)
'' Read byte from I2C bus
    Rd_Block(@i2cresult, 1, ackbit)

    return i2cresult & $FF

PUB Rd_Word(ackbit)
'' Read word from I2C bus
    Rd_Block(@i2cresult, 2, ackbit)

    return i2cresult & $FFFF

PUB Rd_Long(ackbit)
'' Read long from I2C bus
    Rd_Block(@i2cresult, 4, ackbit)

    return i2cresult

PUB Rd_Block(p_dest, count, ackbit) | cmd
'' Read block of count bytes from I2C bus to p_dest
    i2cparams.word[0] := p_dest
    i2cparams.word[1] := count

    if (ackbit)
        ackbit := $80

    i2ccmd := I2C_READ | ackbit
    repeat while (i2ccmd <> 0)

PUB Stop
'' Create I2C stop sequence                                     (P)
    i2ccmd := I2C_STOP
    repeat while (i2ccmd <> 0)

DAT { High-speed I2C }

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

                        cmp     t1, #I2C_WRITE          wz
        if_e            jmp     #cmd_write

                        cmp     t1, #I2C_READ           wz
        if_e            jmp     #cmd_read

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



cmd_write               mov     t1, par                         ' Address of command
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
                        add     thubdest, #8                    ' Point to i2cresult
                        wrlong  tackbit, thubdest               ' Write ack/nak bit
                        jmp     #cmd_exit



cmd_read                mov     tackbit, tcmd                   ' (tackbit := tcmd.bit[7])
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


DAT { License }

{{

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

