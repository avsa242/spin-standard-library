{
    --------------------------------------------
    Filename: sensor.accel.3dof.mma7455.i2c.spin
    Author: Jesse Burt
    Description: Driver for the NXP/Freescale MMA7455 3-axis accelerometer
    Copyright (c) 2020
    Started Nov 27, 2019
    Updated Jan 20, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

'   Operating modes
    #0, STANDBY, MEASURE, LEVELDET, PULSEDET

VAR

    long _aRes

OBJ

    i2c : "com.i2c"
    core: "core.con.mma7455.spin"
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
                    if DeviceID == core#DEVID_RESP
                        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop
' Put any other housekeeping code here required/recommended by your device before shutting down
    i2c.terminate

PUB AccelData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Reads the Accelerometer output registers
    bytefill(@tmp, $00, 8)
    readReg(core#XOUTL, 6, @tmp)

    long[ptr_x] := tmp.word[0]
    long[ptr_y] := tmp.word[1]
    long[ptr_z] := tmp.word[2]

    if long[ptr_x] > 511
        long[ptr_x] := long[ptr_x]-1024
    if long[ptr_y] > 511
        long[ptr_y] := long[ptr_y]-1024
    if long[ptr_z] > 511
        long[ptr_z] := long[ptr_z]-1024

PUB AccelDataOverrun
' Indicates previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overflowed/been overwritten, FALSE otherwise
    readReg(core#STATUS, 1, @result)
    result := ((result >> core#FLD_DOVR) & %1) * TRUE

PUB AccelDataReady
' Indicates data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    readReg(core#STATUS, 1, @result)
    result := (result & %1) * TRUE

PUB AccelG(ptr_x, ptr_y, ptr_z) | tmpX, tmpY, tmpZ, factor
' Reads the Accelerometer output registers and scales the outputs to micro-g's (1_000_000 = 1.000000 g = 9.8 m/s/s)
    AccelData(@tmpX, @tmpY, @tmpZ)
    long[ptr_x] := tmpX * _aRes
    long[ptr_y] := tmpY * _aRes
    long[ptr_z] := tmpZ * _aRes

PUB AccelScale(g) | tmp
' Set measurement range of the accelerometer, in g's
'   Valid values: 2, 4, *8
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#MCTL, 1, @tmp)
    case g
        2, 4, 8:
            g := lookdownz(g: 8, 2, 4)
            _aRes := (2_000000 * lookupz(g: 8, 2, 4)) / 1024     '/1024 = for 10-bit output
            g <<= core#FLD_GLVL
        OTHER:
            tmp >>= core#FLD_GLVL
            tmp &= core#BITS_GLVL
            result := lookupz(tmp: 8, 2, 4)
            return

    tmp &= core#MASK_GLVL
    tmp := (tmp | g)
    writeReg(core#MCTL, 1, @tmp)

PUB AccelSelfTest(enabled) | tmp
' Enable self-test
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
'   NOTE: The datasheet specifies the Z-axis should read between 32 and 83 (64 typ) when the self-test is enabled
    tmp := $00
    readReg(core#MCTL, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_STON
        OTHER:
            tmp >>= core#FLD_STON
            result := (tmp & %1) * TRUE

    tmp &= core#MASK_STON
    tmp := (tmp | enabled)
    writeReg(core#MCTL, 1, @tmp)

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

PUB DeviceID
' Get chip/device ID
'   Known values: $55
    readReg(core#WHOAMI, 1, @result)

PUB OpMode(mode) | tmp
' Set operating mode
'   Valid values:
'       STANDBY (%00): Standby
'       MEASURE (%01): Measurement mode
'       LEVELDET (%10): Level detection mode
'       PULSEDET (%11): Pulse detection mode
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#MCTL, 1, @tmp)
    case mode
        STANDBY, MEASURE, LEVELDET, PULSEDET:
        OTHER:
            result := tmp & core#BITS_MODE
            return

    tmp &= core#MASK_MODE
    tmp := (tmp | mode)
    writeReg(core#MCTL, 1, @tmp)

PRI readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Read num_bytes from the slave device into the address stored in buff_addr
    case reg                                                    'Basic register validation
        $00..$0B, $0D..$1E:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.start
            i2c.wr_block (@cmd_packet, 2)

            i2c.start
            i2c.write (SLAVE_RD)
            i2c.rd_block (buff_addr, nr_bytes, TRUE)
            i2c.stop
        OTHER:
            return

PRI writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Write num_bytes to the slave device from the address stored in buff_addr
    case reg                                                    'Basic register validation
        $10..$1E:                                               ' Consult your device's datasheet!
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.start
            i2c.wr_block (@cmd_packet, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write (byte[buff_addr][tmp])
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
