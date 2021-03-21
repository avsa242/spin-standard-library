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

    i2c : "com.i2c"                             ' PASM I2C Driver
    core: "core.con.xxxxx"                      ' HW-specific constants
    time: "time"                                ' Basic timing functions

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using 'default' Propeller I2C pins,
'   at safest universal speed of 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.msleep(1)
            if i2c.present (SLAVE_WR)           ' test device bus presence

                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB Defaults{}
' Factory default settings

PUB ClockDataOk{}: flag
' Flag indicating battery voltage ok/clock data integrity ok
'   Returns:
'       TRUE (-1): Battery voltage ok, clock data integrity guaranteed
'       FALSE (0): Battery voltage low, clock data integrity not guaranteed
    pollrtc{}
    return _clkdata_ok == 0

PUB ClockOutFreq(freq): curr_freq
' Set frequency of CLKOUT pin, in Hz
'   Valid values: 0, 1, 32, 1024, 32768
'   Any other value polls the chip and returns the current setting
    curr_freq := 0
    readreg(core#CLKOUT, 1, @curr_freq)
    case freq
        0..posx:
        other:
            return 0

    freq := 0
    writereg(core#CTRL_CLKOUT, 1, @freq)

PUB Date(ptr_date)

PUB DeviceID{}: id
' Read device identification
    readreg(core#DEVID, 1, @id)

PUB Day(d): curr_day
' Set day of month
'   Valid values: 1..31
'   Any other value returns the last read current day
    case d
        1..31:
            d := int2bcd(d)
            writereg(core#DAYS, 1, @d)
        other:
            return bcd2int(_days & core#DAYS_MASK)

PUB Hours(hr): curr_hr
' Set hours
'   Valid values: 0..23
'   Any other value returns the last read current hour
    case hr
        0..23:
            hr := int2bcd(hr)
            writereg(core#HOURS, 1, @hr)
        other:
            return bcd2int(_hours & core#HOURS_MASK)

PUB IntClear(mask) | tmp
' Clear interrupts, using a bitmask
'   Valid values:
'       xxx
'           For each bit, 0 to leave as-is, 1 to clear
'   Any other value is ignored
    case mask
        0..%1111_1111:
            readreg(core#INTCLEAR, 1, @tmp)
            writereg(core#INTCLEAR, 1, @tmp)
        other:
            return

PUB Interrupt{}: flags
' Flag indicating one or more interrupts asserted
    readreg(core#INTSRC, 1, @flags)
    return (flags & core#INTSRC_BITS)

PUB IntMask(mask): curr_mask
' Set interrupt mask
'   Valid values:
'       xxx
'   Any other value polls the chip and returns the current setting
    readreg(core#INTMASK, 1, @curr_mask)
    case mask
        0..%1111_11111
        other:
            return curr_mask & core#INTMASK_BITS

    mask := ((curr_mask & core#INTMASK_MASK) | mask)
    writereg(core#INTMASK, 1, @mask)

PUB IntPinState(state): curr_state
' Set interrupt pin active state
    curr_state := 0
    readreg(core#INT_ACT_ST, 1, @curr_state)
    case state
        0, 1:
        other:
            return (curr_state >> core#ACT_ST) & 1

    state := ((curr_state & core#AC_ST_MASK) | state)
    writereg(core#INT_ACT_ST, 1, @state)

PUB Month(m): curr_month
' Set month
'   Valid values: 1..12
'   Any other value returns the last read current month
    case m
        1..12:
            m := int2bcd(m)
            writereg(core#MONTHS, 1, @m)
        other:
            return bcd2int(_months & core#MONTHS_MASK)

PUB Minutes(minute): curr_min
' Set minutes
'   Valid values: 0..59
'   Any other value returns the last read current minute
    case minute
        0..59:
            minute := int2bcd(minute)
            writereg(core#MINUTES, 1, @minute)
        other:
            return bcd2int(_mins & core#MINUTES_MASK)

PUB PollRTC{}
' Read the time data from the RTC and store it in hub RAM
' Update the clock integrity status bit from the RTC
    readreg(core#SECS, 7, @_secs)
    _clkdata_ok := (_secs >> core#CLK_OK) & 1   ' Clock integrity bit

PUB Seconds(second): curr_sec
' Set seconds
'   Valid values: 0..59
'   Any other value polls the RTC and returns the current second
    case second
        0..59:
            second := int2bcd(second)
            writereg(core#SECS, 1, @second)
        other:
            return bcd2int(_secs & core#SECS_BITS)

PUB SetDate(d)
' Set current date/date of month

PUB SetHours(h)
' Set current hour

PUB SetMinutes(m)
' Set current minute

PUB SetMonth(m)
' Set current month

PUB SetSeconds(s)
' Set current second

PUB SetWeekday(w)
' Set current weekday

PUB SetYear(y)
' Set current year

PUB Timer(val): curr_val
' Set countdown timer value
'   Valid values: xxx
'   Any other value polls the chip and returns the current setting
    case val
        0..posx:
            writereg(core#TIMER, 1, @val)
        other:
            readreg(core#TIMER, 1, @curr_val)
            return

PUB TimerClockFreq(freq): curr_freq
' Set timer source clock frequency, in Hz
'   Valid values:
'       xxx
'   Any other value polls the chip and returns the current setting
    curr_freq := 0
    readreg(core#CTRL_TIMER, 1, @curr_freq)
    case freq
        0..posx:
            'Hz -> reg. conversion code here
        other:
            return curr_freq

    freq := ((curr_freq & core#TIMER_MASK) | freq)
    writereg(core#CTRL_TIMER, 1, @freq)

PUB TimerEnabled(state): curr_state
' Enable timer
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL_TIMER, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#TMR_EN
        other:
            return ((curr_state >> core#TMR_EN) & 1) == 1

    state := ((curr_state & core#TMR_EN_MASK) | state)
    writereg(core#CTRL_TIMER, 1, @state)

PUB Weekday(wkday): curr_wkday
' Set day of week
'   Valid values: 1..7
'   Any other value returns the last read current day of week
    case wkday
        1..7:
            wkday := int2bcd(wkday-1)
            writereg(core#WEEKDAYS, 1, @wkday)
        other:
            return bcd2int(_wkdays & core#WEEKDAYS_MASK) + 1

PUB Year(yr): curr_yr
' Set 2-digit year
'   Valid values: 0..99
'   Any other value returns the last read current year
    case yr
        0..99:
            yr := int2bcd(yr)
            writereg(core#YEARS, 1, @yr)
        other:
            return bcd2int(_years & core#YEARS_MASK)

PRI bcd2int(bcd): int
' Convert BCD (Binary Coded Decimal) to integer
    return ((bcd >> 4) * 10) + (bcd // 16)

PRI int2bcd(int): bcd
' Convert integer to BCD (Binary Coded Decimal)
    return ((int / 10) << 4) + (int // 10)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Read nr_bytes from device into ptr_buff
    case reg_nr                                 ' Validate reg
        $00..$ff:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr

            i2c.start{}                         ' Send reg to read
            i2c.wr_block(@cmd_pkt, 2)

            i2c.start{}
            i2c.write(SLAVE_RD)
            i2c.rd_block(ptr_buff, nr_bytes, i2c#NAK)  ' Read it
            i2c.stop{}
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes from ptr_buff to device
    case reg_nr
        $00..$ff:                               ' Validate reg
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr

            i2c.start{}                         ' Send reg to write
            i2c.wr_block(@cmd_pkt, 2)

            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])  ' Write it
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
