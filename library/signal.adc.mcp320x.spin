{
    --------------------------------------------
    Filename: signal.adc.mcp320x.spin
    Author: Jesse Burt
    Description: Driver for Microchip MCP320x
        Analog to Digital Converters
    Copyright (c) 2022
    Started Nov 26, 2019
    Updated Jul 3, 2022
    See end of file for terms of use.
    --------------------------------------------
}

VAR

    long _CS
    word _adc_ref
    byte _ch

OBJ

    spi : "com.spi.4w"
    core: "core.con.mcp320x"
    time: "time"

PUB Null{}
' This is not a top-level object

PUB Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): status

    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if (status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE))
            time.msleep(1)
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    spi.deinit{}
    _CS := 0
    _adc_ref := 0
    _ch := 0

PUB Defaults{}
' Factory defaults
    adcchannel(0)
    refvoltage(3_300)

PUB ADCChannel(ch)
' Set ADC channel for subsequent reads
'   Valid values: 0, 1
'   Any other value returns the current setting
    case ch
        0..1:
            _ch := ch
        other:
            return _ch

PUB ADCData{}: adc_word | cfg
' ADC data word
'   Returns: 12-bit ADC word
    case _ch
        0, 1:
            cfg := core#SINGLE_ENDED | core#MSBFIRST | (_ch << core#ODD_SIGN)
        other:
            return

    outa[_CS] := 0
    spi.wrbits_msbf((core.START_MEAS | cfg), 4)
    adc_word := (spi.rdbits_msbf(13) & $fff)    ' 1 null bit + 12 data bits
    outa[_CS] := 1

PUB RefVoltage(v): curr_v
' Set ADC reference/supply voltage (Vdd), in millivolts
'   Valid values: 2_700..5_500
'   Any other value returns the current setting
    case v
        2_700..5_500:
            _adc_ref := v
        other:
            return _adc_ref

PUB Volts{}: v
' Return ADC reading, in milli-volts
    return (_adc_ref * adcdata{}) / 4096

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
