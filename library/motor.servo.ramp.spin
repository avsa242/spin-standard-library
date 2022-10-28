{
    --------------------------------------------
    Filename: motor.servo.ramp.spin
    Description: Servo driver - optional ramping control
    Author: Beau Schwabe
    Modified by: Jesse Burt
    Started May 11, 2009
    Updated Oct 27, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Servo32_Ramp_v2.spin,
        originally by Beau Schwabe
}

CON

    CORE_SPD    = 620

' increment/decrement pulse width every 3100 clocks
' So at 2us and a full sweep 500us to 2500us (Delta of 2000us)
' the total time travel would be 38.75ms
'
' 160 = 2us @ 38.750ms
' 240 = 3us @ 25.833ms
' 320 = 4us @ 19.375ms
' 400 = 5us @ 15.500ms
' 413 = 5.1625us @ 15.012ms
' 480 = 6us @ 12.917ms
' 560 = 7us @ 11.071ms
' 620 = 7.75us @ 10ms
' 640 = 8us @ 9.6875ms


PUB start_ramp(servo_data)

    cognew(@ramp_start, servo_data)

DAT
' Note: It takes aproximately 3100 clocks to process all 32 Channels,
'       So the resolution is about 38.75us
                    org
ramp_start
                    mov     addr1,      par             ' _servo_data
                    mov     addr2,      addr1
                    add     addr2,      #128            ' _servo_tgt
                    mov     addr3,      addr2
                    add     addr3,      #128            ' _servo_dly

ch01                sub     dly + 00,   #1      wc
            if_c    rdlong  dly + 00,   addr3           ' move _servo_dly into temp delay value
                    call    #ramp_core

ch02                sub     dly + 01,   #1      wc
            if_c    rdlong  dly + 01,   addr3
                    call    #ramp_core

ch03                sub     dly + 02,   #1      wc
            if_c    rdlong  dly + 02,   addr
                    call    #ramp_core

ch04                sub     dly + 04,   #1      wc
            if_c    rdlong  dly + 04,   addr
                    call    #ramp_core

ch05                sub     dly + 05,   #1      wc
            if_c    rdlong  dly + 05,   addr
                    call    #ramp_core

ch06                sub     dly + 06,   #1      wc
            if_c    rdlong  dly + 06,   addr
                    call    #ramp_core

ch07                sub     dly + 07,   #1      wc
            if_c    rdlong  dly + 07,   addr
                    call    #ramp_core

ch08                sub     dly + 08,   #1      wc
            if_c    rdlong  dly + 08,   addr
                    call    #ramp_core

ch09                sub     dly + 09,   #1      wc
            if_c    rdlong  dly + 09,   addr
                    call    #ramp_core

ch10                sub     dly + 10,   #1      wc
            if_c    rdlong  dly + 10,   addr
                    call    #ramp_core

ch11                sub     dly + 11,   #1      wc
            if_c    rdlong  dly + 11,   addr
                    call    #ramp_core

ch12                sub     dly + 12,   #1      wc
            if_c    rdlong  dly + 12,   addr
                    call    #ramp_core

ch13                sub     dly + 13,   #1      wc
            if_c    rdlong  dly + 13,   addr
                    call    #ramp_core

ch14                sub     dly + 14,   #1      wc
            if_c    rdlong  dly + 14,   addr
                    call    #ramp_core

ch15                sub     dly + 15,   #1      wc
            if_c    rdlong  dly + 15,   addr
                    call    #ramp_core

ch16                sub     dly + 16,   #1      wc
            if_c    rdlong  dly + 16,   addr
                    call    #ramp_core

ch17                sub     dly + 17,   #1      wc
            if_c    rdlong  dly + 17,   addr
                    call    #ramp_core

ch18                sub     dly + 18,   #1      wc
            if_c    rdlong  dly + 18,   addr
                    call    #ramp_core

ch19                sub     dly + 19,   #1      wc
            if_c    rdlong  dly + 19,   addr
                    call    #ramp_core

ch20                sub     dly + 20,   #1      wc
            if_c    rdlong  dly + 20,   addr
                    call    #ramp_core

ch21                sub     dly + 21,   #1      wc
            if_c    rdlong  dly + 21,   addr
                    call    #ramp_core

ch22                sub     dly + 22,   #1      wc
            if_c    rdlong  dly + 22,   addr
                    call    #ramp_core

ch23                sub     dly + 23,   #1      wc
            if_c    rdlong  dly + 23,   addr
                    call    #ramp_core

ch24                sub     dly + 24,   #1      wc
            if_c    rdlong  dly + 24,   addr
                    call    #ramp_core

ch25                sub     dly + 25,   #1      wc
            if_c    rdlong  dly + 25,   addr
                    call    #ramp_core

ch26                sub     dly + 26,   #1      wc
            if_c    rdlong  dly + 26,   addr
                    call    #ramp_core

ch27                sub     dly + 27,   #1      wc
            if_c    rdlong  dly + 27,   addr
                    call    #ramp_core

ch28                sub     dly + 28,   #1      wc
            if_c    rdlong  dly + 28,   addr
                    call    #ramp_core

ch29                sub     dly + 29,   #1      wc
            if_c    rdlong  dly + 29,   addr
                    call    #ramp_core

ch30                sub     dly + 30,   #1      wc
            if_c    rdlong  dly + 30,   addr
                    call    #ramp_core

ch31                sub     dly + 31,   #1      wc
            if_c    rdlong  dly + 31,   addr
                    call    #ramp_core

ch32                sub     dly + 32,   #1      wc
            if_c    rdlong  dly + 32,   addr
                    call    #ramp_core

                    jmp     #ramp_start

ramp_core
                    rdlong  temp1,      addr1           ' move _servo_data into temp1
                    rdlong  temp2,      addr2           ' move _servo_tgt into temp2
            if_nc   jmp     #code_bal
                    cmp     temp1,      temp2   wc, wz  ' ramp up or down?

    if_c_and_nz     add     temp1,      _core_spd       ' _servo_data inc if _servo_tgt is greater
    if_nc_and_nz    sub     temp1,      _core_spd       ' _servo_data dec if _servo_tgt is less

outloop             wrlong  temp1,      addr1           ' update _servo_data value

                    add     addr1,      #4              ' increment _servo_dly pointer
                    add     addr2,      #4              ' increment _servo_data pointer
                    add     addr3,      #4
ramp_core_ret       ret

code_bal            nop                                 ' makes for equal code branch path
                    jmp     #outloop

{ initialized data }
time1               long    0
time2               long    0

_core_spd           long    CORE_SPD

addr1               long    0
addr2               long    0
addr3               long    0
addr4               long    0

temp1               long    0
temp2               long    0

dly                 long    0[32]

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

