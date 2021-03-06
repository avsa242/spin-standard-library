{
    --------------------------------------------
    Filename: sensor.power.ina219.i2c.spin
    Author: Jesse Burt
    Description: Driver of the TI INA219 current/power monitor IC
    Copyright (c) 2019
    Started Sep 18, 2019
    Updated Sep 22, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 400_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR


OBJ

    i2c : "com.i2c"
    core: "core.con.ina219.spin"
    time: "time"

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
                    if ID == core#CONFIG_POR
                        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB BusVoltage
' Read bus voltage
'   Returns: Voltage in millivolts
    result := $0000
    readReg(core#BUS_VOLTAGE, 2, @result)
    result ~>= 3                            'Chop off the 3 LSBs (as they're status bits, not part of the measurement),
                                            '   and preserve the sign.
    result *= 4

PUB BusADCRes(bits) | tmp
' Set bus ADC resolution, in bits
'   Valid values: 9, 10, 11, *12
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    case bits
        9, 10, 11, 12:
            bits := lookdownz(bits: 9, 10, 11, 12) << core#FLD_BADC
        OTHER:
            tmp := (tmp >> core#FLD_BADC) & core#BITS_BADC
            result := lookupz(tmp: 9, 10, 11, 12)
            return

    tmp &= core#MASK_BADC
    tmp := (tmp | bits) & core#CONFIG_MASK
    writeReg(core#CONFIG, 2, @tmp)

PUB BusVoltageRange(volts) | tmp
' Set bus voltage range
'   Valid values: 16, *32
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    case volts
        16, 32:
            volts := lookdownz(volts: 16, 32) << core#FLD_BRNG
        OTHER:
            tmp := (tmp >> core#FLD_BRNG) & %1
            result := lookupz(tmp: 16, 32)
            return

    tmp &= core#MASK_BRNG
    tmp := (tmp | volts) & core#CONFIG_MASK
    writeReg(core#CONFIG, 2, @tmp)

PUB Calibration(val) | tmp
' Set calibration value, used in current calculation
'   Valid values: *0..65535
'   Any other value polls the chip and returns the current setting
'   NOTE: The LSB is read-only and is always 0
'   NOTE: Current readings will always be 0 after POR, until this value is set
    tmp := $0000
    readReg(core#CALIBRATION, 2, @tmp)
    case val
        0..65535:
        OTHER:
            return tmp

    tmp := val & core#CALIBRATION_MASK
    writeReg(core#CALIBRATION, 2, @tmp)

PUB ConfigWord
' debug: return value of config register
    readReg(core#CONFIG, 2, @result)

PUB Current
' Read current flowing through shunt resistor
'   Returns: Current in microamps
    readReg(core#CURRENT, 2, @result)
    ~~result
    result *= 20

PUB ID
' Identify the device
'   Returns: POR value of the configuration register
'   NOTE: This method performs a soft-reset of the chip and reads the value of the configuration register,
'       thus it isn't an ID, per se
    result := $0000
    Reset
    readReg(core#CONFIG, 2, @result)
    return result

PUB Power
' Read power (calculated on-chip)
'   Returns: Power in microwatts
    result := $0000
    readReg(core#POWER, 2, @result)
    result *= 400

PUB Reset
' Perform a soft-reset of the chip
    result := (1 << core#FLD_RST)
    writeReg(core#CONFIG, 2, @result)

PUB ShuntADCRes(bits) | tmp
' Set shunt ADC resolution, in bits
'   Valid values: 9, 10, 11, *12
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    case bits
        9, 10, 11, 12:
            bits := lookdownz(bits: 9, 10, 11, 12) << core#FLD_SADC
        OTHER:
            tmp := (tmp >> core#FLD_SADC) & core#BITS_SADC
            result := lookupz(tmp: 9, 10, 11, 12)
            return

    tmp &= core#MASK_SADC
    tmp := (tmp | bits) & core#CONFIG_MASK
    writeReg(core#CONFIG, 2, @tmp)

PUB ShuntSamples(samples) | tmp
' Set number of shunt ADC samples to take when averaging
'   Valid values: 1, 2, 4, 8, 16, 32, 64, 128
'   Any other value polls the chip and returns the current setting
'   NOTE: All averaging modes are performed at 12-bit resolution
'   NOTE: Conversion time is approx 532uSec * number of samples
'   NOTE: 1 effectively disables averaging
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    case samples
        1, 2, 4, 8, 16, 32, 64, 128:
            samples := (1 << core#FLD_SADC_AVG) | (lookdownz(samples: 1, 2, 4, 8, 16, 32, 64, 128) << core#FLD_SADC)
        OTHER:
            tmp := (tmp >> core#FLD_SADC) & core#BITS_SADC
            if tmp & %1000
                tmp &= %0111
                return lookupz(tmp: 1, 2, 4, 8, 16, 32, 64, 128)
            else
                return 0

    tmp &= core#MASK_SADC
    tmp := (tmp | samples) & core#CONFIG_MASK
    writeReg(core#CONFIG, 2, @tmp)

PUB ShuntVoltage
' Read shunt voltage
'   Returns: Voltage in millivolts
    readReg(core#SHUNT_VOLTAGE, 2, @result)
    ~~result
    return result * 10

PUB ShuntVoltageRange(mV) | tmp
' Set shunt voltage range, in millivolts
'   Valid values: 40, 80, 160, 320
'   Any other value polls the chip and returns the current setting
'   Example: Setting of 40 means +/- 40mV
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    case mV
        40, 80, 160, 320:
            mV := lookdownz(mV: 40, 80, 160, 320) << core#FLD_PG
        OTHER:
            tmp := (tmp >> core#FLD_PG) & core#BITS_PG
            result := lookupz(tmp: 40, 80, 160, 320)
            return

    tmp &= core#MASK_PG
    tmp := (tmp | mV) & core#CONFIG_MASK
    writeReg(core#CONFIG, 2, @tmp)

PRI readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Read num_bytes from the slave device into the address stored in buff_addr
    case reg                                                    'Basic register validation
        $00..$05:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.start
            i2c.wr_block (@cmd_packet, 2)
            i2c.start
            i2c.write (SLAVE_RD)
            byte[buff_addr][1] := i2c.Read (i2c#ACK)
            byte[buff_addr][0] := i2c.Read (i2c#NAK)
            i2c.stop
        OTHER:
            return

PRI writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Write num_bytes to the slave device from the address stored in buff_addr
    case reg                                                    'Basic register validation
        $00, $05:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            cmd_packet.byte[2] := byte[buff_addr][1]
            cmd_packet.byte[3] := byte[buff_addr][0]

            i2c.start
            i2c.wr_block (@cmd_packet, 4)
            i2c.stop
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
