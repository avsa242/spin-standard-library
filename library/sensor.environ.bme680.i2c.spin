{
    --------------------------------------------
    Filename: sensor.environ.bme680.i2c.spin
    Author: Jesse Burt
    Description: Driver for the BOSCH BME680 combination
        Temp, RH, Baro., VOC sensor
    Copyright (c) 2019
    Started May 26, 2019
    Updated May 26, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 400_000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

' Operation modes
    OPMODE_SLEEP        = 0
    OPMODE_FORCED       = 1

VAR

    long _t_fine
    byte _coeff_table[core#COEFF_1_LEN + core#COEFF_2_LEN]

OBJ

    i2c     : "com.i2c"
    core    : "core.con.bme680"
    time    : "time"
    types   : "system.types"

PUB Null
''This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                if i2c.present (SLAVE_WR)                       'Response from device?
                    if ID == core#ID_EXPECT_RESP
                        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB GasWaitTime(timer_nr, mult, time_ms) | tmp
' Set time between heater activation and gas sensor reading, in ms
'   Valid values:
'       0..63
'   NOTE: mult can be used to multiply the time by a factor of 1 (default), 4, 16 or 64
'   Any other value polls the chip and returns the current setting
    case timer_nr
        0..9:
            readRegX (core#GAS_WAIT_0 + timer_nr, 1, @tmp)
        OTHER:
            return

    case mult
        1, 4, 16, 64:
            mult := lookdownz(mult: 1, 4, 16, 64) << core#FLD_GAS_WAIT_MULT
        OTHER:
            return
{    if (time_ms > 63)
        if (time_ms // 4) or (time_ms // 16) or (time_ms // 64)
            time_ms := -1}

    case time_ms
        0..63:
{        4..252:
            time_ms := (%01 << core#FLD_GAS_WAIT_MULT) | time_ms
        16..1008:
            time_ms := (%10 << core#FLD_GAS_WAIT_MULT) | time_ms
        64..4032:
            time_ms := (%11 << core#FLD_GAS_WAIT_MULT) | time_ms}
        OTHER:
            result := tmp & core#BITS_GAS_WAIT
            tmp := (tmp >> core#FLD_GAS_WAIT_MULT) & core#BITS_GAS_WAIT_MULT
            tmp := lookupz(tmp: 1, 4, 16, 64)
            return tmp * result

    tmp := (mult | time_ms) & core#GAS_WAIT_MASK
    writeRegX (core#GAS_WAIT_0 + timer_nr, 1, @tmp)

PUB ID

    readRegX (core#ID, 1, @result)

PUB HumidityADC
' Read humidity data
'   Returns: raw humidity data, 16bit word
    readRegX (core#HUM_MSB, 2, @result)
    result.byte[3] := result.byte[0]
    result.byte[0] := result.byte[1]
    result.byte[1] := result.byte[3]
    result &= $FFFF

PUB HumidityOS(oversampling) | tmp
' Set humidity sensor oversampling factor
'   Valid values:
'       0 (effectively turns the sensor off; reading will always be $8000)
'       1, 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    readRegX (core#CTRL_HUM, 1, @tmp)
    case oversampling := lookdown(oversampling: 0, 1, 2, 4, 8, 16)
        1..6:
            oversampling := (oversampling-1) << core#FLD_OSRS_H
        OTHER:
            result := (tmp >> core#FLD_OSRS_H) & core#BITS_OSRS_H
            return lookupz(result: 0, 1, 2, 4, 8, 16)

    tmp &= core#MASK_OSRS_H
    tmp := (tmp | oversampling) & core#CTRL_HUM_MASK
    writeRegX (core#CTRL_HUM, 1, @tmp)

PUB OpMode(mode) | tmp
' Set sensor power mode
'   Valid values:
'       OPMODE_SLEEP (0): Sleep mode
'       OPMODE_FORCED (1): Forced mode (make measurement)
'   Any other value polls the chip and returns the current setting
    readRegX (core#CTRL_MEAS, 1, @tmp)
    case mode
        OPMODE_SLEEP, OPMODE_FORCED:
        OTHER:
            return tmp & core#BITS_MODE

    tmp &= core#MASK_MODE
    tmp := (tmp | mode) & core#CTRL_MEAS_MASK
    writeRegX (core#CTRL_MEAS, 1, @tmp)

PUB PressureOS(oversampling) | tmp
' Set pressure sensor oversampling factor
'   Valid values:
'       0 (effectively turns the sensor off; reading will always be $8000)
'       1, 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    readRegX (core#CTRL_MEAS, 1, @tmp)
    case oversampling := lookdown(oversampling: 0, 1, 2, 4, 8, 16)
        1..6:
            oversampling := (oversampling-1) << core#FLD_OSRS_P
        OTHER:
            result := (tmp >> core#FLD_OSRS_P) & core#BITS_OSRS_P
            return lookupz(result: 0, 1, 2, 4, 8, 16)

    tmp &= core#MASK_OSRS_P
    tmp := (tmp | oversampling) & core#CTRL_MEAS_MASK
    writeRegX (core#CTRL_MEAS, 1, @tmp)

PUB TempADC
' Read temperature data
'   Returns: raw temperature data, 20bit word
    readRegX (core#TEMP_MSB, 3, @result)
    result.byte[3] := result.byte[0]        'Swap byte order
    result.byte[0] := result.byte[2]
    result.byte[2] := result.byte[3]
    result >>= 4
    result &= $FFFFF

PUB Temperature | var1, var2, var3
' Read calibrated temperature
    var1 := (TempADC >> 3) - (Par_T(1) << 1)
    var2 := (var1 * Par_T(2)) >> 11
    var3 := ((var1 >> 1) * (var1 >> 1)) >> 12
    var3 := ((var3) * (Par_T(3) << 4)) >> 14
    _t_fine := (var2 + var3)
    result := (((_t_fine * 5) + 128) >> 8)

PUB Temp_Fine

    return _t_fine

PUB TemperatureOS(oversampling) | tmp
' Set temperature sensor oversampling factor
'   Valid values:
'       0 (effectively turns the sensor off; reading will always be $8000)
'       1, 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    readRegX (core#CTRL_MEAS, 1, @tmp)
    case oversampling := lookdown(oversampling: 0, 1, 2, 4, 8, 16)
        1..6:
            oversampling := (oversampling-1) << core#FLD_OSRS_T
        OTHER:
            result := (tmp >> core#FLD_OSRS_T) & core#BITS_OSRS_T
            return lookupz(result: 0, 1, 2, 4, 8, 16)

    tmp &= core#MASK_OSRS_T
    tmp := (tmp | oversampling) & core#CTRL_MEAS_MASK
    writeRegX (core#CTRL_MEAS, 1, @tmp)

PUB ReadCoefficients

    readRegX (core#COEFF_1, core#COEFF_1_LEN, @_coeff_table)
    readRegX (core#COEFF_2, core#COEFF_2_LEN, @_coeff_table + core#COEFF_1_LEN)
    result := @_coeff_table

PUB Par_GH(param)

    case param
        1:
            return types.s8 (byte[@_coeff_table][core#GH1])
        2:
            return types.u8s16 (byte[@_coeff_table][core#GH2_MSB], byte[@_coeff_table][core#GH2_LSB])
        3:
            return types.s8 (byte[@_coeff_table][core#GH3])

        OTHER:
            return FALSE

PUB Par_H(param)

    case param
        1:
            return types.u8u16 (byte[@_coeff_table][core#H1_MSB] << core#HUM_REG_SHIFT_VAL, byte[@_coeff_table][core#H1_LSB])
        2:
            return types.u8u16 (byte[@_coeff_table][core#H2_MSB] << core#HUM_REG_SHIFT_VAL, byte[@_coeff_table][core#H2_LSB] >> core#HUM_REG_SHIFT_VAL)
        3:
            return types.s8 (byte[@_coeff_table][core#H3])
        4:
            return types.s8 (byte[@_coeff_table][core#H4])
        5:
            return types.s8 (byte[@_coeff_table][core#H5])
        6:
            return byte[@_coeff_table][core#H6]
        7:
            return types.s8 (byte[@_coeff_table][core#H7])
        OTHER:
            return FALSE

PUB Par_T(param)
' Return selected parameter from the Temperature calibration data table
    case param
        1:
            return types.u8u16 (byte[@_coeff_table][core#T1_MSB], byte[@_coeff_table][core#T1_LSB])
        2:
            return types.u8s16 (byte[@_coeff_table][core#T2_MSB], byte[@_coeff_table][core#T2_LSB])
        3:
            return types.s8 (byte[@_coeff_table][core#T3])
        OTHER:
            return FALSE

PUB Par_P(param)
' Return selected parameter from the Barometric Pressure calibration data table
    case param
        1:
            return types.u8u16 (byte[@_coeff_table][core#P1_MSB], byte[@_coeff_table][core#P1_LSB])
        2:
            return types.u8s16 (byte[@_coeff_table][core#P2_MSB], byte[@_coeff_table][core#P2_LSB])
        3:
            return types.s8 (byte[@_coeff_table][core#P3])
        4:
            return types.u8s16 (byte[@_coeff_table][core#P4_MSB], byte[@_coeff_table][core#P4_LSB])
        5:
            return types.u8s16 (byte[@_coeff_table][core#P5_MSB], byte[@_coeff_table][core#P5_LSB])
        6:
            return types.s8 (byte[@_coeff_table][core#P6])
        7:
            return types.s8 (byte[@_coeff_table][core#P7])
        8:
            return types.u8s16 (byte[@_coeff_table][core#P8_MSB], byte[@_coeff_table][core#P8_LSB])
        9:
            return types.u8s16 (byte[@_coeff_table][core#P9_MSB], byte[@_coeff_table][core#P9_LSB])
        10:
            return byte[@_coeff_table][core#P10]
        OTHER:
            return FALSE

PUB readRegX(reg, nr_bytes, buff_addr)
' Read nr_bytes from register 'reg' to address 'buff_addr'
    writeRegX (reg, 0, 0)
    i2c.start
    i2c.write (SLAVE_RD)
    i2c.rd_block (buff_addr, nr_bytes, TRUE)
    i2c.stop

PUB writeRegX(reg, nr_bytes, buff_addr) | cmd_packet
' Write nr_bytes of 'val' to register 'reg'
' If nr_bytes is
'   0, It's a command that has no arguments - write the command only
'   1, It's a command with a single byte argument - write the command, then the byte
    cmd_packet.byte[0] := SLAVE_WR

    case nr_bytes
        0:
            cmd_packet.byte[1] := reg
        1:
            cmd_packet.byte[1] := reg
            cmd_packet.byte[2] := byte[buff_addr][0]
        OTHER:
            return

    i2c.start
    i2c.wr_block (@cmd_packet, 2 + nr_bytes)
    i2c.stop

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
