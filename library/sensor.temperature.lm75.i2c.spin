{
    --------------------------------------------
    Filename: sensor.temperature.lm75.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Maxim LM75
        Digital Temperature Sensor
    Copyright (c) 2021
    Started May 19, 2019
    Updated Aug 20, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 100_000
    DEF_ADDR            = %000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

' Overtemperature alarm (OS) output pin active state
    ACTIVE_LO           = 0
    ACTIVE_HI           = 1

' Temperature scale
    C                   = 0
    F                   = 1

VAR

    byte _temp_scale
    byte _addr

OBJ

#ifdef LM75_SPIN
    i2c : "tiny.com.i2c"                        ' SPIN I2C engine (~30kHz)
#elseifdef LM75_PASM
    i2c : "com.i2c"                             ' PASM I2C engine (~400kHz)
#else
#error "One of LM75_SPIN or LM75_PASM must be defined"
#endif
    core: "core.con.lm75"                       ' HW-specific constants
    time: "time"                                ' timekeeping methods

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins, 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, DEF_ADDR)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ and lookdown(ADDR_BITS: %000..%111)
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            _addr := (ADDR_BITS << 1)
            time.msleep(1)                      ' wait for device startup
            if i2c.present(SLAVE_WR | _addr)    ' check device bus presence
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB Defaults{}
' Factory default settings
    intslatched(FALSE)
    intthresh(80_00)
    intclearthresh(75_00)
    intactivestate(ACTIVE_LO)

