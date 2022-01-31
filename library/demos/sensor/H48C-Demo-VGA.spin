{
    --------------------------------------------
    Filename: H48C-Demo-VGA.spin
    Author: Beau Schwabe
    Modified By: Jesse Burt
    Description: Demo of the H48C 3DoF accel driver
    Started Sept 2006
    Updated Apr 28, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on H48C Tri-Axis Accelerometer DEMO.spin,
        originally by Beau Schwabe
}

{{
*********************************************
* H48C Tri-Axis Accelerometer VGA_DEMO V1.1 *
* Author: Beau Schwabe                      *
* Copyright (c) 2008 Parallax               *
* See end of file for terms of use.         *
*********************************************

Revision History:

Version 1.0 - (Sept. 2006) - Initial release with a TV mode 3D-graphics cube
Version 1.1 - (March 2008) - 3D-graphics cube removed
                           - Basic VGA mode display used instead of TV
                           - Added 600nS padding delay around Clock rise and fall times
}}
{

     220Ω  ┌──────────┐
  P2 ──│1 ‣‣••6│── +5V       P0 = CS_PIN
     220Ω  │  ┌°───┐  │ 220Ω          P1 = DIO_PIN
  P1 ──│2 │ /\ │ 5│── P0      P2 = CLK_PIN
           │  └────┘  │ 220Ω
   VSS ──│3  4│── Zero-G
           └──────────┘

Note1: Zero-G output not used in this demo

Note2: orientation

         Z   Y    
         │  /    /   °/  reference mark on H48C Chip, not white dot on 6-Pin module
         │ /    /    /
         │/     o   white reference mark on 6-Pin module indicating Pin #1
          ──── X

       _theta_a - Angle relation between X and Y
       _theta_b - Angle relation between X and Z
       _theta_c - Angle relation between Z and Y



Note3: The H48C should be powered with a 5V supply.  It has an internal regulator
       that regulates the voltage down to 3.3V where Vref is set to 1/2 of the 3.3V
       In this object, the axis is already compensated with regard to Vref. Because
       of this, the formulas are slightly different (simplified) compared to what is
       stated in the online documentation.

G = ( axis / 4095 ) x ( 3.3 / 0.3663 )

        or

G = axis x 0.0022

        or

G = axis / 455


An expected return value from each axis would range between ±1365.

i.e.
 ±455 would represent ±1g
 ±910 would represent ±2g
±1365 would represent ±3g

}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
' H48C I/O pins
    CS_PIN      = 0
    DIO_PIN     = 1
    CLK_PIN     = 2

' VGA
    VGA_BASEPIN = 16

' --

VAR

    long _vref, _x, _y, _z, _theta_a, _theta_b, _theta_c

OBJ

    cfg     : "core.con.boardcfg.quickstart-hib"
    h48c    : "sensor.accel.3dof.h48c"
    vga     : "display.vga.text"

PUB Demo_Test{}

    'start VGA terminal
    vga.start(VGA_BASEPIN)

    'start and setup Accelerometer
    h48c.start(CS_PIN, DIO_PIN, CLK_PIN)

    vga.char($01)
    vga.str(string("H48C 3DoF Accelerometer"))

    vga.str(string($A, 4, $B, 4))
    vga.str(string("Vref ="))

    vga.str(string($A, 7, $B, 6))
    vga.str(string("X ="))
    vga.str(string($A, 7, $B, 7))
    vga.str(string("Y ="))
    vga.str(string($A, 7, $B, 8))
    vga.str(string("Z ="))

    vga.str(string($A, 1, $B, 10))
    vga.str(string("Theta A ="))
    vga.str(string($A, 1, $B, 11))
    vga.str(string("Theta B ="))
    vga.str(string($A, 1, $B, 12))
    vga.str(string("Theta C ="))

    repeat
        '_vref := (h48C.vref{} * 825) / 1024     ' _vref in mV

        _vref := h48c.vref{}                    '_vref raw

        ' NOTE: The returned value for X, Y, and Z is equal to the axis - Vref
        _x := h48c.x{}
        _y := h48c.y{}
        _z := h48c.z{}

        ' NOTE: The returned value is in Deg (0-359)
        '   remove the '*45)/1024' to return the 13-Bit Angle
        _theta_a := (h48c.thetaa{} * 45) / 1024' angle relationship between X and Y
        _theta_b := (h48c.thetab{} * 45) / 1024' angle relationship between X and Z
        _theta_c := (h48c.thetac{} * 45) / 1024' angle relationship between Y and Z

        vga.str(string($A, 11, $B, 4))
        vga.dec(_vref)
        vga.str(string("   "))

        vga.str(string($A, 11, $B, 6))
        vga.dec(_x)
        vga.str(string("  "))
        vga.str(string($A, 11, $B, 7))
        vga.dec(_y)
        vga.str(string("  "))
        vga.str(string($A, 11, $B, 8))
        vga.dec(_z)
        vga.str(string("  "))

        vga.str(string($A, 11, $B, 10))
        vga.dec(_theta_a)
        vga.str(string("  "))
        vga.str(string($A, 11, $B, 11))
        vga.dec(_theta_b)
        vga.str(string("  "))
        vga.str(string($A, 11, $B, 12))
        vga.dec(_theta_c)
        vga.str(string("  "))

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
