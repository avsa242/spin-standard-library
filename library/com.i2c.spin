{
----------------------------------------------------------------------------------------------------
    Filename:       com.i2c.spin
    Description:    PASM I2C engine
    Author:         Jesse Burt
    Started:        Mar 9, 2019
    Updated:        May 5, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------

    * Minimum bus speed is 1221Hz (80_000_000 / 1221 = 65520)
    * Actual timings @ 80MHz Fsys:
        100kHz:
        Write speed: TBD
        Read speed: TBD

        400kHz:
        Write speed: TBD
        Read speed: TBD

        1MHz:
        Write speed: TBD
        Read speed: TBD

    NOTE: This is based on jm_i2c_fast_2018.spin, by Jon McPhalen

    NOTE: Pull-up resistors are _required_ on SDA _and_ SCL lines
        (open-drain output)
}


con

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


    ' I2C engine commands (_i2c_cmd.[2..0])
    CMD_IDLE    = 0
    CMD_START   = 1
    CMD_STOP    = 2
    CMD_WRITE   = 3
    CMD_READ    = 4
    CMD_RESET   = 5

    ' command flags (_i2c_cmd.[7..4])
    RW_REV      = 1 << 6                        ' reverse RAM read/write order

    ACK         = 0
    NAK         = 1

    DEF_SCL     = 28                            ' default bus pins
    DEF_SDA     = 29


var

    '    PAR        PAR+4        PAR+8
    long _i2c_cmd,  _i2c_params, _i2c_result
    byte _cog


pub init_def(): s
' Initialize the I2C engine using default bus pins and 100kHz speed
    return init(DEF_SCL, DEF_SDA, 100_000)


pub init(SCL_PIN, SDA_PIN, I2C_FREQ): s
' Initialize the I2C engine
'   SCL_PIN:    Serial Clock I/O pin
'   SDA_PIN:    Serial Data I/O pin
'   I2C_FREQ:   I2C bus speed (Hz)
'   Returns:    cogID+1 of running engine on success
'               0 on failure
    ifnot ( _cog )
        _i2c_cmd.byte[0] := SCL_PIN
        _i2c_cmd.byte[1] := SDA_PIN
        _i2c_cmd.word[1] := (clkfreq / I2C_FREQ)' calc timing for one I2C clock cycle
        _cog := cognew(@entry, @_i2c_cmd)+1
        repeat
        while ( _i2c_cmd )                      ' wait for I2C engine readiness
        return _cog

    return 0


pub deinit()
' Deinitialize the I2C engine
    if ( _cog )                                 ' take action only if an instance is running
        cogstop(_cog-1)
        longfill(@_i2c_cmd, 0, 3)
        _cog := 0


pub rdblock_lsbf(p_dest, len, last_ack): s
' Read byte(s) from the I2C bus into RAM forwards (start of buffer to the end)
'   p_dest:     pointer to destination to write data
'   len:        length of data to read (bytes)
'   last_ack:   ack bit of last byte of data sent
'               (0: ACK, non-zero: NAK)
    if ( len =< 0 )
        return -1

    _i2c_params.word[0] := p_dest
    _i2c_params.word[1] := len
    last_ack := (last_ack <> 0) & $80           ' convert MSB to ACK/NAK signal

    _i2c_cmd := CMD_READ | last_ack             ' encode the ACK setting in the command's MSB

    repeat
    while ( _i2c_cmd )


pub rdblock_msbf(p_dest, len, last_ack): s
' Read byte(s) from the I2C bus into RAM in reverse (end of buffer to start)
'   p_dest:     pointer to destination to write data
'   len:        length of data to read (bytes)
'   last_ack:   ack bit of last byte of data sent
'               (0: ACK, non-zero: NAK)
    if ( len =< 0 )
        return -1

    _i2c_params.word[0] := p_dest + len-1       ' set start point to the end of the buffer
    _i2c_params.word[1] := len
    last_ack := (last_ack <> 0) & $80           ' convert MSB to ACK/NAK signal

    _i2c_cmd := CMD_READ | RW_REV | last_ack    ' encode the ACK setting in the command's MSB

    repeat
    while ( _i2c_cmd )


pub reset()
' Attempt to reset the bus (up to 9 clock pulses)
    _i2c_cmd := CMD_RESET

    repeat
    while ( _i2c_cmd )


pub start()
' Start condition (S)
    _i2c_cmd := CMD_START
    repeat
    while ( _i2c_cmd )


