{
    --------------------------------------------
    Filename: lib.ansiterminal.spin
    Description: Library to add ANSI terminal functionality to a
        terminal driver
    Requires: Terminal driver that provides the following methods:
        Char(ch)    - Output one character to terminal
        CharIn      - Read one character from terminal
        Dec(num)    - Output a decimal number to terminal
    Author: Jesse Burt
    Copyright (c) 2020
    Created: Jun 18, 2019
    Updated: Oct 25, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    LBRACKET            = $5B

' Clear modes
    CLR_CUR_TO_END      = 0     ' Clear from cursor position to end of line
    CLR_CUR_TO_BEG      = 1     ' Clear from cursor position to beginning of line
    CLR_ALL_HOME        = 2     ' Clear screen and return to home position
    CLR_ALL_DEL_SCRLB   = 3     ' Clear all and delete scrollback

' Graphic Rendition modes
    SGR_RESET           = 0     ' Reset text attributes

    SGR_INTENSITY_BOLD  = 1     ' Text intensity
    SGR_INTENSITY_FAINT = 2
    SGR_INTENSITY_NML   = 22

    SGR_ITALIC          = 3     ' Can be either Italic or
'    SGR_INVERSE         = 3     '  Inverse, depending on the terminal

    SGR_UNDERLINE       = 4     ' Underlined text
    SGR_UNDERLINE_DBL   = 21
    SGR_UNDERLINE_OFF   = 24

    SGR_BLINKSLOW       = 5     ' Blinking text
    SGR_BLINKFAST       = 6     ' Not supported by all terminals
    SGR_BLINK_OFF       = 25

    SGR_INVERSE         = 7     ' Inverse text, or inverse terminal
    SGR_INVERSE_OFF     = 27

    SGR_CONCEAL         = 8     ' Concealed text
    SGR_REVEAL          = 28

    SGR_STRIKETHRU      = 9     ' Strike-through text
    SGR_STRIKETHRU_OFF  = 29

    SGR_PRI_FONT        = 10    ' Select primary font

    SGR_FGCOLOR_DEF     = 39
    SGR_BGCOLOR_DEF     = 49

    SGR_FRAMED          = 51    '
    SGR_ENCIRCLED       = 52    ' Not supported by many terminals
    SGR_FRAMED_ENC_OFF  = 54    '

    SGR_OVERLINED       = 53    ' Overlined text
    SGR_OVERLINED_OFF   = 55


' Text colors
    FG                  = 30
    BG                  = 40
    BRIGHT              = 60
    BLACK               = 0
    RED                 = 1
    GREEN               = 2
    YELLOW              = 3
    BLUE                = 4
    MAGENTA             = 5
    CYAN                = 6
    WHITE               = 7

' Semi-graphics characters
' Corners:
    LOWRT               = $6a                   ' Lower-right
    UPPRT               = $6b                   ' Upper-right
    UPPLT               = $6c                   ' Upper-left
    LOWLT               = $6d                   ' Lower-left
    CROSS               = $6e                   ' Cross/4-way
' Horizontal and Vertical lines
    HLINE               = $71                   ' H-line
    LVLHSTEM            = $74                   ' Left V-line w/H-stem
    RVLHSTEM            = $75                   ' Right V-line w/H-stem
    BHLVSTEM            = $76                   ' Bottom H-line w/V-stem
    THLVSTEM            = $77                   ' Top H-line w/V-stem
    VLINE               = $78                   ' V-line

PUB BGColor(bcolor)
' Set background color
    CSI
    Char(";")
    Dec(BG + bcolor)
    Char("m")

PUB Blink(mode)
' Set Blink attribute
    SGR(mode)

PUB Bold(mode)
' Set Bold attribute
    SGR(mode)

PUB Box(x0, y0, x1, y1, brd_fg, brd_bg, filled) | inwidth, inheight, inbot, intop, x, y
' Draw a box, using semigraphics characters
'   x0, y0, x1, y1: upper left, lower right coords
'   brd_fg, brd_bg: border foreground, background colors
'   filled: fill box (bool)
    inwidth := x1-x0-1                          ' inside border w, h
    inheight := y1-y0-1
    intop := y0+1                               ' inside border top, bot.
    inbot := y1-1

    case filled
        false:                                  ' not filled:
            bgcolor(brd_bg)
            fgcolor(brd_fg)
            position(x0, y0)                    ' draw top:
            semigfx(true)                       '   enable semigfx mode
            char(UPPLT)                         '   upper-left corner
            repeat inwidth
                char(HLINE)                     '   fill horiz. lines
            char(UPPRT)                         '   upper-right corner

            position(x0, y1)                    ' draw bottom
            char(LOWLT)
            repeat inwidth
                char(HLINE)
            char(LOWRT)

            repeat y from intop to inbot        ' draw left side
                position(x0, y)
                char(VLINE)                     '   v-lines

            repeat y from intop to inbot        ' draw right side
                position(x1, y)
                char(VLINE)
            semigfx(false)                      ' done. turn off semigfx mode

        true:                                   ' filled:
            bgcolor(brd_bg)
            fgcolor(brd_fg)
            position(x0, y0)                    ' set window pos
            semigfx(true)                       ' turn on semigfx mode

            char(UPPLT)                         ' top row:
            repeat inwidth                      '   fill with horiz. lines
                char(HLINE)
            char(UPPRT)

            repeat y from intop to inbot        ' middle rows:
                position(x0, y)                 '   left border
                char(VLINE)                     '   vert. lines
                repeat inwidth
                    char(" ")                   '   fill line with spaces
                char(VLINE)                     '   right border
            newline{}

            char(LOWLT)                         ' bottom row
            repeat inwidth
                char(HLINE)
            char(LOWRT)
            semigfx(false)                      ' done. turn off semigfx mode

PUB Clear

    ClearMode(CLR_ALL_HOME)

PUB ClearLine

    clearlinex(CLR_CUR_TO_END)

PUB ClearLineX(mode)
' Clear line
    CSI
    Dec(mode)
    Char("K")

PUB ClearMode(mode)
' Clear screen
    CSI
    Dec(mode)
    Char("J")
    if mode == 2
        Position (0, 0)

PUB Color(fcolor, bcolor)
' Set foreground and background colors
    CSI
    Dec(fcolor)
    Char(";")
    Dec(bcolor)
    Char("m")

PUB Conceal(mode)
' Set Conceal attribute
    SGR(mode)

PUB CursorPositionReporting(enabled)
' Enable/disable mouse cursor position reporting
    CSI
    case enabled
        FALSE:
            Str(string("?1000;1006;1015l"))
        OTHER:
            Str(string("?1000;1006;1015h"))

PUB CursorNextLine(rows)
' Move cursor to beginning of next row, or 'rows' number of rows down
    CSI
    Dec(rows)
    Char("E")

PUB CursorPrevLine(rows)
' Move cursor to beginning of previous row, or 'rows' number of rows up
    CSI
    Dec(rows)
    Char("F")

PUB Encircle
' Set Encircle attribute
    SGR(SGR_ENCIRCLED)

PUB FGColor(fcolor)
' Set foreground color
    CSI
    Dec(FG + fcolor)
    Char("m")

PUB Framed
' Set framed attribute
    SGR(SGR_FRAMED)

PUB HideCursor
' Hide cursor
    CSI
    Char("?")
    Dec(25)
    Char("l")
    
PUB Home
' Move cursor to home/upper-left position
    Position(0, 0)

PUB Inverse(mode)
' Set inverse attribute
    SGR(mode)

PUB Italic
' Set italicized attribute
    SGR(SGR_ITALIC)

PUB MouseCursorPosition | b, x, y
' Report Current mouse position (press mouse button to update)
'   Returns: Button pressed, X, Y coordinates (packed into long)
'       byte 0: X coordinate
'       byte 1: Y coordinate
'       byte 2: Button pressed/wheel movement:
'           0 - Left
'           1 - Middle
'           2 - Right
'           3 - Released
'           64- Mouse wheel up
'           65- Mouse wheel down
'   NOTE: The position is only updated when a mouse button is pressed or wheel is moved
    if CharIn == ESC
        if CharIn == LBRACKET
            if CharIn == "M"
'               If we made it this far, it's a mouse position event
            else
                return 0
        else
            return 0
    else
        return 0

    b := charin-32                              ' button data = 32+button
    x := charin-33                              ' transform upper-left coords
    y := charin-33                              '   to 0, 0 instead of 1, 1
    result := (b << 16) | (y << 8) | x          ' Pack into the return value

PUB MoveDown(rows)
' Move cursor down 1 or more rows
    CSI
    Dec(rows)
    Char("B")

PUB MoveLeft(columns)
' Move cursor back/left 1 or more columns
    CSI
    Dec(columns)
    Char("D")

PUB MoveRight(columns)
' Move cursor forward/right 1 or more columns
    CSI
    Dec(columns)
    Char("C")

PUB MoveUp(rows)
' Move cursor up 1 or more rows
    CSI
    Dec(rows)
    Char("A")

PUB Overline
' Set Overline attribute
    SGR(SGR_OVERLINED)

PUB Position(x, y)
' Position cursor at column x, row y (from top-left)
    y++                                             ' Need to add 1 because the coords
    x++                                             ' are not 0-based, but 1-based
    CSI
    Dec(y)
    Char(";")
    Dec(x)
    Char("f")

PUB PositionX(column)
' Set horizontal position of cursor
    CSI
    Dec(column+1)
    Char("G")

PUB PositionY(y)                                                                                                 
' Set vertical position of cursor
    y++                                             ' Need to add 1 because the coords
    CSI                                             ' are not 0-based, but 1-based
    Dec(y)
    Char("d")

PUB Reset
' Reset terminal attributes
    CSI
    Char("m")

PUB ScrollDown(lines)
' Scroll display down 1 or more lines
    CSI
    Dec(lines)
    Char("T")

PUB ScrollUp(lines)
' Scroll display up 1 or more lines
    CSI
    Dec(lines)
    Char("S")

PUB SemiGfx(enabled)
' Enable semi-graphics (e.g., line-drawing) mode
    case ||(enabled)
        1:
            str(string(ESC, "(", "0"))
        0:
            str(string(ESC, "(", "B"))

PUB ShowCursor
' Show cursor
    CSI
    Char("?")
    Dec(25)
    Char("h")

PUB Strikethrough(mode)
' Set Strike-through attribute
    SGR(mode)

PUB TextWindow(ptr_titlestr, x, y, w, h, brd_fg, brd_bg, ttl_fg)
' Draw a window with title string and border
'   x, y: upper-left coords of window
'   w, h: window dimensions (_outer_)
'   brd_fg, brd_bg: window border foreground, background colors
'   ttl_fg: title text fg color
    box(x, y, x+w, y+h-1, brd_fg, brd_bg, true)
    bgcolor(brd_bg)
    fgcolor(ttl_fg)

    position(x+2, y)                        ' display window title
    str(ptr_titlestr)

PUB Underline(mode)
' Set Underline attribute
    SGR(mode)

PRI CSI
' Command Sequence Introducer
    Char(ESC)
    Char(LBRACKET)

PRI SGR(mode)
' Select Graphic Rendition
    CSI
    Dec(mode)
    Char("m")

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
