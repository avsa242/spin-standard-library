{
    --------------------------------------------
    Filename: signal.audio.amp.max9744.i2c.spin
    Author: Jesse Burt
    Description: Driver for the MAX9744 20W audio amplifier IC
    Copyright (c) 2019
    Started Jul 7, 2018
    Updated Mar 16, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 400_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR

    long  _shdn

OBJ

    i2c     : "com.i2c"
    core    : "core.con.max9744"
    io      : "io"
    time    : "time"

PUB Null
' This is not a top-level object

PUB Start(SHDN_PIN): okay                                       'Default to "standard" Propeller I2C pins and 400kHz
' Simple start method uses default pin and bus freq settings, but still requires
'  SHDN_PIN to be defined
    if lookdown(SHDN_PIN: 0..31)
        okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ, SHDN_PIN)
    else
        return FALSE

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, SHDN_PIN): okay
' Start with custom settings
'   Returns: Core/cog number+1 of I2C driver, FALSE if no cogs available
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                if i2c.present (SLAVE_WR)                       'Response from device?
                    _shdn := SHDN_PIN
                    Power(TRUE)                                 'Bring SHDN pin high, if it isn't already
                    return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB ModulationMode(mode)
' Set output filter mode
'   Valid values: 0: Filterless, 1: Classic PWM
'   All other values are ignored, and return FALSE
    case mode
        0:
            mode := core#MODULATION_FILTERLESS  'Filterless modulation
        1:
            mode := core#MODULATION_CLASSICPWM  'Classic PWM
        OTHER:
            return

    Power (FALSE)
    Power (TRUE)
  
    writeRegX(mode)

PUB Mute
' Set 0 Volume
    Vol (0)

PUB Power(enabled)
' Power on or off
'   Valid values: FALSE, 0: Power off   TRUE, 1: Power on
'   All other values are ignored, and return FALSE
    case ||enabled
        0:
            io.Low (_shdn)
        1:
            io.High (_shdn)
        OTHER:
            return FALSE

PUB Vol(level)
' Set Volume to a specific level
'   Valid values: 0..63
'   All other values are ignored, and return FALSE

    case level
        0..63:
        OTHER:
            return FALSE
    writeRegX(level)

PUB VolDown
' Decrease volume level
    writeRegX(core#CMD_VOL_DN)

PUB VolUp
' Increase volume level
    writeRegX(core#CMD_VOL_UP)

PRI writeRegX(reg) | cmd_packet

    cmd_packet.byte[0] := SLAVE_WR
    cmd_packet.byte[1] := reg

    i2c.start
    i2c.wr_block (@cmd_packet, 2)
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
