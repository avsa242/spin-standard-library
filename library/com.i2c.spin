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

con { fixed io pins }

  RX1  = 31                                                     ' programming / debug port
  TX1  = 30

  SDA1 = 29                                                     ' boot eeprom
  SCL1 = 28


con

  #0, ACK, NAK

  #1, I2C_START, I2C_WRITE, I2C_READ, I2C_STOP                  ' commands


var

  long  i2ccmd
  long  i2cparams
  long  i2cresult


dat

  cog         long      0                                       ' not connected


pub null

  ' This is not a top-level object


pub setup(hz)

'' Start i2c cog on propeller i2c bus
'' -- aborts if cog already running
'' -- example: i2c.setup(400_000)

  if (cog)
    return

  setupx(SCL1, SDA1, hz)                                        ' use propeller i2c pins



pub setupx(sclpin, sdapin, hz)

'' Start i2c cog on any set of pins
'' -- aborts if cog already running
'' -- example: i2c.setupx(SCL, SDA, 400_000)

  if (cog)
    return

  i2ccmd.byte[0] := sclpin                                      ' setup pins
  i2ccmd.byte[1] := sdapin
  i2ccmd.word[1] := clkfreq / hz                                ' ticks in full cycle

  cog := cognew(@fast_i2c, @i2ccmd) + 1                         ' start the cog

  return cog


pub terminate

'' Kill i2c cog

  if (cog)
    cogstop(cog-1)
    cog := 0

  longfill(@i2ccmd, 0, 4)


pub present(ctrl) | tmp

'' Pings device, returns true it ACK

  i2ccmd := I2C_START
  repeat while (i2ccmd <> 0)

  return (wr_block(@ctrl, 1) == ACK)


pub wait(slaveid)

'' Waits for I2C device to be ready for new command

  repeat
    if (present(slaveid))
      quit

  return ACK


pub waitx(slaveid, toms) : t0

'' Waits toms milliseconds for I2C device to be ready for new command

  toms *= clkfreq / 1000                                        ' convert to system ticks

  t0 := cnt                                                     ' mark
  repeat
    if (present(slaveid))
      quit
    if ((cnt - t0) => toms)
      return NAK

  return ACK


pub start

'' Create I2C start sequence
'' -- will wait if I2C bus SDA pin is held low

  i2ccmd := I2C_START
  repeat while (i2ccmd <> 0)


pub write(b)

'' Write byte to I2C bus

  return wr_block(@b, 1)


pub wr_byte(b)

'' Write byte to I2C bus

  return wr_block(@b, 1)


pub wr_word(w)

'' Write word to I2C bus
'' -- Little Endian

  return wr_block(@w, 2)


pub wr_long(l)

'' Write long to I2C bus
'' -- Little Endian

  return wr_block(@l, 4)


pub wr_block(p_src, count) | cmd

'' Write block of count bytes from p_src to I2C bus

  i2cparams.word[0] := p_src
  i2cparams.word[1] := count

  i2ccmd := I2C_WRITE
  repeat while (i2ccmd <> 0)

  return i2cresult                                              ' return ACK or NAK


pub read(ackbit)

'' Read byte from I2C bus

  rd_block(@i2cresult, 1, ackbit)

  return i2cresult & $FF


pub rd_byte(ackbit)

'' Read byte from I2C bus

  rd_block(@i2cresult, 1, ackbit)

  return i2cresult & $FF


pub rd_word(ackbit)

'' Read word from I2C bus

  rd_block(@i2cresult, 2, ackbit)

  return i2cresult & $FFFF


pub rd_long(ackbit)

'' Read long from I2C bus

  rd_block(@i2cresult, 4, ackbit)

  return i2cresult


pub rd_block(p_dest, count, ackbit) | cmd

'' Read block of count bytes from I2C bus to p_dest

  i2cparams.word[0] := p_dest
  i2cparams.word[1] := count

  if (ackbit)
    ackbit := $80

  i2ccmd := I2C_READ | ackbit
  repeat while (i2ccmd <> 0)


pub stop

'' Create I2C stop sequence

  i2ccmd := I2C_STOP
  repeat while (i2ccmd <> 0)


dat { high-speed i2c }

                        org     0

fast_i2c                mov     outa, #0                        ' clear outputs
                        mov     dira, #0
                        rdlong  t1, par                         ' read pins and delaytix
                        mov     t2, t1                          ' copy for scl pin
                        and     t2, #$1F                        ' isolate scl
                        mov     sclmask, #1                     ' create mask
                        shl     sclmask, t2
                        mov     t2, t1                          ' copy for sda pin
                        shr     t2, #8                          ' isolate scl
                        and     t2, #$1F
                        mov     sdamask, #1                     ' create mask
                        shl     sdamask, t2
                        mov     delaytix, t1                    ' copy for delaytix
                        shr     delaytix, #16

                        mov     t1, #9                          ' reset device
:loop                   or      dira, sclmask
                        call    #hdelay
                        andn    dira, sclmask
                        call    #hdelay
                        test    sdamask, ina            wc      ' sample sda
        if_c            jmp     #cmd_exit                       ' if high, exit
                        djnz    t1, #:loop
                        jmp     #cmd_exit                       ' clear parameters

get_cmd                 rdlong  t1, par                 wz      ' check for command
        if_z            jmp     #get_cmd

                        mov     tcmd, t1                        ' copy to save data
                        and     t1, #%111                       ' isolate command

                        cmp     t1, #I2C_START          wz
        if_e            jmp     #cmd_start

                        cmp     t1, #I2C_WRITE          wz
        if_e            jmp     #cmd_write

                        cmp     t1, #I2C_READ           wz
        if_e            jmp     #cmd_read

                        cmp     t1, #I2C_STOP           wz
        if_e            jmp     #cmd_stop