PUB IntActiveState(state): curr_state
' Interrupt pin active state (OS)
'   Valid values:
'       ACTIVE_LO (0): Pin is active low
'       ACITVE_HI (1): Pin is active high
'   Any other value polls the chip and returns the current setting
'   NOTE: The OS pin is open-drain, under all conditions, and requires
'       a pull-up resistor to output a high voltage.
    readreg(core#CONFIG, 1, @curr_state)
    case state
        ACTIVE_LO, ACTIVE_HI:
            state := state << core#OS_POL
        other:
            return ((curr_state >> core#OS_POL) & 1)

    state := ((curr_state & core#OS_POL_MASK) | state) & core#CONFIG_MASK
    writereg(core#CONFIG, 1, @state)

PUB IntClearThresh(thr): curr_thr
' Interrupt clear threshold (hysteresis), in hundredths of a degree
'   Valid values:
'       TempScale() == C: -55_00..125_00 (default: 80_00)
'       TempScale() == F: -67_00..257_00 (default: 176_00)
'   Any other value polls the chip and returns the current setting
    case tempscale(-2)
        C:
            case thr
                -55_00..125_00:
                    thr := temp2adc(thr)
                    writereg(core#T_HYST, 2, @thr)
                other:
                    curr_thr := 0
                    readreg(core#T_HYST, 2, @curr_thr)
                    return tempword2deg(curr_thr)
        F:
            case thr
                -67_00..257_00:
                    thr := temp2adc(thr)
                    writereg(core#T_HYST, 2, @thr)
                other:
                    curr_thr := 0
                    readreg(core#T_HYST, 2, @curr_thr)
                    return tempword2deg(curr_thr)

PUB IntsLatched(state): curr_state
' Latch interrupts asserted by the sensor
'   Valid values:
'       FALSE (0): Interrupt cleared when temp drops below threshold
'       TRUE (-1 or 1): Interrupt cleared only after reading temperature
'   Any other value polls the chip and returns the current setting
    readreg(core#CONFIG, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#COMP_INT
        other:
            return ((curr_state >> core#COMP_INT) & 1)

    state := ((curr_state & core#COMP_INT_MASK) | state) & core#CONFIG_MASK
    writereg(core#CONFIG, 1, @state)

PUB IntPersistence(thr): curr_thr
' Number of faults necessary to assert alarm
'   Valid values:
'       1, 2, 4, 6
'   Any other value polls the chip and returns the current setting
'   NOTE: The faults must occur consecutively (prevents false positives in noisy environments)
    readreg(core#CONFIG, 1, @curr_thr)
    case thr
        1, 2, 4, 6:
            thr := lookdownz(thr: 1, 2, 4, 6)
        other:
            curr_thr := (curr_thr >> core#FAULTQ) & core#FAULTQ_BITS
            return lookupz(curr_thr: 1, 2, 4, 6)

    thr := ((curr_thr & core#FAULTQ_MASK) | thr) & core#CONFIG_MASK
    writereg(core#CONFIG, 1, @thr)

PUB IntThresh(thr): curr_thr
' Interrupt threshold (overtemperature), in hundredths of a degree Celsius
'   Valid values:
'       TempScale() == C: -55_00..125_00 (default: 80_00)
'       TempScale() == F: -67_00..257_00 (default: 176_00)
'   Any other value polls the chip and returns the current setting
    case tempscale(-2)
        C:
            case thr
                -55_00..125_00:
                    thr := temp2adc(thr)
                    writereg(core#T_OS, 2, @thr)
                other:
                    curr_thr := 0
                    readreg(core#T_OS, 2, @curr_thr)
                    return tempword2deg(curr_thr)
        F:
            case thr
                -67_00..257_00:
                    thr := temp2adc(thr)
                    writereg(core#T_OS, 2, @thr)
                other:
                    curr_thr := 0
                    readreg(core#T_OS, 2, @curr_thr)
                    return tempword2deg(curr_thr)

PUB Powered(state): curr_state
' Enable sensor power
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
'   NOTE: Current consumption when shutdown is approx 1uA
    readreg(core#CONFIG, 1, @curr_state)
    case ||(state)
        0, 1:
            ' bit is actually a "shutdown" bit, so its logic is inverted
            ' (i.e., 0 = powered on, 1 = shutdown), so flip the bit
            state := ||(state) ^ 1
        other:
            return (curr_state & 1) == 0

    state := ((curr_state & core#SHUTDOWN_MASK) | state)
    writereg(core#CONFIG, 1, @state)

PUB TempData{}: temp_raw
' Temperature ADC data
    temp_raw := 0
    readreg(core#TEMP, 2, @temp_raw)

PUB Temperature{}: temp_cal
' Temperature, in hundredths of a degree, in chosen scale
    return tempword2deg(tempdata{})

PUB TempScale(scale): curr_scl
' Set temperature scale used by Temperature method
'   Valid values:
'      *C (0): Celsius
'       F (1): Fahrenheit
'   Any other value returns the current setting
    case scale
        C, F:
            _temp_scale := scale
        other:
            return _temp_scale

PUB TempWord2Deg(temp_word): temp
' Convert temperature ADC word to temperature
'   Returns: temperature, in hundredths of a degree, in chosen scale
    temp := (temp_word << 16 ~> 23)             ' Extend sign, then scale down
    temp *= 50                                  ' LSB = 0.5deg C
    case _temp_scale
        C:
            return
        F:
            return ((temp * 90) / 50) + 32_00
        other:
            return FALSE

PRI temp2adc(temp_cal): temp_word
' Calculate ADC word, using temperature in hundredths of a degree
'   Returns: ADC word, 16bit, left-justified
    case _temp_scale                            ' convert to Celsius, first
        C:
        F:
            temp_cal := ((temp_cal - 32_00) * 50) / 90
        other:
            return FALSE

    temp_word := (temp_cal / 50) << 7
    return ~~temp_word

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from device into ptr_buff
    cmd_pkt.byte[0] := SLAVE_WR | _addr
    cmd_pkt.byte[1] := reg_nr

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start{}
    i2c.write(SLAVE_RD | _addr)
    i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Writes nr_bytes from ptr_buff to device
    cmd_pkt.byte[0] := SLAVE_WR | _addr
    cmd_pkt.byte[1] := reg_nr

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.wrblock_msbf(ptr_buff, nr_bytes)
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
