{
    --------------------------------------------
    Filename: display.oled.ssd1331.spi.spin
    Author: Jesse Burt
    Description: Driver for Solomon Systech SSD1331 RGB OLED displays
    Copyright (c) 2019
    Started: Nov 18, 2018
    Updated: Aug 15, 2019
    See end of file for terms of use.
    --------------------------------------------
}
CON

' Transaction type selection
    TRANS_CMD   = 0
    TRANS_DATA  = 1

' Display on/off modes
    DISP_OFF    = 0
    DISP_ON     = 1
    DISP_ON_DIM = 2

' Color depth formats
    COLOR_256   = %00
    COLOR_65K   = %01
    COLOR_65K2  = %10

' Address increment mode
    ADDR_HORIZ  = 0
    ADDR_VERT   = 1

' Subpixel order
    SUBPIX_RGB  = 0
    SUBPIX_BGR  = 1

OBJ

    core    : "core.con.ssd1331"
    time    : "time"
    spi     : "com.spi.fast"

VAR

    long _DC, _RES
'    byte _shadow_reg[67]
    byte _sh_SETCOLUMN, _sh_SETROW, _sh_SETCONTRAST_A, _sh_SETCONTRAST_B, _sh_SETCONTRAST_C
    byte _sh_MASTERCCTRL, _sh_SECPRECHG[3], _sh_REMAPCOLOR, _sh_DISPSTARTLINE, _sh_DISPOFFSET
    byte _sh_DISPMODE, _sh_MULTIPLEX, _sh_DIM, _sh_MASTERCFG, _sh_DISPONOFF, _sh_POWERSAVE
    byte _sh_PHASE12PER, _sh_CLK, _sh_GRAYTABLE, _sh_PRECHGLEV, _sh_VCOMH, _sh_CMDLOCK
    byte _sh_HVSCROLL, _sh_FILL

PUB Start (CS_PIN, DC_PIN, DIN_PIN, CLK_PIN, RES_PIN): okay

    if lookdown(CS_PIN: 0..31)
        if lookdown(DC_PIN: 0..31)
            if lookdown(DIN_PIN: 0..31)
                if lookdown(CLK_PIN: 0..31)
                    if lookdown(RES_PIN: 0..31)
                        if okay := spi.start (CS_PIN, CLK_PIN, DIN_PIN, -1)
                            _DC := DC_PIN
                            _RES := RES_PIN
                            dira[_DC] := 1
                            dira[_RES] := 1
                            Reset
                            return okay
    return FALSE

PUB Stop

    AllPixelsOff
    DisplayEnabled (FALSE)
    spi.stop

PUB Defaults

    ColorDepth (COLOR_65K)
    MirrorH (FALSE)
    DisplayEnabled (FALSE)
    AllPixelsOff
    StartLine (0)
    VertOffset (0)
    DispInverted (FALSE)
    DisplayLines (64)
    ExtSupply
    PowerSaving (TRUE)
    Phase1Adj (7)
    Phase2Adj (4)
    ClockFreq ($D)
    ClockDiv (1)
    PrechargeSpeed (127, 127, 127)
    PrechargeLevel (500)
    VCOMHDeselect (830)
    CurrentLimit (16)
    ContrastA (127)
    ContrastB (127)
    ContrastC (127)
    DisplayEnabled (DISP_ON)
    DisplayBounds (0, 0, 95, 63)
    Clear

PUB AddrIncMode(mode) | tmp

    tmp := _sh_REMAPCOLOR
    case mode
        ADDR_HORIZ, ADDR_VERT:
        OTHER:
            return (tmp >> core#FLD_ADDRINC) & %1

    _sh_REMAPCOLOR &= core#MASK_SEGREMAP
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | mode) & core#SSD1331_CMD_SETREMAP_MASK
    tmp.byte[0] := core#SSD1331_CMD_SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writeRegX (TRANS_CMD, 2, @tmp)

