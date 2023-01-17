{
    --------------------------------------------
    Filename: 
    Author: 
    Description: Driver for the XXXXX Real Time Clock
    Copyright (c) 2021
    Started MMMM DDDD, YYYY
    Updated MMMM DDDD, YYYY
    See end of file for terms of use.
    --------------------------------------------
}
#include "time.rtc.common.spinh"                ' pull in code common to all RTC drivers

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 100_000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

VAR

    byte _secs, _mins, _hours                   ' Vars to hold time
    byte _days, _wkdays, _months, _years        ' Order is important!

    byte _clkdata_ok                            ' Clock data integrity

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef XXXXX_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.xxxxx"                      ' HW-specific constants
    time: "time"                                ' Basic timing functions

PUB null
' This is not a top-level object

PUB start: status
' Start using 'default' Propeller I2C pins,
'   at safest universal speed of 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom I/O settings
    if (lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.msleep(1)
            if (i2c.present(SLAVE_WR))          ' test device bus presence

                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop
' Stop the driver
    i2c.deinit

PUB defaults
' Factory default settings

PUB clk_data_ok: flag
' Flag indicating battery voltage ok/clock data integrity ok
'   Returns:
'       TRUE (-1): Battery voltage ok, clock data integrity guaranteed
'       FALSE (0): Battery voltage low, clock data integrity not guaranteed
    pollrtc
    return _clkdata_ok == 0

PUB clkut_freq(freq): curr_freq
' Set frequency of CLKOUT pin, in Hz
'   Valid values:
'   Any other value polls the chip and returns the current setting

PUB dev_id: id
' Read device identification

PRI bcd2int(bcd): int
' Convert BCD (Binary Coded Decimal) to integer
    return ((bcd >> 4) * 10) + (bcd // 16)

PRI int2bcd(int): bcd
' Convert integer to BCD (Binary Coded Decimal)
    return ((int / 10) << 4) + (int // 10)

PRI readreg(reg_nr, nr_bytes, ptr_buff)
' Read nr_bytes from device into ptr_buff
    case reg_nr                                 ' Validate reg
        $00..$ff:
            i2c.start                           ' Send reg to read
            i2c.write(SLAVE_WR)
            i2c.write(reg_nr)

            i2c.start
            i2c.write(SLAVE_RD)
'            i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
'            i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop
        other:
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes from ptr_buff to device
    case reg_nr
        $00..$ff:                               ' Validate reg
            i2c.start                           ' Send reg to write
            i2c.write(SLAVE_WR)
            i2c.write(reg_nr)
'            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
'            i2c.wrblock_msbf(ptr_buff, nr_bytes)
            i2c.stop
        other:
            return


DAT
{
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

