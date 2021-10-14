{
    --------------------------------------------
    Filename: display.lcd.ili9341.8bp.spin
    Author: Jesse Burt
    Description: Driver for ILI9341 LCD controllers
    Copyright (c) 2021
    Started Oct 14, 2021
    Updated Oct 14, 2021
    See end of file for terms of use.
    --------------------------------------------
}

' memory usage for a buffered display would vastly exceed what's available
'   on the P1, so hardcode direct-to-display directive:
#define GFX_DIRECT
#include "lib.gfx.bitmap.spin"

CON

    MAX_COLOR       = 65535
    BYTESPERPX      = 2

' Subpixel order
    RGB             = 0
    BGR             = 1

' Character attributes
    DRAWBG          = 1 << 0

OBJ

    time: "time"                                ' timekeeping methods
    core: "core.con.ili9341"                    ' HW-specific constants
    com : "com.parallel-8bit"                   ' 8-bit Parallel I/O engine

VAR

    long _buff_sz
    word _disp_width, _disp_height, _disp_xmax, _disp_ymax
    word _bytesperln
    byte _RESET

    ' shadow registers
    byte _madctl

PUB Startx(DATA_BASEPIN, RES_PIN, CS_PIN, DC_PIN, WR_PIN, RD_PIN, WIDTH, HEIGHT): status
' Start driver using custom I/O settings
'   DATA_BASEPIN: first (lowest) pin of 8 data pin block (must be contiguous)
'   RES_PIN: display's hardware reset pin (optional, -1 to ignore)
'   CS_PIN: Chip Select
'   DC_PIN: Data/Command (sometimes labeled RS, or Register Select)
'   WR_PIN: Write clock
'   RD_PIN: Read clock (not currently implemented; ignored)
'   WIDTH, HEIGHT: display dimensions, in pixels
    if lookdown(DATA_BASEPIN: 0..24) and lookdown(CS_PIN: 0..31) and {
}   lookdown(DC_PIN: 0..31) and lookdown(WR_PIN: 0..31)
        if (status := com.init(DATA_BASEPIN, CS_PIN, DC_PIN, WR_PIN, RD_PIN))
            _RESET := RES_PIN
            _disp_width := WIDTH
            _disp_height := HEIGHT
            _disp_xmax := _disp_width - 1
            _disp_ymax := _disp_height - 1
            _buff_sz := (_disp_width * _disp_height)
            _bytesperln := _disp_width * BYTESPERPX
            reset{}

