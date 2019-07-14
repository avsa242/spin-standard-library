{
    --------------------------------------------
    Filename: sensor.baro-alt.bmp280.i2c.spin
    Description: Driver object for the BOSCH BMP280 Barometric Pressure/Temperature sensor
    Author: Jesse Burt
    Copyright (c) 2018
    Created: Sep 16, 2018
    Updated: Mar 9, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 400_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ
    ID_EXPECTED     = core#ID_EXPECTED

    MODE_SLEEP      = core#MODE_SLEEP
    MODE_FORCED1    = core#MODE_FORCED1
    MODE_FORCED2    = core#MODE_FORCED2
    MODE_NORMAL     = core#MODE_NORMAL

' Offset within compensation data where Pressure compensation values start
    PRESS_OFFSET    = 6
    
VAR

    byte _comp_data[24]
    long _last_temp, _last_press

OBJ

    core    : "core.con.bmp280"
    i2c     : "jm_i2c_fast"
    time    : "time"
    types   : "system.types"

PUB null
' This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                if ID == core#ID_EXPECTED
                    return okay
    return FALSE                                                'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB ID
' Chip identification number
'   Returns: $58 (core#ID_EXPECTED)
    readRegX (core#ID, 1, @result)

PUB MeasureMode(mode) | tmp
' Sensor measurement mode
'   Valid values:
'       %00 (MODE_SLEEP): Performs no measurements (low-power mode)
'       %01 (MODE_FORCED1): One-shot measurement, then return to MODE_SLEEP
'       %10 (MODE_FORCED2): Same as MODE_FORCED1
'       %11 (MODE_NORMAL): Continuous measurement
    readRegX (core#CTRL_MEAS, 1, @tmp)
    case mode
        core#MODE_SLEEP, core#MODE_FORCED1, core#MODE_FORCED2, core#MODE_NORMAL:
        OTHER:
            return result := tmp & core#BITS_MODE

    tmp &= core#MASK_MODE
    tmp := (tmp | mode) & core#CTRL_MEAS_MASK
    writeRegX (core#CTRL_MEAS, 1, tmp)

PUB Measure | alldata[2], i
' Queries BMP280 for one "frame" of measurement
'  (burst-reads both barometric pressure and temperature)
' Call this method, then LastTemp and LastPress to get data from the same measurement
    readRegX (core#PRESS_MSB, 6, @alldata)
    repeat i from 0 to 2
        _last_temp.byte[i] := alldata.byte[5-i]     '_last_temp := alldata.long[1] ? check bit order
        _last_press.byte[i] := alldata.byte[2-i]    '_last_press := alldata.long[0] ? check bit order
'    _last_temp &= $1F_FF_FF
'    _last_press &= $1F_FF_FF
    _last_temp >>= 4
    _last_press >>= 4

PUB Measuring
' Indicates if a conversion is running
'   Returns: TRUE when conversion is running, FALSE when results have been transferred to data registers
    readRegX (core#STATUS, 1, @result)
    result := ((result >> core#FLD_MEASURING) & %1) * TRUE

PUB NVMBusy
' Indicates if NVM (device-specific trimming) data are being copied to image registers
'   Returns: TRUE when data is being copied, FALSE when complete
    readRegX (core#STATUS, 1, @result)
    result := ((result {>> core#FLD_IM_UPDATE}) & %1) * TRUE

PUB Pressure
' Takes measurement and returns pressure data
    Measure
    return _last_press

PUB Temperature
' Takes measurement and returns temperature data
    Measure
    return _last_temp

PUB LastTemp
' Returns Temperature data from last read using Measure
    return _last_temp

PUB LastPress
' Returns Pressure data from last read using Measure
    return _last_press

PUB PressRes(bits) | tmp
' Set Barometric Pressure sensor resolution, in bits
'   Valid values: 16, 17, 18, 19, 20, or 0 to disable pressure data acqusition
'   Any other values polls the chip and returns the current setting
    readRegX (core#CTRL_MEAS, 1, @tmp)
    case bits
        0, 16..20:
            bits := lookdownz(bits: 0, 16, 17, 18, 19, 20) << core#FLD_OSRS_P
        OTHER:
            result := (tmp >> core#FLD_OSRS_P) & core#BITS_OSRS_P
            return lookupz(result: 0, 16, 17, 18, 19, 20)

    tmp &= core#MASK_OSRS_P
    tmp := (tmp | bits) & core#CTRL_MEAS_MASK
    writeRegX (core#CTRL_MEAS, 1, tmp)

PUB TempRes(bits) | tmp
' Set Temperature sensor resolution, in bits
'   Valid values: 16, 17, 18, 19, 20, or 0 to disable temperature data acqusition
'   Any other values polls the chip and returns the current setting
    readRegX (core#CTRL_MEAS, 1, @tmp)
    case bits
        0, 16..20:
            bits := lookdownz(bits: 0, 16, 17, 18, 19, 20) << core#FLD_OSRS_T
        OTHER:
            result := (tmp >> core#FLD_OSRS_T) & core#BITS_OSRS_T
            return lookupz(result: 0, 16, 17, 18, 19, 20)

    tmp &= core#MASK_OSRS_T
    tmp := (tmp | bits) & core#CTRL_MEAS_MASK
    writeRegX (core#CTRL_MEAS, 1, tmp)

PUB ReadTrim
' Read Trim/Compensation values from the sensor's NVM
    readRegX(core#DIG_T1_LSB, 24, @_comp_data)

PUB dig_T(param)
' Return selected parameter from the Temperature trimming values table
    case param
        1:
'            return (byte[_comp_data][1] << 8) | byte[_comp_data][0]
            result := types.u8u16 (byte[_comp_data][1], byte[_comp_data][0])
        2, 3:
'            return types.s16 (_comp_data.byte[((param - 1) * 2) + 1{param+1}], _comp_data.byte[((param - 1) * 2){param}])
'            result := (byte[_comp_data][((param - 1) * 2) + 1] << 8) | byte[_comp_data][((param - 1) * 2)]
            result := types.u8s16 (byte[_comp_data][((param - 1) * 2) + 1], byte[_comp_data][((param - 1) * 2)])

'            return result
        OTHER:
            return FALSE
    return result

PUB dig_P(param)
' Return selected parameter from the Barometric Pressure trimming values table
'   param-1 * 2 + offset
'   1-1 * 2=0 + 6 = 6
'   2-1 * 2=2 + 6 = 8
'   3-1 * 2=4 + 6 = 10
'   4-1 * 2=6 + 6 = 12
'   5-1 * 2=8 + 6 = 14
'   6-1 * 2=10 +6 = 16
'   7-1 * 2=12 +6 = 18
'   8-1 * 2=14 +6 = 20
'   9-1 * 2=16 +6 = 22
    case param
        1:
 '           return (byte[_comp_data][PRESS_OFFSET + 1] << 8) | byte[_comp_data][PRESS_OFFSET + 0]
            result := types.u8s16 (byte[_comp_data][PRESS_OFFSET + 1], byte[_comp_data][PRESS_OFFSET + 0])

        2..9:
'            return types.s16 (_comp_data.byte[((param - 1) * 2) + PRESS_OFFSET+1{param+1}], _comp_data.byte[((param - 1) * 2) + PRESS_OFFSET{param}])
'            result := (byte[_comp_data][((param - 1) * 2) + PRESS_OFFSET+1] << 8) | byte[_comp_data][((param - 1) * 2) + PRESS_OFFSET]
            result := types.u8s16 (byte[_comp_data][((param - 1) * 2) + PRESS_OFFSET+1], byte[_comp_data][((param - 1) * 2) + PRESS_OFFSET])
'            return ~~result
        OTHER:
            return FALSE
    return result

PUB TrimAddr

    return @_comp_data

PUB SoftReset
' Sends soft-reset command to BMP280
    writeRegX (core#RESET, 1, core#DO_RESET)

PUB Standby(ms) | tmp
' Set standby period between measurements, in milliseconds.
' For use in MODE_NORMAL measurement mode
'   Valid values: 1, 63, 125, 250, 500, 1000, 2000, 4000
'     NOTE: 1 is rounded up from actual duration 0.5ms, 63 is rounded up from actual duration 62.5ms
'     NOTE: This has a direct impact on current consumption of the sensor.
'   Any other values polls the chip and returns the current setting
    readRegX (core#CONFIG, 1, @tmp)
    case ms
        1, 63, 125, 250, 500, 1000, 2000, 4000:
            ms := lookdownz(ms: 1, 63, 125, 250, 500, 1000, 2000, 4000) << core#FLD_SB
        OTHER:
            result := (tmp >> core#FLD_SB) & core#BITS_SB
            return lookupz(result: 1, 63, 125, 250, 500, 1000, 2000, 4000)

    tmp &= core#MASK_SB
    tmp := (tmp | ms) & core#CONFIG_MASK
    writeRegX (core#CONFIG, 1, tmp)

PUB readRegX(reg, nr_bytes, addr_buff)
' Read nr_bytes from register 'reg' to address 'addr_buff'
    writeRegX (reg, 0, 0)
    i2c.start
    i2c.write (SLAVE_RD)
    i2c.pread (addr_buff, nr_bytes, TRUE)
    i2c.stop

PUB writeRegX(reg, nr_bytes, val) | cmd_packet
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
            cmd_packet.byte[2] := val
        OTHER:
            return

    i2c.start
    i2c.pwrite (@cmd_packet, 2 + nr_bytes)
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
