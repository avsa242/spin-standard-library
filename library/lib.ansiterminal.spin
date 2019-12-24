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
    FG_BLACK            = 30
    FG_RED              = 31
    FG_GREEN            = 32
    FG_YELLOW           = 33
    FG_BLUE             = 34
    FG_MAGENTA          = 35
    FG_CYAN             = 36
    FG_WHITE            = 37
    BG_BLACK            = 40
    BG_RED              = 41
    BG_GREEN            = 42
    BG_YELLOW           = 43
    BG_BLUE             = 44
    BG_MAGENTA          = 45
    BG_CYAN             = 46
    BG_WHITE            = 47
    BRIGHT              = 60

PUB BGColor(bcolor)
' Set background color
    CSI
    Char(";")
    Dec(bcolor)
    Char("m")

PUB Blink(mode)
' Set Blink attribute
    SGR(mode)

PUB Bold(mode)
' Set Bold attribute
    SGR(mode)

PUB Clear

    ClearMode(CLR_ALL_HOME)

PUB ClearLine(mode)
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
    Dec(fcolor)
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

PUB MouseCursorPosition | tmp, token, place
' Report Current mouse position (press mouse button to update)
' Read serial
' If ESC, discard + proceed, otherwise, NEXT
'       If LBRACKET, discard + proceed, otherwise, NEXT
'               If "<", discard + proceed, otherwise, NEXT
'                       If isnum, echo to term, NEXT
'                               if ";", echo to term, NEXT
'                                       if "M", quit
    repeat
        tmp := CharIn
        case tmp
            ESC:
                token := 1
            LBRACKET:
                token := 2
            "<":
                token := 3
            "0".."9":
                case token
                    3:  'Mouse button
                        Char(tmp)
                    4:  'X
                        Char(tmp)
                    5:  'Y
                        Char(tmp)
            ";":
                Char(";")
                token++
                place := 0
            "M":
                quit
            OTHER:
    until tmp == "M"

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
    CSI
    Dec(y)
    Char(";")
    Dec(x)
    Char("f")

PUB PositionX(column)
' Set horizontal position of cursor
'   Default value: column 1
    CSI
    Dec(column)
    Char("G")

PUB PositionY(y)                                                                                                 

    CSI
    Char("P")
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

PUB ShowCursor
' Show cursor
    CSI
    Char("?")
    Dec(25)
    Char("h")

PUB Strikethrough(mode)
' Set Strike-through attribute
    SGR(mode)

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
