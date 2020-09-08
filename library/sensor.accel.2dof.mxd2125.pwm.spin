{
    --------------------------------------------
    Filename: sensor.accel.2dof.mxd2125.pwm.spin
    Author: Jesse Burt
    Description: Driver for the Memsic MXD2125
        2DoF accelerometer (PWM)
        (based on driver originally by Beau Schwabe)
    Started 2006
    Updated Sep 8, 2020
    See end of file for terms of use.
    --------------------------------------------
}

{{
*****************************************
* Memsic 2125 Driver v1.2               *
* Author: Beau Schwabe                  *
* Copyright (c) 2006 - 2009 Parallax    *
* See end of file for terms of use.     *
*****************************************


History:

Version 1.0 - (07-31-2006) original release
Version 1.1 - (08-17-2008) modified code to return RAW x and y values
Version 1.2 - (12-18-2009) Added X and Y Tilt values

}}
{
         ┌──────────┐
Tout ──│1  6│── VDD
         │  ┌────┐  │
Yout ──│2 │ /\ │ 5│── Xout
         │  │/  \│  │
 VSS ──│3 └────┘ 4│── VSS
         └──────────┘

}
' Indicate to the counters object that we want constants shifted appropriate
'   for PASM operands
#define _PASM_
CON

    ACCEL_DOF           = 2
    GYRO_DOF            = 0
    MAG_DOF             = 0
    BARO_DOF            = 0
    DOF                 = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

VAR

    long  _cog

    long  _offset
    long  _scale

    long  _cal_flag                                 ' 5 contiguous longs
    long  _ro
    long  _theta
    long  _xraw
    long  _yraw

OBJ

    ctrs    : "core.con.counters"                   ' Counter setup constants
    time    : "time"

PUB Null{}
' This is not a top-level object

PUB Start(MXD_XPIN, MXD_YPIN): okay
' Start driver - starts a cog
' returns false if no cog available
    stop{}
    _offset := 90 * (clkfreq / 200)                 ' offset value for Tilt conversion
    _scale  := clkfreq / 800                        ' scale value for Tilt conversion
    ctra_value := ctrs#LOGIC_A + MXD_XPIN
    ctrb_value := ctrs#LOGIC_A + MXD_YPIN
    mask_value := (|< MXD_XPIN) + (|< MXD_YPIN)
    okay := _cog := cognew(@entry, @_cal_flag) + 1
    calibrateaccel{}
    time.msleep(100)

PUB Stop{}
' Stop driver - frees a cog
    if _cog
       cogstop(_cog~ - 1)
    longfill(@_cal_flag, 0, 3)

PUB AccelADCRes(bits)
' dummy method

PUB AccelAxisEnabled(xyz_mask)
' Enable accelerometer axis per bit mask
'   NOTE: Read-only
'   Returns: %110 (x = 1, y = 1, z = 0)
    return %110

PUB AccelBias(x, y, z, rw)
' dummy method

PUB AccelData(ptr_x, ptr_y, ptr_z)
' Read accelerometer raw data
    long[ptr_x] := _xraw
    long[ptr_y] := _yraw
    long[ptr_z] := 0

PUB AccelDataOverrun{}: flag
' dummy method

PUB AccelDataRate(Hz): curr_rate
' Set Accelerometer output data rate, in Hz
'   NOTE: Read-only
'   Returns: 100
    return 100

PUB AccelDataReady{}: flag
' Flag indicating new accelerometer data available
'   Returns: TRUE (-1)
    return true

PUB AccelG(ptr_x, ptr_y, ptr_z)
' Read accelerometer calibrated data (g's)
    long[ptr_x] := _ro / (clkfreq / 500_000) 'XXX separate measurements?
    long[ptr_y] := _ro / (clkfreq / 500_000) 'XXX

PUB AccelInt{}: flag
' dummy method

PUB AccelScale(g): curr_setting
' Set full-scale range of accelerometer
'   NOTE: Read-only
'   Returns: 3
    return 3

PUB AccelTilt(ptr_x, ptr_y, ptr_z)
' Read accelerometer tilt
    long[ptr_x] := (_xraw * 90 - _offset) / _scale
    long[ptr_y] := (_yraw * 90 - _offset) / _scale

PUB CalibrateAccel{}
' Calibrate the accelerometer
    _cal_flag := 1

PUB Theta{}: angle

    return _theta

DAT

                        org
entry                   mov     ctra, ctra_value        ' Setup counters
                        mov     ctrb, ctrb_value        ' (ctra = X, ctrb = Y)

                        mov     frqa, #1
                        mov     frqb, #1

:loop                   mov     phsa, #0                ' Reset phase A & B
                        mov     phsb, #0

                        waitpeq mask_value, mask_value  ' Wait until X and Y
                        waitpeq zero, mask_value        '  go high, then low

                        mov     rawx, phsa              ' Copy to working
                        mov     rawy, phsb              '  variables

                        rdlong  t1, par          wz     ' Check cal flag and if
        if_nz           mov     levelx, rawx            '  set, initialize bias
        if_nz           mov     levely, rawy            '  offsets to compensate
                                                        '  level tilt error
        if_nz           wrlong  zero, par               ' Reset cal flag

                        mov     cx, rawx                ' Get final x,y and
                        sub     cx, levelx              '  apply level offset
                        mov     cy, rawy
                        sub     cy, levely

                        call    #cordic                 ' Convert to polar

                        mov     t1, par                 ' Write result
                        add     t1, #4
                        wrlong  cx, t1
                        add     t1, #4
                        wrlong  ca, t1
                        add     t1, #4
                        wrlong  rawx, t1
                        add     t1, #4
                        wrlong  rawy, t1

                        jmp     #:loop

' Perform CORDIC cartesian-to-polar conversion
cordic                  abs     cx, cx           wc
        if_c            neg     cy, cy
                        mov     ca, #0
                        rcr     ca, #1

                        movs    :lookup, #table
                        mov     t1, #0
                        mov     t2, #20

:loop                   mov     dx, cy           wc
                        sar     dx, t1
                        mov     dy, cx
                        sar     dy, t1
                        sumc    cx, dx
                        sumnc   cy, dy
:lookup                 sumc    ca, table

                        add     :lookup, #1
                        add     t1, #1
                        djnz    t2, #:loop

cordic_ret              ret


table                   long    $20000000
                        long    $12E4051E
                        long    $09FB385B
                        long    $051111D4
                        long    $028B0D43
                        long    $0145D7E1
                        long    $00A2F61E
                        long    $00517C55
                        long    $0028BE53
                        long    $00145F2F
                        long    $000A2F98
                        long    $000517CC
                        long    $00028BE6
                        long    $000145F3
                        long    $0000A2FA
                        long    $0000517D
                        long    $000028BE
                        long    $0000145F
                        long    $00000A30
                        long    $00000518

' Initialized data
ctra_value              long    0
ctrb_value              long    0
mask_value              long    0
zero                    long    0
h80000000               long    $80000000


' Uninitialized data
t1                      res     1
t2                      res     1

rawx                    res     1
rawy                    res     1

levelx                  res     1
levely                  res     1

dx                      res     1
dy                      res     1
cx                      res     1
cy                      res     1
ca                      res     1

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
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
