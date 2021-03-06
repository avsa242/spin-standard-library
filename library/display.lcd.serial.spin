{
    --------------------------------------------
    Filename: display.lcd.serial.spin
    Author: Jon Williams, Jeff Martin
    Modified by: Jesse Burt
    Description: Driver for serial LCDs
        Parallax PNs (#27976, #27977, #27979)
    Started Apr 29, 2006
    Updated May 24, 2020
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is a derivative of Serial_Lcd.spin,
        originally by Jon Williams, Jeff Martin.
    The existing header is preserved below.
}

' Authors: Jon Williams, Jeff Martin
{{
    Driver for Parallax Serial LCDs (#27976, #27977, #27979)

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
}}

#include "lib.terminal.spin"

CON

    LCD_BKSPC     = $08                                         ' move cursor left
    LCD_RT        = $09                                         ' move cursor right
    LCD_LF        = $0A                                         ' move cursor down 1 line
    LCD_CLS       = $0C                                         ' clear LCD (follow with 5 ms delay)
    LCD_CR        = $0D                                         ' move pos 0 of next line
    LCD_BL_ON     = $11                                         ' backlight on
    LCD_BL_OFF    = $12                                         ' backlight off
    LCD_OFF       = $15                                         ' LCD off
    LCD_ON1       = $16                                         ' LCD on; cursor off, blink off
    LCD_ON2       = $17                                         ' LCD on; cursor off, blink on
    LCD_ON3       = $18                                         ' LCD on; cursor on, blink off
    LCD_ON4       = $19                                         ' LCD on; cursor on, blink on
    LCD_LINE0     = $80                                         ' move to line 1, column 0
    LCD_LINE1     = $94                                         ' move to line 2, column 0
    LCD_LINE2     = $A8                                         ' move to line 3, column 0
    LCD_LINE3     = $BC                                         ' move to line 4, column 0

    #$F8, LCD_CC0, LCD_CC1, LCD_CC2, LCD_CC3
    #$FC, LCD_CC4, LCD_CC5, LCD_CC6, LCD_CC7

VAR

    long  _display_lines

OBJ

    serial  : "com.serial.terminal"
    time    : "time"

PUB Start(LCD_PIN, LCD_BAUD, LCD_LINES): okay

    if lookdown(LCD_PIN: 0..31)
        if lookdown(LCD_BAUD: 2400, 9600, 19200)
            if lookdown(LCD_LINES: 2, 4)
                if okay := serial.StartRxTx(-1, LCD_PIN, 0, LCD_BAUD)   ' tx pin only, true mode
                    _display_lines := LCD_LINES                 ' save lines size
                    return okay

    return FALSE                                                ' If we got here, something went wrong

PUB Char(txByte)
{{
    Transmit a byte
}}
    serial.Char(txByte)

PUB Clear
{{
    Clears LCD and moves cursor to home (0, 0) position
}}
    Char(LCD_CLS)
    time.MSleep(5)

PUB ClearLine(y)
{{
    Clears line
}}
    if _display_lines == 2                                      ' check lcd size
        if lookdown(y: 0..1)                                    ' qualify line input
            Char(LinePos[y])                                    ' move to that line
            repeat 16
                Char(32)                                        ' clear line with spaces
            Char(LinePos[y])                                    ' return to start of line
    else
        if lookdown(y: 0..3)
            Char(LinePos[y])
            repeat 20
                Char(32)
            Char(LinePos[y])

PUB CursorMode(type)
{{
    Selects cursor type

    - 0 : cursor off, blink off
    - 1 : cursor off, blink on
    - 2 : cursor on, blink off
    - 3 : cursor on, blink on
}}
    case type
        0..3: Char(DispMode[type])                              ' get mode from table
        OTHER: Char(LCD_ON3)                                    ' use serial lcd power-up default

PUB DefineChars(bytechr, chrDataAddr)
{{
    Installs custom character map
    -- chrDataAddr is address of 8-byte character definition array
}}
    if lookdown(bytechr: 0..7)                                  ' make sure char in range
        Char(LCD_CC0 + bytechr)                                 ' write character code
        repeat 8
            Char(byte[chrDataAddr++])                           ' write character data

PUB DisplayVisibility(enable)
{{
    Controls display visibility; use display(false) to hide contents
    without clearing.
}}
    if enable
        CursorMode(0)
    else
        Char(LCD_OFF)

PUB EnableBacklight(enable)
{{
    Enable (true) or disable (false) LCD backlight
    -- works only with backlight-enabled displays
}}
    enable := enable <> 0                                       ' promote non-zero to -1
    if enable
        Char(LCD_BL_ON)
    else
        Char(LCD_BL_OFF)

PUB Home
{{
    Moves cursor to 0, 0
}}
    Char(LCD_LINE0)

PUB Position(x, y) | pos
{{
    Moves cursor to x/y
}}
    if _display_lines == 2                                      ' check lcd size
        if lookdown(y: 0..1)                                    ' qualify y input
            if lookdown(x: 0..15)                               ' qualify x input
                Char(LinePos[y] + x)                            ' move to target position
    else
        if lookdown(y: 0..3)
            if lookdown(x: 0..19)
                Char(LinePos[y] + x)

DAT

    LinePos     byte    LCD_LINE0, LCD_LINE1, LCD_LINE2, LCD_LINE3
    DispMode    byte    LCD_ON1, LCD_ON2, LCD_ON3, LCD_ON4

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