pub stop()
' Stop condition (P)
    _i2c_cmd := CMD_STOP
    repeat
    while ( _i2c_cmd )


pub wrblock_lsbf(p_src, len=1): a
' Write byte(s) from RAM to the I2C bus forwards (start of buffer to the end)
'   p_src:      pointer to source data to write
'   len:        length of data to write (bytes)
'   Returns:    ACK (0) if a device acknowledged the write
'               NAK (1) if no device acknowledged the write

    ' set up the command: write the parameters
    _i2c_params.word[0] := p_src
    _i2c_params.word[1] := len

    ' execute the command
    _i2c_cmd := CMD_WRITE

    ' wait for the PASM engine to finish
    repeat
    while ( _i2c_cmd )

    return _i2c_result


pub wrblock_msbf(p_src, len=1): a
' Write byte(s) from RAM to the I2C bus in reverse (end of buffer to beginning)
'   p_src:      pointer to source data to write
'   len:        length of data to write (bytes)
'   Returns:    ACK (0) if a device acknowledged the write
'               NAK (1) if no device acknowledged the write

    ' set up the command: write the parameters
    _i2c_params.word[0] := p_src + len-1          ' set start point to the end of the buffer
    _i2c_params.word[1] := len

    ' execute the command
    _i2c_cmd := CMD_WRITE | RW_REV

    ' wait for the PASM engine to finish
    repeat
    while ( _i2c_cmd )

    return _i2c_result


#include "com.i2c.common.spinh"


dat

                    org     0


entry               mov     outa,       #0
                    mov     dira,       #0
                    rdlong  t0,         par         ' read parameters
                    mov     t1,         t0
                    and     t1,         #$1f
                    shl     sclmask,    t1          ' read SCL
                    mov     t1,         t0
                    shr     t1,         #8
                    and     t1,         #$1f
                    shl     sdamask,    t1          ' read SDA
                    mov     tcyc,       t0
                    shr     tcyc,       #16+1       ' isolate param (word 1) and divide by 2
                    sub     tcyc,       #27         ' compensate for overhead
                    jmp     #cmd_exit               ' clear command input


cmd_loop
' Wait for a command from the hub
                    rdlong  t0,         par         wz
        if_z        jmp     #cmd_loop

                    mov     flags,      t0          ' R/W command flags
                    and     t0,         #%111

                    cmp     t0,         #CMD_START  wz
        if_e        jmp     #i2c_start

                    cmp     t0,         #CMD_STOP   wz
        if_e        jmp     #i2c_stop

                    cmp     t0,         #CMD_WRITE  wz
        if_e        jmp     #i2c_write

                    cmp     t0,         #CMD_READ   wz
        if_e        jmp     #i2c_read

                    cmp     t0,         #CMD_RESET  wz
        if_e        jmp     #bus_reset


cmd_exit            mov     t0,         #CMD_IDLE   '
                    wrlong  t0,         par         ' tell the hub we're ready
                    jmp     #cmd_loop


i2c_start
' Start condition (S), (Sr)
                    andn    dira,       sdamask     '
                    andn    dira,       sclmask     ' float bus pins
:waitcs             test    sclmask,    ina     wz  ' clock stretch: wait for slave to release SCL
        if_z        jmp     #:waitcs
                    call    #delay
                    or      dira,       sdamask
                    call    #delay
                    or      dira,       sclmask
                    call    #delay
                    jmp     #cmd_exit

i2c_stop
' Stop condition (P)
                    or      dira,       sdamask     ' ensure SDA is low first
                    call    #delay
                    andn    dira,       sclmask     ' float SCL
                    call    #delay
:waitcs             test    sclmask,    ina     wz  ' clock stretch: wait for slave to release SCL
        if_z        jmp     #:waitcs
                    andn    dira,       sdamask     ' float SDA
                    call    #delay
                    jmp     #cmd_exit

i2c_read
' Read byte(s) from the bus
                    mov     ackbit,     flags
                    shr     ackbit,     #7          ' get the ack/nak bit from the command
                    and     ackbit,     #1
                    mov     t1,         par         ' t1 := @_i2c_cmd
                    add     t1,         #4          ' t1 := @_i2c_cmd+4 (= @_i2c_params)
                    rdlong  dest,       t1          ' dest := long[@_i2c_params]
                    mov     c0,         dest        ' extract byte count (_i2c_params.word[1])
                    and     dest,       xFFFF
                    shr     c0,         #16
:bytes              andn    dira,       sdamask     ' release bus
                    andn    dira,       sclmask
