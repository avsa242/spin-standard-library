{
    --------------------------------------------
    Filename: sensor.accel.3dof.lis3dh.spi.spin
    Author: Jesse Burt
    Description: Driver for the ST LIS3DH 3DoF accelerometer
    Copyright (c) 2020
    Started Mar 15, 2020
    Updated Mar 16, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' XYZ axis constants used throughout the driver
    X_AXIS          = 0
    Y_AXIS          = 1
    Z_AXIS          = 2

' Operating modes

' FIFO modes
    BYPASS          = %00
    FIFO            = %01
    STREAM          = %10
    STREAM2FIFO     = %11

VAR

    long _aRes
    long _aBias[3], _aBiasRaw[3]
    byte _CS, _MOSI, _MISO, _SCK

OBJ

    spi : "com.spi.4w"                                          'PASM SPI Driver
    core: "core.con.lis3dh"
    time: "time"                                                'Basic timing functions
    io  : "io"

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN) : okay

    okay := Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, core#SCK_DELAY)

PUB Startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN, SCL_DELAY): okay
    if lookdown(CS_PIN: 0..31) and lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and lookdown(SDO_PIN: 0..31)
        if SCL_DELAY => 1
            if okay := spi.start (SCL_DELAY, core#CPOL)         'SPI Object Started?
                time.MSleep (core#TPOR)
                _CS := CS_PIN
                _MOSI := SDA_PIN
                _MISO := SDO_PIN
                _SCK := SCL_PIN

                io.High(_CS)
                io.Output(_CS)
                if DeviceID == core#WHO_AM_I_RESP
                    return okay
    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.Stop

PUB Defaults
' Factory defaults
    AccelScale(2)
    AccelDataRate(0)
    AccelAxisEnabled(%111)

PUB AccelADCRes(bits) | tmp1, tmp2
' Set accelerometer ADC resolution, in bits
'   Valid values:
'       8:  8-bit data output, Low-power mode
'       10: 10-bit data output, Normal mode
'       12: 12-bit data output, High-resolution mode
'   Any other value polls the chip and returns the current setting
    tmp1 := tmp2 := $00
    readReg(core#CTRL_REG1, 1, @tmp1)
    readReg(core#CTRL_REG4, 1, @tmp2)
    case bits
        8:
            tmp1 &= core#MASK_LPEN
            tmp2 &= core#MASK_HR
            tmp1 := (tmp1 | (1 << core#FLD_LPEN))
        10:
            tmp1 &= core#MASK_LPEN
            tmp2 &= core#MASK_HR
        12:
            tmp1 &= core#MASK_LPEN
            tmp2 &= core#MASK_HR
            tmp2 := (tmp2 | (1 << core#FLD_HR))
        OTHER:
            tmp1 := (tmp1 >> core#FLD_LPEN) & %1
            tmp2 := (tmp2 >> core#FLD_HR) & %1
            tmp1 := (tmp1 << 1) | tmp2
            result := lookupz(tmp1: 10, 12, 8)
            return

    writeReg(core#CTRL_REG1, 1, @tmp1)
    writeReg(core#CTRL_REG4, 1, @tmp2)

PUB AccelAxisEnabled(xyz_mask) | tmp
' Enable data output for Accelerometer - per axis
'   Valid values: 0 or 1, for each axis:
'       Bits    210
'               XYZ
'   Any other value polls the chip and returns the current setting
    readReg(core#CTRL_REG1, 1, @tmp)
    case xyz_mask
        %000..%111:
            xyz_mask := (xyz_mask >< 3) & core#BITS_XYZEN
        OTHER:
            return tmp & core#BITS_XYZEN

    tmp &= core#MASK_XYZEN
    tmp := (tmp | xyz_mask) & core#CTRL_REG1_MASK
    writeReg(core#CTRL_REG1, 1, @tmp)

PUB AccelData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Reads the Accelerometer output registers
    bytefill(@tmp, $00, 8)
    readReg(core#OUT_X_L, 6, @tmp)

    long[ptr_x] := ~~tmp.word[0]
    long[ptr_y] := ~~tmp.word[1]
    long[ptr_z] := ~~tmp.word[2]

    long[ptr_x] -= _aBiasRaw[X_AXIS]
    long[ptr_y] -= _aBiasRaw[Y_AXIS]
    long[ptr_z] -= _aBiasRaw[Z_AXIS]

PUB AccelDataOverrun
' Indicates previously acquired data has been overwritten
'   Returns:
'       Bits 3210 (decimal val):
'           3 (8): X, Y, and Z-axis data overrun
'           2 (4): Z-axis data overrun
'           1 (2): Y-axis data overrun
'           0 (1): X-axis data overrun
'       Returns 0 otherwise
    result := $00
    readReg(core#STATUS_REG, 1, @result)
    result := (result >> core#FLD_XOR) & %1111

PUB AccelDataRate(Hz) | tmp
' Set accelerometer output data rate, in Hz
'   Valid values: See case table below
'   Any other value polls the chip and returns the current setting
'   NOTE: A value of 0 powers down the device
    tmp := $00
    readReg(core#CTRL_REG1, 1, @tmp)
    case Hz
        0, 1, 10, 25, 50, 100, 200, 400, 1344, 1600:
            Hz := lookdownz(Hz: 0, 1, 10, 25, 50, 100, 200, 400, 1344, 1600) << core#FLD_ODR
        OTHER:
            tmp := (tmp >> core#FLD_ODR) & core#BITS_ODR
            result := lookupz(tmp: 0, 1, 10, 25, 50, 100, 200, 400, 1344, 1600)
            return

    tmp &= core#MASK_ODR
    tmp := (tmp | Hz) & core#CTRL_REG1_MASK
    writeReg(core#CTRL_REG1, 1, @tmp)

PUB AccelDataReady
' Indicates data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    result := $00
    readReg(core#STATUS_REG, 1, @result)
    result := ((result >> core#FLD_ZYXDA) & %1) * TRUE

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
    readReg(core#CTRL_REG4, 1, @tmp)
    case g
        2, 4, 8, 16:
            g := lookdownz(g: 2, 4, 8, 16)
            _aRes := lookupz(g: 61, 122, 244, 732)
            g <<= core#FLD_FS
        OTHER:
            tmp := (tmp >> core#FLD_FS) & core#BITS_FS
            return lookupz(tmp: 2, 4, 8, 16)

    tmp &= core#MASK_FS
    tmp := (tmp | g) & core#CTRL_REG4_MASK
    writeReg(core#CTRL_REG4, 1, @tmp)
{
PUB AccelSelfTest(enabled) | tmp
' Enable self-test mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#ST_REG, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_
        OTHER:
            tmp >>= core#FLD_
            return (tmp & %1) * TRUE

    tmp &= core#MASK_
    tmp := (tmp | enabled) & core#ST_REG_MASK
    writeReg(core#ST_REG, 1, @tmp)
}

PUB Calibrate | tmpX, tmpY, tmpZ, tmpBiasRaw[3], axis, samples
' Calibrate the accelerometer
'   NOTE: The accelerometer must be oriented with the package top facing up for this method to be successful
    tmpX := tmpY := tmpZ := axis := samples := 0
    longfill(@tmpBiasRaw, $00000000, 3)

    FIFOEnabled(TRUE)
    FIFOMode(FIFO)
    FIFOThreshold (32)
    samples := FIFOThreshold (-2)
    repeat until FIFOFull

    repeat samples
' Read the accel data stored in the FIFO
        AccelData(@tmpx, @tmpy, @tmpz)
        tmpBiasRaw[X_AXIS] += tmpx
        tmpBiasRaw[Y_AXIS] += tmpy
        tmpBiasRaw[Z_AXIS] += tmpz - (1_000_000 / _aRes) ' Assumes sensor facing up!

    repeat axis from X_AXIS to Z_AXIS
        _aBiasRaw[axis] := tmpBiasRaw[axis] / samples
        _aBias[axis] := _aBiasRaw[axis] / _aRes

    FIFOEnabled(FALSE)
    FIFOMode (BYPASS)

PUB DeviceID
' Read device identification
    result := $00
    readReg(core#WHO_AM_I, 1, @result)

PUB FIFOEnabled(enabled) | tmp
' Enable FIFO memory
'   Valid values: FALSE (0), TRUE(1 or -1)
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL_REG5, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled << core#FLD_FIFO_EN)
        OTHER:
            tmp := (tmp >> core#FLD_FIFO_EN) & %1
            return tmp * TRUE

    tmp &= core#MASK_FIFO_EN
    tmp := (tmp | enabled) & core#CTRL_REG5_MASK
    writeReg(core#CTRL_REG5, 1, @tmp)

PUB FIFOEmpty | tmp
' Flag indicating FIFO is empty
'   Returns: FALSE (0): FIFO contains at least one sample, TRUE(-1): FIFO is empty
    readReg(core#FIFO_SRC_REG, 1, @result)
    result := ((result >> core#FLD_EMPTY) & %1) * TRUE

PUB FIFOFull | tmp
' Flag indicating FIFO is full
'   Returns: FALSE (0): FIFO contains less than 32 samples, TRUE(-1): FIFO contains 32 samples
    readReg(core#FIFO_SRC_REG, 1, @result)
    result := ((result >> core#FLD_OVRN_FIFO) & %1) * TRUE

PUB FIFOMode(mode) | tmp
' Set FIFO behavior
'   Valid values:
'       BYPASS      (%00) - Bypass mode - FIFO off
'       FIFO        (%01) - FIFO mode
'       STREAM      (%10) - Stream mode
'       STREAM2FIFO (%11) - Stream-to-FIFO mode
'   Any other value polls the chip and returns the current setting
    readReg(core#FIFO_CTRL_REG, 1, @tmp)
    case mode
        BYPASS, FIFO, STREAM, STREAM2FIFO:
            mode <<= core#FLD_FM
        OTHER:
            return (tmp >> core#FLD_FM) & core#BITS_FM

    tmp &= core#MASK_FM
    tmp := (tmp | mode) & core#FIFO_CTRL_REG_MASK
    writeReg(core#FIFO_CTRL_REG, 1, @tmp)

PUB FIFOThreshold(level) | tmp
' Set FIFO threshold level
'   Valid values: 1..32
'   Any other value polls the chip and returns the current setting
    readReg(core#FIFO_CTRL_REG, 1, @tmp)
    case level
        1..32:
            level -= 1
        OTHER:
            return (tmp & core#BITS_FTH) + 1

    tmp &= core#MASK_FTH
    tmp := (tmp | level) & core#FIFO_CTRL_REG_MASK
    writeReg(core#FIFO_CTRL_REG, 1, @tmp)

PUB FIFOUnreadSamples
' Number of unread samples stored in FIFO
'   Returns: 0..32
    readReg(core#FIFO_SRC_REG, 1, @result)
    result &= core#BITS_FSS

PUB Interrupt
' Read interrupt state
'   Bit 6543210 (For each bit, 0: No interrupt, 1: Interrupt has been generated)
'       6: One or more interrupts have been generated
'       5: Z-axis high event
'       4: Z-axis low event
'       3: Y-axis high event
'       2: Y-axis low event
'       1: X-axis high event
'       0: X-axis low event
    readReg(core#INT1_SRC, 1, @result)


PUB IntMask(mask) | tmp
' Set interrupt mask
'   Bits:   543210
'       5: Z-axis high event
'       4: Z-axis low event
'       3: Y-axis high event
'       2: Y-axis low event
'       1: X-axis high event
'       0: X-axis low event
'   Valid values: %000000..%111111
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#INT1_CFG, 1, @tmp)
    case mask
        %000000..%111111:
        OTHER:
            return tmp

    writeReg(core#INT1_CFG, 1, @mask)

PUB IntThresh(level) | tmp
' Set interrupt threshold level, in micro-g's
'   Valid values: 0..16_000000
    tmp := $00
    readReg(core#INT1_THS, 1, @tmp)
    case level
        0..16_000000:                                       ' 0..16_000000 = 0..16M micro-g's = 0..16 g's
        OTHER:
            case AccelScale(-2)                             '
                2: tmp *= 16_000                            '
                4: tmp *= 32_000                            '
                8: tmp *= 62_000                            '
                16: tmp *= 186_000                          ' Scale threshold register's 7-bit range
            return tmp                                      '   to micro-g's

    case AccelScale(-2)                                     '
        2: tmp := 16_000                                    '
        4: tmp := 32_000                                    '
        8: tmp := 62_000                                    '
        16: tmp := 186_000                                  ' Scale micro-g's to threshold register's

    level /= tmp                                            '   7-bit range
    writeReg(core#INT1_THS, 1, @level)

{
PUB OpMode(mode) | tmp
' Set operating mode
'   Valid values:
'
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#OPMODE_REG, 1, @tmp)
    case mode
        mode1, mode2, modeN:
            mode <<= core#FLD_
        OTHER:
            result := (tmp >> core#FLD_) & %1
            return

    tmp &= core#MASK_
    tmp := (tmp | mode) & core#OPMODE_REG_MASK
    writeReg(core#OPMODE_REG, 1, @tmp)
}
PRI readReg(reg, nr_bytes, buff_addr) | tmp
' Read nr_bytes from register 'reg' to address 'buff_addr'
    case reg
        $07..$0D, $0F, $1E..$27, $2E..$3F:
        $28..$2D:
            reg |= core#MS
        OTHER:
            return FALSE

    io.Low(_CS)
    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg | core#R)

    repeat tmp from 0 to nr_bytes-1
        byte[buff_addr][tmp] := spi.SHIFTIN(_MISO, _SCK, core#MISO_BITORDER, 8)
    io.High(_CS)

PRI writeReg(reg, nr_bytes, buff_addr) | tmp
' Write nr_bytes to register 'reg' stored at buff_addr
    case reg
        $1E..$26, $2E, $30, $32..$34, $36..$38, $3A..$3F:
        OTHER:
            return FALSE

    io.Low(_CS)
    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)

    repeat tmp from 0 to nr_bytes-1
        spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][tmp])
    io.High(_CS)

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