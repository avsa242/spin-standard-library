{
    --------------------------------------------
    Filename: sensor.accel.3dof.mma7455.i2c.spin
    Author: Jesse Burt
    Description: Driver for the NXP/Freescale MMA7455 3-axis accelerometer
    Copyright (c) 2021
    Started Nov 27, 2019
    Updated May 17, 2021
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

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF           = 3
    GYRO_DOF            = 0
    MAG_DOF             = 0
    BARO_DOF            = 0
    DOF                 = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

' Operating modes
    #0, STANDBY, MEASURE, LEVELDET, PULSEDET

' Individual axes
    X_AXIS              = 0
    Y_AXIS              = 1
    Z_AXIS              = 2

VAR

    long _ares

OBJ

    i2c : "com.i2c"
    core: "core.con.mma7455"
    time: "time"

PUB Null{}
'This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.msleep(1)
            if i2c.present(SLAVE_WR)        ' check device bus presence
                if deviceid{} == core#DEVID_RESP
                    return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB AccelData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Reads the Accelerometer output registers
    longfill(@tmp, 0, 2)
    readreg(core#XOUTL, 6, @tmp)    'XXX these regs only valid for 8g scale
                                    'use hub var to hold reg# depending on scale?
                                    'set in accelscale()

    ' shift left to put the sign into bit 31, then SAR back down to the
    '   original position
    long[ptr_x] := (tmp.word[X_AXIS] << 22) ~> 22
    long[ptr_y] := (tmp.word[Y_AXIS] << 22) ~> 22
    long[ptr_z] := (tmp.word[Z_AXIS] << 22) ~> 22

PUB AccelDataOverrun{}: flag
' Flag indicating previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overflowed/been overwritten, FALSE otherwise
    readreg(core#STATUS, 1, @flag)
    return (((flag >> core#DOVR) & 1) == 1)

PUB AccelDataReady{}: flag
' Flag indicating data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    readreg(core#STATUS, 1, @flag)
    return ((flag & 1) == 1)

PUB AccelG(ptr_x, ptr_y, ptr_z) | tmpx, tmpy, tmpz
' Reads the Accelerometer output registers and scales the outputs to micro-g's (1_000_000 = 1.000000 g = 9.8 m/s/s)
    acceldata(@tmpx, @tmpy, @tmpz)
    long[ptr_x] := tmpx * _ares
    long[ptr_y] := tmpy * _ares
    long[ptr_z] := tmpz * _ares

PUB AccelScale(scale): curr_scl
' Set measurement range of the accelerometer, in g's
'   Valid values: 2, 4, *8
'   Any other value polls the chip and returns the current setting
    curr_scl := 0
    readreg(core#MCTL, 1, @curr_scl)
    case scale
        2, 4:
            _ares := (2_000000 * scale) / 256   ' 8-bit output
            scale := lookdownz(scale: 8, 2, 4) << core#GLVL
        8:
            _ares := (2_000000 * scale) / 1024  ' 10-bit output
            scale := lookdownz(scale: 8, 2, 4) << core#GLVL
        other:
            curr_scl := (curr_scl >> core#GLVL) & core#GLVL_BITS
            return lookupz(curr_scl: 8, 2, 4)

    scale := ((curr_scl & core#GLVL_MASK) | scale)
    writereg(core#MCTL, 1, @scale)

PUB AccelSelfTest(state) | curr_state
' Enable self-test
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
'   NOTE: The datasheet specifies the Z-axis should read between 32 and 83 (64 typ) when the self-test is state
    curr_state := 0
    readreg(core#MCTL, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#STON
        other:
            return (((curr_state >> core#STON) & 1) == 1)

    state := ((curr_state & core#STON_MASK) | state)
    writereg(core#MCTL, 1, @state)

PUB CalibrateAccel{} | tmpx, tmpy, tmpz
' Calibrate the accelerometer
'   NOTE: The accelerometer must be oriented with the package top facing up for this method to be successful
    repeat 3
        acceldata(@tmpx, @tmpy, @tmpz)
        tmpx += 2 * -tmpx
        tmpy += 2 * -tmpy
        tmpz += 2 * -(tmpz-(_ares/1000))

    writereg(core#XOFFL, 2, @tmpx)
    writereg(core#YOFFL, 2, @tmpy)
    writereg(core#ZOFFL, 2, @tmpz)
    time.msleep(200)

PUB DeviceID{}
' Get chip/device ID
'   Known values: $55
    readreg(core#WHOAMI, 1, @result)

PUB OpMode(mode) | curr_mode
' Set operating mode
'   Valid values:
'       STANDBY (%00): Standby
'       MEASURE (%01): Measurement mode
'       LEVELDET (%10): Level detection mode
'       PULSEDET (%11): Pulse detection mode
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#MCTL, 1, @curr_mode)
    case mode
        STANDBY, MEASURE, LEVELDET, PULSEDET:
        other:
            return curr_mode & core#MODE_BITS

    mode := ((curr_mode & core#MODE_MASK) | mode)
    writereg(core#MCTL, 1, @mode)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from slave device into ptr_buff
    case reg_nr
        $00..$0B, $0D..$1E:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)

            i2c.start{}
            i2c.write(SLAVE_RD)
            i2c.rdblock_lsbf(ptr_buff, nr_bytes, TRUE)
            i2c.stop{}
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes from ptr_buff to slave device
    case reg_nr
        $10..$1E:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
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
