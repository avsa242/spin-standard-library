{
    --------------------------------------------
    Filename: display.oled.ssd1309.spin
    Description: Driver for Solomon Systech SSD1309 SPI OLED display drivers
    Author: Jesse Burt
    Copyright (c) 2022
    Created: Dec 27, 2019
    Updated: Feb 6, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#define 1BPP
#define MEMMV_NATIVE bytemove
#include "lib.gfx.bitmap.spin"

CON

    BYTESPERPX      = 1
    MAX_COLOR       = 1

' Display visibility modes
    NORMAL          = 0
    ALL_ON          = 1
    INVERTED        = 2

' Addressing modes
    HORIZ           = 0
    VERT            = 1
    PAGE            = 2

OBJ

    core    : "core.con.ssd1309"                ' HW-specific constants
    time    : "time"                            ' timekeeping methods
    io      : "io"                              ' I/O abstraction
    spi     : "com.spi.bitbang"                 ' PASM SPI engine (~4MHz)

VAR

    long _CS, _DC, _RES

PUB Null{}
' This is not a top-level object

PUB Startx(CS_PIN, SCK_PIN, SDA_PIN, DC_PIN, RES_PIN, {
}   WIDTH, HEIGHT, ptr_dispbuff): status
' Start the driver with custom settings
' Valid values:
'       width: 0..128
'       height: 32, 64
'       CS_PIN, SCK_PIN, SDA_PIN, DC_PIN, RES_PIN: 0..31
    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(SDA_PIN: 0..31) and lookdown(DC_PIN: 0..31)
        if (status := spi.init(CS_PIN, SCK_PIN, SDA_PIN, SDA_PIN, {
}       core#SPI_MODE))
            longmove(@_CS, @CS_PIN, 5)

            io.low(_DC)
            io.high(_RES)
            io.output(_DC)
            io.output(_RES)

            reset{}

            _disp_width := WIDTH
            _disp_height := HEIGHT
            _disp_xmax := _disp_width-1
            _disp_ymax := _disp_height-1
            _buff_sz := (_disp_width * _disp_height) / 8
            _bytesperln := _disp_width * BYTESPERPX

            address(ptr_dispbuff)
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    powered(FALSE)
    spi.deinit{}

PUB Defaults{}
' Factory default settings
    powered(FALSE)
    displaylines(64)
    displaystartline(0)
    chargepumpreg(TRUE)
    addrmode(PAGE)
    contrast(127)
    displayvisibility(NORMAL)
    displaybounds(0, 0, 127, 63)

PUB Preset_128x{}
' Preset: 128px wide, determine settings for height at runtime
    displaylines(_disp_height)
    displaystartline(0)
    chargepumpreg(TRUE)
    addrmode(HORIZ)
    displayvisibility(NORMAL)
    case _disp_height
        32:
            compincfg(0, 0)
        64:
            compincfg(1, 0)
        other:
            compincfg(0, 0)
    powered(TRUE)

PUB Preset_128x32{}
' Preset: 128px wide, setup for 32px height
    displaylines(32)
    displaystartline(0)
    chargepumpreg(TRUE)
    addrmode(HORIZ)
    displayvisibility(NORMAL)
    compincfg(0, 0)
    powered(TRUE)

PUB Preset_128x64{}
' Preset: 128px wide, setup for 64px height
    displaylines(64)
    displaystartline(0)
    chargepumpreg(TRUE)
    addrmode(HORIZ)
    displayvisibility(NORMAL)
    compincfg(1, 0)
    powered(TRUE)

PUB Address(addr): curr_addr
' Set framebuffer address
    case addr
        $0004..$7FFF-_buff_sz:
            _ptr_drawbuffer := addr
            return _ptr_drawbuffer
        other:
            return _ptr_drawbuffer

PUB AddrMode(mode)
' Set Memory Addressing Mode
'   Valid values:
'       0: Horizontal addressing mode
'       1: Vertical
'       2: Page (POR)
    case mode
        HORIZ, VERT, PAGE:
        other:
            return

    writereg(core#CMD_MEM_ADDRMODE, 1, mode)

PUB ChargePumpReg(enabled)
' Enable Charge Pump Regulator when display power enabled
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value is ignored
    case ||(enabled)
        0, 1:
            enabled := lookupz(||(enabled): $10, $14)
            writereg(core#CMD_CHARGEPUMP, 1, enabled)
        other:
            return

PUB Clear{}
' Clear the display buffer
    bytefill(_ptr_drawbuffer, _bgcolor, _buff_sz)

PUB ClockFreq(kHz)
' Set Oscillator frequency, in kHz
'   Valid values: 360, 372, 384, 396, 408, 420, 432, 444, 456, 468, 480, 492,
'                 504, 516, 528, 540
'   Any other value is ignored
'   NOTE: Range is interpolated, based solely on the range specified in the
'       datasheet, divided into 16 steps
    case kHz
        core#FOSC_MIN..core#FOSC_MAX:
            kHz := lookdownz(kHz: 360, 372, 384, 396, 408, 420, 432, 444, 456,{
}           468, 480, 492, 504, 516, 528, 540) << core#OSCFREQ
            writereg(core#CMD_SETOSCFREQ, 1, kHz)
        other:
            return

PUB COMLogicHighLevel(level)
' Set Vcomh deselect level, in volts
'   Valid values: 0_65, 0_77, 0_83 (0.65, 0.77, 0.83)
'   Any other value sets the POR value, 0_77
    case level
        0_67:
            level := %000 << 4
        0_77:
            level := %010 << 4
        0_83:
            level := %011 << 4
        other:
            level := %010 << 4

    writereg(core#CMD_SETVCOMDESEL, 1, level)

PUB COMPinCfg(pin_config, remap) | config
' Set COM Pins Hardware Configuration and Left/Right Remap
'  pin_config: 0: Sequential                      1: Alternative (POR)
'       remap: 0: Disable Left/Right remap (POR)  1: Enable remap
' POR: $12  ' XXX clear this up
    config := %0000_0010    'XXX clear this up - use CON
    case pin_config
        0:
        other:
            config := config | (1 << 4)

    case remap
        1:
            config := config | (1 << 5)
        other:

    writereg(core#CMD_SETCOM_CFG, 1, config)

PUB Contrast(level)
' Set Contrast Level
'   Valid values: 0..255
'   Any other value sets the POR value, 127
    case level
        0..255:
        other:
            level := 127

    writereg(core#CMD_CONTRAST, 1, level)

PUB DisplayBounds(sx, sy, ex, ey)
' Set displayable area
'   Valid values:
'       sx, ex: 0..127
'       sy, ey: 0..63
    ifnot lookup(sx: 0..127) or lookup(sy: 0..63) or lookup(ex: 0..127){
}   or lookup(ey: 0..63)                        ' if coordinates are invalid,
        return                                  '   ignore and return

    sy >>= 3
    ey >>= 3
    writereg(core#CMD_SET_COLADDR, 2, (ex << 8) | sx)
    writereg(core#CMD_SET_PAGEADDR, 2, (ey << 8) | sy)

PUB DisplayInverted(enabled)
' Invert display colors
'   Valid values: TRUE (-1 or 1), FALSE (0)
    case ||(enabled)
        0:
            displayvisibility(NORMAL)
        1:
            displayvisibility(INVERTED)
        other:
            return

PUB DisplayLines(lines)
' Set total number of display lines
'   Valid values: 16..64
'   Typical values: 32, 64
'   Any other value is ignored
    case lines
        16..64:
            lines -= 1
            writereg(core#CMD_SETMUXRATIO, 1, lines)
        other:
            return

PUB DisplayOffset(offset)
' Set Display Offset/vertical shift
'   Valid values: 0..63
'   Any other value sets the POR value, 0
    case offset
        0..63:
        other:
            offset := 0

    writereg(core#CMD_SETDISPOFFS, 1, offset)

PUB DisplayStartLine(start_line)
' Set Display Start Line
'   Valid values: 0..63
'   Any other value sets the POR value, 0
    case start_line
        0..63:
        other:
            start_line := 0

    writereg($40, 0, start_line)    'XXX define reg in core file

PUB DisplayVisibility(mode)
' Set display visibility
'   Valid values:
'       NORMAL: Normal display
'       ALL_ON: Set all pixels on (doesn't affect previous display contents)
'       INVERTED: Invert display colors
    case mode
        NORMAL:
            writereg(core#CMD_RAMDISP_ON, 0, 0)
            writereg(core#CMD_DISP_NORM, 0, 0)
        ALL_ON:
            writereg(core#CMD_RAMDISP_ON, 0, 1)
        INVERTED:
            writereg(core#CMD_DISP_NORM, 0, 1)
        other:
            return

PUB MirrorH(enabled)
' Mirror display, horizontally
' NOTE: Takes effect only after next drawing operation; doesn't affect
'   current display contents
    case ||(enabled)
        0, 1:
            enabled := ||(enabled)
        other:
            return

    writereg(core#CMD_SEG_MAP0, 0, enabled)

PUB MirrorV(enabled)
' Mirror display, vertically
' NOTE: Takes effect only after next drawing operation; doesn't affect
'   current display contents
    case ||(enabled)
        0, 1:
            enabled := lookupz(||(enabled): 0, 8)
        other:
            return

    writereg(core#CMD_COMDIR_NORM, 0, enabled)

PUB Plot(x, y, color)
' Plot pixel at (x, y) in color
    if (x < 0 or x > _disp_xmax) or (y < 0 or y > _disp_ymax)
        return                                  ' coords out of bounds, ignore
#ifdef GFX_DIRECT
' direct to display
'   (not implemented)
#else
' buffered display
    case color
        1:
            byte[_ptr_drawbuffer][x + (y>>3) * _disp_width] |= (|< (y&7))
        0:
            byte[_ptr_drawbuffer][x + (y>>3) * _disp_width] &= !(|< (y&7))
        -1:
            byte[_ptr_drawbuffer][x + (y>>3) * _disp_width] ^= (|< (y&7))
        OTHER:
            return
#endif

PUB Point(x, y): pix_clr
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    return (byte[_ptr_drawbuffer][(x + (y >> 3) * _disp_width)] & (1 << (y & 7)) <> 0) * -1

PUB Powered(enabled)
' Enable display power
'   Valid values: TRUE (-1 or 1), FALSE (0)
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) + core#CMD_DISP_OFF
        other:
            return
    writereg(enabled, 0, 0)

PUB PrechargePeriod(phs1_clks, phs2_clks)
' Set Pre-charge period, in display clocks
'   Valid values: 1..15
'   Any other value sets the POR value, 2 (both)
    case phs1_clks
        1..15:
        other:
            phs1_clks := 2

    case phs2_clks
        1..15:
        other:
            phs2_clks := 2

    writereg(core#CMD_SETPRECHARGE, 1, (phs2_clks << 4) | phs1_clks)

PUB Reset{}
' Reset the display controller
    if lookup(_RES: 0..31)
        io.high(_RES)
        time.usleep(3)
        io.low(_RES)
        time.usleep(3)
        io.high(_RES)

PUB Update{}
' Write display buffer to display
    displaybounds(0, 0, _disp_xmax, _disp_ymax)

    io.high(_DC)
    spi.deselectafter(true)
    spi.wrblock_lsbf(_ptr_drawbuffer, _buff_sz)

PUB WriteBuffer(ptr_buff, buff_sz) | tmp
' Write buff_sz bytes of ptr_buff to display
    displaybounds(0, 0, _disp_xmax, _disp_ymax)

    io.high(_DC)
    spi.deselectafter(true)
    spi.wrblock_lsbf(ptr_buff, buff_sz)

PRI memFill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    bytefill(_ptr_drawbuffer + (xs + (ys * _bytesperln)), val, count)

PRI writeReg(reg_nr, nr_bytes, val) | cmd_pkt[2], tmp
' Write nr_bytes to register 'reg_nr' stored in val
' If nr_bytes is
'   0, Command without arguments: write the command only
'   1, Command with a single byte argument - write the command, then the byte
'   2, Command with two arguments - write the command, then the two bytes
    case nr_bytes
        0:
            cmd_pkt.byte[0] := reg_nr | val     ' Simple command
            nr_bytes := 1
        1:
            cmd_pkt.byte[0] := reg_nr           ' Command w/1-byte argument
            cmd_pkt.byte[1] := val
            nr_bytes := 2
        2:
            cmd_pkt.byte[0] := reg_nr           ' Command w/2-byte argument
            cmd_pkt.byte[1] := val & $FF
            cmd_pkt.byte[2] := (val >> 8) & $FF
            nr_bytes := 3
        other:                                  ' invalid
            return

    io.low(_DC)
    spi.deselectafter(true)
    spi.wrblock_lsbf(@cmd_pkt, nr_bytes)

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