PUB Preset
' Preset settings
    com.wrbyte_cmd(core#SWRESET)
    time.msleep(5)

    com.wrbyte_cmd(core#DISPOFF)

    com.wrbyte_cmd(core#PWCTR1)
    com.wrbyte_dat($26)

    com.wrbyte_cmd(core#PWCTR2)
    com.wrbyte_dat($11)

    com.wrbyte_cmd(core#VMCTR1)
    com.wrbyte_dat($5c)
    com.wrbyte_dat($4c)

    com.wrbyte_cmd(core#VMCTR2)
    com.wrbyte_dat($94)

    com.wrbyte_cmd(core#MADCTL)
'    com.wrbyte_dat(%0010_11_00)
'    com.wrbyte_dat(%0010_11_00)
    com.wrbyte_dat($48)

    com.wrbyte_cmd(core#PIXFMT) 'OK
    com.wrbyte_dat($55)

    com.wrbyte_cmd(core#FRMCTR1)
    com.wrbyte_dat($00)
    com.wrbyte_dat($1B)

    com.wrbyte_cmd($f2) ' 3Gamma Function Disable
    com.wrbyte_dat($08)
    com.wrbyte_cmd(core#GAMMASET)
    com.wrbyte_dat($01) ' gamma set 4 gamma curve 01/02/04/08
    com.wrbyte_cmd(core#GMCTRP1) 'positive gamma correction
    com.wrbyte_dat($1f)
    com.wrbyte_dat($1a)
    com.wrbyte_dat($18)
    com.wrbyte_dat($0a)
    com.wrbyte_dat($0f)
    com.wrbyte_dat($06)
    com.wrbyte_dat($45)
    com.wrbyte_dat($87)
    com.wrbyte_dat($32)
    com.wrbyte_dat($0a)
    com.wrbyte_dat($07)
    com.wrbyte_dat($02)
    com.wrbyte_dat($07)
    com.wrbyte_dat($05)
    com.wrbyte_dat($00)
    com.wrbyte_cmd(core#GMCTRN1) 'negamma correction
    com.wrbyte_dat($00)
    com.wrbyte_dat($25)
    com.wrbyte_dat($27)
    com.wrbyte_dat($05)
    com.wrbyte_dat($10)
    com.wrbyte_dat($09)
    com.wrbyte_dat($3a)
    com.wrbyte_dat($78)
    com.wrbyte_dat($4d)
    com.wrbyte_dat($05)
    com.wrbyte_dat($18)
    com.wrbyte_dat($0d)
    com.wrbyte_dat($38)
    com.wrbyte_dat($3a)
    com.wrbyte_dat($1f)

'--------------ddram ---------------------
    com.wrbyte_cmd(core#CASET) ' column set
    com.wrbyte_dat($00)
    com.wrbyte_dat($00)
    com.wrbyte_dat($00)
    com.wrbyte_dat($EF)
    com.wrbyte_cmd(core#PASET) ' page address set
    com.wrbyte_dat($00)
    com.wrbyte_dat($00)
    com.wrbyte_dat($01)
    com.wrbyte_dat($3F)
    ' com.wrbyte_cmd($34) ' tearing effect off
    'com.wrbyte_cmd($35) ' tearing effect on
    'com.wrbyte_cmd($b4) ' display inversion
    'com.wrbyte_dat($00)
    com.wrbyte_cmd(core#ENTRYMODE) 'entry mode set
    com.wrbyte_dat($07)

'-----------------display---------------------
    com.wrbyte_cmd(core#DFUNCTR) ' display function control
    com.wrbyte_dat($0a)
    com.wrbyte_dat($82)
    com.wrbyte_dat($27)
    com.wrbyte_dat($00)
    com.wrbyte_cmd(core#SLPOUT) 'sleep out
    time.msleep(100)
    com.wrbyte_cmd(core#DISPON) ' display on
    time.msleep(100)
    com.wrbyte_cmd(core#RAMWR) 'memory write
    time.msleep(200)

PUB Stop{}
' Power off the display, and stop the engine
    powered(false)
    com.deinit{}

PUB Box(x1, y1, x2, y2, color, filled) | xt, yt
' Draw a box from (x1, y1) to (x2, y2) in color, optionally filled
    xt := ||(x2-x1)+1
    yt := ||(y2-y1)+1
    if filled
        displaybounds(x1, y1, x2, y2)
        com.wrbyte_cmd(core#RAMWR)
        com.wrwordx_dat(color, (yt * xt))
    else
        displaybounds(x1, y1, x2, y1)           ' top
        com.wrbyte_cmd(core#RAMWR)
        com.wrwordx_dat(color, xt)

        displaybounds(x1, y2, x2, y2)           ' bottom
        com.wrbyte_cmd(core#RAMWR)
        com.wrwordx_dat(color, xt)

        displaybounds(x1, y1, x1, y2)           ' left
        com.wrbyte_cmd(core#RAMWR)
        com.wrwordx_dat(color, yt)

        displaybounds(x2, y1, x2, y2)           ' right
        com.wrbyte_cmd(core#RAMWR)
        com.wrwordx_dat(color, yt)

PUB Char(ch) | gl_c, gl_r, lastgl_c, lastgl_r
' Draw character from currently loaded font
    lastgl_c := _font_width-1
    lastgl_r := _font_height-1
    case ch
        CR:
            _charpx_x := 0
        LF:
            _charpx_y += _charcell_h
            if _charpx_y > _charpx_xmax
                _charpx_y := 0
        0..127:                                 ' validate ASCII code
            ' walk through font glyph data
            repeat gl_c from 0 to lastgl_c      ' column
                repeat gl_r from 0 to lastgl_r  ' row
                    ' if the current offset in the glyph is a set bit, draw it
                    if byte[_font_addr][(ch << 3) + gl_c] & (|< gl_r)
                        plot((_charpx_x + gl_c), (_charpx_y + gl_r), _fgcolor)
                    else
                    ' otherwise, draw the background color, if enabled
                        if _char_attrs & DRAWBG
                            plot((_charpx_x + gl_c), (_charpx_y + gl_r), _bgcolor)
            ' move the cursor to the next column, wrapping around to the left,
            ' and wrap around to the top of the display if the bottom is reached
            _charpx_x += _charcell_w
            if _charpx_x > _charpx_xmax
                _charpx_x := 0
                _charpx_y += _charcell_h
            if _charpx_y > _charpx_ymax
                _charpx_y := 0
        other:
            return

PUB Clear{}
' Clear display
    displaybounds(0, 0, _disp_xmax, _disp_ymax)
    com.wrbyte_cmd(core#RAMWR)
    com.wrwordx_dat(_bgcolor, _buff_sz)

PUB Contrast(c)

PUB DisplayBounds(x1, y1, x2, y2) | x, y, cmd_pkt[2]
' Set drawing area for subsequent drawing command(s)
    if x2 < x1                                  ' x2 must be greater than x1
        x := x2                                 ' if it isn't, swap them
        x2 := x1
        x1 := x
    if y2 < y1                                  ' same as above, for y2, y1
        y := y2
        y2 := y1
        y1 := y

    cmd_pkt.byte[0] := x1.byte[1]
    cmd_pkt.byte[1] := x1.byte[0]
    cmd_pkt.byte[2] := x2.byte[1]
    cmd_pkt.byte[3] := x2.byte[0]
    cmd_pkt.byte[4] := y1.byte[1]
    cmd_pkt.byte[5] := y1.byte[0]
    cmd_pkt.byte[6] := y2.byte[1]
    cmd_pkt.byte[7] := y2.byte[0]

    com.wrbyte_cmd(core#CASET)
    com.wrblock_dat(@cmd_pkt.byte[0], 4)

    com.wrbyte_cmd(core#PASET)
    com.wrblock_dat(@cmd_pkt.byte[4], 4)

PUB DisplayInverted(state)
' Invert display colors
'   Valid values:
'       TRUE (-1 or 1), FALSE (0)
'   Any other value is ignored
    case ||(state)
        0, 1:
            com.wrbyte_cmd(core#INVOFF + ||(state))

PUB DisplayRotate(state): curr_state
' Rotate display
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    curr_state := _madctl
    case ||(state)
        0, 1:
            state := ||(state) << core#MV
        other:
            return (((curr_state >> core#MV) & 1) == 1)

    _madctl := ((curr_state & core#MV_MASK) | state)
    com.wrbyte_cmd(core#MADCTL)
    com.wrbyte_dat(_madctl)

PUB Line(x1, y1, x2, y2, color) | sx, sy, ddx, ddy, err, e2
' Draw line from (x1, y1) to (x2, y2), in color
    if (x1 == x2)
        displaybounds(x1, y1, x1, y2)           ' vertical
        com.wrbyte_cmd(core#RAMWR)
        com.wrwordx_dat(color, (||(y2-y1))+1)
        return
    if (y1 == y2)
        displaybounds(x1, y1, x2, y1)           ' horizontal
        com.wrbyte_cmd(core#RAMWR)
        com.wrwordx_dat(color, (||(x2-x1))+1)
        return

    ddx := ||(x2-x1)
    ddy := ||(y2-y1)
    err := ddx-ddy

    sx := -1
    if (x1 < x2)
        sx := 1

    sy := -1
    if (y1 < y2)
        sy := 1

    repeat until ((x1 == x2) and (y1 == y2))
        plot(x1, y1, color)
        e2 := err << 1

        if e2 > -ddy
            err -= ddy
            x1 += sx

        if e2 < ddx
            err += ddx
            y1 += sy

PUB MirrorH(state): curr_state
' Mirror display, horizontally
'   Valid values:
'       TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current (cached) setting
    curr_state := _madctl
    case ||(state)
        0, 1:
            state := (||(state) ^ 1) << core#MX
        other:
            return ((((curr_state >> core#MX) & 1) == 1) ^ 1)

    _madctl := ((curr_state & core#MX_MASK) | state)
    com.wrbyte_cmd(core#MADCTL)
    com.wrbyte_dat(_madctl)

PUB MirrorV(state): curr_state
' Mirror display, vertically
'   Valid values:
'       TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current (cached) setting
    curr_state := _madctl
    case ||(state)
        0, 1:
            state := ||(state) << core#MY
        other:
            return (((curr_state >> core#MY) & 1) == 1)

    _madctl := ((curr_state & core#MY_MASK) | state)
    com.wrbyte_cmd(core#MADCTL)
    com.wrbyte_dat(_madctl)

PUB Plot(x, y, color) | cmd_pkt[3]
' Draw a pixel at (x, y), in color
    cmd_pkt.byte[0] := x.byte[1]                ' set x start and end
    cmd_pkt.byte[1] := x.byte[0]                '   params to the same
    cmd_pkt.byte[2] := x.byte[1]
    cmd_pkt.byte[3] := x.byte[0]

    cmd_pkt.byte[4] := y.byte[1]                ' set y start and end
    cmd_pkt.byte[5] := y.byte[0]                '   params to the same
    cmd_pkt.byte[6] := y.byte[1]
    cmd_pkt.byte[7] := y.byte[0]

    cmd_pkt.byte[8] := color.byte[1]
    cmd_pkt.byte[9] := color.byte[0]

    com.wrbyte_cmd(core#CASET)
    com.wrblock_dat(@cmd_pkt.byte[0], 4)
    com.wrbyte_cmd(core#PASET)
    com.wrblock_dat(@cmd_pkt.byte[4], 4)
    com.wrbyte_cmd(core#RAMWR)
    com.wrblock_dat(@cmd_pkt.byte[8], 2)

PUB Powered(state)
' Enable display power
'   Valid values:
'       TRUE (-1 or 1), FALSE (0)
    case ||(state)
        0:
            com.wrbyte_cmd(core#DISPOFF)
            com.wrbyte_cmd(core#SLPIN)
        1:
            com.wrbyte_cmd(core#SLPOUT)
            time.msleep(60)
            com.wrbyte_cmd(core#DISPON)

PUB Reset{}
' Reset the display controller
    if lookdown(_RESET: 0..31)                  ' perform hard reset, if
        dira[_RESET] := 1                       '   I/O pin is defined
        outa[_RESET] := 1
        time.msleep(1)
        outa[_RESET] := 0
        time.msleep(10)
        outa[_RESET] := 1
        time.msleep(120)
    else                                        ' if not, just soft-reset
        com.wrbyte_cmd(core#SWRESET)
        time.msleep(5)

PUB SubpixelOrder(order): curr_ord
' Set subpixel color order
'   Valid values:
'       RGB (0): Red-Green-Blue order
'       BGR (1): Blue-Green-Red order
'   Any other value returns the current (cached) setting
    curr_ord := _madctl
    case order
        RGB, BGR:
            order <<= core#BGR
        other:
            return ((curr_ord >> core#BGR) & 1)

    _madctl := ((curr_ord & core#BGR_MASK) | order)
    com.wrbyte_cmd(core#MADCTL)
    com.wrbyte_dat(_madctl)

PUB Update
' Dummy method

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
