{
    --------------------------------------------
    Filename: core.con.4dgl-oled.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Jun 1, 2019
    Updated Jun 2, 2019
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This file contains excerpts from the 4DGL OLED driver object
        originally written by Beau Schwabe, oled-128-g2_v2.1.spin
}

CON

    CMD_GFX_BGCOLOR             = $FF6E
    CMD_GFX_CHANGECOLOR         = $FFBE
    CMD_GFX_CIRCLE              = $FFCD
    CMD_GFX_CIRCLEFILLED        = $FFCC
    CMD_GFX_CLIPPING            = $FF6C
    CMD_GFX_CLIPWINDOW          = $FFBF
    CMD_GFX_CLS                 = $FFD7
    CMD_GFX_CONTRAST            = $FF66
    CMD_GFX_FRAMEDELAY          = $FF69
    CMD_GFX_GETPIXEL            = $FFCA
    CMD_GFX_LINE                = $FFD2
    CMD_GFX_LINEPATTERN         = $FF65
    CMD_GFX_LINETO              = $FFD4
    CMD_GFX_MOVETO              = $FFD6
    CMD_GFX_ORBIT               = $0003
    CMD_GFX_OUTLINECOLOR        = $FF67
    CMD_GFX_POLYGON             = $0004
    CMD_GFX_POLYLINE            = $0005
    CMD_GFX_PUTPIXEL            = $FFCB
    CMD_GFX_RECTANGLE           = $FFCF
    CMD_GFX_RECTANGLEFILLED     = $FFCE
    CMD_GFX_SCREENMODE          = $FF68
    CMD_GFX_SET                 = $FFD8
    CMD_GFX_SETCLIPREGION       = $FFBC
    CMD_GFX_TRANSPARENCY        = $FF6A
    CMD_GFX_TRANSPARENCYCOLOR   = $FF6B
    CMD_GFX_TRIANGLE            = $FFC9

    CMD_TXT_ATTRIBUTES          = $FF72
    CMD_TXT_BGCOLOR             = $FF7E
    CMD_TXT_BOLD                = $FF76
    CMD_TXT_FGCOLOR             = $FF7F
    CMD_TXT_FONTID              = $FF7D
    CMD_TXT_HEIGHT              = $FF7B
    CMD_TXT_INVERSE             = $FF74
    CMD_TXT_ITALIC              = $FF75
    CMD_TXT_MOVECURSOR          = $FFE4
    CMD_TXT_OPACITY             = $FF77
    CMD_TXT_SET                 = $FFE3
    CMD_TXT_UNDERLINE           = $FF73
    CMD_TXT_WIDTH               = $FF7C
    CMD_TXT_XGAP                = $FF7A
    CMD_TXT_YGAP                = $FF79

    CMD_MEDIA_FLUSH             = $FFB2
    CMD_MEDIA_IMAGE             = $FFB3
    CMD_MEDIA_INIT              = $FFB1
    CMD_MEDIA_READBYTE          = $FFB7
    CMD_MEDIA_READWORD          = $FFB6
    CMD_MEDIA_SETADD            = $FFB9
    CMD_MEDIA_SETSECTOR         = $FFB8
    CMD_MEDIA_VIDEO             = $FFBB
    CMD_MEDIA_VIDEOFRAME        = $FFBA
    CMD_MEDIA_WRITEBYTE         = $FFB5
    CMD_MEDIA_WRITEWORD         = $FFB4

    _BEEP                       = $FFDA
    _BLITCOMTODISPLAY           = $000A
    _CHARHEIGHT                 = $0001
    _CHARWIDTH                  = $0002
    _JOYSTICK                   = $FFD9
    _PEEKB                      = $FFF6
    _PEEKW                      = $FFF5
    _POKEB                      = $FFF4
    _POKEW                      = $FFF3
    _PUTCH                      = $FFFE
    _PUTSTR                     = $0006
    _SSMODE                     = $000E
    _SSSPEED                    = $000D
    _SSTIMEOUT                  = $000C
    CMD_SYS_GETMODEL            = $0007
    CMD_SYS_GETVERSION          = $0008
    CMD_SYS_GETPMMC             = $0009

    _SETBAUD                    = $000B

PUB Null
'' This is not a top-level object
