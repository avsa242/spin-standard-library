{
    --------------------------------------------
    Filename: time.rtc.ds3231.i2c.spin
    Author: Jesse Burt
    Description: Driver for the DS3231 Real-Time Clock
    Copyright (c) 2020
    Started Nov 17, 2020
    Updated Nov 18, 2020
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

VAR

    byte _secs, _mins, _hours                   ' Vars to hold time
    byte _wkdays, _days, _months, _years        ' Order is important!

OBJ

    i2c : "com.i2c"
    core: "core.con.ds3231.spin"
    time: "time"

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins and 100kHz

    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay
' Start using custom I2C pins and bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)
                time.usleep(core#TPOR)
                if i2c.present(SLAVE_WR)        ' check device bus presence
                    return
    return FALSE                                ' something above failed

PUB Stop{}

    i2c.terminate{}

PUB Defaults{}
' Set factory defaults

PUB Date(ptr_date)

PUB Day(d): day_now
' Set day of month
'   Valid values: 1..31
'   Any other value returns the current day
    case d
        1..31:
            d := int2bcd(d)
            writereg(core#DATE, 1, @d)
        other:
            return bcd2int(_days & core#DATE_MASK)

PUB Hours(hr): curr_hr
' Set hours
'   Valid values: 0..23
'   Any other value returns the current hour
    case hr
        0..23:
            hr := int2bcd(hr)
            writereg(core#HOURS, 1, @hr)
        other:
            return bcd2int(_hours & core#HOURS_MASK)

PUB Minutes(minute): curr_min
' Set minutes
'   Valid values: 0..59
'   Any other value returns the current minute
    case minute
        0..59:
            minute := int2bcd(minute)
            writereg(core#MINUTES, 1, @minute)
        other:
            return bcd2int(_mins & core#MINUTES_MASK)

PUB Month(mon): curr_month
' Set month
'   Valid values: 1..12
'   Any other value returns the current month
    case mon
        1..12:
            mon := int2bcd(mon)
            writereg(core#MONTH, 1, @mon)
        other:
            return bcd2int(_months & core#MONTH_MASK)

PUB PollRTC{}
' Read the time data from the RTC and store it in hub RAM
    readreg(core#SECONDS, 7, @_secs)

PUB Seconds(second): curr_sec
' Set seconds
'   Valid values: 0..59
'   Any other value returns the current second
    case second
        0..59:
            second := int2bcd(second)
            writereg(core#SECONDS, 1, @second)
        other:
            return bcd2int(_secs & core#SECONDS_MASK)

PUB Weekday(wkday): curr_wkday
' Set day of week
'   Valid values: 1..7
'   Any other value returns the current day of week
    case wkday
        1..7:
            wkday := int2bcd(wkday-1)
            writereg(core#DAY, 1, @wkday)
        other:
            return bcd2int(_wkdays & core#DAY_MASK) + 1

PUB Year(yr): curr_yr
' Set 2-digit year
'   Valid values: 0..99
'   Any other value returns the current year
    case yr
        0..99:
            yr := int2bcd(yr)
            writereg(core#YEAR, 1, @yr)
        other:
            return bcd2int(_years & core#YEAR_MASK)

PUB Reset{}
' Reset the device

PRI bcd2int(bcd): int
' Convert BCD (Binary Coded Decimal) to integer
    return ((bcd >> 4) * 10) + (bcd // 16)

PRI int2bcd(int): bcd
' Convert integer to BCD (Binary Coded Decimal)
    return ((int / 10) << 4) + (int // 10)

PUB readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Read nr_bytes from device into ptr_buff
    case reg_nr
        core#SECONDS..core#TEMP_MSB:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)
            i2c.start{}
            i2c.write(SLAVE_RD)
            i2c.rd_block(ptr_buff, nr_bytes, TRUE)
            i2c.stop{}
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes to device from ptr_buff
    case reg_nr
        core#SECONDS..core#AGE_OFFS:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}
        other:
            return


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
