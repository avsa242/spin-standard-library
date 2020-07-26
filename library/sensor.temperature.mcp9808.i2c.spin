{
    --------------------------------------------
    Filename: sensor.temperature.mcp9808.i2c.spin2
    Author: Jesse Burt
    Description: Driver for Microchip MCP9808 temperature sensors
    Copyright (c) 2020
    Started Jul 26, 2020
    Updated Jul 26, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

' Temperature scales
    C               = 0
    F               = 1

' Interrupt active states
    LOW             = 0
    HIGH            = 1

' Interrupt modes
    COMP            = 0
    INT             = 1

VAR

    byte _temp_scale

OBJ

    i2c : "com.i2c"                                                 ' PASM I2C Driver
    core: "core.con.mcp9808.spin"
    time: "time"

PUB Null{}
''This is not a top-level object

PUB Start(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)        ' I2C object started?
                time.msleep (1)
                if i2c.present (SLAVE_WR)                           ' Response from device?
                    if deviceid{} == core#DEVID_RESP
                        return okay

    return FALSE                                                    ' If we got here, something went wrong

PUB Stop{}

    i2c.terminate

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
    readreg(core#MFR_ID, 2, @id.word[1])
    readreg(core#DEV_ID, 2, @id.word[0])

PUB IntActiveState(state): curr_state
' Set interrupt active state
'   Valid values: *LOW (0), HIGH (1)
'   Any other value polls the chip and returns the current setting
'   NOTE: LOW (Active-low) requires the use of a pull-up resistor
    curr_state := $00
    readreg(core#CONFIG, 2, @curr_state)
    case state
        LOW, HIGH:
            state <<= core#FLD_ALTPOL
        OTHER:
            return (curr_state >> core#FLD_ALTPOL) & 1

    curr_state &= core#MASK_ALTPOL
    curr_state := (curr_state | state) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_state)

PUB IntClear{} | tmp
' Clear interrupt
    readreg(core#CONFIG, 2, @tmp)
    tmp |= (1 << core#FLD_INTCLR)
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
    curr_setting := $00
    readreg(core#CONFIG, 2, @curr_setting)
    case deg
        0, 1_5, 3_0, 6_0:
            deg := lookdownz(deg: 0, 1_5, 3_0, 6_0) << core#FLD_HYST
        OTHER:
            curr_setting := (curr_setting >> core#FLD_HYST) & core#BITS_HYST
            return lookupz(curr_setting: 0, 1_5, 3_0, 6_0)

    curr_setting &= core#MASK_HYST
    curr_setting := (curr_setting | deg) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_setting)

PUB IntMask(mask): curr_mask
' Set interrupt mask
'   Valid values:
'      *0: Interrupts asserted for Upper, Lower, and Critical thresholds
'       1: Interrupts asserted only for Critical threshold
'   Any other value polls the chip and returns the current setting
    curr_mask := $00
    readreg(core#CONFIG, 2, @curr_mask)
    case mask
        0, 1:
            mask <<= core#FLD_ALTSEL
        OTHER:
            return (curr_mask >> core#FLD_ALTSEL) & 1

    curr_mask &= core#MASK_ALTSEL
    curr_mask := (curr_mask | mask) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_mask)

PUB IntMode(mode): curr_mode
' Set interrupt mode
'   Valid values:
'      *COMP (0): Comparator output
'       INT (1): Interrupt output
'   Any other value polls the chip and returns the current setting
    curr_mode := $00
    readreg(core#CONFIG, 2, @curr_mode)
    case mode
        COMP, INT:
        OTHER:
            return curr_mode & 1

    curr_mode &= core#MASK_ALTMOD
    curr_mode := (curr_mode | mode) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_mode)

PUB IntsEnabled(enable): curr_state
' Enable interrupts
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := $00
    readreg(core#CONFIG, 2, @curr_state)
    case ||enable
        0, 1:
            enable := ||(enable) << core#FLD_ALTCNT
        OTHER:
            return ((curr_state >> core#FLD_ALTCNT) & 1) == 1

    curr_state &= core#MASK_ALTCNT
    curr_state := (curr_state | enable) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_state)

PUB IntTempCritThresh(level): curr_lvl
' Set critical (high) temperature interrupt threshold, in hundredths of a degree Celsius
'   Valid values: -256_00..255_94 (-256.00C .. 255.94C)
'   Any other value polls the chip and returns the current setting
    case level
        -256_00..255_94:
            level := calctempword(level)
            writereg(core#ALERT_CRIT, 2, @level)
        OTHER:
            readreg(core#ALERT_CRIT, 2, @curr_lvl)
            return calctemp(curr_lvl)

PUB IntTempHiThresh(level): curr_lvl
' Set high temperature interrupt threshold, in hundredths of a degree Celsius
'   Valid values: -256_00..255_94 (-256.00C .. 255.94C)
'   Any other value polls the chip and returns the current setting
    case level
        -256_00..255_94:
            level := calctempword(level)
            writereg(core#ALERT_UPPER, 2, @level)
        OTHER:
            readreg(core#ALERT_UPPER, 2, @curr_lvl)
            return calctemp(curr_lvl)

PUB IntTempLoThresh(level): curr_lvl
' Set low temperature interrupt threshold, in hundredths of a degree Celsius
'   Valid values: -256_00..255_94 (-256.00C .. 255.94C)
'   Any other value polls the chip and returns the current setting
    case level
        -256_00..255_94:
            level := calctempword(level)
            writereg(core#ALERT_LOWER, 2, @level)
        OTHER:
            readreg(core#ALERT_LOWER, 2, @curr_lvl)
            return calctemp(curr_lvl)

PUB Powered(enabled): curr_state
' Enable sensor power
'   Valid values: *TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := $00
    readreg(core#CONFIG, 2, @curr_state)
    case ||(enabled)
        0, 1:
            enabled := ||(enabled)
            enabled := (enabled ^ 1) << core#FLD_SHDN
        OTHER:
            return (((curr_state >> core#FLD_SHDN) & %1) ^ 1) == 1

    curr_state &= core#MASK_SHDN
    curr_state := (curr_state | enabled) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_state)

PUB Temperature{}: temp
' Current Temperature, in hundredths of a degree
'   Returns: Integer
'   (e.g., 2105 is equivalent to 21.05 deg C)
    temp := $00
    readreg(core#TEMP, 2, @temp)
    temp := calcTemp(temp)

    if _temp_scale == F
        return ((temp * 9_00) / 5_00) + 32_00
    else
        return temp

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
        OTHER:
            curr_res := $00
            readreg(core#RESOLUTION, 1, @curr_res)
            return lookupz(curr_res: 0_5000, 0_2500, 0_1250, 0_0625)

    writereg(core#RESOLUTION, 1, @deg_c)

PUB TempScale(scale): curr_scale
' Set temperature scale used by Temperature method
'   Valid values:
'      *C (0): Celsius
'       F (1): Fahrenheit
'   Any other value returns the current setting
    case scale
        C, F:
            _temp_scale := scale
        OTHER:
            return _temp_scale

PRI calcTemp(temp_word): temp_c | whole, part
' Calculate temperature in degrees Celsius, given ADC word
    temp_word := (temp_word << 19) ~> 19                    ' Extend sign bit (#13)
    whole := (temp_word / 16) * 100                         ' Scale up to hundredths
    part := ((temp_word // 16) * 0_0625) / 100
    return whole+part

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

PRI readReg(reg_nr, nr_bytes, buff_addr) | cmd_packet, tmp
' Read num_bytes from the slave device into the address stored in buff_addr
    case reg_nr                                                     ' Basic register validation
        $00..$08:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg_nr & $0F
            i2c.start{}                                             ' S
            repeat tmp from 0 to 1
                i2c.write (cmd_packet.byte[tmp])                    ' SL|W, reg_nr

            i2c.start{}                                             ' Rs
            i2c.write (SLAVE_RD)                                    ' SL|R
            repeat tmp from nr_bytes-1 to 0
                byte[buff_addr][tmp] := i2c.read(tmp == 0)          ' R 0..n, NAK last byte to signal complete
            i2c.stop{}                                              ' P
        OTHER:
            return

PRI writeReg(reg_nr, nr_bytes, buff_addr) | cmd_packet, tmp
' Write num_bytes to the slave device from the address stored in buff_addr
    case reg_nr                                                     ' Basic register validation
        $01..$04, $08:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg_nr & $0F
            i2c.start{}                                             ' S
            repeat tmp from 0 to 1
                i2c.write(cmd_packet.byte[tmp])                     ' SL|W, reg_nr

            repeat tmp from nr_bytes-1 to 0
                i2c.write (byte[buff_addr][tmp])                    ' W 0..n
            i2c.stop{}                                              ' P
        OTHER:
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
