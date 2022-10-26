{
    --------------------------------------------
    Filename: display.vga.text.100x50.spin
    Description: VGA text terminal driver
        * 100x50 characters (signalled as 800x600@75Hz)
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

    { 800 x 600 @ 75Hz settings: 100 x 50 characters }
    HP      = 800                               ' horizontal pixels
    VP      = 600                               ' vertical pixels
    HF      = 40                                ' horizontal front porch pixels
    HS      = 128                               ' horizontal sync pixels
    HB      = 88                                ' horizontal back porch pixels
    VF      = 1                                 ' vertical front porch lines
    VS      = 4                                 ' vertical sync lines
    VB      = 23                                ' vertical back porch lines
    HN      = 0                                 ' horizontal normal sync state (0|1)
    VN      = 0                                 ' vertical normal sync state (0|1)
    PR      = 50                                ' pixel rate in MHz at 80MHz system clock
                                                '   (5MHz granularity)

{ see this include for actual driver code }
#include "display.vga.text.common.spinh"