:waitcs             test    sclmask,    ina     wz  ' clock stretch: wait for slave to release SCL
        if_z        jmp     #:waitcs

                    mov     t2,         #0          ' init byte to 0
                    mov     c1,         #8          ' read 8 bits
:bits
                    andn    dira,       sclmask
                    call    #delay
                    shl     t2,         #1
                    test    sdamask,    ina     wc  ' read bit from slave device
                    muxc    t2,         #1          '   and merge it into the result
                    or      dira,       sclmask
                    call    #delay
                    djnz    c1,         #:bits

' Write ACK bit
                    cmp     c0,         #1      wz  ' last byte?
        if_nz       jmp     #:ack                   '   no: ACK
                    xor     ackbit,     #1      wz  ' transform user ACK to pin state
:ack    if_nz       or      dira,       sdamask     ' ACK: pull SDA low
:nak    if_z        andn    dira,       sdamask     ' NAK: let SDA remain floating
                    andn    dira,       sclmask     ' \
                    call    #delay                  '  - clock out ACK bit
                    or      dira,       sclmask     ' /
                    call    #delay
                    andn    dira,       sdamask     ' release SDA
                    wrbyte  t2,         dest        ' write data to user buffer
                    test    flags,      #RW_REV wc  ' depending on user-provided flag,
        if_c        sub     dest,       #1          '   move pointer backwards in RAM
        if_nc       add     dest,       #1          '   or forwards
                    call    #delay
                    djnz    c0,         #:bytes     ' write more bytes
                    jmp     #cmd_exit

i2c_write
' Write byte(s) to the bus
                    mov     t1,         par
                    add     t1,         #4          ' t1 := @_i2c_params
                    rdlong  src,        t1          ' point to write parameters
                    mov     c0,         src
                    and     src,        xFFFF       ' get source buffer
                    shr     c0,         #16         ' get data length
                    mov     ackbit,     #ACK
:byteloop
                    rdbyte  t2,         src         ' get byte
                    test    flags,      #RW_REV wc  ' depending on user-provided flag,
    if_c            sub     src,        #1          '   move pointer backwards in RAM
    if_nc           add     src,        #1          '   or forwards
                    shl     t2,         #24         ' left-justify byte for bitloop

                    mov     c1,         #8
:bitloop            rcl     t2,         #1      wc  ' src byte bit 31 -> carry
                    muxnc   dira,       sdamask     ' carry -> SDA
                    call    #delay
                    andn    dira,       sclmask     ' clock high
                    call    #delay
                    or      dira,       sclmask     ' clock low
                    djnz    c1,         #:bitloop

                    andn    dira,       sdamask     ' \
                    call    #delay                  '  - release bus to slave device
                    andn    dira,       sclmask     ' /
                    call    #delay
:waitcs             test    sclmask,    ina     wz  ' clock stretch: wait for slave to release SCL
    if_z            jmp     #:waitcs
                    test    sdamask,    ina     wc  ' read ACK bit
    if_c            mov     ackbit,     #NAK        ' high=NAK
                    or      dira,       sclmask
                    call    #delay
                    djnz    c0,         #:byteloop  ' next byte

                    mov     dest,       par
                    add     dest,       #8          ' dest := @_i2c_result
                    wrlong  ackbit,     dest        ' write ACK bit
                    jmp     #cmd_exit


bus_reset
' Attempt to "reset" the bus
                    mov     c0,         #9          ' attempt with up to 9 clock pulses

:do_reset           or      dira,       sclmask
                    call    #delay
                    andn    dira,       sclmask
                    call    #delay
                    test    sdamask,    ina     wc  ' SDA released? bus is clear
    if_c            jmp     #cmd_exit
                    djnz    c0,         #:do_reset
                    jmp     #cmd_exit


delay
' Inter-bit delay
                    mov     t0,         tcyc        ' init counter with SCL period
                    add     t0,         cnt
                    waitcnt t0,         #0
delay_ret           ret


' variables
t0                  long    0                       ' temporary
t1                  long    0
t2                  long    0

c0                  long    0                       ' counter
c1                  long    0

xFFFF               long    $ffff
sclmask             long    1                       ' pinmasks
sdamask             long    1
tcyc                long    0                       ' SCL cycle time

src                 long    0                       ' hub source address
dest                long    0                       ' hub destination address

flags               long    0
ackbit              long    0                       ' ACK/NAK
wr_rev              long    0                       ' write in reverse


dat
{
Copyright 2026 Jesse Burt

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

