{
    --------------------------------------------
    Filename: io.expander.pcf8574.i2c.spin
    Author: Jesse Burt
    Description: Driver for the PCF8574 I2C I/O expander
    Copyright (c) 2021
    Started Sep 06, 2021
    Updated Sep 11, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

OBJ

#ifdef PCF8574_PASM
    i2c : "com.i2c"                             ' PASM I2C engine (up to ~800kHz)
#elseifdef PCF8574_SPIN
    i2c : "tiny.com.i2c"                        ' SPIN I2C engine (~40kHz)
#else
#error "One of PCF8574_PASM or PCF8574_SPIN must be defined"
#endif
    core: "core.con.pcf8574"                    ' hw-specific low-level const's
    time: "time"                                ' basic timing functions

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ                 ' validate pins and bus freq
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            if i2c.present(SLAVE_WR)            ' test device bus presence
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB Rd_Byte{}: rd_b
' Read I/O expander P0..7 as byte rd_b
'   Example:
'       P7..0 state is: %1010_1010
'       rd_b returns $AA
    i2c.start{}
    i2c.write(SLAVE_RD)
    rd_b := i2c.rd_byte(i2c#NAK)
    i2c.stop{}

PUB Wr_byte(wr_b)
' Write byte wr_b to I/O expander P0..7
'   Example:
'       Wr_Byte("A")
'       PCF8574 P7..0 state will be: %0010_0001
    i2c.start{}
    i2c.write(SLAVE_WR)
    i2c.wr_byte(wr_b)
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
