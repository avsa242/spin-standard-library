{
    --------------------------------------------
    Filename: display.vga.text.128x64.spin
    Description: VGA text terminal driver
        * 100x50 characters (signalled as 1024x768@57Hz)
        * 8x12 glyphs
    Author: Jesse Burt
    Started 2006
    Updated Oct 26, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on VGA_HiRes_Text.spin,
        originally by Chip Gracey
}

CON

    { 1024 x 768 @ 57Hz settings: 128 x 64 characters }
    HP = 1024                                   ' horizontal pixels
    VP = 768                                    ' vertical pixels
    HF = 16                                     ' horizontal front porch pixels
    HS = 96                                     ' horizontal sync pixels
    HB = 176                                    ' horizontal back porch pixels
    VF = 1                                      ' vertical front porch lines
    VS = 3                                      ' vertical sync lines
    VB = 28                                     ' vertical back porch lines
    HN = 1                                      ' horizontal normal sync state (0|1)
    VN = 1                                      ' vertical normal sync state (0|1)
    PR = 60                                     ' pixel rate in MHz at 80MHz system clock
                                                '   (5MHz granularity)

{ see this include for actual driver code }
#include "display.vga.text.common.spinh"

