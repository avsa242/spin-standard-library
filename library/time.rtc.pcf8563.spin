{
    --------------------------------------------
    Filename: time.rtc.pcf8563.spin
    Author: Jesse Burt
    Description: Driver for the PCF8563 Real Time Clock
    Copyright (c) 2022
    Started Sep 6, 2020
    Updated Sep 22, 2022
    See end of file for terms of use.
    --------------------------------------------
}

#include "time.rtc.common.spinh"

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 100_000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

    { /INT pin active state }
    WHEN_TF_ACTIVE      = 0
    INT_PULSES          = 1 << core#TI_TP

    { Operating modes }
    CLKRUN              = 0
    CLKSTOP             = 1

VAR

    byte _secs, _mins, _hours                   ' Vars to hold time
    byte _days, _wkdays, _months, _years        ' Order is important!

    byte _clkdata_ok                            ' Clock data integrity

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef PCF8563_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.pcf8563"                    ' HW-specific constants
    time: "time"                                ' timekeeping functions

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using 'default' Propeller I2C pins,
'   at safest universal speed of 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom I/O pins and bus speed
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.msleep(1)
            if (i2c.present(SLAVE_WR))          ' test device bus presence
                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}
    bytefill(@_secs, 0, 8)

PUB defaults{}
' Factory default settings
    clkout_freq(32768)

PUB clk_data_ok{}: flag
' Flag indicating battery voltage ok/clock data integrity ok
'   Returns:
'       TRUE (-1): Battery voltage ok, clock data integrity guaranteed
'       FALSE (0): Battery voltage low, clock data integrity not guaranteed
    poll_rtc{}
    return _clkdata_ok == 0

