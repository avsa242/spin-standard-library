{
    --------------------------------------------
    Filename: display.vga.80x40.spin
    Description: VGA text terminal driver
        * 80x40 characters (signalled as 640x480@69Hz)
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

    { 640 x 480 @ 69Hz settings: 80 x 40 characters }
    HP = 640                                    ' horizontal pixels
    VP = 480                                    ' vertical pixels
    HF = 24                                     ' horizontal front porch pixels
    HS = 40                                     ' horizontal sync pixels
    HB = 128                                    ' horizontal back porch pixels
    VF = 9                                      ' vertical front porch lines
    VS = 3                                      ' vertical sync lines
    VB = 28                                     ' vertical back porch lines
    HN = 1                                      ' horizontal normal sync state (0|1)
    VN = 1                                      ' vertical normal sync state (0|1)
    PR = 30                                     ' pixel rate in MHz at 80MHz system clock
                                                '   (5MHz granularity)

{ see this include for actual driver code }
#include "display.vga.text.common.spinh"

