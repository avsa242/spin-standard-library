{
    --------------------------------------------
    Filename: input.gesture.paj7620u2.i2c.spin
    Author: Jesse Burt
    Description: Driver for PAJ6520U2 Gesture Sensor
    Copyright (c) 2020
    Started May 21, 2020
    Updated Dec 30, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 100_000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

' Delays used to make correct gesture detection easier
    ENTRY_TIME          = 400
    QUIT_TIME           = 800

' Gestures recognized
    RIGHT               = 1
    LEFT                = 2
    UP                  = 3
    DOWN                = 4
    FORWARD             = 5
    BACKWARD            = 6
    CCLOCKWISE          = 7
    CLOCKWISE           = 8
    WAVE                = 9

OBJ

    i2c : "com.i2c"
    core: "core.con.paj7620u2"
    time: "time"

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins and 100kHz
    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
                time.msleep(10)
                repeat 2
                    if i2c.present(SLAVE_WR)    ' check device bus presence
                time.msleep(1)
                if deviceid{} == core#DEVID_RESP
                    powered(TRUE)
                    return okay

    return FALSE                                ' something above failed

PUB Stop{}
' Put any other housekeeping code here required/recommended by your device before shutting down
    powered(FALSE)
    i2c.terminate{}

PUB Defaults{}
' Set factory defaults
    intmask(%111111111)

PUB DeviceID{}: id
' Read device identification
    readreg(core#PARTID_LSB, 2, @id)

PUB Interrupt{}: int_src
' Flag indicating one or more interrupts have asserted, as a 9-bit mask
'   Mask:
'       %876543210
'       8 - Wave gesture
'       7 - Counter-clockwise
'       6 - Clockwise
'       5 - Backward
'       4 - Forward
'       3 - Down
'       2 - Up
'       1 - Left
'       0 - Right
    readreg(core#INTFLAG_1, 2, @int_src)

PUB IntMask(mask): curr_mask
' Select which events will trigger an interrupt, as a 9-bit mask
'   Mask:
'       %876543210
'       8 - Wave gesture
'       7 - Counter-clockwise
'       6 - Clockwise
'       5 - Backward
'       4 - Forward
'       3 - Down
'       2 - Up
'       1 - Left
'       0 - Right
'   Any other value polls the chip and returns the current setting
    case mask
        %000000000..%111111111:
            writereg(core#INTFLAG_1, 2, @mask)
        other:
            curr_mask := 0
            readreg(core#R_INT_1_EN, 2, @curr_mask)
            return curr_mask

PUB LastGesture{}: gest
' Last gesture recognized by sensor
'   Returns:
'       Right               (1)
'       Left                (2)
'       Up                  (3)
'       Down                (4)
'       Forward             (5)
'       Backward            (6)
'       Clockwise           (7)
'       Counter-Clockwise   (8)
'       Wave                (9)
'           or 0, if no gesture was detected
    case interrupt{}
        core#FLAG_RIGHT:
            time.msleep(ENTRY_TIME)
            case interrupt{}
                core#FLAG_FORWARD:
                    time.msleep(QUIT_TIME)
                    return FORWARD
                core#FLAG_BACKWARD:
                    time.msleep(QUIT_TIME)
                    return BACKWARD
                other:
                    return RIGHT
        core#FLAG_LEFT:
            time.msleep(ENTRY_TIME)
            case interrupt{}
                core#FLAG_FORWARD:
                    time.msleep(QUIT_TIME)
                    return FORWARD
                core#FLAG_BACKWARD:
                    time.msleep(QUIT_TIME)
                    return BACKWARD
                other:
                    return LEFT
        core#FLAG_UP:
            time.msleep(ENTRY_TIME)
            case interrupt{}
                core#FLAG_FORWARD:
                    time.msleep(QUIT_TIME)
                    return FORWARD
                core#FLAG_BACKWARD:
                    time.msleep(QUIT_TIME)
                    return BACKWARD
                other:
                    return UP
        core#FLAG_DOWN:
            time.msleep(ENTRY_TIME)
            case interrupt{}
                core#FLAG_FORWARD:
                    time.msleep(QUIT_TIME)
                    return FORWARD
                core#FLAG_BACKWARD:
                    time.msleep(QUIT_TIME)
                    return BACKWARD
                other:
                    return DOWN
        core#FLAG_FORWARD:
            time.msleep(QUIT_TIME)
            return FORWARD
        core#FLAG_BACKWARD:
            time.msleep(QUIT_TIME)
            return BACKWARD
        core#FLAG_CLOCKWISE:
            return CLOCKWISE
        core#FLAG_CCLOCKWISE:
            return CCLOCKWISE
        core#FLAG_WAVE:
            return WAVE
        other:
            return 0

PUB ObjBrightness{}: obj_brt
' Object brightness
'   Returns: 0..255
    readreg(core#OBJECTAVGY, 1, @obj_brt)

PUB ObjSize{}: sz
' Object size
'   Returns: 0..4095
    readreg(core#OBJECTSIZE_LSB, 2, @sz)

PUB Powered(state): curr_state
' Enable device power
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#TG_ENH, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) & 1
        other:
            return curr_state & 1

    writereg(core#TG_ENH, 1, @state)

PUB Reset{} | tmp
' Reset the device
    tmp := 1
    writereg(core#R_REGBANK_RESET, 1, @tmp)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
'' Read num_bytes from the slave device into the address stored in ptr_buff
    case reg_nr
        $000..$003, $032..$03F, $040..$052, $054..$05F, $060, $061, $063..$06C, $080..$089, $08B..$09D, $09F..$0A5, $0A9, $0AA..$0DF, $0EE, $0EF, $100..$17F:   'XXX TRIM
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := core#REGBANKSEL
            cmd_pkt.byte[2] := (reg_nr >> 8) & 1

            i2c.start{}                         '
            i2c.wr_block(@cmd_pkt, 3)           ' Bank select
            i2c.stop{}                          '

            cmd_pkt.byte[0] := SLAVE_WR         '
            cmd_pkt.byte[1] := reg_nr & $FF     '
            i2c.start{}                         '
            i2c.wr_block(@cmd_pkt, 2)           ' Command/setup

            i2c.start{}                         '
            i2c.write(SLAVE_RD)                 '
            i2c.rd_block(ptr_buff, nr_bytes, TRUE)
            i2c.stop{}                          ' Read data

            return TRUE
        other:
            return FALSE

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes from ptr_buff to slave device
    case reg_nr
        $003, $032..$03A, $03F, $040..$042, $046..$052, $05C..$05F, $061, $063..$06A, $080..$089, $08B..$09D, $09F..$0A5, $0A9, $0AA, $0AB, $0CC..$0D2, $0EE, $0EF, {}$060, $062, $06D..$075, $08A, $09E, $0A6..$0A8, $0E0..$0E9, $100..$1EF:   'XXX TRIM
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := core#REGBANKSEL
            cmd_pkt.byte[2] := (reg_nr >> 8) & 1

            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)           ' Bank select
            i2c.stop{}

            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr & $FF
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)           ' Command/setup
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}
            return TRUE

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
