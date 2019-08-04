{
    --------------------------------------------
    Filename: display.oled.ssd1306.i2c.spin
    Description: Driver for Solomon Systech SSD1306 I2C OLED display drivers
    Author: Jesse Burt
    Copyright (c) 2018
    Created: Apr 26, 2018
    Updated: Mar 12, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 400_000

OBJ

    core    : "core.con.ssd1306"
    time    : "time"
    i2c     : "com.i2c"
    font    : "font.5x8.spin"

VAR

    long _draw_buffer
    byte _disp_width, _disp_height
    word _buffsz
    byte _sa0

PUB Null
' This is not a top-level object

PUB Start(width, height): okay
' Default to "standard" Propeller I2C pins and 400kHz
    okay := Startx (width, height, DEF_SCL, DEF_SDA, DEF_HZ, 0)

PUB Startx(width, height, SCL_PIN, SDA_PIN, I2C_HZ, SLAVE_LSB): okay
' Start the driver with custom settings
' Startx with SLAVE_LSB set to 0 for default slave address or 1 for alternate
    _sa0 := ||(SLAVE_LSB == 1) << 1
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (20)
                if i2c.present (SLAVE_WR | _sa0)                                         'Response from device?
                    _disp_width := width
                    _disp_height := height
                    _buffsz := ((_disp_width * _disp_height)/8)
                    return okay
    return FALSE                                                'If we got here, something went wrong

PUB Stop

    DisplayOff
    i2c.terminate

PUB Defaults

    DisplayOff
    OSCFreq (372)
    MuxRatio(_disp_height-1)
    DisplayOffset(0)
    DisplayStartLine(0)
    ChargePumpReg(TRUE)
    AddrMode (0)
    MirrorH(FALSE)
    MirrorV(FALSE)
    case _disp_height
        32:
            COMPinCfg(0, 0)
        64:
            COMPinCfg(1, 0)
        OTHER:
            COMPinCfg(0, 0)
    Contrast($7F)
    PrechargePeriod (1, 15)
    VCOMHDeselectLevel ($40)
    EntireDisplayOn(FALSE)
    InvertDisplay(FALSE)
    StopScroll
    ColumnStartEnd (0, _disp_width-1)
    case _disp_height
        32:
            PageRange (0, 3)
        64:
            PageRange (0, 7)
        OTHER:
            PageRange (0, 3)
    DisplayOn

PUB AddrMode(mode)
' Set Memory Addressing Mode
'   0: Horizontal addressing mode
'   1: Vertical
'   2: Page (POR)
    case mode
        0, 1:
        OTHER:
            return

    writeRegX(core#CMD_MEM_ADDRMODE, 1, mode)

PUB BufferSize
' Get size of buffer
    return _buffsz

PUB Char (col, row, ch) | i 'XXX Move to generic bitmap gfx lib, make operate like terminal methods
' Write a character to the display @ row and column
    col &= (_disp_width / 8) - 1    'Clamp position based on
    row &= (_disp_height / 8) - 1   ' screen's dimensions
    repeat i from 0 to 7
        byte[_draw_buffer][row << 7 + col << 3 + i] := byte[font.baseaddr + 8 * ch + i]

PUB ChargePumpReg(enabled)
' Enable Charge Pump Regulator when display power enabled
    case ||enabled
        0, 1: enabled := ||enabled
        OTHER:
            return
    writeRegX(core#CMD_CHARGEPUMP, 1, lookupz(enabled: $10, $14))

PUB Clear
' Clear the display buffer
    longfill(_draw_buffer, $00, _buffsz/4)

PUB ColumnStartEnd(column_start, column_end)
' Set display start and end columns
    case column_start
        0..127:
        OTHER:
            column_start := 0

    case column_end
        0..127:
        OTHER:
            column_end := 127

    writeRegX(core#CMD_SET_COLADDR, 2, (column_end << 8) | column_start)

PUB COMPinCfg(pin_config, remap) | config
' Set COM Pins Hardware Configuration and Left/Right Remap
'  pin_config: 0: Sequential                      1: Alternative (POR)
'       remap: 0: Disable Left/Right remap (POR)  1: Enable remap
' POR: $12
    config := %0000_0010
    case pin_config
        0:
        OTHER:
            config := config | (1 << 4)

    case remap
        1:
            config := config | (1 << 5)
        OTHER:

    writeRegX(core#CMD_SETCOM_CFG, 1, config)

PUB Contrast(level)
' Set Contrast Level 0..255 (POR = 127)
    case level
        0..255:
        OTHER:
            level := 127

    writeRegX(core#CMD_CONTRAST, 1, level)

PUB DisplayOn
' Power on display
    writeRegX(core#CMD_DISP_ON, 0, 0)

PUB DisplayOff
' Power off display
    writeRegX(core#CMD_DISP_OFF, 0, 0)

PUB DisplayOffset(offset)
' Set Display Offset/vertical shift from 0..63
' POR: 0
    case offset
        0..63:
        OTHER:
            offset := 0

    writeRegX(core#CMD_SETDISPOFFS, 1, offset)

PUB DisplayStartLine(start_line)
' Set Display Start Line from 0..63
    case start_line
        0..63:
        OTHER:
            return

    writeRegX($40, 0, start_line)

PUB DrawBitmap(addr_bitmap)
' Blits bitmap to display buffer
    bytemove(_draw_buffer, addr_bitmap, _buffsz)

PUB DrawBuffer(address)
' Set address of display buffer
    return _draw_buffer := address

PUB DrawCircle(x0, y0, radius, color) | x, y, err, cdx, cdy

    x := radius - 1
    y := 0
    cdx := 1
    cdy := 1
    err := cdx - (radius << 1)

    repeat while (x => y)
        DrawPixel(x0 + x, y0 + y, color)
        DrawPixel(x0 + y, y0 + x, color)
        DrawPixel(x0 - y, y0 + x, color)
        DrawPixel(x0 - x, y0 + y, color)
        DrawPixel(x0 - x, y0 - y, color)
        DrawPixel(x0 - y, y0 - x, color)
        DrawPixel(x0 + y, y0 - x, color)
        DrawPixel(x0 + x, y0 - y, color)

        if (err =< 0)
            y++
            err += cdy
            cdy += 2

        if (err > 0)
            x--
            cdx += 2
            err += cdx - (radius << 1)

PUB DrawLine(x1, y1, x2, y2, c) | sx, sy, ddx, ddy, err, e2

    ddx := ||(x2-x1)
    ddy := ||(y2-y1)
    err := ddx-ddy

    sx := -1
    if (x1 < x2)
        sx := 1

    sy := -1
    if (y1 < y2)
        sy := 1

    case c
        1:
            repeat until ((x1 == x2) AND (y1 == y2))
                byte[_draw_buffer][x1 + (y1>>3{/8})*_disp_width] |= (1 << (y1&7))'try >>3 instead of /8

                e2 := err << 1

                if e2 > -ddy
                    err := err - ddy
                    x1 := x1 + sx

                if e2 < ddx
                    err := err + ddx
                    y1 := y1 + sy

        0:
            repeat until ((x1 == x2) AND (y1 == y2))
                byte[_draw_buffer][x1 + (y1>>3{/8})*_disp_width] &= (1 << (y1&7))

                e2 := err << 1

                if e2 > -ddy
                    err := err - ddy
                    x1 := x1 + sx

                if e2 < ddx
                    err := err + ddx
                    y1 := y1 + sy

        -1:
            repeat until ((x1 == x2) AND (y1 == y2))
                byte[_draw_buffer][x1 + (y1>>3{/8})*_disp_width] ^= (1 << (y1&7))

                e2 := err << 1

                if e2 > -ddy
                    err := err - ddy
                    x1 := x1 + sx

                if e2 < ddx
                    err := err + ddx
                    y1 := y1 + sy

        OTHER:
            return

PUB DrawPattern'XXX IMPLEMENT ME

PUB DrawPixel (x, y, c)

    case x
        0.._disp_width-1:
        OTHER:
            return
    case y
        0.._disp_height-1:
        OTHER:
            return

    case c
        1:
            byte[_draw_buffer][x + (y>>3)*_disp_width] |= (1 << (y&7))
        0:
            byte[_draw_buffer][x + (y>>3)*_disp_width] &= (1 << (y&7))
        -1:
            byte[_draw_buffer][x + (y>>3)*_disp_width] ^= (1 << (y&7))
        OTHER:
            return

PUB EntireDisplayOn(enabled)
' TRUE    - Turns on all pixels (doesn't affect GDDRAM contents)
' FALSE   - Displays GDDRAM contents
    case ||enabled
        0, 1:
            enabled := ||enabled
        OTHER:
            return

    writeRegX(core#CMD_RAMDISP_ON, 0, enabled)

PUB InvertDisplay(enabled)
' Invert display
    case ||enabled
        0, 1:
            enabled := ||enabled
        OTHER:
            return

    writeRegX(core#CMD_DISP_NORM, 0, enabled)

PUB MirrorH(enabled)
' Mirror display, horizontally
' NOTE: Only affects subsequent data - no effect on data in GDDRAM
    case ||enabled
        0, 1: enabled := ||enabled
        OTHER:
            return

    writeRegX(core#CMD_SEG_MAP0, 0, enabled)

PUB MirrorV(enabled)
' Mirror display, vertically
' NOTE: Only affects subsequent data - no effect on data in GDDRAM
' POR: 0
    case ||enabled
        0:
        1: enabled := 8
        OTHER:
            return

    writeRegX(core#CMD_COMDIR_NORM, 0, enabled)

PUB MuxRatio(mux_ratio)
' Valid values: 16..64
    case mux_ratio
        16..64:
        OTHER:
            return

    writeRegX(core#CMD_SETMUXRATIO, 1, mux_ratio-1)

PUB OSCFreq(kHz)
' Set Oscillator frequency, in kHz
'   Valid values: 333, 337, 342, 347, 352, 357, 362, 367, 372, 377, 382, 387, 392, 397, 402, 407
'   Any other value is ignored
'   NOTE: Range is interpolated, based solely in the range specified in the datasheet, divided into 16 steps
    case kHz
        core#FOSC_MIN..core#FOSC_MAX:
            kHz := lookdownz(kHz: 333, 337, 342, 347, 352, 357, 362, 367, 372, 377, 382, 387, 392, 397, 402, 407) << core#FLD_OSCFREQ
        OTHER:
            return

    writeRegX(core#CMD_SETOSCFREQ, 1, kHz)

PUB PageRange(pgstart, pgend)

    case pgstart
        0..7:{1..7}
        OTHER:
            pgstart := 0

    case pgend
        0..7:{0..6}
        OTHER:
            pgend := 7

    writeRegX(core#CMD_SET_PAGEADDR, 2, (pgend << 8) | pgstart)

PUB PrechargePeriod(phs1_clks, phs2_clks)
' Set Pre-charge period: 1..15 DCLK
' POR: 2 (both)
    case phs1_clks
        1..15:
        OTHER:
            phs1_clks := 2

    case phs2_clks
        1..15:
        OTHER:
            phs2_clks := 2

    writeRegX(core#CMD_SETPRECHARGE, 1, (phs2_clks << 4) | phs1_clks)

PUB StopScroll

    writeRegX(core#CMD_STOPSCROLL, 0, 0)

PUB Str (col, row, string_addr) | i
' Write string at string_addr to the display @ row and column.
'   NOTE: Wraps to the left at end of line and to the top-left at end of display
    repeat i from 0 to strsize(string_addr)-1
        char(col, row, byte[string_addr][i])
        col++
        if col > (_disp_width / 8) - 1
            col := 0
            row++
            if row > (_disp_height / 8) - 1
                row := 0

PUB VCOMHDeselectLevel(level)
' Set Vcomh deselect level 0.65, 0.77, 0.83 * Vcc
'   Valid values: 0.65, 0.77, 0.83
'   Any other value sets the POR value, 0.77
    case level
        0.67:
            level := %000 << 4
        0.77:
            level := %010 << 4
        0.83:
            level := %011 << 4
        OTHER:
            level := %010 << 4

    writeRegX(core#CMD_SETVCOMDESEL, 1, level)

PUB writeBuffer

'  SetColumnStartEnd (0, _disp_width-1)
'  SetPageStartEnd (0, 3)

    i2c.start
    i2c.write (SLAVE_WR)
    i2c.write (core#CTRLBYTE_DATA)
    i2c.wr_block (_draw_buffer, _buffsz)
    i2c.stop

PUB writeAltBuffer(ptr_buf)

'  SetColumnStartEnd (0, _disp_width-1)
'  SetPageStartEnd (0, 3)

    i2c.start
    i2c.write (SLAVE_WR)
    i2c.write (core#CTRLBYTE_DATA)
    i2c.wr_block (ptr_buf, _buffsz)
    i2c.stop

PRI writeRegX(reg, nr_bytes, val) | cmd_packet[2]
' Write nr_bytes to register 'reg' stored in val
' If nr_bytes is
'   0, It's a command that has no arguments - write the command only
'   1, It's a command with a single byte argument - write the command, then the byte
'   2, It's a command with two arguments - write the command, then the two bytes (encoded as a word)
    cmd_packet.byte[0] := SLAVE_WR | _sa0
    cmd_packet.byte[1] := core#CTRLBYTE_CMD
    case nr_bytes
        0:
            cmd_packet.byte[2] := reg | val 'Simple command
        1:
            cmd_packet.byte[2] := reg       'Command w/1-byte argument
            cmd_packet.byte[3] := val
        2:
            cmd_packet.byte[2] := reg       'Command w/2-byte argument
            cmd_packet.byte[3] := val & $FF
            cmd_packet.byte[4] := (val >> 8) & $FF
        OTHER:
            return

    i2c.start
    i2c.wr_block (@cmd_packet, 3 + nr_bytes)
    i2c.stop

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
