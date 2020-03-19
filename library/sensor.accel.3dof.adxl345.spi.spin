{
    --------------------------------------------
    Filename: sensor.accel.3dof.adxl345.spi.spin
    Author: Jesse Burt
    Description: Driver for the Analog Devices ADXL345 3DoF Accelerometer
    Copyright (c) 2020
    Started Mar 14, 2020
    Updated Mar 15, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Operating modes
    STANDBY             = 0
    MEASURE             = 1

' FIFO modes
    BYPASS              = %00
    FIFO                = %01
    STREAM              = %10
    TRIGGER             = %11

' ADC resolution
    FULL                = 1

VAR

    long _aRes
    byte _CS, _MOSI, _MISO, _SCK

OBJ

    spi : "com.spi.4w"                                          'PASM SPI Driver
    core: "core.con.adxl345"
    time: "time"                                                'Basic timing functions
    io  : "io"

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN) : okay

    okay := Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, core#CLK_DELAY)

PUB Startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN, SCL_DELAY): okay
    if lookdown(CS_PIN: 0..31) and lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and lookdown(SDO_PIN: 0..31)
        if SCL_DELAY => 1
            if okay := spi.start (SCL_DELAY, core#CPOL)         'SPI Object Started?
                time.MSleep (1)
                _CS := CS_PIN
                _MOSI := SDA_PIN
                _MISO := SDO_PIN
                _SCK := SCL_PIN

                io.High(_CS)
                io.Output(_CS)
                if DeviceID == core#DEVID_RESP
                    return okay
    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.Stop

PUB Defaults
' Factory defaults
    AccelADCRes(10)
    AccelDataRate(100)
    AccelScale(2)
    AccelSelfTest(FALSE)
    FIFOMode(BYPASS)
    IntMask(%00000000)
    OpMode(STANDBY)

PUB AccelADCRes(bits) | tmp
' Set accelerometer ADC resolution, in bits
'   Valid values:
'       10: 10bit ADC resolution (AccelScale determines maximum g range and scale factor)
'       FULL: Output resolution increases with the g range, maintaining a 4mg/LSB scale factor
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#DATA_FORMAT, 1, @tmp)
    case bits
        10:
            bits := 0
        FULL:
            bits <<= core#FLD_FULL_RES
        OTHER:
            tmp >>= core#FLD_FULL_RES
            return tmp & %1

    tmp &= core#MASK_FULL_RES
    tmp := (tmp | bits) & core#DATA_FORMAT_MASK
    writeReg(core#DATA_FORMAT, 1, @tmp)

PUB AccelData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Reads the Accelerometer output registers
    bytefill(@tmp, $00, 8)
    readReg(core#DATAX0, 6, @tmp)

    long[ptr_x] := tmp.word[0]
    long[ptr_y] := tmp.word[1]
    long[ptr_z] := tmp.word[2]

    if long[ptr_x] > 32767
        long[ptr_x] := long[ptr_x]-65536
    if long[ptr_y] > 32767
        long[ptr_y] := long[ptr_y]-65536
    if long[ptr_z] > 32767
        long[ptr_z] := long[ptr_z]-65536

PUB AccelDataOverrun
' Indicates previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overflowed/been overwritten, FALSE otherwise
    result := $00
    readReg(core#INT_SOURCE, 1, @result)
    result := (result & %1) * TRUE

PUB AccelDataRate(Hz) | tmp
' Set accelerometer output data rate, in Hz
'   Valid values: See case table below
'   Any other value polls the chip and returns the current setting
'   NOTE: Values containing an underscore represent fractional settings.
'       Examples: 0_10 == 0.1Hz, 12_5 == 12.5Hz
    tmp := $00
    readReg(core#BW_RATE, 1, @tmp)
    case Hz
        0_10, 0_20, 0_39, 0_78, 1_56, 3_13, 6_25, 12_5, 25, 50, 100, 200, 400, 800, 1600, 3200:
            Hz := lookdownz(Hz: 0_10, 0_20, 0_39, 0_78, 1_56, 3_13, 6_25, 12_5, 25, 50, 100, 200, 400, 800, 1600, 3200)
        OTHER:
            tmp &= core#BITS_RATE
            result := lookupz(tmp: 0_10, 0_20, 0_39, 0_78, 1_56, 3_13, 6_25, 12_5, 25, 50, 100, 200, 400, 800, 1600, 3200)
            return

    tmp &= core#MASK_RATE
    tmp := (tmp | Hz) & core#BW_RATE_MASK
    writeReg(core#BW_RATE, 1, @tmp)

PUB AccelDataReady
' Indicates data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    result := $00
    readReg(core#INT_SOURCE, 1, @result)
    result := ((result >> core#FLD_DATA_READY) & %1) * TRUE

PUB AccelG(ptr_x, ptr_y, ptr_z) | tmpX, tmpY, tmpZ
' Reads the Accelerometer output registers and scales the outputs to micro-g's (1_000_000 = 1.000000 g = 9.8 m/s/s)
    AccelData(@tmpX, @tmpY, @tmpZ)
    long[ptr_x] := tmpX * _aRes
    long[ptr_y] := tmpY * _aRes
    long[ptr_z] := tmpZ * _aRes

PUB AccelScale(g) | tmp
' Set measurement range of the accelerometer, in g's
'   Valid values: 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#DATA_FORMAT, 1, @tmp)
    case g
        2, 4, 8, 16:
            g := lookdownz(g: 2, 4, 8, 16)
            if AccelADCRes(-2) == FULL                              ' If ADC is set to full-resolution,
                _aRes := 4_300                                      '   scale factor is always 4.3mg/LSB
            else                                                    ' else if set to 10-bits,
                _aRes := lookup(g: 4_300, 8_700, 17_500, 34_500)    '   it depends on the range
            g <<= core#FLD_RANGE
        OTHER:
            tmp &= core#BITS_RANGE
            result := lookupz(tmp: 2, 4, 8, 16)
            return

    tmp &= core#MASK_RANGE
    tmp := (tmp | g)
    writeReg(core#DATA_FORMAT, 1, @tmp)

PUB AccelSelfTest(enabled) | tmp
' Enable self-test mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#DATA_FORMAT, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_SELF_TEST
        OTHER:
            tmp >>= core#FLD_SELF_TEST
            return (tmp & %1) * TRUE

    tmp &= core#MASK_SELF_TEST
    tmp := (tmp | enabled) & core#DATA_FORMAT_MASK
    writeReg(core#DATA_FORMAT, 1, @tmp)

{
PUB Calibrate | tmpX, tmpY, tmpZ
' Calibrate the accelerometer
'   NOTE: The accelerometer must be oriented with the package top facing up for this method to be successful
    repeat 3
        AccelData(@tmpX, @tmpY, @tmpZ)
        tmpX += 2 * -tmpX
        tmpY += 2 * -tmpY
        tmpZ += 2 * -(tmpZ-(_aRes/1000))

    writeReg(core#XOFFL, 2, @tmpX)
    writeReg(core#YOFFL, 2, @tmpY)
    writeReg(core#ZOFFL, 2, @tmpZ)
    time.MSleep(200)
}
PUB DeviceID
' Read device identification
    result := $00
    readReg(core#DEVID, 1, @result)

PUB FIFOMode(mode) | tmp
' Set FIFO operation mode
'   Valid values:
'      *BYPASS (%00): Don't use the FIFO functionality
'       FIFO (%01): FIFO enabled (stops collecting data when full, but device continues to operate)
'       STREAM (%10): FIFO enabled (continues accumulating samples; holds latest 32 samples)
'       TRIGGER (%11): FIFO enabled (holds latest 32 samples. When trigger event occurs, the last n samples,
'           set by FIFOSamples(), are kept. The FIFO then collects samples as long as it isn't full.
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#FIFO_CTL, 1, @tmp)
    case mode
        BYPASS, FIFO, STREAM, TRIGGER:
            mode <<= core#FLD_FIFO_MODE
        OTHER:
            result := tmp >> core#FLD_FIFO_MODE
            result &= core#BITS_FIFO_MODE
            return

    tmp &= core#MASK_FIFO_MODE
    tmp := (tmp | mode) & core#FIFO_CTL_MASK
    writeReg(core#FIFO_CTL, 1, @tmp)

PUB IntMask(mask) | tmp
' Set interrupt mask
'   Bits:   76543210
'       7: Data Ready (Always enabled, regardless of setting)
'       6: Single-tap
'       5: Double-tap
'       4: Activity
'       3: Inactivity
'       2: Free-fall
'       1: Watermark (Always enabled, regardless of setting)
'       0: Overrun (Always enabled, regardless of setting)
'   Valid values: %00000000..%11111111
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#INT_ENABLE, 1, @tmp)
    case mask
        %0000_0000..%1111_1111:
        OTHER:
            return tmp

    writeReg(core#INT_ENABLE, 1, @mask)

PUB OpMode(mode) | tmp
' Set operating mode
'   Valid values:
'       STANDBY (0): Standby
'       MEASURE (1): Measurement mode
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#POWER_CTL, 1, @tmp)
    case mode
        STANDBY, MEASURE:
            mode <<= core#FLD_MEASURE
        OTHER:
            result := (tmp >> core#FLD_MEASURE) & %1
            return

    tmp &= core#MASK_MEASURE
    tmp := (tmp | mode) & core#POWER_CTL_MASK
    writeReg(core#POWER_CTL, 1, @tmp)

PRI readReg(reg, nr_bytes, buff_addr) | tmp
' Read nr_bytes from register 'reg' to address 'buff_addr'
    case reg
        $00, $1D..$31, $38, $39:
        $32..37:                                    ' If reading the accelerometer data registers,
            reg |= core#MB                          '   set the multiple-byte transaction bit
        OTHER:
            return

    io.Low(_CS)
    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg | core#R)

    repeat tmp from 0 to nr_bytes-1
        byte[buff_addr][tmp] := spi.SHIFTIN(_MISO, _SCK, core#MISO_BITORDER, 8)
    io.High(_CS)

PRI writeReg(reg, nr_bytes, buff_addr) | tmp
' Write nr_bytes to register 'reg' stored at buff_addr

    case reg
        $1D..$2A, $2C..$2F, $31, $38:
            io.Low(_CS)
            spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)

            repeat tmp from 0 to nr_bytes-1
                spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][tmp])
            io.High(_CS)
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