PUB clkout_freq(freq): curr_freq
' Set frequency of CLKOUT pin, in Hz
'   Valid values: 0, 1, 32, 1024, 32768
'   Any other value polls the chip and returns the current setting
    curr_freq := 0
    readreg(core#CTRL_CLKOUT, 1, @curr_freq)
    case freq
        0:
            freq := 1 << core#FE                ' Turn off clock output
        1, 32, 1024, 32768:
            freq := lookdownz(freq: 32768, 1024, 32, 1)
        other:
            curr_freq &= core#FD_BITS
            return lookupz(curr_freq: 32768, 1024, 32, 1)

    freq := ((curr_freq & core#FD_MASK & core#FE_MASK) | freq)
    writereg(core#CTRL_CLKOUT, 1, @freq)

PUB int_clear(mask) | tmp
' Clear interrupts, using a bitmask
'   Valid values:
'       Bits: 1..0
'           1: clear alarm interrupt
'           0: clear timer interrupt
'           For each bit, 0 to leave as-is, 1 to clear
'   Any other value is ignored
    case mask
        %01, %10, %11:
            readreg(core#CTRLSTAT2, 1, @tmp)
            mask := (mask ^ %11) << core#TF     ' Reg bits are inverted
            tmp |= mask
            tmp &= core#CTRLSTAT2_MASK
            writereg(core#CTRLSTAT2, 1, @tmp)
        other:
            return

PUB interrupt{}: flags
' Flag indicating one or more interrupts asserted
    readreg(core#CTRLSTAT2, 1, @flags)
    flags := (flags >> core#TF) & core#IF_BITS

PUB int_mask(mask): curr_mask
' Set interrupt mask
'   Valid values:
'       Bits: 1..0
'           1: enable alarm interrupt
'           0: enable timer interrupt
'   Any other value polls the chip and returns the current setting
    readreg(core#CTRLSTAT2, 1, @curr_mask)
    case mask
        %00..%11:
        other:
            return curr_mask & core#IE_BITS

    mask := ((curr_mask & core#IE_MASK) | mask)
    writereg(core#CTRLSTAT2, 1, @mask)

PUB int_pin_state(state): curr_state
' Set interrupt pin active state
'   WHEN_TF_ACTIVE (0): /INT is active when timer interrupt asserted
'   INT_PULSES (1): /INT pulses at rate set by TimerClockFreq()
    curr_state := 0
    readreg(core#CTRLSTAT2, 1, @curr_state)
    case state
        WHEN_TF_ACTIVE, INT_PULSES:
        other:
            return (curr_state >> core#TI_TP) & 1

    state := ((curr_state & core#TI_TP_MASK) | state)
    writereg(core#CTRLSTAT2, 1, @state)

PUB opmode(mode): curr_mode
' Set RTC internal operating mode
'   CLKRUN (0): normal operation; RTC source clock runs
'   CLKSTOP (1): RTC clock is stopped (32.768kHz CLKOUT still available)
    curr_mode := 0
    readreg(core#CTRLSTAT1, 1, @curr_mode)
    case mode
        CLKRUN, CLKSTOP:
            mode <<= core#STOP
        other:
            return ((curr_mode >> core#STOP) & 1)

    mode := ((curr_mode & core#STOP_MASK) | mode)
    writereg(core#CTRLSTAT1, 1, @mode)

PUB poll_rtc{}
' Read the time data from the RTC and store it in hub RAM
' Update the clock integrity status bit from the RTC
    readreg(core#VL_SECS, 7, @_secs)
    _clkdata_ok := (_secs >> core#VL) & 1       ' Clock integrity bit
    _secs &= core#SECS_BITS
    _mins &= core#MINUTES_MASK
    _hours &= core#HOURS_MASK
    _days &= core#DAYS_MASK
    _wkdays &= core#WEEKDAYS_MASK
    _months &= core#CENTMONTHS_MASK
    _years &= core#YEARS_MASK

PUB set_date(d)
' Set date/day of month
'   Valid values: 1..31
'   Any other value is ignored
    case d
        1..31:
            d := int2bcd(d)
            writereg(core#DAYS, 1, @d)
        other:
            return

PUB set_hours(h)
' Set hours
'   Valid values: 0..23
'   Any other value is ignored
    case h
        0..23:
            h := int2bcd(h)
            writereg(core#HOURS, 1, @h)
        other:
            return

PUB set_minutes(m)
' Set minutes
'   Valid values: 0..59
'   Any other value is ignored
    case m
        0..59:
            m := int2bcd(m)
            writereg(core#MINUTES, 1, @m)
        other:
            return

PUB set_month(m)
' Set month
'   Valid values: 1..12
'   Any other value is ignored
    case m
        1..12:
            m := int2bcd(m)
            writereg(core#CENTMONTHS, 1, @m)
        other:
            return

PUB set_seconds(s)
' Set seconds
'   Valid values: 0..59
'   Any other value is ignored
    case s
        0..59:
            s := int2bcd(s)
            writereg(core#VL_SECS, 1, @s)
        other:
            return

PUB set_weekday(w)
' Set day of week
'   Valid values: 1..7
'   Any other value is ignored
    case w
        1..7:
            w := int2bcd(w-1)
            writereg(core#WEEKDAYS, 1, @w)
        other:
            return

PUB set_year(y)
' Set 2-digit year
'   Valid values: 0..99
'   Any other value is ignored
    case y
        0..99:
            y := int2bcd(y)
            writereg(core#YEARS, 1, @y)
        other:
            return

PUB timer(val): curr_val
' Set countdown timer value
'   Valid values: 0..255
'   Any other value polls the chip and returns the current setting
'   NOTE: The countdown period in seconds is equal to
'       timer() / timer_clk_freq()
'       e.g., if timer() is set to 255, and timer_clk_freq() is set to 1,
'       the period is 255 seconds
    case val
        0..255:
            writereg(core#TIMER, 1, @val)
        other:
            repeat 2                                    ' Datasheet recommends
                curr_val := 0                           ' 2 reads to check for
                readreg(core#TIMER, 1, @curr_val.byte[0]) ' consistent results
                readreg(core#TIMER, 1, @curr_val.byte[1]) '
                if (curr_val.byte[0] == curr_val.byte[1])
                    curr_val.byte[1] := 0
                    quit
            return curr_val & core#TIMER_MASK

PUB timer_clk_freq(freq): curr_freq
' Set timer source clock frequency, in Hz
'   Valid values:
'       1_60 (1/60Hz), 1, 64, 4096
'   Any other value polls the chip and returns the current setting
    curr_freq := 0
    readreg(core#CTRL_TIMER, 1, @curr_freq)
    case freq
        1_60, 1, 64, 4096:
            freq := lookdownz(freq: 4096, 64, 1, 1_60)
        other:
            curr_freq &= core#TD_BITS
            return lookupz(curr_freq: 4096, 64, 1, 1_60)

    freq := ((curr_freq & core#TD_MASK) | freq)
    writereg(core#CTRL_TIMER, 1, @freq)

PUB timer_enabled(state): curr_state
' Enable timer
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL_TIMER, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#TE
        other:
            return ((curr_state >> core#TE) & 1) == 1

    if (state == 0)                             ' If disabling the timer,
        timer_clk_freq(1_60)                    ' set freq to 1/60Hz for
                                                ' lowest power usage
    state := ((curr_state & core#TE_MASK) | state)
    writereg(core#CTRL_TIMER, 1, @state)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from device into ptr_buff
    case reg_nr                                 ' Validate reg
        $00..$0f:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr

            i2c.start{}                         ' Send reg to read
            i2c.wrblock_lsbf(@cmd_pkt, 2)

            i2c.start{}                         ' read it
            i2c.write(SLAVE_RD)
            i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes from ptr_buff to device
    case reg_nr
        $00..$0f:                               ' Validate reg
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr

            i2c.start{}                         ' Send reg to write
            i2c.wrblock_lsbf(@cmd_pkt, 2)

            i2c.wrblock_lsbf(ptr_buff, nr_bytes)' write it
            i2c.stop{}
        other:
            return


DAT
{
Copyright 2022 Jesse Burt

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

