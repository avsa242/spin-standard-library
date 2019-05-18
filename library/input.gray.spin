{
    --------------------------------------------
    Filename: input.gray.spin
    Author: Jesse Burt
    Based on jm_grayenc2.spin, Copyright by Jon McPhalen
    Description: Input driver for 2-bit graycode encoder
    Copyright (c) 2019
    Started May 18, 2019
    Updated Mar 18, 2019
    See end of file for terms of use.
    --------------------------------------------
}

{{
    Connection:

            3v3   3v3
                  
             │     │
              10k 
             │     │
    Pa ─────┫     │
    Pb ─────┼─────┫
             │     │
           A ┤  B ┤
             │     │
             └──┳──┘
                 C

    Pa, Pb  - 2 consecutive I/O pins
    A, B    - Encoder outputs
    C       - GND
}}

VAR

    long  cog                                                     ' cog # of driver
    long  encoder                                                 ' current encoder value
    long  detent                                                  ' mult x4 if detented

PUB Start(base, has_detent, lo, hi, preset): okay
' Start graycode encoder cog
' -- base is lsb pin of contiguous group
' -- detent: 0 for non-detented encoders; 1 for encoders with off-off detent
' -- lo is low limit value for encoder
' -- hi is high limit value for encoder
' -- preset is starting value for encoder
    Stop                                                          ' stop if already running

    basepin   := base                                             ' set LSB of inputs
    enctiming := clkfreq / 500                                    ' sample @500Hz
  
    if has_detent
        detent  := true                                             ' x4 for detented encoder
        lolimit := lo << 2
        hilimit := hi << 2
        encoder := preset << 2
    else
        detent  := false
        lolimit := lo
        hilimit := hi
        encoder := preset

    okay := cog := cognew(@grayenc, @encoder) + 1                 ' start the cog
  
    return okay

PUB Stop
' Stops graycode encoder cog

    if cog
        cogstop(cog~ - 1)

PUB Read
' Get current encoder value

    if detent
        return (encoder ~> 2)                                       ' signed divide by 4
    else
        return encoder


PUB Set(value)
' Set/Reset encoder value

    if detent
        value <<= 2

    encoder := lolimit #> value <# hilimit  

DAT
' processes 2-bit, graycode input stream 
'
'   ---------------------------->>
'   00 <-> 01 <-> 11 <-> 10 <-> 00                              ' encoder outputs
'   <<----------------------------

                        org     0

grayenc                 rdlong  tmp1, par                       ' force preset to limits
                        cmps    tmp1, lolimit           wc, wz
              if_b      mov     tmp1, lolimit
                        cmps    tmp1, hilimit           wc, wz
              if_a      mov     tmp1, hilimit
                        wrlong  tmp1, par

                        mov     oldscan, ina                    ' get start-up inputs
                        shr     oldscan, basepin                ' z-align scan   
                        and     oldscan, #%11                   ' clear other bits

                        mov     timer, cnt                      ' sync with system cnt
                        add     timer, enctiming                ' set loop timing                        

encloop                 waitcnt timer, enctiming                ' hold for loop timing

scan                    mov     newscan, ina                    ' get current inputs     
                        shr     newscan, basepin                ' z-align scan
                        and     newscan, #%11                   ' clear other bits
                        cmp     newscan, oldscan        wz      ' check for change
              if_e      jmp     #encloop                        ' wait if none

case00                  cmp     oldscan, #%00           wz      ' oldscan == %00?
              if_ne     jmp     #case01                         ' if no, try next
                        cmp     newscan, #%01           wz      ' postive change? Z = yes
                        jmp     #update

case01                  cmp     oldscan, #%01           wz
              if_ne     jmp     #case11
                        cmp     newscan, #%11           wz   
                        jmp     #update

case11                  cmp     oldscan, #%11           wz
              if_ne     jmp     #case10
                        cmp     newscan, #%10           wz   
                        jmp     #update

case10                  cmp     oldscan, #%10           wz
              if_ne     jmp     #encloop                        ' (should never happen)
                        cmp     newscan, #%00           wz   
'                       jmp     #update                  
                                             
update                  rdlong  tmp2, par                       ' read current value from hub
              if_nz     jmp     #decvalue                       ' inc or dec?

incvalue                cmps    tmp2, hilimit           wz, wc  ' below high limit?
              if_b      adds    tmp2, #1                        ' increment
              if_a      mov     tmp2, hilimit                   ' fix bad value
              if_ne     wrlong  tmp2, par                       ' update hub if changed
                        mov     oldscan, newscan                ' reset                   
                        jmp     #encloop

decvalue                cmps    tmp2, lolimit           wz, wc  ' above low limit?
              if_a      subs    tmp2, #1                        ' decrement
              if_b      mov     tmp2, lolimit                   ' fix bad value
              if_ne     wrlong  tmp2, par                       ' update hub if changed
                        mov     oldscan, newscan                ' reset                   
                        jmp     #encloop
                        
' --------------------------------------------------------------------------------------------------

basepin                 long    0-0                             ' lsb of encoder group
enctiming               long    0-0                             ' encoder loop timing (ticks)

lolimit                 long    0-0                             ' encoder value limits
hilimit                 long    0-0

newscan                 res     1                               ' current inputs scan
oldscan                 res     1                               ' last inputs scan
timer                   res     1                               ' for loop delay

tmp1                    res     1                               ' work variables
tmp2                    res     1

                        fit     492                                    

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
