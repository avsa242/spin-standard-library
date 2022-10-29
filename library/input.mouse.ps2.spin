{
    --------------------------------------------
    Filename: input.mouse.ps2.spin
    Description: PS/2 mouse interface driver
    Author: Chip Gracey
    Modified by: Jesse Burt
    Started May 1, 2006
    Updated Oct 29, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Mouse.spin,
    originally by Chip Gracey

    Usage:
        use 100-ohm resistors between pins and jack
        use 10K-ohm resistors to pull jack-side signals to VDD
        connect jack-power to 5V, jack-gnd to VSS

}

VAR

    long _cog

    long _oldx, _oldy, _oldz                    ' must be followed by parameters (10 contig. longs)

    long _par_x                                 ' absolute x     read-only (7 contiguous longs)
    long _par_y                                 ' absolute y     read-only
    long _par_z                                 ' absolute z     read-only
    long _par_buttons                           ' button states  read-only
    long _par_present                           ' mouse present  read-only
    long _par_dpin                              ' data pin       write-only
    long _par_cpin                              ' clock pin      write-only

    long _bx_min, _by_min, _bz_min              ' min/max must be contiguous
    long _bx_max, _by_max, _bz_max
    long _bx_div, _by_div, _bz_div
    long _bx_acc, _by_acc, _bz_acc

PUB start(DPIN, CPIN): status
' Start mouse driver
'   DPIN: PS/2 data signal
'   CPIN: PS/2 clock signal
'   Returns:
'       cog ID + 1 of started cog, or FALSE if none available
    stop{}
    _par_dpin := DPIN
    _par_cpin := CPIN
    status := _cog := cognew(@entry, @_par_x) + 1

PUB stop{}
' Stop the driver
    if (_cog)
        cogstop(_cog~ - 1)                      ' stop cog
    longfill(@_oldx, 0, 22)                     ' clear global vars

PUB present{}: type
' Check if mouse present
'   Returns: mouse type
'       3: five-button scrollwheel mouse
'       2: three-button scrollwheel mouse
'       1: two-button or three-button mouse
'       0: no mouse connected
'   NOTE: Valid approx. 2 seconds after start
    return _par_present

PUB abs_x{}: x
' Get absolute x position
    return _par_x

PUB abs_y{}: y
' Get absolute y position
    return _par_y

PUB abs_z{}: z
' Get absolute z position (scrollwheel)
    return _par_z

PUB bound_limits(xmin, ymin, zmin, xmax, ymax, zmax) | i
' Set bounding limits
    longmove(@_bx_min, @xmin, 6)

PUB bound_scales(x_scale, y_scale, z_scale)
' Set bounding scales (usually +/-1's, bigger values divide)
    longmove(@_bx_div, @x_scale, 3)

PUB bound_preset(x, y, z) | i, d
' Preset bound coordinates
    repeat i from 0 to 2
        d := ||_bx_div[i]
        _bx_acc[i] := (x[i] - _bx_min[i]) * d + d >> 1

PUB bound_x{}: x
' Get bound-x
    return bound(0, delta_x)

PUB bound_y{}: y
' Get bound-y
    return bound(1, delta_y)

PUB bound_z{}: z
' Get bound-z
    return bound(2, delta_z)

PUB button(b): state
' Get the state of a particular button
'   Returns: TRUE or FALSE
    return -((_par_buttons >> b) & 1)

PUB buttons{}: states
' Get the states of all buttons
'   Returns: 5-bit mask
'       4: right-side button
'       3: left-side button
'       2: center/scrollwheel button
'       1: right button
'       0: left button
    return _par_buttons

PUB delta_reset{}
' Reset deltas
    _oldx := _par_x
    _oldy := _par_y
    _oldz := _par_z

PUB delta_x{}: x | newx
' Get delta-x
    newx := _par_x
    x := newx - _oldx
    _oldx := newx

PUB delta_y{}: y | newy
' Get delta-y
    newy := _par_y
    y := newy - _oldy
    _oldy := newy

