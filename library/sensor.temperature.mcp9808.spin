{
    --------------------------------------------
    Filename: sensor.temperature.mcp9808.i2c.spin
    Author: Jesse Burt
    Description: Driver for Microchip MCP9808 temperature sensors
    Copyright (c) 2022
    Started Jul 26, 2020
    Updated May 25, 2022
    See end of file for terms of use.
    --------------------------------------------
}
{ pull in methods common to all Temp drivers }
#include "sensor.temp.common.spinh"

CON

    { I2C }
    SLAVE_WR    = core#SLAVE_ADDR
    SLAVE_RD    = core#SLAVE_ADDR | 1
    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000

' Interrupt active states
    LOW         = 0
    HIGH        = 1

' Interrupt modes
    COMP        = 0
    INT         = 1

VAR

    byte _addr_bits

OBJ

#ifdef MCP9808_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
#define MCP9808_I2C
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.mcp9808"                    ' HW-specific constants
    time: "time"                                ' timekeeping methods

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins, default slave address and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, %000)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom I/O pins and I2C bus speed
    ' validate pins, bus freq, and optional slave address bits:
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ and lookdown(ADDR_BITS: %000..%111)
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            _addr_bits := ADDR_BITS << 1
            time.usleep(core#T_POR)
            ' check device bus presence:
            if i2c.present(SLAVE_WR | _addr_bits)
                if deviceid{} == core#DEVID_RESP
                    return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB Defaults{}
' Factory defaults
    tempscale(C)
    powered(TRUE)
    tempres(0_0625)

PUB DeviceID{}: id
' Read device identification
'   Returns:
'       Manufacturer ID: $0054 (MSW)
'       Revision: $0400 (LSW)
    readreg(core#MFR_ID, 2, @id.word[1])        ' 9808 doesn't support seq. R/W
    readreg(core#DEV_ID, 2, @id.word[0])        '   so do discrete reads

PUB IntActiveState(state): curr_state
' Set interrupt active state
'   Valid values: *LOW (0), HIGH (1)
'   Any other value polls the chip and returns the current setting
'   NOTE: LOW (Active-low) requires the use of a pull-up resistor
    curr_state := 0
    readreg(core#CONFIG, 2, @curr_state)
    case state
        LOW, HIGH:
            state <<= core#ALTPOL
        other:
            return (curr_state >> core#ALTPOL) & 1

    state := ((curr_state & core#ALTPOL_MASK) | state)
    writereg(core#CONFIG, 2, @state)

PUB IntClear{} | tmp
' Clear interrupt
    readreg(core#CONFIG, 2, @tmp)
    tmp |= (1 << core#INTCLR)
    writereg(core#CONFIG, 2, @tmp)

PUB Interrupt{}: active_ints
' Flag indicating interrupt(s) asserted
'   Returns: 3-bit mask, [2..0]
'       2: Temperature at or above Critical threshold
'       1: Temperature above high threshold
'       0: Temperature below low threshold
    readreg(core#TEMP, 2, @active_ints)
    active_ints >>= 13

PUB IntHysteresis(deg): curr_setting
' Set interrupt Upper and Lower threshold hysteresis, in degrees Celsius
'   Valid values:
'       Value   represents
'       0       0
'       1_5     1.5C
'       3_0     3.0C
'       6_0     6.0C
'   Any other value polls the chip and returns the current setting
    curr_setting := 0
    readreg(core#CONFIG, 2, @curr_setting)
    case deg
        0, 1_5, 3_0, 6_0:
            deg := lookdownz(deg: 0, 1_5, 3_0, 6_0) << core#HYST
        other:
            curr_setting := (curr_setting >> core#HYST) & core#HYST_BITS
            return lookupz(curr_setting: 0, 1_5, 3_0, 6_0)

    deg := ((curr_setting & core#HYST_MASK) | deg)
    writereg(core#CONFIG, 2, @deg)

PUB IntMask(mask): curr_mask
' Set interrupt mask
'   Valid values:
'      *0: Interrupts asserted for Upper, Lower, and Critical thresholds
'       1: Interrupts asserted only for Critical threshold
'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readreg(core#CONFIG, 2, @curr_mask)
    case mask
        0, 1:
            mask <<= core#ALTSEL
        other:
            return ((curr_mask >> core#ALTSEL) & 1)

    mask := ((curr_mask & core#ALTSEL_MASK) | mask)
    writereg(core#CONFIG, 2, @mask)

PUB IntMode(mode): curr_mode
' Set interrupt mode
'   Valid values:
'      *COMP (0): Comparator output
'       INT (1): Interrupt output
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#CONFIG, 2, @curr_mode)
    case mode
        COMP, INT:
        other:
            return curr_mode & 1

    mode := ((curr_mode & core#ALTMOD_MASK) | mode)
    writereg(core#CONFIG, 2, @mode)

PUB IntsEnabled(state): curr_state
' Enable interrupts
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CONFIG, 2, @curr_state)
    case ||state
        0, 1:
            state := ||(state) << core#ALTCNT
        other:
            return (((curr_state >> core#ALTCNT) & 1) == 1)

    state := ((curr_state & core#ALTCNT_MASK) | state)
    writereg(core#CONFIG, 2, @state)

PUB IntTempCritThresh(level): curr_lvl
' Set critical (high) temperature interrupt threshold, in hundredths of a degree Celsius
'   Valid values: -256_00..255_94 (-256.00C .. 255.94C)
'   Any other value polls the chip and returns the current setting
    case level
        -256_00..255_94:
            level := calctempword(level)
            writereg(core#ALERT_CRIT, 2, @level)
        other:
            readreg(core#ALERT_CRIT, 2, @curr_lvl)
            return tempword2deg(curr_lvl)

PUB IntTempHiThresh(level): curr_lvl
' Set high temperature interrupt threshold, in hundredths of a degree Celsius
'   Valid values: -256_00..255_94 (-256.00C .. 255.94C)
'   Any other value polls the chip and returns the current setting
    case level
        -256_00..255_94:
            level := calctempword(level)
            writereg(core#ALERT_UPPER, 2, @level)
        other:
            readreg(core#ALERT_UPPER, 2, @curr_lvl)
            return tempword2deg(curr_lvl)

PUB IntTempLoThresh(level): curr_lvl
' Set low temperature interrupt threshold, in hundredths of a degree Celsius
'   Valid values: -256_00..255_94 (-256.00C .. 255.94C)
'   Any other value polls the chip and returns the current setting
    case level
        -256_00..255_94:
            level := calctempword(level)
            writereg(core#ALERT_LOWER, 2, @level)
        other:
            readreg(core#ALERT_LOWER, 2, @curr_lvl)
            return tempword2deg(curr_lvl)

PUB Powered(state): curr_state
' Enable sensor power
'   Valid values: *TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CONFIG, 2, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) ^ 1) << core#SHDN
        other:
            return ((((curr_state >> core#SHDN) & 1) ^ 1) == 1)

    state := ((curr_state & core#SHDN_MASK) | state)
    writereg(core#CONFIG, 2, @state)

PUB TempData{}: temp_adc
' Read temperature ADC data
'   Returns: s13
    temp_adc := 0
    readreg(core#TEMP, 2, @temp_adc)

PUB TempRes(deg_c): curr_res
' Set temperature resolution, in degrees Celsius (fractional)
'   Valid values:
'       Value   represents      Conversion time
'      *0_0625  0.0625C         (250ms)
'       0_1250  0.125C          (130ms)
'       0_2500  0.25C           (65ms)
'       0_5000  0.5C            (30ms)
'   Any other value polls the chip and returns the current setting
    case deg_c
        0_0625, 0_1250, 0_2500, 0_5000:
            deg_c := lookdownz(deg_c: 0_5000, 0_2500, 0_1250, 0_0625)
            writereg(core#RESOLUTION, 1, @deg_c)
        other:
            curr_res := 0
            readreg(core#RESOLUTION, 1, @curr_res)
            return lookupz(curr_res: 0_5000, 0_2500, 0_1250, 0_0625)

PUB TempWord2Deg(temp_word): temp | whole, part
' Convert temperature ADC word to temperature
'   Returns: temperature, in hundredths of a degree, in chosen scale
    temp_word := (temp_word << 19) ~> 19        ' Extend sign bit (#12)
    whole := (temp_word / 16) * 100             ' Scale up to hundredths
    part := ((temp_word // 16) * 0_0625) / 100
    temp := (whole + part)
    case _temp_scale
        C:
            return temp
        F:
            return ((temp * 9_00) / 5_00) + 32_00
        other:
            return FALSE

PRI calcTempWord(temp_c): temp_word
' Calculate word, given temperature in degrees Celsius
'   Returns: 11-bit, two's complement word (0.25C resolution)
    temp_word := 0
    if temp_c < 0
        temp_word := temp_c + 256_00
    else
        temp_word := temp_c

    temp_word := ((temp_word * 4) << 2) / 100

    if temp_c < 0
        temp_word |= constant(1 << 12)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the slave device into ptr_buff
    case reg_nr                                 ' validate reg number
        $00..$08:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)

            i2c.start{}
            i2c.write(SLAVE_RD | _addr_bits)
            i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the slave device from ptr_buff
    case reg_nr
        $01..$04, $08:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr & $0F
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_msbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return


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

