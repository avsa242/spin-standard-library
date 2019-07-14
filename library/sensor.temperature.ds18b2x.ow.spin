{
    --------------------------------------------
    Filename: sensor.temperature.ds18b2x.ow.spin
    Author: Jesse Burt
    Description: Driver for the Dallas/Maxim DS18B2x-series temperature sensors
    Copyright (c) 2019
    Started Jul 13, 2019
    Updated Jul 13, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SCALE_C = 0
    SCALE_F = 1

OBJ

    time    : "time"
    core    : "core.con.ds18b2x"
    ow      : "com.onewire"

VAR

  byte _temp_scale

PUB Start(OW_PIN): okay

    if lookdown(OW_PIN: 0..31)
        okay := ow.Start(OW_PIN)
        if okay
            if Status == ow#OW_STAT_FOUND
                return
    return FALSE

PUB Stop

    ow.Stop

PUB Family
' Returns: 8-bit family code of device
'   20: DS18B20
'   22: DS18B22
    result := 0
    ow.Reset
    ow.Write(ow#RD_ROM)
    result := ow.Read
    ow.Reset

    case result
        core#FAMILY_20:
            return 20
        core#FAMILY_22:
            return 22
        OTHER:
            'Unknown or not yet implemented - return the raw data

PUB Resolution(bits) | tmp
' Set resolution of temperature readings, in bits
'   Valid values: 9..12
'   Any other value polls the chip and returns the current setting
    ow.Reset
    ow.Write(ow#SKIP_ROM)
    ow.Write(core#RD_SPAD)
    repeat 4
        ow.Read
    tmp := (ow.Read >> 5)
    case bits
        9..12:
            bits := lookdownz(bits: 9..12) << 5
        OTHER:
            result := lookupz(tmp: 9..12)
            return result
    ow.Reset
    ow.Write(ow#SKIP_ROM)
    ow.Write(core#WR_SPAD)
    ow.Write($00)
    ow.Write($00)
    ow.Write(bits)
    OW.Reset

PUB Scale(temp_scale)
' Set scale of temperature data returned by Temperature method
'   Valid values:
'       SCALE_C (0): Celsius
'       SCALE_F (1): Fahrenheit
'   Any other value returns the current setting
    case temp_scale
        SCALE_F, SCALE_C:
            _temp_scale := temp_scale
        OTHER:
            return _temp_scale

PUB SN(buff_addr) | tmp
' Read 48-bit serial number of device into buffer at buff_addr
'   NOTE: Buffer at buff_addr must be 6 bytes in length
    ow.Reset
    ow.Write(ow#RD_ROM)
    ow.Read                                 ' Discard first byte (family code)
    repeat tmp from 5 to 0                  ' Read only the 48-bit unique SN
        byte[buff_addr][tmp] := ow.Read
 
PUB Status
' Returns: One-Wire bus status
    return ow.Reset

PUB Temperature
' Returns: Temperature in centi-degrees
'   NOTE: Temperature scale is set using the Scale method, and defaults to Celsius
    result := 0
    ow.Reset
    ow.Write(ow#SKIP_ROM)
    ow.Write(core#CONV_TEMP)
    repeat
        result := ow.RdBit
    until (result == 1)
    ow.Reset
    ow.Write(ow#SKIP_ROM)
    ow.Write(core#RD_SPAD)
    result := ow.Read
    result |= ow.Read << 8
    ow.Reset

    result := ~~result * 5
    case _temp_scale
        SCALE_F:
            if result > 0
                result := result * 9 / 5 + 32_00
            else
                result := 32_00 - (||result * 9 / 5)
        OTHER:
            return result

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

