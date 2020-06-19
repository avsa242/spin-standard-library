{
    --------------------------------------------
    Filename: display.electrophoretic.il3820.spi.spin
    Author: Jesse Burt
    Description: Driver for the IL3820 electrophoretic display controller
    Copyright (c) 2020
    Started Nov 30, 2019
    Updated Jun 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}
#define IL3820
#include "lib.gfx.bitmap.spin"

CON

    MAX_COLOR   = 1
    BYTESPERPX  = 1

    MSB         = 1
    LSB         = 0

VAR

    long _ptr_drawbuffer, _buff_sz
    long _disp_width, _disp_height, _disp_xmax, _disp_ymax
    word BYTESPERLN
    byte _CS, _MOSI, _DC, _SCK, _RESET, _BUSY
    byte _shadow_regs[40]

OBJ

    spi : "com.spi.4w"
    core: "core.con.il3820"
    time: "time"
    io  : "io"

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, CLK_PIN, DIN_PIN, DC_PIN, RST_PIN, BUSY_PIN, WIDTH, HEIGHT, dispbuffer_address): okay

    if lookdown(CS_PIN: 0..31) and lookdown(CLK_PIN: 0..31) and lookdown(DIN_PIN: 0..31) and lookdown(DC_PIN: 0..31) and lookdown(RST_PIN: 0..31) and lookdown(BUSY_PIN: 0..31)
        if okay := spi.start (core#CLK_DELAY, core#SCK_CPOL)
            _CS := CS_PIN
            _MOSI := DIN_PIN
            _DC := DC_PIN
            _SCK := CLK_PIN
            _RESET := RST_PIN
            _BUSY := BUSY_PIN

            io.Input (_BUSY)
            io.Output (_CS)
            io.Output (_DC)
            io.Output (_RESET)

            io.High (_CS)
            io.Low (_DC)
            io.High (_RESET)

            _disp_width := WIDTH
            _disp_height := HEIGHT
            _disp_xmax := _disp_width-1
            _disp_ymax := _disp_height-1
            _buff_sz := _disp_width * ((_disp_height + 7) / 8)
            BYTESPERLN := _disp_width * BYTESPERPX
            Address(dispbuffer_address)
            Reset
            ClearAccel
            return okay
    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.stop

PUB Defaults
' Factory defaults
    GateHighVoltage(22_000)
    GateLowVoltage(-20_000)

PUB Address(addr)
' Set framebuffer address
    case addr
        $0004..$7FFF-_buff_sz:
            _ptr_drawbuffer := addr
        OTHER:
            return _ptr_drawbuffer

PUB ClearAccel
' Clear the display immediately
    bytefill(_ptr_drawbuffer, $FF, _buff_sz)
    Update

PUB DataEntryMode(mode)
' Define data entry sequence
'   Valid values:
'       Bit %2_10
'           2: Address counter update direction
'              *0: X direction
'               1: Y direction
'           10: Increment/decrement address counter:
'               00: Y dec, X dec
'               01: Y dec, X inc
'               10: Y inc, X dec
'              *11: Y inc, X inc
'   Any other value is ignored
    case mode
        %0_00..%1_11:
        OTHER:
            return FALSE
    writeReg(core#DATA_ENTRY_MODE, 1, @mode)

PUB DisplayBounds(sx, sy, ex, ey) | x, y
' Set drawable display region for subsequent drawing operations
    x.byte[1] := ex >> 3
    x.byte[0] := sx >> 3

    y.byte[3] := ey.byte[1]
    y.byte[2] := ey.byte[0]
    y.byte[1] := sy.byte[1]
    y.byte[0] := sy.byte[0]

    writeReg(core#RAM_X_ST_END, 2, @x)
    writeReg(core#RAM_Y_ST_END, 4, @y)

PUB DisplayLines(lines) | tmp
' Set total number of display lines
    tmp.byte[0] := lines.byte[LSB]
    tmp.byte[1] := lines.byte[MSB]
    tmp.byte[2] := %000             ' 1=Interlaced LSB=MirrorV
    writeReg( core#DRIVER_OUT_CTRL, 3, @tmp)

PUB DisplayReady
' Flag indicating display is ready to accept commands
'   Returns: TRUE if display is ready, FALSE otherwise
    return (io.Input(_BUSY) ^ 1) * TRUE

PUB DummyLinePeriod(TGate) | tmp
' Set dummy line period, in units TGate (1 TGate = line width in uSec)
    tmp := $00
    readReg(core#DUMMY_LINE_PER, 1, @tmp)
    case TGate
        0..127:
        OTHER:
            return tmp

    writeReg(core#DUMMY_LINE_PER, 1, @tmp)

PUB GateHighVoltage(mV) | tmp
' Set gate driving voltage (high level), in millivolts
'   Valid values: 15_000..22_000 (default 22_000)
'   Any other value returns the current setting
    tmp := $00
    readReg(core#GATEDRV_VOLT_CTRL, 1, @tmp)
    case mV
        15_000..22_000:
            mV := ((mV / 500) - 30) << core#FLD_VGH
        OTHER:
            tmp := (tmp >> core#FLD_VGH) & core#BITS_VGH
            return ((tmp + 30) * 500)

    mV &= core#MASK_VGH
    tmp := (tmp | mV) & core#GATEDRV_VOLT_CTRL_MASK
    writeReg(core#GATEDRV_VOLT_CTRL, 1, @tmp)

PUB GateLineWidth(uS)
' Set gate line width, in microseconds (figure TGate)
'   Valid values: 30, 34, 38, 40, 44, 46, 52, 56, 62, 68, 78, 88, 104, 125, 156, 208
'   Any other value is ignored
    case uS
        30, 34, 38, 40, 44, 46, 52, 56, 62, 68, 78, 88, 104, 125, 156, 208:
            uS := lookdownz(uS: 30, 34, 38, 40, 44, 46, 52, 56, 62, 68, 78, 88, 104, 125, 156, 208)
        OTHER:
            return

    writeReg(core#GATE_LINE_WIDTH, 1, @uS)

PUB GateLowVoltage(mV) | tmp
' Set gate driving voltage (low level), in millivolts
'   Valid values: -20_000..-15_000 (default: -20_000)
'   Any other value returns the current setting
    tmp := $00
    readReg(core#GATEDRV_VOLT_CTRL, 1, @tmp)
    case mV
        -20_000..-15_000:
            mV := (||mV / 500) - 30
        OTHER:
            tmp &= core#BITS_VGL
            return ((tmp + 30) * 500) * -1

    mV &= core#MASK_VGL
    tmp := (tmp | mV) & core#GATEDRV_VOLT_CTRL_MASK
    writeReg(core#GATEDRV_VOLT_CTRL, 1, @tmp)

PUB Powered(enabled) | tmp
' Enable display power
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value is ignored
    case ||enabled
        0:
            tmp := $00
            writeReg(core#DISP_UPDATE_CTRL2, 1, @tmp)
        1:
            tmp := $FF
            writeReg(core#DISP_UPDATE_CTRL2, 1, @tmp)
        OTHER:
            return

PUB Reset | tmp
' Reset the display controller
'   2 HW Reset
    io.Low (_RESET)
    time.MSleep (200)
    io.High (_RESET)
    time.MSleep (200)

'   3
    DisplayLines(_disp_height)                                  ' MUX
    GateHighVoltage(22_000)                                     ' VGH
    GateLowVoltage(-20_000)                                     ' VGL
    SourceVoltage(15_000)                                       ' VSH/VSL
    DummyLinePeriod(26)
    GateLineWidth(62)

    tmp.byte[0] := $D7
    tmp.byte[1] := $D6
    tmp.byte[2] := $9D
    writeReg( core#BOOSTER_SOFTST_CTRL, 3, @tmp)

    tmp := $A8
    writeReg( core#WRITE_VCOM_REG, 1, @tmp)

    DataEntryMode(%0_11)

    WriteLUT(@lut_update)

    repeat until DisplayReady

    DisplayBounds(0, 0, _disp_width-1, _disp_height-1)
    SetXY(0, 0)

PUB SetXY(x, y)
' Set x, y coordinate for subsequent drawing operations
    writeReg(core#RAM_X_ADDR_AC, 1, @x)
    writeReg(core#RAM_Y_ADDR_AC, 2, @y)

PUB SourceVoltage(mV)
' Set source drive level, in millivolts
'   Valid values: 10_000..17_000
'   Any other value is ignored
    case mV
        10_000..17_000:
            mV := (mV / 500) - 20
        OTHER:
            return

    writeReg(core#SRCDRV_VOLT_CTRL, 1, @mV)

PUB Update | tmp
' Send the draw buffer to the display
    DisplayBounds(0, 0, _disp_width-1, _disp_height-1)
    SetXY(0, 0)

    repeat until DisplayReady

    writeReg(core#WRITE_RAM, _buff_sz, _ptr_drawbuffer)         ' Write the display buffer to the display

    tmp := core#SEQ_CLK_CP_EN | core#SEQ_PATTERN_DISP
    writeReg(core#DISP_UPDATE_CTRL2, 1, @tmp)
    writeReg(core#MASTER_ACT, 0, 0)
    writeReg(core#NOOP, 0, 0)

    repeat until DisplayReady

PUB WriteLUT(ptr_lut)
' Write display-specific pixel waveform LookUp Table
    writeReg( core#WRITE_LUT_REG, 30, ptr_lut)

PRI readReg(reg, nr_bytes, buff_addr) | tmp

    case reg
        core#GATEDRV_VOLT_CTRL:
            byte[buff_addr][0] := _shadow_regs[core#SH_GATEDRV_VOLT_CTRL]
        core#DUMMY_LINE_PER:
            byte[buff_addr][0] := _shadow_regs[core#SH_DUMMY_LINE_PER]
        core#BOOSTER_SOFTST_CTRL:
            repeat tmp from 0 to nr_bytes-1
                byte[buff_addr][tmp] := _shadow_regs[core#SH_BOOSTER_SOFTST_CTRL+tmp]
        OTHER:
            return

PRI writeReg(reg, nr_bytes, buff_addr) | i
' Write nr_bytes of data from buff_addr to register 'reg'
    case reg
        $01, $0C, $10, $11, $1A, $20, $21, $22, $24, $2C, $32, $3A..$3C, $44, $45, $4E, $4F:    ' Commands w/data bytes
            io.Low (_CS)
            io.Low (_DC)                                                                        ' D/C mode: Command
            spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)

            io.High (_DC)                                                                       ' D/C mode: Data
            repeat i from 0 to nr_bytes-1
                spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][i])
            io.High (_CS)

        core#SWRESET, core#MASTER_ACT, core#NOOP:                                               ' Simple commands; no accompanying data bytes
            io.Low (_CS)
            io.Low (_DC)                                                                        ' D/C mode: Command
            spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            io.High (_CS)

        OTHER:
            return FALSE

DAT

    lut_update  byte    $02, $02, $01, $11, $12, $12, $22, $22, $66, $69
                byte    $69, $59, $58, $99, $99, $88, $00, $00, $00, $00
                byte    $F8, $B4, $13, $51, $35, $51, $51, $19, $01, $00

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
