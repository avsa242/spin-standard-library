{
    --------------------------------------------
    Filename: sensor.baro.mpl3115a2.spin
    Author: Jesse Burt
    Description: Driver for MPL3115A2 Pressure sensor with altimetry
    Copyright (c) 2022
    Started Feb 01, 2021
    Updated Nov 26, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#include "sensor.pressure.common.spinh"
#include "sensor.temp.common.spinh"

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

' Operating modes
    SINGLE          = 0
    CONT            = 1

' Barometer/altitude modes
    BARO            = 0
    ALT             = 1

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef MPL3115A2_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.mpl3115a2"                  ' hw-specific low-level const's
    time: "time"                                ' basic timing functions
    u64 : "math.unsigned64"                     ' 64-bit unsigned int math

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if (lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and I2C_HZ =< core#I2C_MAX_FREQ)
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            if (i2c.present(SLAVE_WR))          ' test device bus presence
                if (dev_id{} == core#DEVID_RESP)' validate device
                    return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}

PUB defaults{}
' Set factory defaults
    reset{}

PUB preset_active{}
' Like Defaults(), but
'   * continuous sensor measurement
    reset{}
    opmode(CONT)

PUB alt_baro_mode(mode): curr_mode | opmd_orig
' Set sensor to altimeter or barometer mode
'   Valid values:
'       BARO (0): Sensor outputs barometric pressure data
'       ALT (1): Sensor outputs altitude data
    curr_mode := 0
    readreg(core#CTRL_REG1, 1, @curr_mode)
    case mode
        BARO, ALT:
            mode <<= core#ALT
        other:
            return ((curr_mode >> core#ALT) & 1)

    opmd_orig := (curr_mode & 1)                ' get current opmode
    ' must be in standby/SINGLE mode to set certain bits in this reg, so
    '   clear the opmode bit
    mode := ((curr_mode & core#ALT_MASK & core#SBYB_MASK) | mode)
    writereg(core#CTRL_REG1, 1, @mode)

    if (opmd_orig == CONT)                      ' restore opmode, if it
        opmode(opmd_orig)                       ' was CONT, previously

PUB alt_bias(offs): curr_offs
' Get altitude bias/offset
'   Returns: meters
    curr_offs := 0
    readreg(core#OFF_H, 1, @curr_offs)
    return ~curr_offs                           ' extend sign

PUB alt_data{}: alt_adc
' Read altimeter data
'   NOTE: This is valid as altitude data _only_ if alt_baro_mode() is set to ALT (1)
    alt_adc := 0
    readreg(core#OUT_P_MSB, 3, @alt_adc)

PUB alt_set_bias(offs)
' Set altitude bias/offset, in meters
'   Valid values: -128..127
    offs := (-128 #> offs <# 127)               ' LSB = 1m
    writereg(core#OFF_H, 1, @offs)

PUB altitude{}: alt_cm
' Read altitude, in centimeters
'   NOTE: This is valid as altitude data _only_ if alt_baro_mode() is set to ALT (1)
    return alt_word2cm(alt_data{})

PUB alt_word2cm(alt_adc): alt_cm
' Convert altitude word to altitude, in centimeters
    return u64.multdiv(alt_adc, 100_00, 65536)

PUB dev_id{}: id
' Read device identification
'   Returns: $C4
    readreg(core#WHO_AM_I, 1, @id)

PUB measure{} | tmp, meas
' Perform measurement
    tmp := 0
    readreg(core#CTRL_REG1, 1, @tmp)
    case opmode(-2)
        SINGLE:
            tmp |= (1 << core#OST)              ' bit auto-clears in SINGLE
            writereg(core#CTRL_REG1, 1, @tmp)   '   mode
        CONT:
            tmp |= (1 << core#OST)
            writereg(core#CTRL_REG1, 1, @tmp)
            tmp &= core#OST_MASK                ' bit doesn't auto-clear in
            writereg(core#CTRL_REG1, 1, @tmp)   '   CONT mode; do it manually

PUB opmode(mode): curr_mode
' Set operating mode
'   Valid values:
'       SINGLE (0): Single-shot/standby
'       CONT (1): Continuous measurement
    curr_mode := 0
    readreg(core#CTRL_REG1, 1, @curr_mode)
    case mode
        SINGLE, CONT:
        other:
            return (curr_mode & 1)

    mode := ((curr_mode & core#SBYB_MASK) | mode)
    writereg(core#CTRL_REG1, 1, @mode)

PUB oversampling(ratio): curr_ratio | opmd_orig
' Set output data ratio
'   Valid values: 1, 2, 4, 8, 16, 32, 64, 128
'   Any other value polls the chip and returns the current setting
    curr_ratio := 0
    readreg(core#CTRL_REG1, 1, @curr_ratio)
    case ratio
        1, 2, 4, 8, 16, 32, 64, 128:
            ratio := lookdownz(ratio: 1, 2, 4, 8, 16, 32, 64, 128) << core#OS
        other:
            curr_ratio := (curr_ratio >> core#OS) & core#OS_BITS
            return lookupz(curr_ratio: 1, 2, 4, 8, 16, 32, 64, 128)

    opmd_orig := (curr_ratio & 1)               ' get current opmode
    ' must be in standby/SINGLE mode to set certain bits in this reg, so
    '   clear the opmode bit
    ratio := ((curr_ratio & core#OS_MASK & core#SBYB_MASK) | ratio)
    writereg(core#CTRL_REG1, 1, @ratio)
    if opmd_orig == CONT                        ' restore opmode, if it
        opmode(opmd_orig)                       ' was CONT, previously

PUB press_bias{}: offs
' Get pressure bias/offset
'   Returns: Pascals
    offs := 0
    readreg(core#OFF_P, 1, @offs)
    return (~offs * 4)                          ' extend sign

PUB press_data{}: press_adc
' Read pressure data
'   Returns: s20 (Q18.2 fixed-point)
'   NOTE: This is valid as pressure data _only_ if alt_baro_mode() is
'       set to BARO (0)
    press_adc := 0
    readreg(core#OUT_P_MSB, 3, @press_adc)

PUB press_data_rdy{}: flag
' dummy method
    return true

PUB press_set_bias(offs)
' Set pressure bias/offset, in Pascals
'   Valid values: -512..508 (clamped to range)
    offs := (-512 #> offs <# 508) / 4           ' LSB = 4Pa
    writereg(core#OFF_P, 1, @offs)

PUB press_word2pa(p_word): p_pa
' Convert pressure ADC word to pressure in Pascals
    return ((p_word * 100) / 640)

PUB reset{} | tmp
' Reset the device
    tmp := (1 << core#RST)
    writereg(core#CTRL_REG1, 1, @tmp)
    time.usleep(core#T_POR)

PUB sea_lvl_press{}: curr_press
' Get sea-level pressure for altitude calculations
'   Returns: Pascals
    curr_press := 0
    readreg(core#BAR_IN_MSB, 2, @curr_press)
    return curr_press << 1

PUB sea_lvl_set_press(press)
' Set sea-level pressure for altitude calculations, in Pascals
'   Valid values: 0..131_070 (clamped to range)
    press := (0 #> press <# 131_070) >> 1       ' LSB = 2Pa
    writereg(core#BAR_IN_MSB, 2, @press)

PUB temp_bias{}: curr_offs
' Get temperature bias/offset
'   Returns: ten-thousandths of a degree C
    curr_offs := 0
    readreg(core#OFF_T, 1, @curr_offs)
    return (~curr_offs * 0_0625)                ' extend sign

PUB temp_data{}: temp_adc
' Read temperature data
'   Returns: s12 (Q8.4 fixed-point)
    temp_adc := 0
    readreg(core#OUT_T_MSB, 2, @temp_adc)

PUB temp_set_bias(offs)
' Set temperature bias/offset, in ten-thousandths of a degree C
    offs := (-8_0000 #> offs <# 7_9375) / 0_0625' LSB = 0.0625C
    writereg(core#OFF_T, 1, @offs)

PUB temp_word2deg(temp_word): temp
' Calculate temperature in degrees Celsius, given ADC word
    ' extend sign, chop off reserved LSBs, scale up to hundredths
    '   divide down to scale to degrees C
    temp := (((~~temp_word) ~> 4) * 100) / 16
    case _temp_scale
        C:
            return temp
        F:
            return ((temp * 9) / 5) + 32_00
        other:
            return FALSE

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        core#STATUS..core#OFF_H:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.start{}
            i2c.wr_byte(SLAVE_RD)

            ' write MSByte to LSByte
            i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:                                  ' invalid reg_nr
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        core#F_SETUP, core#PT_DATA_CFG..core#OFF_H:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)

            ' write MSByte to LSByte
            i2c.wrblock_msbf(ptr_buff, nr_bytes)
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