PUB AllPixelsOn | tmp

    _sh_DISPMODE := core#SSD1331_CMD_DISPLAYALLON
    tmp := _sh_DISPMODE
    writeRegX (TRANS_CMD, 1, @tmp)

PUB AllPixelsOff | tmp

    _sh_DISPMODE := core#SSD1331_CMD_DISPLAYALLOFF
    tmp := _sh_DISPMODE
    writeRegX (TRANS_CMD, 1, @tmp)

PUB Bitmap(buf_addr, nr_bytes) | tmp[2]

'    NoOp
'    NoOp
    DisplayBounds (0, 0, 95, 63)
'    StartLine (0)
'    VertOffset (0)
    writeRegX (TRANS_DATA, nr_bytes, buf_addr)

PUB Box(sx, sy, ex, ey, box_rgb, fill_rgb) | tmp[3]

    case sx
        0..95:
        OTHER:
            return

    case sy
        0..63:
        OTHER:
            return

    case ex
        0..95:
        OTHER:
            return

    case ey
        0..63:
        OTHER:
            return

    tmp.byte[0] := core#SSD1331_CMD_DRAWRECT
    tmp.byte[1] := sx
    tmp.byte[2] := sy
    tmp.byte[3] := ex
    tmp.byte[4] := ey
    tmp.byte[5] := Color_R (box_rgb)
    tmp.byte[6] := Color_G (box_rgb)
    tmp.byte[7] := Color_B (box_rgb)
    tmp.byte[8] := Color_R (fill_rgb)
    tmp.byte[9] := Color_G (fill_rgb)
    tmp.byte[10] := Color_B (fill_rgb)
    writeRegX (TRANS_CMD, 11, @tmp)

PUB Clear | tmp[2]

    tmp.byte[0] := core#SSD1331_CMD_NOP3
    tmp.byte[1] := core#SSD1331_CMD_CLEAR
    tmp.byte[2] := 0
    tmp.byte[3] := 0
    tmp.byte[4] := 95
    tmp.byte[5] := 63
    writeRegX (TRANS_CMD, 6, @tmp)

