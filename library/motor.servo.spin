{
    --------------------------------------------
    Filename: motor.servo.spin
    Description: Servo driver
        (32ch max)
    Author: Beau Schwabe
    Modified by: Jesse Burt
    Started Dec 29, 2006
    Updated Oct 27, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Servo32v7.spin,
        originally by Beau Schwabe
}

CON
    _1US            = 1_000_000 / 1             ' divisor for 1 uS

    ZONE_PER        = 5_000                     ' 5mS (1/4th of typical servo period of 20mS)
    NO_GLITCH_WIN   = 3_000                     ' 3mS glitch prevention window (set value larger
                                                '   than maximum servo width of 2.5mS)
                                                ' Use at least 500uS for overhead (actual overhead
                                                '   about 300uS)
    LOW_RNG         = 500
    HI_RNG          = 2500

VAR

    long _ramp_flag
    long _zone_clks
    long _no_glitch
    long _servo_pin_dir
    long _servo_data[32]                        ' 0-31 Current Servo Value
    long _servo_tgt[32]                         ' 0-31 Desired Servo Value
    long _servo_dly[32]                         ' 0-31 Servo Ramp Delay

OBJ

    sramp : "motor.servo.ramp.spin"

PUB start
' Start servo engine
    _ramp_flag := 0
    _zone_clks := (clkfreq / _1US * ZONE_PER)   ' calculate # of clocks per ZONE_PER

    { calculate # of clocks for glitch-free servos; problem occurs when 'cnt' value rollover is
        less than the servo's pulse width. }
    _no_glitch := $FFFF_FFFF-(clkfreq / _1US * NO_GLITCH_WIN)

    cognew(@servo_start, @_zone_clks)

PUB ramp
' Start (optional) servo ramping core
    sramp.start_ramp(@_servo_data)
    _ramp_flag := 1

PUB setramp = set_ramp
PUB set_ramp(pin, width, delay) | s_width
' Ramp servo to position set by 'width' over 'delay' time period
'   NOTE: delay resolution is approx. 38.75 microseconds (3100 clocks)
    _servo_dly[pin] := delay

    { calculate # of clocks for a specific pulse width and adjust the snap value to match the
    value of CORE_SPD (this prevents jitter when servo has reached it's target position) }
    s_width := LOW_RNG #> width <# HI_RNG
    pin := 0 #> pin <# 31
    _servo_tgt[pin] := ((clkfreq / _1US * s_width) / sramp#CORE_SPD) * sramp#CORE_SPD


    if (s_width == width)
        dira[in] := 1                           ' set servo pin to output
    else
        dira[pin] := 0                          ' or as input if width out of range
    _servo_pin_dir := dira                      ' read I/O state of ALL pins

PUB set(pin, width) | s_width
' Set servo on I/O pin to pulse width
    { clamp pulse width range and I/O pin }
    s_width := (LOW_RNG #> width <# HI_RNG)
    pin := (0 #> pin <# 31)

    if (_ramp_flag == 0)
        { calculate # of clocks for a specific pulse width }
        _servo_data[pin] := (clkfreq / _1US * s_width)
    else
        _servo_data[pin] := ((clkfreq / _1US * s_width) / sramp#CORE_SPD) * sramp#CORE_SPD

    _servo_tgt[pin] := _servo_data[pin]

    if (s_width == width)
        dira[pin] := 1                          ' set servo pin to output
    else
        dira[pin] := 0                          ' or as input if width out of range
    _servo_pin_dir := dira                      ' read I/O state of ALL pins

DAT

                    org

servo_start         mov     idx,            par             ' set idx pointer
                    rdlong  zone_clks,      idx             ' get zoneclock value
                    add     idx,            #4              ' inc to next ptr
                    rdlong  no_glitch,      idx             ' get no_glitch value
                    add     idx,            #4
                    mov     pin_dir_addr,   idx             ' set pointer for I/O direction addr
                    add     idx,            #32             ' inc idx to END of zone1 pointer
                    mov     zone1idx,       idx             ' set idx pointer for zone1
                    add     idx,            #32             ' inc idx to END of zone2 pointer
                    mov     zone2idx,       idx             ' set idx pointer for zone2
                    add     idx,            #32             ' inc idx to END of zone3 pointer
                    mov     zone3idx,       idx             ' set idx pointer for zone3
                    add     idx,            #32             ' inc idx to END of zone4 pointer
                    mov     zone4idx,       idx             ' set idx pointer for zone4
io_upd              rdlong  dira,           pin_dir_addr    ' get and set I/O pin directions


zone1               mov     zone_idx,       zone1idx        ' set idx pointer for zone1
                    call    #reset_zone
                    call    #zone_core
zone2               mov     zone_idx,       zone2idx        ' set idx pointer for zone2
                    call    #inc_zone
                    call    #zone_core
zone3               mov     zone_idx,       zone3idx        ' set idx pointer for zone3
                    call    #inc_zone
                    call    #zone_core
zone4               mov     zone_idx,       zone4idx        ' set idx pointer for zone4
                    call    #inc_zone
                    call    #zone_core
                    jmp     #io_upd


reset_zone          mov     zone_shift1,    #1
                    mov     zone_shift2,    #2
                    mov     zone_shift3,    #4
                    mov     zone_shift4,    #8
                    mov     zone_shift5,    #16
                    mov     zone_shift6,    #32
                    mov     zone_shift7,    #64
                    mov     zone_shift8,    #128
reset_zone_ret      ret


inc_zone            shl     zone_shift1,    #8
                    shl     zone_shift2,    #8
                    shl     zone_shift3,    #8
                    shl     zone_shift4,    #8
                    shl     zone_shift5,    #8
                    shl     zone_shift6,    #8
                    shl     zone_shift7,    #8
                    shl     zone_shift8,    #8
inc_zone_ret        ret


zone_core           mov     servo_byte,     #0
                    mov     idx,            zone_idx        ' set idx pointer for proper zone

zone_sync           mov     sync_pt,        cnt             ' set sync point with the system counter
                    sub     no_glitch,      sync_pt nr, wc  ' cnt rollover within pulse width?
            if_c    jmp     #zone_sync                      '   yes: set a new sync point

                    add     sync_pt,        #260            ' add overhead offset to counter sync
                                                            '   point midpoint

                    mov     loop_cntr,      #8              ' 8 servos for this zone
                    movd    ld_servos,      #servo_width8   ' restore/set ld_servos line
                    movd    servo_sync,     #servo_width8   ' Restore/set servo_sync line

ld_servos           rdlong  servo_width8,   idx             ' get servo data
                    sub     idx,            #4              ' decrement idx pointer to next addr
                    nop
servo_sync          add     servo_width8,   sync_pt         ' pulse end
                    sub     ld_servos,      d_field         ' self-modify dest. ptr for ld_servos
                    sub     servo_sync,     d_field         ' self-modify dest. ptr for servo_sync
                    djnz    loop_cntr,      #ld_servos      ' do ALL 8 servo positions for this zone

                    mov     temp,           zone_clks
                    add     temp,           sync_pt         ' add sync_pt to zone_clks

{ Servo code (80 clocks - 1uS resolution at 80MHz) }
zoneloop            mov     tempcnt,        cnt             ' snapshot of current counter value
                    cmpsub  servo_width1,   tempcnt nr, wc  ' compare system counter to servo_width
                    muxc    servo_byte,     zone_shift1     ' set servo_byte.bit0 to the result
                    cmpsub  servo_width2,   tempcnt nr, wc
                    muxc    servo_byte,     zone_shift2     ' servo_byte.bit1
                    cmpsub  servo_width3,   tempcnt nr, wc
                    muxc    servo_byte,     zone_shift3     ' servo_byte.bit2
                    cmpsub  servo_width4,   tempcnt nr, wc
                    muxc    servo_byte,     zone_shift4     ' servo_byte.bit3
                    cmpsub  servo_width5,   tempcnt nr, wc
                    muxc    servo_byte,     zone_shift5     ' servo_byte.bit4
                    cmpsub  servo_width6,   tempcnt nr, wc
                    muxc    servo_byte,     zone_shift6     ' servo_byte.bit5
                    cmpsub  servo_width7,   tempcnt nr, wc
                    muxc    servo_byte,     zone_shift7     ' servo_byte.bit6
                    cmpsub  servo_width8,   tempcnt nr, wc
                    muxc    servo_byte,     zone_shift8     ' servo_byte.bit7
                    mov     outa,           servo_byte      ' send servo_byte to zone port
                    cmp     temp,           tempcnt nr, wc  ' cnt > zone_clks width? write C
            if_nc   jmp     #zoneloop                       '   no? set stay in the current zone

zone_core_ret       ret

{ initialized data }
d_field             long    $0000_0200

pin_dir_addr        long    0

counter             long    0
addr1               long    0
addr2               long    0
addr3               long    0
temp1               long    0
temp2               long    0
tempcnt             long    0

dly                 long    0[32]

servo_width1        res     1
servo_width2        res     1
servo_width3        res     1
servo_width4        res     1
servo_width5        res     1
servo_width6        res     1
servo_width7        res     1
servo_width8        res     1

zone_shift1         res     1
zone_shift2         res     1
zone_shift3         res     1
zone_shift4         res     1
zone_shift5         res     1
zone_shift6         res     1
zone_shift7         res     1
zone_shift8         res     1

temp                res     1
idx                 res     1
zone_idx            res     1
zone1idx            res     1
zone2idx            res     1
zone3idx            res     1
zone4idx            res     1
sync_pt             res     1

servo_byte          res     1
loop_cntr           res     1

zone_clks           res     1
no_glitch           res     1
servo_pin_dir       res     1

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

