{
    --------------------------------------------
    Filename: signal.audio.amp.max9744.spin
    Author: Jesse Burt
    Description: Driver for the MAX9744 20W audio amplifier IC
    Copyright (c) 2022
    Started Jul 7, 2018
    Updated May 25, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

' Filter setting
    NONE            = 0
    PWM             = 1

VAR

    long _shdn
    byte _vol_level, _mod_mode

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef MAX9744_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core    : "core.con.max9744"                ' HW-specific constants
    time    : "time"                            ' timekeeping methods

PUB Null{}
' This is not a top-level object

PUB Start(SHDN_PIN): status
' Start using "standard" Propeller I2C pins and 100kHz
'   Still requires SHDN_PIN
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, SHDN_PIN)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, SHDN_PIN): status
' Start using custom I/O settings
'   Returns: Core/cog number+1 of I2C engine, FALSE if no cogs available
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.msleep(1)
            if i2c.present(SLAVE_WR)            ' test device bus presence
                _shdn := SHDN_PIN
                powered(TRUE)                   ' SHDN pin high
                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    mute{}
    powered(FALSE)
    i2c.deinit{}

PUB ModulationMode(mode): curr_mode
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
        other:
            return _mod_mode

    powered(FALSE)                              ' cycle power
    powered(TRUE)                               '   to effect changes
  
    writereg(_mod_mode)

PUB Mute{}
' Set 0 Volume
    volume(0)

PUB Powered(state): curr_state
' Power on or off
'   Valid values:
'       FALSE (0): Power off
'       TRUE (-1 or 1): Power on
'   Any other value returns the current setting
    case ||(state)
        0:
            outa[_shdn] := 0
            dira[_shdn] := 1
        1:
            outa[_shdn] := 1
            dira[_shdn] := 1
            volume(_vol_level)
        other:
            return outa[_shdn]

PUB VolDown{}
' Decrease volume level
    writereg(core#CMD_VOL_DN)

PUB Volume(level): curr_lvl
' Set Volume to a specific level
'   Valid values: 0..63
'   Any other value returns the current setting
    case level
        0..63:
            _vol_level := level
        other:
            return _vol_level

    writereg(_vol_level)

PUB VolUp{}
' Increase volume level
    writereg(core#CMD_VOL_UP)

PRI writeReg(reg_nr) | cmd_pkt
' Write register/command to device
    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.stop{}

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

