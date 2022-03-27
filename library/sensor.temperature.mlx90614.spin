{
    --------------------------------------------
    Filename: sensor.temperature.mlx90614.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Melexis MLX90614 IR thermometer
    Copyright (c) 2022
    Started Mar 17, 2019
    Updated Mar 27, 2022
    See end of file for terms of use.
    --------------------------------------------
}
{ pull in methods common to all Temp/RH drivers }
#include "sensor.temp_rh.common.spinh"

CON

    MSB             = 0
    LSB             = 1
    PEC             = 2

OBJ

    i2c : "com.i2c"                             ' PASM I2C engine
    core: "core.con.mlx90614"                   ' HW-specific constants
    time: "time"                                ' timekeeping methods

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)
            if i2c.present(SLAVE_WR)            ' check bus device presence
                if deviceid{}
                    return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB AmbientTempData{}: temp_adc
' Read ambient temperature ADC data
'   Returns: s16
    readreg(core#CMD_RAM, core#T_A, 2, @temp_adc)

PUB AmbientTemp{}: temp
' Reads the Ambient temperature
'   Returns: Temperature in hundredths of a degree (e.g., 2135 is 21.35 deg),
'       using the chosen scale
    return tempword2deg(ambienttempdata{})

PUB DeviceID{}: id
' Reads the sensor ID
    readreg(core#CMD_EEPROM, core#EE_ID_1, 4, @id)

PUB EEPROM(ptr_buff)
' Dump EEPROM to array at ptr_buff
'   NOTE: ptr_buff must be at least 64 bytes
    readreg(core#CMD_EEPROM, $00, 64, ptr_buff)

PUB ObjTempData(channel): temp_adc
' Read object temperature ADC data
'   channel
'       Valid values: 1, 2 (CH2 availability is device-dependent)
'       Any other value is ignored
'   Returns: s16
    case channel
        1, 2:
            readreg(core#CMD_RAM, core#T_OBJ1+(channel-1), 3, @temp_adc)
        other:
            return

    return temp_adc & $FFFF

PUB ObjTemp(channel): temp
' Reads the Object temperature (IR temp)
'   channel
'       Valid values: 1, 2 (CH2 availability is device-dependent)
'       Any other value is ignored
'   Returns: Temperature in hundredths of a degree (e.g., 2135 is 21.35 deg),
'       using the chosen scale
    return tempword2deg(objtempdata(channel))

PUB RHData{}
' dummy method

PUB RHWord2Pct(rh_word)
' dummy method

PUB TempWord2Deg(temp_word): temp
' Convert temperature ADC word to temperature
'   Returns: temperature, in hundredths of a degree, in chosen scale
    temp_word *= 2
    case _temp_scale
        C:
            return temp_word - 273_15
        F:
            return (((temp_word - 273_15) * 9_00) / 5_00) + 32_00
        K:
            return
        other:
            return FALSE

PRI readReg(region, reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from device into ptr_buff
    case region
        core#CMD_RAM:
        core#CMD_EEPROM:
        core#CMD_READFLAGS:
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := region | reg_nr

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start{}
    i2c.write(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

PRI writeReg(region, reg_nr, nr_bytes, val) | cmd_pkt[2]
' Write nr_bytes from val to device
    case region
        core#CMD_EEPROM:
        core#CMD_SLEEPMODE:
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := region | reg_nr
    cmd_pkt.byte[2] := val.byte[LSB]
    cmd_pkt.byte[3] := val.byte[MSB]
    cmd_pkt.byte[4] := val.byte[PEC]

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2 + nr_bytes)
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
