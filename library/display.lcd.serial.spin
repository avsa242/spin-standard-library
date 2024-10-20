{
    --------------------------------------------
    Filename: display.lcd.serial.spin
    Author: Jesse Burt
    Description: Driver for serial LCDs
        Parallax PNs (#27976, #27977, #27979)
    Started Apr 29, 2006
    Updated Oct 29, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Serial_Lcd.spin,
        originally by Jon Williams, Jeff Martin.

    ## Serial LCD Switch Settings for Baud rate

        ┌─────────┐   ┌─────────┐   ┌─────────┐
        │   O N   │   │   O N   │   │   O N   │
        │ ┌──┬──┐ │   │ ┌──┬──┐ │   │ ┌──┬──┐ │
        │ │[]│  │ │   │ │  │[]│ │   │ │[]│[]│ │
        │ │  │  │ │   │ │  │  │ │   │ │  │  │ │
        │ │  │[]│ │   │ │[]│  │ │   │ │  │  │ │
        │ └──┴──┘ │   │ └──┴──┘ │   │ └──┴──┘ │
        │  1   2  │   │  1   2  │   │  1   2  │
        └─────────┘   └─────────┘   └─────────┘
           2400          9600          19200
}

#include "terminal.common.spinh"

CON

    LCD_BKSPC     = $08                         ' move cursor left
    LCD_RT        = $09                         ' move cursor right
    LCD_LF        = $0A                         ' move cursor down 1 line
    LCD_CLS       = $0C                         ' clear LCD (follow with 5 ms delay)
    LCD_CR        = $0D                         ' move pos 0 of next line
    LCD_BL_ON     = $11                         ' backlight on
    LCD_BL_OFF    = $12                         ' backlight off
    LCD_OFF       = $15                         ' LCD off
    LCD_ON1       = $16                         ' LCD on; cursor off, blink off
    LCD_ON2       = $17                         ' LCD on; cursor off, blink on
    LCD_ON3       = $18                         ' LCD on; cursor on, blink off
    LCD_ON4       = $19                         ' LCD on; cursor on, blink on
    LCD_LINE0     = $80                         ' move to line 1, column 0
    LCD_LINE1     = $94                         ' move to line 2, column 0
    LCD_LINE2     = $A8                         ' move to line 3, column 0
    LCD_LINE3     = $BC                         ' move to line 4, column 0

    #$F8, LCD_CC0, LCD_CC1, LCD_CC2, LCD_CC3
    #$FC, LCD_CC4, LCD_CC5, LCD_CC6, LCD_CC7

VAR

    long  _disp_lines

OBJ

    serial  : "com.serial.terminal"
    time    : "time"

PUB start = startx
PUB startx(LCD_PIN, LCD_BAUD, LCD_LINES): status
' Start the driver using custom I/O settings
'   LCD_PIN: I/O pin connected to LCD
'   LCD_BAUD: bitrate LCD is set to receive at
'   LCD_LINES: design height of LCD in number of text lines (2 or 4)
    if (lookdown(LCD_PIN: 0..31) and lookdown(LCD_BAUD: 2400, 9600, 19200))
        if (status := serial.init(-1, LCD_PIN, 0, LCD_BAUD))
            ifnot (lookdown(LCD_LINES: 2, 4))
                LCD_LINES := 2
            _disp_lines := LCD_LINES         ' save lines size
            return

    return FALSE                                ' If we got here, something went wrong

PUB char = putchar
PUB putchar(txb)
' Transmit a byte
    serial.putchar(txb)

PUB clear{}
' Clear LCD and move cursor to home (0, 0) position
    putchar(LCD_CLS)
    time.msleep(5)

PUB clearline = clear_ln
PUB clear_line = clear_ln
PUB clear_ln(y)
' Clear line
    if (_disp_lines == 2)                    ' check lcd size
        if (lookdown(y: 0..1))                  ' qualify line input
            putchar(_line_pos[y])               ' move to that line
            repeat 16
                putchar(32)                     ' clear line with spaces
            putchar(_line_pos[y])               ' return to start of line
    else
        if (lookdown(y: 0..3))
            putchar(_line_pos[y])
            repeat 20
                putchar(32)
            putchar(_line_pos[y])

PUB cursormode = curs_mode
PUB curs_mode(mode)
' Selects cursor type
'   - 0 : cursor off, blink off
'   - 1 : cursor off, blink on
'   - 2 : cursor on, blink off
'   - 3 : cursor on, blink on
    case mode
        0..3:
            putchar(_disp_mode[mode])           ' get mode from table
        other:
            putchar(LCD_ON3)                    ' use serial lcd power-up default

PUB definechars = def_chars
PUB def_chars(bytechr, ptr_char)
' Install custom character map
'   ptr_char: address of 8-byte character definition array
    if (lookdown(bytechr: 0..7))                ' make sure char in range
        putchar(LCD_CC0 + bytechr)              ' write character code
        repeat 8
            putchar(byte[ptr_char++])           ' write character data

PUB disp_vis_ena(state)
' Enable display visibility
'   Valid values: TRUE (non-zero), FALSE (0)
'   NOTE: Doesn't alter display contents (turning off, then on, the display contents will return)
    if (state)
        curs_mode(0)
    else
        putchar(LCD_OFF)

PUB enablebacklight = backlight_ena
PUB backlight_ena(enable)
' Enable LCD backlight
'   Valid values: TRUE (non-zero), FALSE (0)
'   NOTE: works only with backlight-enabled displays
    if (enable)
        putchar(LCD_BL_ON)
    else
        putchar(LCD_BL_OFF)

PUB home{}
' Move cursor to 0, 0
    putchar(LCD_LINE0)

PUB position = pos_xy
PUB pos_xy(x, y) | pos
' Move cursor to (x, y) position
    if (_disp_lines == 2)                    ' check lcd size
        if (lookdown(y: 0..1))                  ' validate coords
            if (lookdown(x: 0..15))             ' ...
                putchar(_line_pos[y] + x)       ' move to target position
    else
        if (lookdown(y: 0..3))
            if (lookdown(x: 0..19))
                putchar(_line_pos[y] + x)

DAT

    _line_pos   byte    LCD_LINE0, LCD_LINE1, LCD_LINE2, LCD_LINE3
    _disp_mode  byte    LCD_ON1, LCD_ON2, LCD_ON3, LCD_ON4

DAT
{
Copyright 2022 Jesse Burt

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