PUB ClockDiv(divider) | tmp

    tmp := _sh_CLK
    case divider
        1..16:
            divider -= 1
        OTHER:
            return (tmp & core#BITS_CLKDIV) + 1

    _sh_CLK &= core#MASK_CLKDIV
    _sh_CLK := _sh_CLK | divider
    tmp.byte[0] := core#SSD1331_CMD_CLOCKDIV
    tmp.byte[1] := divider
    writeRegX (TRANS_CMD, 2, @tmp)

PUB ClockFreq(freq) | tmp

    tmp := _sh_CLK
    case freq
        0..15:
            freq <<= core#FLD_FOSCFREQ
        OTHER:
            return (tmp >> core#FLD_FOSCFREQ) & core#BITS_FOSCFREQ

    _sh_CLK &= core#MASK_FOSCFREQ
    _sh_CLK := _sh_CLK | freq
    tmp.byte[0] := core#SSD1331_CMD_CLOCKDIV
    tmp.byte[1] := freq
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Color_R(rgb888)

    return (((rgb888 & $F800) >> 11) * 527 + 23 ) >> 6

PUB Color_G(rgb888)

    return (((rgb888 & $7E0) >> 5)  * 259 + 33 ) >> 6

PUB Color_B(rgb888)

    return ((rgb888 & $1F) * 527 + 23 ) >> 6

PUB ColorDepth(format) | tmp

    tmp := _sh_REMAPCOLOR
    case format
        COLOR_256, COLOR_65K, COLOR_65K2:
            format <<= core#FLD_COLORFORMAT
        OTHER:
            return tmp >> core#FLD_COLORFORMAT

    _sh_REMAPCOLOR &= core#MASK_COLORFORMAT
    _sh_REMAPCOLOR := _sh_REMAPCOLOR | format

    tmp.byte[0] := core#SSD1331_CMD_SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR

    writeRegX (TRANS_CMD, 2, @tmp)

PUB Contrast(level)

    ContrastA (level)
    ContrastB (level)
    ContrastC (level)

PUB ContrastA(level) | tmp

    tmp := _sh_SETCONTRAST_A
    case level
        0..255:
        OTHER:
            return tmp

    _sh_SETCONTRAST_A := level
    tmp.byte[0] := core#SSD1331_CMD_CONTRASTA
    tmp.byte[1] := level
    writeRegX (TRANS_CMD, 2, @tmp)

PUB ContrastB(level) | tmp

    tmp := _sh_SETCONTRAST_B
    case level
        0..255:
        OTHER:
            return tmp

    _sh_SETCONTRAST_B := level
    tmp.byte[0] := core#SSD1331_CMD_CONTRASTB
    tmp.byte[1] := level
    writeRegX (TRANS_CMD, 2, @tmp)

PUB ContrastC(level) | tmp

    tmp := _sh_SETCONTRAST_C
    case level
        0..255:
        OTHER:
            return tmp

    _sh_SETCONTRAST_C := level
    tmp.byte[0] := core#SSD1331_CMD_CONTRASTC
    tmp.byte[1] := level
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Copy(sx, sy, ex, ey, dx, dy) | tmp[2]

    case sx
        0..95:
        OTHER:
            return

    case sy
        0..63:
        OTHER:
            return

    case ex
        0..95:
        OTHER:
            return

    case ey
        0..63:
        OTHER:
            return

    case dx
        0..95:
        OTHER:
            return

    case dy
        0..63:
        OTHER:
            return

    tmp.byte[0] := core#SSD1331_CMD_COPY
    tmp.byte[1] := sx
    tmp.byte[2] := sy
    tmp.byte[3] := ex
    tmp.byte[4] := ey
    tmp.byte[5] := dx
    tmp.byte[6] := dy
    writeRegX (TRANS_CMD, 7, @tmp)


PUB CurrentLimit(divisor) | tmp

    tmp := _sh_MASTERCCTRL
    case divisor
        1..16:
            divisor -= 1
        OTHER:
            return tmp + 1

    _sh_MASTERCCTRL := divisor
    tmp.byte[0] := core#SSD1331_CMD_MASTERCURRENT
    tmp.byte[1] := divisor
    writeRegX (TRANS_CMD, 2, @tmp)

PUB DisplayBounds(sx, sy, ex, ey) | tmp[2]

    ifnot lookup(sx: 0..95) or lookup(sy: 0..63) or lookup(ex: 0..95) or lookup(ey: 0..63)
        return

    tmp.byte[0] := core#SSD1331_CMD_SETCOLUMN
    tmp.byte[1] := sx
    tmp.byte[2] := ex

    writeRegX (TRANS_CMD, 3, @tmp)

    tmp.byte[0] := core#SSD1331_CMD_SETROW
    tmp.byte[1] := sy
    tmp.byte[2] := ey

    writeRegX (TRANS_CMD, 3, @tmp)

PUB DisplayEnabled(enabled) | tmp

    tmp := _sh_DISPONOFF
    case ||enabled
        DISP_OFF, DISP_ON, DISP_ON_DIM:
            enabled := lookupz(enabled: core#SSD1331_CMD_DISPLAYOFF, core#SSD1331_CMD_DISPLAYON, core#SSD1331_CMD_DISPLAYONDIM)
        OTHER:
            return lookdownz(tmp: core#SSD1331_CMD_DISPLAYOFF, core#SSD1331_CMD_DISPLAYON, core#SSD1331_CMD_DISPLAYONDIM)

    _sh_DISPONOFF := enabled
    writeRegX (TRANS_CMD, 1, @_sh_DISPONOFF)

PUB DisplayLines(lines) | tmp

    tmp := _sh_MULTIPLEX
    case lines
        16..64:
            lines -= 1
        OTHER:
            return tmp + 1

    _sh_MULTIPLEX := lines
    tmp.byte[0] := core#SSD1331_CMD_SETMULTIPLEX
    tmp.byte[1] := lines
    writeRegX (TRANS_CMD, 2, @tmp)

PUB DispInverted(enabled) | tmp

    tmp := _sh_DISPMODE
    case ||enabled
        0, 1:
            enabled := lookupz(||enabled: core#SSD1331_CMD_NORMALDISPLAY, core#SSD1331_CMD_INVERTDISPLAY)
        OTHER:
            result := lookdownz(tmp: core#SSD1331_CMD_NORMALDISPLAY, core#SSD1331_CMD_INVERTDISPLAY)
            return (result & %1) * TRUE

    _sh_DISPMODE := enabled
    tmp := _sh_DISPMODE
    writeRegX (TRANS_CMD, 1, @tmp)

PUB ExtSupply | tmp

    tmp.byte[0] := core#SSD1331_CMD_SETMASTER
    tmp.byte[1] := core#MASTERCFG_EXT_VCC
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Fill(enabled) | tmp

    tmp := _sh_FILL
    case ||enabled
        0, 1:
            enabled := ||enabled & %1
        OTHER:
            return (tmp & %1) * TRUE

    _sh_FILL &= core#MASK_FILL
    _sh_FILL := (_sh_FILL | enabled) & core#SSD1331_CMD_FILL_MASK
    tmp.byte[0] := core#SSD1331_CMD_FILL
    tmp.byte[1] := _sh_FILL
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Interlaced(enabled) | tmp

    tmp := _sh_REMAPCOLOR
    case ||enabled
        0, 1:
            enabled := (not ||enabled) << core#FLD_COMSPLIT
        OTHER:
            return not (((tmp >> core#FLD_COMSPLIT) & %1) * TRUE)

    _sh_REMAPCOLOR &= core#MASK_COMSPLIT
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SSD1331_CMD_SETREMAP_MASK
    tmp.byte[0] := core#SSD1331_CMD_SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Line(sx, sy, ex, ey, rgb) | tmp[2]

    case sx
        0..95:
        OTHER:
            return

    case sy
        0..63:
        OTHER:
            return

    case ex
        0..95:
        OTHER:
            return

    case ey
        0..63:
        OTHER:
            return

    tmp.byte[0] := core#SSD1331_CMD_DRAWLINE
    tmp.byte[1] := sx
    tmp.byte[2] := sy
    tmp.byte[3] := ex
    tmp.byte[4] := ey
    tmp.byte[5] := Color_R (rgb)
    tmp.byte[6] := Color_G (rgb)
    tmp.byte[7] := Color_B (rgb)
    writeRegX (TRANS_CMD, 8, @tmp)

PUB MirrorH(enabled) | tmp

    tmp := _sh_REMAPCOLOR
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_SEGREMAP
        OTHER:
            return ((tmp >> core#FLD_SEGREMAP) & %1) * TRUE

    _sh_REMAPCOLOR &= core#MASK_SEGREMAP
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SSD1331_CMD_SETREMAP_MASK
    tmp.byte[0] := core#SSD1331_CMD_SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writeRegX (TRANS_CMD, 2, @tmp)

PUB MirrorV(enabled) | tmp

    tmp := _sh_REMAPCOLOR
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_COMREMAP
        OTHER:
            return ((tmp >> core#FLD_COMREMAP) & %1) * TRUE

    _sh_REMAPCOLOR &= core#MASK_COMREMAP
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SSD1331_CMD_SETREMAP_MASK
    tmp.byte[0] := core#SSD1331_CMD_SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writeRegX (TRANS_CMD, 2, @tmp)

PUB NoOp | tmp

    tmp := core#SSD1331_CMD_NOP3
    writeRegX (TRANS_CMD, 1, @tmp)

PUB Phase1Adj(clks) | tmp

    tmp := _sh_PHASE12PER
    case clks
        1..15:
        OTHER:
            return tmp & core#BITS_PHASE1

    _sh_PHASE12PER &= core#MASK_PHASE1
    _sh_PHASE12PER := (_sh_PHASE12PER | clks)
    tmp.byte[0] := core#SSD1331_CMD_PRECHARGE
    tmp.byte[1] := _sh_PHASE12PER
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Phase2Adj(clks) | tmp

    tmp := _sh_PHASE12PER
    case clks
        1..15:
            clks <<= core#FLD_PHASE2
        OTHER:
            return (tmp >> core#FLD_PHASE2) & core#BITS_PHASE2

    _sh_PHASE12PER &= core#MASK_PHASE2
    _sh_PHASE12PER := (_sh_PHASE12PER | clks)
    tmp.byte[0] := core#SSD1331_CMD_PRECHARGE
    tmp.byte[1] := _sh_PHASE12PER
    writeRegX (TRANS_CMD, 2, @tmp)

PUB PlotXY(x, y, rgb) | tmp[2]

    tmp.byte[0] := core#SSD1331_CMD_SETCOLUMN
    tmp.byte[1] := x
    tmp.byte[2] := 95
    tmp.byte[3] := core#SSD1331_CMD_SETROW
    tmp.byte[4] := y
    tmp.byte[5] := 63
    
    writeRegX (TRANS_CMD, 6, @tmp)

    time.USleep (3)

    writeRegX (TRANS_DATA, 2, @rgb)

PUB PowerSaving(enabled) | tmp

    tmp := _sh_POWERSAVE
    case ||enabled
        0, 1:
            enabled := lookupz(||enabled: core#POWERMODE_POWERSAVE_DIS, core#POWERMODE_POWERSAVE_ENA)
        OTHER:
            return (lookdownz(_sh_POWERSAVE: core#POWERMODE_POWERSAVE_DIS, core#POWERMODE_POWERSAVE_ENA) & %1) * TRUE

    _sh_POWERSAVE := enabled
    tmp.byte[0] := core#SSD1331_CMD_POWERMODE
    tmp.byte[1] := enabled
    writeRegX (TRANS_CMD, 2, @tmp)

PUB PrechargeLevel(mV) | tmp

    tmp := _sh_PRECHGLEV
    case mV := lookdown(mv: 100, 110, 130, 140, 150, 170, 180, 190, 200, 220, 230, 240, 260, 270, 280, 300, 310, 320, 330, 350, 360, 370, 390, 400, 410, 430, 440, 450, 460, 480, 490, 500)
        1..32:
            mV := (mV - 1) << 1
        OTHER:
            result := (tmp >> 1)
            return lookupz(result: 100, 110, 130, 140, 150, 170, 180, 190, 200, 220, 230, 240, 260, 270, 280, 300, 310, 320, 330, 350, 360, 370, 390, 400, 410, 430, 440, 450, 460, 480, 490, 500)

    _sh_PRECHGLEV := mV
    tmp.byte[0] := core#SSD1331_CMD_PRECHARGELEVEL
    tmp.byte[1] := mV
    writeRegX (TRANS_CMD, 2, @tmp)

PUB PrechargeSpeed(seg_a, seg_b, seg_c) | tmp[2]

    case seg_a
        $00..$FF:
        OTHER:
            return _sh_SECPRECHG.byte[0]
    case seg_b
        $00..$FF:
        OTHER:
            return _sh_SECPRECHG.byte[1]
    case seg_c
        $00..$FF:
        OTHER:
            return _sh_SECPRECHG.byte[2]

    _sh_SECPRECHG[0] := seg_a
    _sh_SECPRECHG[1] := seg_b
    _sh_SECPRECHG[2] := seg_c

    tmp.byte[0] := core#SSD1331_CMD_PRECHARGEA
    tmp.byte[1] := seg_a
    tmp.byte[2] := core#SSD1331_CMD_PRECHARGEB
    tmp.byte[3] := seg_b
    tmp.byte[4] := core#SSD1331_CMD_PRECHARGEC
    tmp.byte[5] := seg_c
    writeRegX (TRANS_CMD, 6, @tmp)

PUB ReverseCopy(enabled) | tmp

    tmp := _sh_FILL
    case ||enabled
        0, 1:
            enabled := (||enabled << core#FLD_REVCOPY)
        OTHER:
            return ((tmp >> core#FLD_REVCOPY) & %1) * TRUE

    _sh_FILL &= core#MASK_REVCOPY
    _sh_FILL := (_sh_FILL | enabled) & core#SSD1331_CMD_FILL_MASK
    tmp.byte[0] := core#SSD1331_CMD_FILL
    tmp.byte[1] := _sh_FILL
    writeRegX (TRANS_CMD, 2, @tmp)

PUB StartLine(disp_line) | tmp

    tmp := _sh_DISPSTARTLINE
    case disp_line
        0..63:
        OTHER:
            return tmp

    _sh_DISPSTARTLINE := disp_line
    tmp.byte[0] := core#SSD1331_CMD_STARTLINE
    tmp.byte[1] := disp_line
    writeRegX (TRANS_CMD, 2, @tmp)

PUB SubpixelOrder(order) | tmp

    tmp := _sh_REMAPCOLOR
    case order
        SUBPIX_RGB, SUBPIX_BGR:
            order <<= core#FLD_SUBPIX_ORDER
        OTHER:
            return (tmp >> core#FLD_SUBPIX_ORDER) & %1

    _sh_REMAPCOLOR &= core#MASK_SUBPIX_ORDER
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | order) & core#SSD1331_CMD_SETREMAP_MASK
    tmp.byte[0] := core#SSD1331_CMD_SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writeRegX (TRANS_CMD, 2, @tmp)

PUB VCOMHDeselect(mV) | tmp

    tmp := _sh_VCOMH
    case mV := lookdown(mv: 440, 520, 610, 710, 830)
        1..5:
            mV := lookup(mV: $00, $10, $20, $30, $3E)
        OTHER:
            result := lookdown(tmp: $00, $10, $20, $30, $3E)
            return lookup(result: 440, 520, 610, 710, 830)

    _sh_VCOMH := mV
    tmp.byte[0] := core#SSD1331_CMD_VCOMH
    tmp.byte[1] := mV
    writeRegX (TRANS_CMD, 2, @tmp)

PUB VertAltScan(enabled) | tmp

    tmp := _sh_REMAPCOLOR
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_COMLR_SWAP
        OTHER:
            return ((tmp >> core#FLD_COMLR_SWAP) & %1) * TRUE

    _sh_REMAPCOLOR &= core#MASK_COMLR_SWAP
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SSD1331_CMD_SETREMAP_MASK
    tmp.byte[0] := core#SSD1331_CMD_SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writeRegX (TRANS_CMD, 2, @tmp)

PUB VertOffset(disp_line) | tmp

    tmp := _sh_DISPOFFSET
    case disp_line
        0..63:
        OTHER:
            return tmp

    _sh_DISPOFFSET := disp_line
    tmp.byte[0] := core#SSD1331_CMD_DISPLAYOFFSET
    tmp.byte[1] := disp_line
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Reset

    outa[_RES] := 1
    time.MSleep (1)
    outa[_RES] := 0
    time.MSleep (10)
    outa[_RES] := 1

PUB writeRegX(trans_type, nr_bytes, buf_addr)

    case trans_type
        TRANS_DATA:
            outa[_DC] := 1
        TRANS_CMD:
            outa[_DC] := 0

        OTHER:
            return

    spi.write (TRUE, buf_addr, nr_bytes) ' Write SPI transaction with blocking enabled


{PRI POR
'shadow reg binary blob: array of bytes set during startup
'api-level methods use symbolic names in read/writeRegX
'low-level methods use lookup/lookdown table to find that reg in array
'core.con file uses std masks, fields, bits
'   _shadow_reg.byte[0] := $00
'   _shadow_reg.byte[1] := $5F
'   _shadow_reg.byte[1] := $00
'   _shadow_reg.byte[1] := $3F
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $5F
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $3F
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $0F
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $40
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $A4
    _shadow_reg.byte[0] := $3F
    _shadow_reg.byte[0] := $00 '$AB - A
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $0F '$AB - E
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $00
 }   
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
