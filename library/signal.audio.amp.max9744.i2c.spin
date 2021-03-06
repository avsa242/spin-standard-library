{
    --------------------------------------------
    Filename: signal.audio.amp.max9744.i2c.spin
    Author: Jesse Burt
    Description: Driver for the MAX9744 20W audio amplifier IC
    Copyright (c) 2020
    Started Jul 7, 2018
    Updated Nov 22, 2020
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

' Filter setting
    NONE                = 0
    PWM                 = 1

VAR

    long _shdn
    byte _vol_level, _mod_mode

OBJ

    i2c     : "com.i2c"
    core    : "core.con.max9744"
    io      : "io"
    time    : "time"

PUB Null{}
' This is not a top-level object

PUB Start(SHDN_PIN): okay
' Start using "standard" Propeller I2C pins and 100kHz
'   Still requires SHDN_PIN
    if lookdown(SHDN_PIN: 0..31)
        okay := startx(DEF_SCL, DEF_SDA, DEF_HZ, SHDN_PIN)
    else
        return FALSE

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, SHDN_PIN): okay
' Start with custom settings
'   Returns: Core/cog number+1 of I2C driver, FALSE if no cogs available
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
                time.msleep(1)
                if i2c.present (SLAVE_WR)       ' check device bus presence
                    _shdn := SHDN_PIN
                    powered(TRUE)               ' SHDN pin high
                    return okay

    return FALSE                                ' something above failed

PUB Stop{}

    mute{}
    powered(FALSE)
    i2c.terminate{}

PUB ModulationMode(mode)
' Set output filter mode
'   Valid values:
'       NONE (0): Filterless
'       PWM (1): Classic PWM
'   Any other value returns the current setting
    case mode
        0:                                      ' filterless modulation
            _mod_mode := core#MOD_FILTERLESS
        1:                                      ' classic PWM
            _mod_mode := core#MOD_CLASSICPWM
        OTHER:
            return _mod_mode

    powered(FALSE)                              ' cycle power
    powered(TRUE)                               '   to effect changes
  
    writereg(_mod_mode)

PUB Mute{}
' Set 0 Volume
    volume(0)

PUB Powered(enabled)
' Power on or off
'   Valid values:
'       FALSE (0): Power off
'       TRUE (-1 or 1): Power on
'   Any other value returns the current setting
    case ||(enabled)
        0:
            io.low(_shdn)
        1:
            io.high(_shdn)
            volume(_vol_level)
        OTHER:
            return io.state(_shdn)

PUB VolDown{}
' Decrease volume level
    writereg(core#CMD_VOL_DN)

PUB Volume(level)
' Set Volume to a specific level
'   Valid values: 0..63
'   Any other value returns the current setting
    case level
        0..63:
            _vol_level := level
        OTHER:
            return _vol_level

    writereg(_vol_level)

PUB VolUp{}
' Increase volume level
    writereg(core#CMD_VOL_UP)

PRI writeReg(reg) | cmd_pkt
' Write register/command to device
    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg

    i2c.start{}
    i2c.wr_block(@cmd_pkt, 2)
    i2c.stop{}

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