cmd_exit                mov     t1, #0                          ' clear old command
                        wrlong  t1, par
                        jmp     #get_cmd



cmd_start               andn    dira, sdamask                   ' float SDA (1)
                        andn    dira, sclmask                   ' float SCL (1, input)
                        nop
:loop                   test    sclmask, ina            wz      ' scl -> C
        if_z            jmp     #:loop                          ' wait while low
                        call    #hdelay
                        or      dira, sdamask                   ' SDA low
                        call    #hdelay
                        or      dira, sclmask                   ' SCL low
                        call    #hdelay
                        jmp     #cmd_exit



cmd_write               mov     t1, par                         ' address of command
                        add     t1, #4                          ' address of parameters
                        rdlong  thubsrc, t1                     ' read parameters
                        mov     tcount, thubsrc                 ' copy
                        and     thubsrc, HX_FFFF                ' isolate p_src
                        shr     tcount, #16                     ' isolate count
                        mov     tackbit, #ACK                   ' assume okay

:byteloop               rdbyte  t2, thubsrc                     ' get byte
                        add     thubsrc, #1                     ' increment source pointer
                        shl     t2, #24                         ' position msb
                        mov     tbits, #8                       ' prep for 8 bits out

:bitloop                rcl     t2, #1                  wc      ' bit31 -> carry
                        muxnc   dira, sdamask                   ' carry -> sda
                        call    #hdelay                         ' hold a quarter period
                        andn    dira, sclmask                   ' clock high
                        call    #hdelay
                        or      dira, sclmask                   ' clock low
                        djnz    tbits, #:bitloop

                        ' read ack/nak

                        andn    dira, sdamask                   ' make SDA input
                        call    #hdelay
                        andn    dira, sclmask                   ' SCL high
                        call    #hdelay
                        test    sdamask, ina            wc      ' test ackbit
        if_c            mov     tackbit, #NAK                   ' mark if NAK
                        or      dira, sclmask                   ' SCL low
                        djnz    tcount, #:byteloop

                        mov     thubdest, par
                        add     thubdest, #8                    ' point to i2cresult
                        wrlong  tackbit, thubdest               ' write ack/nak bit
                        jmp     #cmd_exit



cmd_read                mov     tackbit, tcmd                   ' (tackbit := tcmd.bit[7])
                        shr     tackbit, #7                     ' remove cmd
                        and     tackbit, #1                     ' isolate
                        mov     t1, par                         ' address of command
                        add     t1, #4                          ' address of parameters
                        rdlong  thubdest, t1                    ' read parameters
                        mov     tcount, thubdest                ' copy
                        and     thubdest, HX_FFFF               ' isolate p_dest
                        shr     tcount, #16                     ' isolate count

:byteloop               andn    dira, sdamask                   ' make SDA input
                        mov     t2, #0                          ' clear result
                        mov     tbits, #8                       ' prep for 8 bits

:bitloop                call    #qdelay
                        andn    dira, sclmask                   ' SCL high
                        call    #hdelay
                        shl     t2, #1                          ' prep for new bit
                        test    sdamask, ina            wc      ' sample SDA
                        muxc    t2, #1                          ' new bit to t2.bit0
                        or      dira, sclmask                   ' SCL low
                        call    #qdelay
                        djnz    tbits, #:bitloop

                        ' write ack/nak

                        cmp     tcount, #1              wz      ' last byte?
        if_nz           jmp     #:ack                           ' if no, do ACK
                        xor     tackbit, #1             wz      ' test user test ackbit
:ack    if_nz           or      dira, sdamask                   ' ACK (SDA low)
:nak    if_z            andn    dira, sdamask                   ' NAK (SDA high)
                        call    #qdelay
                        andn    dira, sclmask                   ' SCL high
                        call    #hdelay
                        or      dira, sclmask                   ' SCL low
                        call    #qdelay

                        wrbyte  t2, thubdest                    ' write result to p_dest
                        add     thubdest, #1                    ' increment p_dest pointer
                        djnz    tcount, #:byteloop
                        jmp     #cmd_exit



cmd_stop                or      dira, sdamask                   ' SDA low
                        call    #hdelay
                        andn    dira, sclmask                   ' float SCL
                        call    #hdelay
:loop                   test    sclmask, ina            wz      ' check SCL for "stretch"
        if_z            jmp     #:loop                          ' wait while low
                        andn    dira, sdamask                   ' float SDA
                        call    #hdelay
                        jmp     #cmd_exit



hdelay                  mov     t1, delaytix                    ' delay half period
                        shr     t1, #1
                        add     t1, cnt
                        waitcnt t1, #0
hdelay_ret              ret



qdelay                  mov     t1, delaytix                    ' delay quarter period
                        shr     t1, #2
                        add     t1, cnt
                        waitcnt t1, #0
qdelay_ret              ret

' --------------------------------------------------------------------------------------------------

HX_FFFF                 long    $FFFF                           ' low word mask

sclmask                 res     1                               ' pin masks
sdamask                 res     1
delaytix                res     1                               ' ticks in 1/2 cycle

t1                      res     1                               ' temp vars
t2                      res     1
tcmd                    res     1                               ' command
tcount                  res     1                               ' bytes to read/write
thubsrc                 res     1                               ' hub address for write
thubdest                res     1                               ' hub address for read
tackbit                 res     1
tbits                   res     1

                        fit     496


dat { license }

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

