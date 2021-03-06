{
    --------------------------------------------
    Filename: sensor.power.ina260.i2c.spin
    Author: Jesse Burt
    Description: Driver for the TI INA260 Precision Current and Power Monitor IC
    Copyright (c) 2021
    Started Nov 13, 2019
    Updated Jan 9, 2021
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

' Operating modes
    POWERDN         = %000
    CURR_TRIGD      = %001
    VOLT_TRIGD      = %010
    CURR_VOLT_TRIGD = %011
    POWERDN2        = %100
    CURR_CONT       = %101
    VOLT_CONT       = %110
    CURR_VOLT_CONT  = %111

' Interrupt/alert pin sources
    INT_CONV_READY  = 1
    INT_POWER_HI    = 2
    INT_BUSVOLT_LO  = 4
    INT_BUSVOLT_HI  = 8
    INT_CURRENT_LO  = 16
    INT_CURRENT_HI  = 32

' Interrupt/alert pin level/polarity
    INTLVL_LO       = 0
    INTLVL_HI       = 1

VAR


OBJ

    i2c : "com.i2c"
    core: "core.con.ina260"
    time: "time"

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins and 100kHz
    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
                time.msleep(1)
                if i2c.present(SLAVE_WR)        ' test device bus presence
                    reset{}
                    if deviceid{} == core#DEVID_RESP
                    return okay

    return FALSE                                ' something above failed

PUB Stop{}

    i2c.terminate{}

PUB BusVoltage{}: v
' Read the measured bus voltage, in microvolts
'   NOTE: If averaging is enabled, this will return the averaged value
'   NOTE: Full-scale range is 40_960_000uV
    v := 0
    readreg(core#BUS_VOLTAGE, 2, @v)
    return (v & $7fff) * 1_250

PUB ConversionReady{}: flag
' Flag indicating data from the last conversion is available for reading
'   Returns: TRUE (-1) if data available, FALSE (0) otherwise
    readreg(core#ENABLE, 2, @flag)
    return (((flag >> core#CVRF) & 1) == 1)

PUB Current{}: a
' Read the measured current, in microamperes
'   NOTE: If averaging is enabled, this will return the averaged value
    a := 0
    readreg(core#CURRENT, 2, @a)
    return (~~a) * 1_250

PUB CurrentConvTime(ctime): curr_set
' Set conversion time for shunt current measurement, in microseconds
'   Valid values: 140, 204, 332, 588, *1100, 2116, 4156, 8244
'   Any other value polls the chip and returns the current setting
    curr_set := 0
    readreg(core#CONFIG, 2, @curr_set)
    case ctime
        140, 204, 332, 588, 1100, 2116, 4156, 8244:
            ctime := lookdownz(ctime: 140, 204, 332, 588, 1100, 2116, 4156, 8244) << core#ISHCT
        other:
            curr_set := (curr_set >> core#ISHCT) & core#ISHCT_BITS
            return lookupz(curr_set: 140, 204, 332, 588, 1100, 2116, 4156, 8244)

    ctime := ((curr_set & core#ISHCT_MASK) | ctime) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @ctime)

PUB DeviceID{}: id
' Read device ID
'   Returns:
'       Most-significant word: Die ID
'       Least-significant word: Mfr ID
    return (dieid{} << 16) | mfrid{}

PUB DieID{}: id
' Read the Die ID from the chip
'   Returns: $2270
    id := 0
    readreg(core#DIE_ID, 2, @id)

PUB IntLevel(level): curr_lvl
' Set interrupt active level/polarity
'   Valid values:
'      *INTLVL_LO   (0) Active low
'       INTLVL_HI   (1) Active high
'   Any other value polls the chip and returns the current setting
'   NOTE: The ALERT pin is open collector
    curr_lvl := 0
    readreg(core#ENABLE, 2, @curr_lvl)
    case level
        INTLVL_LO, INTLVL_HI:
            level <<= core#APOL
        other:
            return ((curr_lvl >> core#APOL) & 1)

    level := ((curr_lvl & core#APOL_MASK) | level) & core#ENABLE_MASK
    writereg(core#ENABLE, 2, @level)

PUB IntsLatched(state): curr_state
' Enable latching of interrupts
'   Valid values:
'       TRUE (-1 or 1): Active interrupts remain asserted until cleared manually
'       FALSE (0): Active interrupts clear when the fault has been cleared
    curr_state := 0
    readreg(core#ENABLE, 2, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) & 1
        other:
            return ((curr_state & 1) == 1)

    state := ((curr_state & core#LEN_MASK) | state) & core#ENABLE_MASK
    writereg(core#ENABLE, 2, @state)

PUB IntSource(src): curr_src
' Set interrupt/alert pin assertion source
'   Valid values:
'       INT_CURRENT_HI  (32)    Over current limit
'       INT_CURRENT_LO  (16)    Under current limit
'       INT_BUSVOLT_HI  (8)     Bus voltage over-voltage
'       INT_BUSVOLT_LO  (4)     Bus voltage under-voltage
'       INT_POWER_HI    (2)     Power over-limit
'       INT_CONV_READY  (1)     Conversion ready
'       Example:
'           IntSource(INT_BUSVOLT_HI) or IntSource(8)
'               would trigger an alert when the bus voltage exceeded the set threshold
'   Any other value polls the chip and returns the current setting
    curr_src := 0
    readreg(core#ENABLE, 2, @curr_src)
    case src
        INT_CONV_READY, INT_POWER_HI, INT_BUSVOLT_LO, INT_BUSVOLT_HI,{
}       INT_CURRENT_LO, INT_CURRENT_HI:
            src <<= core#ALERTS
        other:
            return (curr_src >> core#ALERTS) & core#ALERTS_BITS

    src := ((curr_src & core#ALERTS_MASK) | src) & core#ENABLE_MASK
    writereg(core#ENABLE, 2, @src)

PUB IntThresh(thresh): curr_thr
' Set interrupt/alert threshold
'   Valid values: 0..65535
'   Any other value polls the chip and returns the current setting
    case thresh
        0..65535:
            writereg(core#ALERT_LIMIT, 2, @thresh)
        other:
            curr_thr := 0
            readreg(core#ALERT_LIMIT, 2, @curr_thr)
            return curr_thr

PUB MfrID{}: id
' Read the Manufacturer ID from the chip
'   Returns: $5449
    id := 0
    readreg(core#MFR_ID, 2, @id)

PUB OpMode(mode): curr_mode
' Set operation mode
'   Valid values:
'       POWERDN (0): Power-down/shutdown
'       CURR_TRIGD (1): Shunt current, triggered
'       VOLT_TRIGD (2): Bus voltage, triggered
'       CURR_VOLT_TRIGD (3): Shunt current and bus voltage, triggered
'       POWERDN2 (4): Power-down/shutdown
'       CURR_CONT (5): Shunt current, continuous
'       VOLT_CONT (6): Bus voltage, continuous
'      *CURR_VOLT_CONT (7): Shunt current and bus voltage, continuous
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#CONFIG, 2, @curr_mode)
    case mode
        POWERDN, CURR_TRIGD, VOLT_TRIGD, CURR_VOLT_TRIGD, POWERDN2,{
}       CURR_CONT, VOLT_CONT, CURR_VOLT_CONT:
            mode := lookdownz(mode: POWERDN, CURR_TRIGD, VOLT_TRIGD,{
}                                CURR_VOLT_TRIGD, POWERDN2, CURR_CONT,{
}                                VOLT_CONT, CURR_VOLT_CONT)
        other:
            curr_mode &= core#MODE_BITS
            return curr_mode

    mode := ((curr_mode & core#MODE_MASK) | mode) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @mode)

PUB Power{}: p
' Read the power measured by the chip, in microwatts
'   NOTE: If averaging is enabled, this will return the averaged value
'   NOTE: The maximum value returned is 419_430_000
    p := 0
    readreg(core#POWER, 2, @p)
    return (p * 10_000)

PUB PowerOverflowed{}: flag
' Flag indicating power data exceeded the maximum measurable value
'   (419_430_000uW/419.43W)
    readreg(core#ENABLE, 2, @flag)
    return (((flag >> core#OVF) & 1) == 1)

PUB Reset{} | tmp
' Reset the chip
'   NOTE: Equivalent to Power-On Reset
    tmp := 1 << core#RESET
    writereg(core#CONFIG, 2, @tmp)

PUB SamplesAveraged(samples): curr_smp
' Set number of samples used for averaging measurements
'   Valid values: *1, 4, 16, 64, 128, 256, 512, 1024
'   Any other value polls the chip and returns the current setting
    curr_smp := 0
    readreg(core#CONFIG, 2, @curr_smp)
    case samples
        1, 4, 16, 64, 128, 256, 512, 1024:
            samples := lookdownz(samples: 1, 4, 16, 64, 128, 256, 512,{
}                                           1024) << core#AVG
        other:
            curr_smp := (curr_smp >> core#AVG) & core#AVG_BITS
            return lookupz(curr_smp: 1, 4, 16, 64, 128, 256, 512, 1024)

    samples := ((curr_smp & core#AVG_MASK) | samples) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @samples)

PUB VoltageConvTime(ctime): curr_time
' Set conversion time for bus voltage measurement, in microseconds
'   Valid values: 140, 204, 332, 588, *1100, 2116, 4156, 8244
'   Any other value polls the chip and returns the current setting
    curr_time := 0
    readreg(core#CONFIG, 2, @curr_time)
    case ctime
        140, 204, 332, 588, 1100, 2116, 4156, 8244:
            ctime := lookdownz(ctime: 140, 204, 332, 588, 1100, 2116, 4156,{
}                                       8244) << core#VBUSCT
        other:
            curr_time := (curr_time >> core#VBUSCT) & core#VBUSCT_BITS
            return lookupz(curr_time: 140, 204, 332, 588, 1100, 2116, 4156,{
}                                       8244)

    ctime := ((curr_time & core#VBUSCT_MASK) | ctime) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @ctime)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Read nr_bytes from the slave device into ptr_buff
    case reg_nr
        $00..$03, $06, $07, $fe, $ff:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            repeat tmp from 0 to 1
                i2c.write(cmd_pkt.byte[tmp])

            i2c.start{}
            i2c.write(SLAVE_RD)
            repeat tmp from nr_bytes-1 to 0
                byte[ptr_buff][tmp] := i2c.read(tmp == 0)
            i2c.stop{}
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes from ptr_buff to the slave device
    case reg_nr
        $00:
            word[ptr_buff][0] |= core#RSVD_BITS
        $06, $07:
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    repeat tmp from 0 to 1
        i2c.write(cmd_pkt.byte[tmp])

    repeat tmp from nr_bytes-1 to 0
        i2c.write(byte[ptr_buff][tmp])
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