PUB delta_z{}: z | newz
' Get delta-z (scrollwheel)
    newz := _par_z
    z := newz - _oldz
    _oldz := newz

PRI bound(i, delta): b | d

    d := _bx_div[i]
    _bx_acc[i] := (_bx_acc[i] + delta * (d < 0) | 1 #> 0 <# (_bx_max[i] - _bx_min[i] + 1) * ||d - 1) / ||d
    b := (_bx_acc[i] + _bx_min[i])

DAT
                        org

entry                   mov     p, par                  ' load input parameters:
                        add     p, #5*4                 ' _dpin/_cpin
                        rdlong  _dpin, p
                        add     p, #4
                        rdlong  _cpin, p

                        mov     dmask, #1               ' set pin masks
                        shl     dmask, _dpin
                        mov     cmask, #1
                        shl     cmask, _cpin

                        test    _dpin, #$20      wc     ' modify port registers within code
                        muxc    _d1, dlsb
                        muxc    _d2, dlsb
                        muxc    _d3, #1
                        muxc    _d4, #1
                        test    _cpin, #$20      wc
                        muxc    _c1, dlsb
                        muxc    _c2, dlsb
                        muxc    _c3, #1

                        movd    :par, #_x               ' reset output parameters:
                        mov     p, #5                   ' _x/_y/_z/_buttons/_present
:par                    mov     0, #0
                        add     :par, dlsb
                        djnz    p, #:par
reset
' Reset mouse
                        mov     dira, #0                ' reset directions
                        mov     dirb, #0

                        mov     stat, #1                ' set reset flag


update
' Update parameters
                        movd    :par, #_x               ' update output parameters:
                        mov     p, par                  ' _x/_y/_z/_buttons/_present
                        mov     q, #5
:par                    wrlong  0, p
                        add     :par, dlsb
                        add     p, #4
                        djnz    q, #:par

                        test    stat, #1         wc     ' if reset flag, transmit reset command
        if_c            mov     data, #$FF
        if_c            call    #transmit


' Get data packet
                        mov     stat, #0                ' reset state

                        call    #receive                ' receive first byte

                        cmp     data, #$AA       wz     ' powerup/reset?
        if_z            jmp     #init

                        mov     _buttons, data          ' data packet, save buttons

                        call    #receive                ' receive second byte

                        test    _buttons, #$10   wc     ' adjust _x
                        muxc    data, signext
                        add     _x, data

                        call    #receive                ' receive third byte

                        test    _buttons, #$20   wc     ' adjust _y
                        muxc    data, signext
                        add     _y, data

                        and     _buttons, #%111         ' trim buttons

                        cmp     _present, #2     wc     ' if not scrollwheel mouse, update parameters
        if_c            jmp     #update


                        call    #receive                ' scrollwheel mouse, receive fourth byte

                        cmp     _present, #3     wz     ' if 5-button mouse, handle two extra buttons
        if_z            test    data, #$10       wc
        if_z_and_c      or      _buttons, #%01000
        if_z            test    data, #$20       wc
        if_z_and_c      or      _buttons, #%10000

                        shl     data, #28               ' adjust _z
                        sar     data, #28
                        sub     _z, data

                        jmp     #update                 ' update parameters


init
' Initialize mouse
                        call    #receive                ' $AA received, receive id

                        movs    crate, #100             ' try to enable 3-button scrollwheel type
                        call    #checktype
                        movs    crate, #200             ' try to enable 5-button scrollwheel type
                        call    #checktype
                        shr     data, #1                ' if neither, 3-button type
                        add     data, #1
                        mov     _present, data

                        movs    srate, #200             ' set 200 samples per second
                        call    #setrate

                        mov     data, #$F4              ' enable data reporting
                        call    #transmit

                        jmp     #update


checktype
' Check mouse type
                        movs    srate, #200             ' perform "knock" sequence to enable
                        call    #setrate                ' ..scrollwheel and extra buttons

crate                   movs    srate, #200/100
                        call    #setrate

                        movs    srate, #80
                        call    #setrate

                        mov     data, #$F2              ' read type
                        call    #transmit
                        call    #receive

checktype_ret           ret


setrate
' Set sample rate
                        mov     data, #$F3
                        call    #transmit
srate                   mov     data, #0
                        call    #transmit

setrate_ret             ret


transmit
' Transmit byte to mouse
_c1                     or      dira, cmask             ' pull clock low
                        movs    napshr, #13             ' hold clock for ~128us (must be >100us)
                        call    #nap
_d1                     or      dira, dmask             ' pull data low
                        movs    napshr, #18             ' hold data for ~4us
                        call    #nap
_c2                     xor     dira, cmask             ' release clock

                        test    data, #$0FF      wc     ' append parity and stop bits to byte
                        muxnc   data, #$100
                        or      data, dlsb

                        mov     p, #10                  ' ready 10 bits
transmit_bit            call    #wait_c0                ' wait until clock low
                        shr     data, #1         wc     ' output data bit
_d2                     muxnc   dira, dmask
                        mov     wcond, c1               ' wait until clock high
                        call    #wait
                        djnz    p, #transmit_bit        ' another bit?

                        mov     wcond, c0d0             ' wait until clock and data low
                        call    #wait
                        mov     wcond, c1d1             ' wait until clock and data high
                        call    #wait

                        call    #receive_ack            ' receive ack byte with timed wait
                        cmp     data, #$FA       wz     ' if ack error, reset mouse
        if_nz           jmp     #reset

transmit_ret            ret


receive
' Receive byte from mouse
                        test    _cpin, #$20      wc     ' wait indefinitely for initial clock low
                        waitpne cmask, cmask
receive_ack
                        mov     p, #11                  ' ready 11 bits
receive_bit             call    #wait_c0                ' wait until clock low
                        movs    napshr, #16             ' pause ~16us
                        call    #nap
_d3                     test    dmask, ina       wc     ' input data bit
                        rcr     data, #1
                        mov     wcond, c1               ' wait until clock high
                        call    #wait
                        djnz    p,#receive_bit          ' another bit?

                        shr     data, #22               ' align byte
                        test    data, #$1FF      wc     ' if parity error, reset mouse
        if_nc           jmp     #reset
                        and     data, #$FF              ' isolate byte
receive_ack_ret
receive_ret             ret


wait_c0
' Wait for clock/data to be in required states
                        mov     wcond, c0               ' (wait until clock low)

wait                    mov     q, tenms                ' set timeout to 10ms

wloop                   movs    napshr, #18             ' nap ~4us
                        call    #nap
_c3                     test    cmask, ina       wc     ' check required state(s)
_d4                     test    dmask, ina       wz     ' loop until got state(s) or timeout
wcond   if_never        djnz    q, #wloop               ' (replaced with c0/c1/c0d0/c1d1)

                        tjz     q, #reset               ' if timeout, reset mouse
wait_ret
wait_c0_ret             ret


c0      if_c            djnz    q, #wloop               ' (if_never replacements)
c1      if_nc           djnz    q, #wloop
c0d0    if_c_or_nz      djnz    q, #wloop
c1d1    if_nc_or_z      djnz    q, #wloop


nap
' Nap
                        rdlong  t, #0                   ' get clkfreq
napshr                  shr     t, #18/16/13            ' shr scales time
                        min     t, #3                   ' ensure waitcnt won't snag
                        add     t, cnt                  ' add cnt to time
                        waitcnt t, #0                   ' wait until time elapses (nap)
nap_ret                 ret


{ initialized data }
dlsb                    long    1 << 9
tenms                   long    10_000 / 4
signext                 long    $FFFFFF00

{ uninitialized data }
dmask                   res     1
cmask                   res     1
stat                    res     1
data                    res     1
p                       res     1
q                       res     1
t                       res     1

_x                      res     1                       ' write-only
_y                      res     1                       ' write-only
_z                      res     1                       ' write-only
_buttons                res     1                       ' write-only
_present                res     1                       ' write-only
_dpin                   res     1                       ' read-only
_cpin                   res     1                       ' read-only

DAT
{
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

