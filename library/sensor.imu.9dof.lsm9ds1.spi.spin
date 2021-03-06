{
    --------------------------------------------
    Filename: sensor.imu.9dof.lsm9ds1.3wspi.spin
    Author: Jesse Burt
    Description: Driver for the ST LSM9DS1 9DoF/3-axis IMU
    Copyright (c) 2021
    Started Aug 12, 2017
    Updated Jan 25, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF               = 3
    GYRO_DOF                = 3
    MAG_DOF                 = 3
    BARO_DOF                = 0
    DOF                     = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

' Constants used in low-level SPI read/write
    READ                    = 1 << 7
    WRITE                   = 0
    MS                      = 1 << 6

' Bias adjustment (AccelBias(), GyroBias(), MagBias()) read or write
    R                       = 0
    W                       = 1

' Axis-specific constants
    X_AXIS                  = 0
    Y_AXIS                  = 1
    Z_AXIS                  = 2
    ALL_AXIS                = 3

' Temperature scale constants
    C                       = 0
    F                       = 1

' Endian constants
    LITTLE                  = 0
    BIG                     = 1

' Interrupt active states (applies to both XLG and Mag)
    ACTIVE_HIGH             = 0
    ACTIVE_LOW              = 1

' FIFO settings
    FIFO_OFF                = core#FIFO_OFF
    FIFO_THS                = core#FIFO_THS
    FIFO_CONT_TRIG          = core#FIFO_CONT_TRIG
    FIFO_OFF_TRIG           = core#FIFO_OFF_TRIG
    FIFO_CONT               = core#FIFO_CONT

' Sensor-specific constants
    XLG                     = 0
    MAG                     = 1
    BOTH                    = 2

' Magnetometer operation modes
    MAG_OPMODE_CONT         = %00
    MAG_OPMODE_SINGLE       = %01
    MAG_OPMODE_POWERDOWN    = %10

' Magnetometer performance setting
    MAG_PERF_LOW            = %00
    MAG_PERF_MED            = %01
    MAG_PERF_HIGH           = %10
    MAG_PERF_ULTRA          = %11

' Operating modes (dummy)
    STANDBY                 = 0
    MEASURE                 = 1

' Gyroscope operating modes (dummy)
    #0, POWERDOWN, SLP, NORMAL

OBJ

    spi     : "com.spi.4w"
    core    : "core.con.lsm9ds1"
    time    : "time"

VAR

    long _gres, _gbiasraw[3]
    long _ares, _abiasraw[3]
    long _mres, _mbiasraw[3]
    long _CS_AG, _CS_M
    byte _temp_scale

PUB Null{}
' This is not a top-level object

PUB Start(CS_AG_PIN, CS_M_PIN, SCL_PIN, SDIO_PIN): status
' Start using custom I/O pins
    if lookdown(SCL_PIN: 0..31) and lookdown(SDIO_PIN: 0..31) and {
}   lookdown(CS_AG_PIN: 0..31) and lookdown(CS_M_PIN: 0..31)
        if (status := spi.init(SCL_PIN, SDIO_PIN, SDIO_PIN, core#SPI_MODE))
            longmove(@_CS_AG, @CS_AG_PIN, 2)
            outa[_CS_AG] := 1                   ' make sure CS starts
            outa[_CS_M] := 1                    '   high
            dira[_CS_AG] := 1
            dira[_CS_M] := 1
            time.usleep(core#TPOR)              ' startup time

            xlgsoftreset{}                      ' reset/initialize to
            magsoftreset{}                      ' POR defaults

            if deviceid{} == core#WHOAMI_BOTH_RESP
                return status                   ' validate device
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    spi.deinit{}

PUB Defaults{}
' Factory default settings
    xlgsoftreset{}
    magsoftreset{}
    time.usleep(core#TPOR)

PUB Preset_XL_G_M_3WSPI{}
' Like Defaults(), but
'   * enables output data (XL/G: 59Hz, Mag: 40Hz)
'   * sets SPI mode to 3-wire
'   * disables magnetometer I2C interface
    xlgsoftreset{}
    magsoftreset{}
    time.usleep(core#TPOR)

' Set both the Accel/Gyro and Mag to 3-wire SPI mode
    setspi3wiremode{}
    addressautoinc(TRUE)
    magi2c(FALSE)                               ' disable mag I2C interface
    xlgdatarate(59)                             ' arbitrary
    magdatarate(40_000)                         '
    gyroscale(245)                              ' already the POR defaults,
    accelscale(2)                               ' but still need to call these
    magscale(4)                                 ' to set scale factor hub vars

PUB AccelAxisEnabled(mask): curr_mask
' Enable data output for Accelerometer - per axis
'   Valid values: FALSE (0) or TRUE (1 or -1), for each axis
'   Any other value polls the chip and returns the current setting
    readreg(XLG, core#CTRL_REG5_XL, 1, @curr_mask)
    case mask
        %000..%111:
            mask <<= core#XEN_XL
        other:
            return ((curr_mask >> core#EN_XL) & core#EN_XL_BITS)

    mask := ((curr_mask & core#EN_XL_MASK) | mask)
    writereg(XLG, core#CTRL_REG5_XL, 1, @mask)

PUB AccelBias(axbias, aybias, azbias, rw)
' Read or write/manually set accelerometer calibration offset values
'   Valid values:
'       rw:
'           R (0), W (1)
'       axbias, aybias, azbias:
'           -32768..32767
'   NOTE: When rw is set to READ, axbias, aybias and azbias must be addresses
'       of respective variables to hold the returned calibration offset values
    case rw
        R:
            long[axbias] := _abiasraw[X_AXIS]
            long[aybias] := _abiasraw[Y_AXIS]
            long[azbias] := _abiasraw[Z_AXIS]
        W:
            case axbias
                -32768..32767:
                    _abiasraw[X_AXIS] := axbias
                other:
            case aybias
                -32768..32767:
                    _abiasraw[Y_AXIS] := aybias
                other:
            case azbias
                -32768..32767:
                    _abiasraw[Z_AXIS] := azbias
                other:

PUB AccelData(ax, ay, az) | tmp[2]
' Reads the Accelerometer output registers
    readreg(XLG, core#OUT_X_L_XL, 6, @tmp)

    long[ax] := ~~tmp.word[X_AXIS] - _abiasraw[X_AXIS]
    long[ay] := ~~tmp.word[Y_AXIS] - _abiasraw[Y_AXIS]
    long[az] := ~~tmp.word[Z_AXIS] - _abiasraw[Z_AXIS]

PUB AccelDataOverrun{}: flag
' Dummy method

PUB AccelDataRate(rate): curr_rate
' Set accelerometer output data rate, in Hz
'   NOTE: This is locked with the gyroscope output data rate
'       (hardware limitation)
    return xlgdatarate(rate)

PUB AccelDataReady{} | tmp
' Accelerometer sensor new data available
'   Returns TRUE or FALSE
    readreg(XLG, core#STATUS_REG, 1, @tmp)
    result := (((tmp >> core#XLDA) & 1) == 1)

PUB AccelG(ax, ay, az) | tmpx, tmpy, tmpz
' Reads the Accelerometer output registers and scales the outputs to
'   micro-g's (1_000_000 = 1.000000 g = 9.8 m/s/s)
    acceldata(@tmpx, @tmpy, @tmpz)
    long[ax] := tmpx * _ares
    long[ay] := tmpy * _ares
    long[az] := tmpz * _ares

PUB AccelHighRes(state): curr_state
' Enable high resolution mode for accelerometer
'   Valid values: FALSE (0) or TRUE (1 or -1)
'   Any other value polls the chip and returns the current setting
    return booleanchoice(XLG, core#CTRL_REG7_XL, core#HR, core#HR, {
}   core#CTRL_REG7_XL_MASK, state, 1)

PUB AccelInt{}: flag
' Flag indicating accelerometer interrupt asserted
'   Returns TRUE if interrupt asserted, FALSE if not
    readreg(XLG, core#STATUS_REG, 1, @flag)
    return (((flag >> core#IG_XL) & 1) == 1)

PUB AccelIntClear{} | tmp, reg_nr
' Clears out any interrupts set up on the Accelerometer
'   and resets all Accelerometer interrupt registers to their default values.
    tmp := 0
    repeat reg_nr from core#INT_GEN_CFG_XL to core#INT_GEN_DUR_XL
        writereg(XLG, reg_nr, 1, @tmp)
    readreg(XLG, core#INT1_CTRL, 1, @tmp)
    tmp &= core#INT1_IG_XL_MASK
    writereg(XLG, core#INT1_CTRL, 1, @tmp)

PUB AccelScale(scale): curr_scl
' Sets the full-scale range of the Accelerometer, in g's
'   Valid values: 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    readreg(XLG, core#CTRL_REG6_XL, 1, @curr_scl)
    case scale
        2, 4, 8, 16:
            scale := lookdownz(scale: 2, 16, 4, 8)
            _ares := lookupz(scale: 0_000061, 0_000732, 0_000122, 0_000244)
            scale <<= core#FS_XL
        other:
            curr_scl := ((curr_scl >> core#FS_XL) & core#FS_XL_BITS) + 1
            return lookup(curr_scl: 2, 16, 4, 8)

    scale := ((curr_scl & core#FS_XL_MASK) | scale)
    writereg(XLG, core#CTRL_REG6_XL, 1, @scale)

PUB CalibrateMag{} | magmin[3], magmax[3], magtmp[3], axis, samples, orig_opmode, orig_odr
' Calibrate the magnetometer
    longfill(@magmin, 0, 11)                    ' Initialize variables to 0
    orig_opmode := magopmode(-2)                ' Store the user-set operating mode
    orig_odr := magdatarate(-2)                 '   and data rate

    magopmode(MAG_OPMODE_CONT)                  ' Change to continuous measurement mode
    magdatarate(80_000)                         '   and fastest data rate
    magbias(0, 0, 0, W)                         ' Start with offsets cleared

    repeat 5
        repeat until magdataready{}
        magdata(@magtmp[X_AXIS], @magtmp[Y_AXIS], @magtmp[Z_AXIS])
        ' Establish initial minimum and maximum values for averaging:
        ' Start both with the same value to avoid skewing the
        '   calcs (because vars were initialized with 0)
        magmax[X_AXIS] := magmin[X_AXIS] := magtmp[X_AXIS]
        magmax[Y_AXIS] := magmin[Y_AXIS] := magtmp[Y_AXIS]
        magmax[Z_AXIS] := magmin[Z_AXIS] := magtmp[Z_AXIS]

    samples := 100                              ' XXX arbitrary
    repeat samples
        repeat until magdataready{}
        magdata(@magtmp[X_AXIS], @magtmp[Y_AXIS], @magtmp[Z_AXIS])
        repeat axis from X_AXIS to Z_AXIS
            magmin[axis] := magtmp[axis] <# magmin[axis]
            magmax[axis] := magtmp[axis] #> magmax[axis]

    magbias((magmax[X_AXIS] + magmin[X_AXIS]) / 2,{
}   (magmax[Y_AXIS] + magmin[Y_AXIS]) / 2, {
}   (magmax[Z_AXIS] + magmin[Z_AXIS]) / 2, W)

    magopmode(orig_opmode)                      ' Restore the user settings
    magdatarate(orig_odr)

PUB CalibrateXLG{} | abiasrawtmp[3], gbiasrawtmp[3], axis, ax, ay, az, gx, gy, gz, samples ' XXX break this up into CalibrateAccel() and CalibrateGyro(), then this calls both
' Calibrates the Accelerometer and Gyroscope
' Turn on FIFO and set threshold to 32 samples
    fifoenabled(TRUE)
    fifomode(FIFO_THS)
    fifothreshold(31)
    samples := fifothreshold(-2)
    repeat until fifofull{}
    repeat axis from 0 to 2
        gbiasrawtmp[axis] := 0
        abiasrawtmp[axis] := 0

    gyrobias(0, 0, 0, W)                        ' Clear out existing bias offsets
    accelbias(0, 0, 0, W)                       '
    repeat samples
        gyrodata(@gx, @gy, @gz)                 ' read gyro and accel data
        gbiasrawtmp[X_AXIS] += gx               ' from FIFO
        gbiasrawtmp[Y_AXIS] += gy
        gbiasrawtmp[Z_AXIS] += gz

        acceldata(@ax, @ay, @az)
        abiasrawtmp[X_AXIS] += ax
        abiasrawtmp[Y_AXIS] += ay
        ' compensate on z-axis for chip 'facing up' orientation:
        abiasrawtmp[Z_AXIS] += az - (1_000_000 / _ares)

    gyrobias(gbiasrawtmp[X_AXIS]/samples, gbiasrawtmp[Y_AXIS]/samples,{
}   gbiasrawtmp[Z_AXIS]/samples, W)
    accelbias(abiasrawtmp[X_AXIS]/samples, abiasrawtmp[Y_AXIS]/samples,{
}   abiasrawtmp[Z_AXIS]/samples, W)

    fifoenabled(FALSE)
    fifomode(FIFO_OFF)

PUB DeviceID{}: id
' Read device identification
'   Returns: $683D
    id := 0
    readreg(XLG, core#WHO_AM_I_XG, 1, @id.byte[1])
    readreg(MAG, core#WHO_AM_I_M, 1, @id.byte[0])

PUB Endian(order): curr_order  'XXX rename to DataByteOrder()
' Choose byte order of acclerometer/gyroscope data
'   Valid values: LITTLE (0) or BIG (1)
'   Any other value polls the chip and returns the current setting
    readreg(XLG, core#CTRL_REG8, 1, @curr_order)
    case order
        LITTLE, BIG:
            order := order << core#BLE
        other:
            return ((curr_order >> core#BLE) & 1)

    order := ((curr_order & core#BLE_MASK) | order)
    writereg(XLG, core#CTRL_REG8, 1, @order)

PUB FIFOEnabled(state): curr_state
' Enable FIFO memory
'   Valid values: FALSE (0), TRUE(1 or -1)
'   Any other value polls the chip and returns the current setting
    return booleanchoice(XLG, core#CTRL_REG9, core#FIFO_EN, core#FIFO_EN,{
}   core#CTRL_REG9_MASK, state, 1)

PUB FIFOFull{}: flag
' FIFO Threshold status
'   Returns: FALSE (0): lower than threshold level, TRUE(-1): at or higher than threshold level
    readreg(XLG, core#FIFO_SRC, 1, @flag)
    return (((flag >> core#FTH_STAT) & 1) == 1)

PUB FIFOMode(mode): curr_mode
' Set FIFO behavior
'   Valid values:
'       FIFO_OFF        (%000) - Bypass mode - FIFO off
'       FIFO_THS        (%001) - Stop collecting data when FIFO full
'       FIFO_CONT_TRIG  (%011) - Continuous mode until trigger is deasserted,
'           then FIFO mode
'       FIFO_OFF_TRIG   (%100) - FIFO off until trigger is deasserted,
'           then continuous mode
'       FIFO_CONT       (%110) - Continuous mode. If FIFO full, new sample
'           overwrites older sample
'   Any other value polls the chip and returns the current setting
    readreg(XLG, core#FIFO_CTRL, 1, @curr_mode)
    case mode
        FIFO_OFF, FIFO_THS, FIFO_CONT_TRIG, FIFO_OFF_TRIG, FIFO_CONT:
            mode <<= core#FMODE
        other:
            return (curr_mode >> core#FMODE) & core#FMODE_BITS

    mode := ((curr_mode & core#FMODE_MASK) | mode)
    writereg(XLG, core#FIFO_CTRL, 1, @mode)

PUB FIFOThreshold(level): curr_lvl
' Set FIFO threshold level
'   Valid values: 0..31
'   Any other value polls the chip and returns the current setting
    readreg(XLG, core#FIFO_CTRL, 1, @curr_lvl)
    case level
        0..31:
        other:
            return curr_lvl & core#FTH_BITS

    level := ((curr_lvl & core#FTH_MASK) | level)
    writereg(XLG, core#FIFO_CTRL, 1, @level)

PUB FIFOUnreadSamples{}: nr_samples
' Number of unread samples stored in FIFO
'   Returns: 0 (empty) .. 32
    readreg(XLG, core#FIFO_SRC, 1, @nr_samples)
    return nr_samples & core#FSS_BITS

PUB GyroAxisEnabled(mask): curr_mask
' Enable data output for Gyroscope - per axis
'   Valid values: FALSE (0) or TRUE (1 or -1), for each axis
'   Any other value polls the chip and returns the current setting
    readreg(XLG, core#CTRL_REG4, 1, @curr_mask)
    case mask
        %000..%111:
            mask <<= core#XEN_G
        other:
            return (curr_mask >> core#XEN_G) & core#EN_G_BITS

    mask := ((curr_mask & core#EN_G_MASK) | mask)
    writereg(XLG, core#CTRL_REG4, 1, @mask)

PUB GyroBias(gxbias, gybias, gzbias, rw)
' Read or write/manually set Gyroscope calibration offset values
'   Valid values:
'       rw:
'           R (0), W (1)
'       gxbias, gybias, gzbias:
'           -32768..32767
'   NOTE: When rw is set to READ, gxbias, gybias and gzbias must be addresses
'       of respective variables to hold the returned calibration offset values.
    case rw
        R:
            long[gxbias] := _gbiasraw[X_AXIS]
            long[gybias] := _gbiasraw[Y_AXIS]
            long[gzbias] := _gbiasraw[Z_AXIS]
        W:
            case gxbias
                -32768..32767:
                    _gbiasraw[X_AXIS] := gxbias
                other:
            case gybias
                -32768..32767:
                    _gbiasraw[Y_AXIS] := gybias
                other:
            case gzbias
                -32768..32767:
                    _gbiasraw[Z_AXIS] := gzbias
                other:

PUB GyroData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data
    readreg(XLG, core#OUT_X_G_L, 6, @tmp)
    long[ptr_x] := ~~tmp.word[X_AXIS] - _gbiasraw[X_AXIS]
    long[ptr_y] := ~~tmp.word[Y_AXIS] - _gbiasraw[Y_AXIS]
    long[ptr_z] := ~~tmp.word[Z_AXIS] - _gbiasraw[Z_AXIS]

PUB GyroDataRate(rate): curr_rate
' Set Gyroscope Output Data Rate, in Hz
'   Valid values: 0, 15, 60, 119, 238, 476, 952
'   Any other value polls the chip and returns the current setting
'   NOTE: 0 powers down the Gyroscope
'   NOTE: 15 and 60 are rounded up from the datasheet specifications of 14.9
'       and 59.5, respectively
    readreg(XLG, core#CTRL_REG1_G, 1, @curr_rate)
    case rate
        0, 15, 60, 119, 238, 476, 952:
            rate := lookdownz(rate: 0, 15, 60, 119, 238, 476, 952) << core#ODR
        other:
            curr_rate := ((curr_rate >> core#ODR) & core#ODR_BITS)
            return lookupz(curr_rate: 0, 15, 60, 119, 238, 476, 952)

    rate := ((curr_rate & core#ODR_MASK) | rate)
    writereg(XLG, core#CTRL_REG1_G, 1, @rate)

PUB GyroDataReady{}: flag
' Flag indicating new gyroscope data available
'   Returns TRUE or FALSE
    readreg(XLG, core#STATUS_REG, 1, @flag)
    return (((flag >> core#GDA) & 1) == 1)

PUB GyroDPS(gx, gy, gz) | tmp[3]
' Read the Gyroscope output registers and scale the outputs to micro-degrees
'   of rotation per second (1_000_000 = 1.000000 deg/sec)
    gyrodata(@tmp[X_AXIS], @tmp[Y_AXIS], @tmp[Z_AXIS])
    long[gx] := tmp[X_AXIS] * _gres
    long[gy] := tmp[Y_AXIS] * _gres
    long[gz] := tmp[Z_AXIS] * _gres

PUB GyroHighPass(freq): curr_freq
' Set Gyroscope high-pass filter cutoff frequency
'   Valid values: 0..9
'   Any other value polls the chip and returns the current setting
    readreg(XLG, core#CTRL_REG3_G, 1, @curr_freq)
    case freq
        0..9:
            freq := freq << core#HPCF_G
        other:
            return (curr_freq >> core#HPCF_G) & core#HPCF_G_BITS

    freq := ((curr_freq & core#HPCF_G_MASK) | freq)
    writereg(XLG, core#CTRL_REG3_G, 1, @freq)

PUB GyroInactiveDur(duration): curr_dur
' Set gyroscope inactivity timer (use GyroInactiveSleep() to define behavior on
'   inactivity)
'   Valid values: 0..255 (0 effectively disables the feature)
'   Any other value polls the chip and returns the current setting
    curr_dur := 0
    readreg(XLG, core#ACT_DUR, 1, @curr_dur)
    case duration
        0..255:
        other:
            return curr_dur

    writereg(XLG, core#ACT_DUR, 1, @duration)

PUB GyroInactiveThr(thresh): curr_thr
' Set gyroscope inactivity threshold (use GyroInactiveSleep() to define
'   behavior on inactivity)
'   Valid values: 0..127 (0 effectively disables the feature)
'   Any other value polls the chip and returns the current setting
    curr_thr := 0
    readreg(XLG, core#ACT_THS, 1, @curr_thr)
    case thresh
        0..127:
        other:
            return curr_thr & core#ACT_THR_BITS

    thresh := ((curr_thr & core#ACT_THR_MASK) | thresh)
    writereg(XLG, core#ACT_THS, 1, @thresh)

PUB GyroInactiveSleep(state): curr_state
' Enable gyroscope sleep mode when inactive (see GyroActivityThr())
'   Valid values:
'       FALSE (0): Gyroscope powers down
'       TRUE (1 or -1) Gyroscope enters sleep mode
'   Any other value polls the chip and returns the current setting
    return booleanChoice(XLG, core#ACT_THS, core#SLP_ON_INACT, {
}   core#SLP_ON_INACT_MASK, core#ACT_THS_MASK, state, 1)

PUB GyroInt{}: flag
' Flag indicating gyroscope interrupt asserted
'   Returns TRUE if interrupt asserted, FALSE if not
    readreg(XLG, core#STATUS_REG, 1, @flag)
    return (((flag >> core#IG_G) & 1) == 1)

PUB GyroIntClear{} | tmp, reg_nr
' Clear gyroscope interrupts and reset all gyroscope interrupt registers to
'   their default values
    tmp := 0
    repeat reg_nr from core#INT_GEN_CFG_G to core#INT_GEN_DUR_G
        writereg(XLG, reg_nr, 1, @tmp)
    readreg(XLG, core#INT1_CTRL, 1, @tmp)
    tmp &= core#INT1_IG_G_MASK
    writereg(XLG, core#INT1_CTRL, 1, @tmp)

PUB GyroIntSelect(mode): curr_mode' XXX expand
' Set gyroscope interrupt generator selection
'   Valid values:
'       *%00..%11
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(XLG, core#CTRL_REG2_G, 1, @curr_mode)
    case mode
        %00..%11:
            mode := mode << core#INT_SEL
        other:
            return (curr_mode >> core#INT_SEL) & core#INT_SEL_BITS

    mode := ((curr_mode & core#INT_SEL_MASK) | mode)
    writereg(XLG, core#CTRL_REG2_G, 1, @mode)

PUB GyroLowPower(state): curr_state
' Enable low-power mode
'   Valid values: FALSE (0), TRUE (1 or -1)
'   Any other value polls the chip and returns the current setting
    return booleanChoice(XLG, core#CTRL_REG3_G, core#LP_MODE, {
}   core#LP_MODE_MASK, core#CTRL_REG3_G_MASK, state, 1)

PUB GyroScale(scale): curr_scale
' Set full scale of gyroscope output, in degrees per second (dps)
'   Valid values: 245, 500, 2000
'   Any other value polls the chip and returns the current setting
    curr_scale := 0
    readreg(XLG, core#CTRL_REG1_G, 1, @curr_scale)
    case scale
        245, 500, 2000:
            scale := lookdownz(scale: 245, 500, 0, 2000)
            _gres := lookupz(scale: 0_008750, 0_017500, 0, 0_070000)
            scale <<= core#FS
        other:
            curr_scale := ((curr_scale >> core#FS) & core#FS_BITS) + 1
            return lookup(curr_scale: 245, 500, 0, 2000)

    scale := ((curr_scale & core#FS_MASK) | scale)
    writereg(XLG, core#CTRL_REG1_G, 1, @scale)

PUB GyroSleep(state): curr_state
' Enable gyroscope sleep mode
'   Valid values: FALSE (0), TRUE (1 or -1)
'   Any other value polls the chip and returns the current setting
'   NOTE: If state, the gyro output will contain the last measured values
    return booleanChoice(XLG, core#CTRL_REG9, core#SLP_G, core#SLP_G_MASK,{
}   core#CTRL_REG9_MASK, state, 1)

PUB Interrupt{}: flag
' Flag indicating one or more interrupts asserted
'   Returns TRUE if one or more interrupts asserted, FALSE if not
    readreg(XLG, core#INT_GEN_SRC_XL, 1, @flag)
    return (((flag >> core#IA_XL) & 1) == 1)

PUB IntInactivity{}: flag
' Flag indicating inactivity interrupt asserted
'   Returns TRUE if interrupt asserted, FALSE if not
    readreg(XLG, core#STATUS_REG, 1, @flag)
    return (((flag >> core#INACT) & 1) == 1)

PUB MagBlockUpdate(state): curr_state
' Enable block update for magnetometer data
'   Valid values:
'       TRUE(-1 or 1): Output registers not updated until MSB and LSB have been
'           read
'       FALSE(0): Continuous update
'   Any other value polls the chip and returns the current setting
    return booleanChoice (MAG, core#CTRL_REG5_M, core#BDU_M, core#BDU_M_MASK,{
}   core#CTRL_REG5_M_MASK, state, 1)

PUB MagBias(mxbias, mybias, mzbias, rw) | axis, msb, lsb
' Read or write/manually set Magnetometer calibration offset values
'   Valid values:
'       rw:
'           R (0), W (1)
'       mxbias, mybias, mzbias:
'           -32768..32767
'   NOTE: When rw is set to READ, mxbias, mybias and mzbias must be addresses
'       of respective variables to hold the returned calibration offset values
    case rw
        R:
            long[mxbias] := _mbiasraw[X_AXIS]
            long[mybias] := _mbiasraw[Y_AXIS]
            long[mzbias] := _mbiasraw[Z_AXIS]
        W:
            case mxbias
                -32768..32767:
                    _mbiasraw[X_AXIS] := mxbias
                other:
            case mybias
                -32768..32767:
                    _mbiasraw[Y_AXIS] := mybias
                other:
            case mzbias
                -32768..32767:
                    _mbiasraw[Z_AXIS] := mzbias
                other:
            repeat axis from X_AXIS to Z_AXIS
                msb := (_mbiasraw[axis] & $FF00) >> 8
                lsb := _mbiasraw[axis] & $00FF
                writereg(MAG, core#OFFSET_X_REG_L_M + (2 * axis), 1, @lsb)
                writereg(MAG, core#OFFSET_X_REG_H_M + (2 * axis), 1, @msb)

PUB MagData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read the Magnetometer output registers
    readreg(MAG, core#OUT_X_L_M, 6, @tmp)
    long[ptr_x] := ~~tmp.word[X_AXIS]              ' no offset correction
    long[ptr_y] := ~~tmp.word[Y_AXIS]              ' because the mag has
    long[ptr_z] := ~~tmp.word[Z_AXIS]              ' offset registers built-in

PUB MagDataOverrun{}: status
' Magnetometer data overrun
'   Returns: Overrun flag as bitfield
'       MSB   LSB
'       |     |
'       3 2 1 0
'       3: All axes data overrun
'       2: Z-axis data overrun
'       1: Y-axis data overrun
'       0: X-axis data overrun
'   Example:
'       %1111: Indicates data has overrun on all axes
'       %0010: Indicates Y-axis data has overrun
'   NOTE: Overrun flag indicates new data for axis has overwritten the previous data.
    readreg(MAG, core#STATUS_REG_M, 1, @status)
    return ((status >> core#OVERRN) & core#OVERRN_BITS)

PUB MagDataRate(rate): curr_rate
' Set Magnetometer Output Data Rate, in milli-Hz
'   Valid values: 625, 1250, 2500, 5000, *10_000, 20_000, 40_000, 80_000
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(MAG, core#CTRL_REG1_M, 1, @curr_rate)
    case rate
        625, 1250, 2500, 5000, 10_000, 20_000, 40_000, 80_000:
            rate := lookdownz(rate: 625, 1250, 2500, 5000, 10_000, 20_000, {
}           40_000, 80_000) << core#DO
        other:
            curr_rate := ((curr_rate >> core#DO) & core#DO_BITS)
            return lookupz(curr_rate: 625, 1250, 2500, 5000, 10_000, 20_000, {
}           40_000, 80_000)

    rate := ((curr_rate & core#DO_MASK) | rate)
    writereg(MAG, core#CTRL_REG1_M, 1, @rate)

PUB MagDataReady{}: flag
' Flag indicating new magnetometer data ready
'   Returns: TRUE (-1) if data available, FALSE (0) otherwise
    readreg(MAG, core#STATUS_REG_M, 1, @flag)
    return (((flag >> core#ZYXDA) & 1) == 1)

PUB MagEndian(order): curr_order
' Choose byte order of magnetometer data
'   Valid values: LITTLE (0) or BIG (1)
'   Any other value polls the chip and returns the current setting
    curr_order := 0
    readreg(MAG, core#CTRL_REG4_M, 1, @curr_order)
    case order
        LITTLE, BIG:
            order := order << core#BLE_M
        other:
            return ((curr_order >> core#BLE_M) & 1)

    order := ((curr_order & core#BLE_M_MASK) | order)
    writereg(MAG, core#CTRL_REG4_M, 1, @order)

PUB MagFastRead(state): curr_state
' Enable reading of only the MSB of data to increase reading efficiency, at
'   the cost of precision and accuracy
'   Valid values: TRUE(-1 or 1), FALSE(0)
'   Any other value polls the chip and returns the current setting
    return booleanChoice (MAG, core#CTRL_REG5_M, core#FAST_READ, {
}   core#FAST_READ_MASK, core#CTRL_REG5_M_MASK, state, 1)

PUB MagGauss(ptr_x, ptr_y, ptr_z) | tmp[3]
' Read the Magnetometer output registers and scale the outputs to micro-Gauss
'   (1_000_000 = 1.000000 Gs)
    magdata(@tmp[X_AXIS], @tmp[Y_AXIS], @tmp[Z_AXIS])
    long[ptr_x] := tmp[X_AXIS] * _mres
    long[ptr_y] := tmp[Y_AXIS] * _mres
    long[ptr_z] := tmp[Z_AXIS] * _mres

PUB MagInt{}: intsrc
' Magnetometer interrupt source(s)
'   Returns: Interrupts that are currently asserted, as a bitmask
'   MSB    LSB
'   |      |
'   76543210
'   7: X-axis exceeds threshold, positive side
'   6: Y-axis exceeds threshold, positive side
'   5: Z-axis exceeds threshold, positive side
'   4: X-axis exceeds threshold, negative side
'   3: Y-axis exceeds threshold, negative side
'   2: Z-axis exceeds threshold, negative side
'   1: A measurement exceeded the magnetometer's measurement range (overflow)
'   0: Interrupt asserted
    readreg(MAG, core#INT_SRC_M, 1, @intsrc)

PUB MagIntClear{} | tmp
' Clears out any interrupts set up on the Magnetometer and
'   resets all Magnetometer interrupt registers to their default values
    tmp := 0
    writereg(MAG, core#INT_SRC_M, 1, @tmp)

PUB MagIntLevel(state): curr_state
' Set active state of INT_MAG pin when magnetometer interrupt asserted
'   Valid values: ACTIVE_LOW (0), ACTIVE_HIGH (1)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(MAG, core#INT_CFG_M, 1, @curr_state)
    case state
        ACTIVE_LOW, ACTIVE_HIGH:
            state ^= 1                   ' This bit's polarity is
            state <<= core#IEA           ' opposite that of the XLG
        other:
            return (curr_state >> core#IEA) & 1

    state := ((curr_state & core#IEA_MASK) | state)
    writereg(MAG, core#INT_CFG_M, 1, @state)

PUB MagIntsEnabled(mask): curr_mask
' Enable magnetometer interrupts, as a bitmask
'   Valid values: %000..%111
'     MSB   LSB
'       |   |
'       2 1 0
'       2: X-axis data overrun
'       1: Y-axis data overrun
'       0: Z-axis dta overrun
'   Example:
'       %111: Enable interrupts for all three axes
'       %010: Enable interrupts for Y axis only

'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readreg(MAG, core#INT_CFG_M, 1, @curr_mask)
    case mask
        %000..%111:
            mask <<= core#XYZIEN
        other:
            return (curr_mask >> core#XYZIEN) & core#XYZIEN_BITS

    mask := ((curr_mask & core#XYZIEN_MASK) | mask)
    writereg(MAG, core#INT_CFG_M, 1, @mask)

PUB MagIntsLatched(state): curr_state
' Latch interrupts asserted by the magnetometer
'   Valid values: TRUE (-1 or 1) or FALSE
'   Any other value polls the chip and returns the current setting
'   NOTE: If enabled, interrupts must be explicitly cleared using MagClearInt()
'        XXX verify
    return booleanchoice(MAG, core#INT_CFG_M, core#IEL, core#IEL_MASK,{
}   core#INT_CFG_M, state, -1)

PUB MagIntThresh(thresh): curr_thr 'XXX rewrite to take gauss as a param
' Set magnetometer interrupt threshold
'   Valid values: 0..32767
'   Any other value polls the chip and returns the current setting
'   NOTE: The set thresh is an absolute value and is compared to positive and
'       negative measurements alike
    curr_thr := 0
    readreg(MAG, core#INT_THS_L_M, 2, @curr_thr)
    case thresh
        0..32767:
            swap(@thresh)
        other:
            swap(@curr_thr)
            return curr_thr

    curr_thr := thresh & $7FFF
    writereg(MAG, core#INT_THS_L_M, 2, @curr_thr)

PUB MagLowPower(state): curr_state
' Enable magnetometer low-power mode
'   Valid values: TRUE (-1 or 1) or FALSE
'   Any other value polls the chip and returns the current setting
    return booleanchoice(MAG, core#CTRL_REG3_M, core#LP, core#LP_MASK, {
}   core#CTRL_REG3_M_MASK, state, 1)

PUB MagOpMode(mode): curr_mode
' Set magnetometer operating mode
'   Valid values:
'       MAG_OPMODE_CONT (0): Continuous conversion
'       MAG_OPMODE_SINGLE (1): Single conversion
'       MAG_OPMODE_POWERDOWN (2): Power down
    curr_mode := 0
    readreg(MAG, core#CTRL_REG3_M, 1, @curr_mode)
    case mode
        MAG_OPMODE_CONT, MAG_OPMODE_SINGLE, MAG_OPMODE_POWERDOWN:
        other:
            return (curr_mode & core#MD_BITS)

    mode := ((curr_mode & core#MD_MASK) | mode)
    writereg(MAG, core#CTRL_REG3_M, 1, @mode)

PUB MagOverflow{}: flag
' Flag indicating magnetometer measurement has overflowed
'   Returns:
'       TRUE (-1) if measurement overflows sensor's internal range
'       FALSE (0) otherwise
    return (((magint{} >> core#MROI) & 1) == 1)

PUB MagPerf(mode): curr_mode
' Set magnetometer performance mode
'   Valid values:
'       MAG_PERF_LOW (0)
'       MAG_PERF_MED (1)
'       MAG_PERF_HIGH (2)
'       MAG_PERF_ULTRA (3)
'   Any other value polls the chip and returns the current setting
    readreg(MAG, core#CTRL_REG1_M, 1, @curr_mode.byte[0])
    readreg(MAG, core#CTRL_REG4_M, 1, @curr_mode.byte[1])

    case mode
        MAG_PERF_LOW, MAG_PERF_MED, MAG_PERF_HIGH, MAG_PERF_ULTRA:
        other:
            return (curr_mode.byte[0] >> core#OM) & core#OM_BITS

    curr_mode.byte[0] &= core#OM_MASK
    curr_mode.byte[0] := (curr_mode.byte[0] | (mode << core#OM))
    curr_mode.byte[1] &= core#OMZ_MASK
    curr_mode.byte[1] := (curr_mode.byte[1] | (mode << core#OMZ))

    writereg(MAG, core#CTRL_REG1_M, 1, @curr_mode.byte[0])
    writereg(MAG, core#CTRL_REG4_M, 1, @curr_mode.byte[1])

PUB MagScale(scale): curr_scl
' Set full scale of Magnetometer, in Gauss
'   Valid values: 4, 8, 12, 16
'   Any other value polls the chip and returns the current setting
    curr_scl := 0
    readreg(MAG, core#CTRL_REG2_M, 1, @curr_scl)
    case(scale)
        4, 8, 12, 16:
            scale := lookdownz(scale: 4, 8, 12, 16)
            _mres := lookupz(scale: 0_000140, 0_000290, 0_000430, 0_000580)
            scale <<= core#FS_M
        other:
            curr_scl := (curr_scl >> core#FS_M) & core#FS_M_BITS
            return lookupz(curr_scl: 4, 8, 12, 16)

    ' Mask off ALL other bits, because the only other
    ' fields in this reg are for performing soft-reset/reboot
    curr_scl := scale & (core#FS_M_BITS << core#FS_M)
    writereg(MAG, core#CTRL_REG2_M, 1, @curr_scl)

PUB MagSelfTest(state): curr_state
' Enable on-chip magnetometer self-test
'   Valid values: TRUE (-1 or 1) or FALSE
'   Any other value polls the chip and returns the current setting
    return booleanchoice(MAG, core#CTRL_REG1_M, core#ST, core#ST_MASK, {
}   core#CTRL_REG1_M_MASK, state, 1)

PUB MagSoftreset{} | tmp
' Perform soft-test of magnetometer
    tmp := (1 << core#RE_BOOT) | (1 << core#SOFT_RST)
    tmp &= core#CTRL_REG2_M_MASK
    writereg(MAG, core#CTRL_REG2_M, 1, @tmp)
    time.msleep(10)

    tmp := 0                                    ' clear reset bit manually
    writereg(MAG, core#CTRL_REG2_M, 1, @tmp)    ' to come out of reset
    setspi3wiremode{}

PUB Temperature{}: temp
' Get temperature from chip
'   Returns: Temperature in hundredths of a degree in chosen scale
    return adc2temp(tempdata{})

PUB TempCompensation(enable): curr_setting
' Enable on-chip temperature compensation for magnetometer readings
'   Valid values: TRUE (-1 or 1) or FALSE
'   Any other value polls the chip and returns the current setting
    return booleanchoice(MAG, core#CTRL_REG1_M, core#TEMP_COMP, {
}   core#TEMP_COMP_MASK, core#CTRL_REG1_M, enable, 1)

PUB TempData{}: temp_adc
' Temperature ADC data
    temp_adc := 0
    readreg(XLG, core#OUT_TEMP_L, 2, @temp_adc)
    return ~~temp_adc

PUB TempDataReady{}: flag
' Temperature sensor new data available
'   Returns TRUE or FALSE
    readreg(XLG, core#STATUS_REG, 1, @flag)
    return (((flag >> core#TDA) & 1) == 1)

PUB TempScale(scale): curr_scl
' Set temperature scale used by Temperature method
'   Valid values:
'      *C (0): Celsius
'       F (1): Fahrenheit
'   Any other value returns the current setting
    case scale
        C, F:
            _temp_scale := scale
        other:
            return _temp_scale

PRI XLGDataBlockUpdate(state): curr_state
' Wait until both MSB and LSB of output registers are read before updating
'   Valid values:
'       FALSE (0): Continuous update
'       TRUE (1 or -1): Do not update until both MSB and LSB are read
'   Any other value polls the chip and returns the current setting
    return booleanchoice(XLG, core#CTRL_REG8, core#BDU, core#BDU_MASK,{
}   core#CTRL_REG8_MASK, state, 1)

PUB XLGDataRate(rate): curr_rate
' Set output data rate of accelerometer and gyroscope, in Hz
'   Valid values: 0 (power down), 14, 59, 119, 238, 476, 952
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(XLG, core#CTRL_REG1_G, 1, @curr_rate)
    case rate := lookdown(rate: 0, 14{.9}, 59{.5}, 119, 238, 476, 952)
        1..7:
            rate := (rate - 1) << core#ODR
        other:
            curr_rate := ((curr_rate >> core#ODR) & core#ODR_BITS) + 1
            return lookup(curr_rate: 0, 14{.9}, 59{.5}, 119, 238, 476, 952)

    rate := ((curr_rate & core#ODR_MASK) | rate)
    writereg(XLG, core#CTRL_REG1_G, 1, @rate)

PUB XLGIntLevel(state): curr_state
' Set active state for interrupts from Accelerometer and Gyroscope
'   Valid values: ACTIVE_HIGH (0) - active high, ACTIVE_LOW (1) - active low
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(XLG, core#CTRL_REG8, 1, @curr_state)
    case state
        ACTIVE_HIGH, ACTIVE_LOW:
            state := state << core#H_LACTIVE
        other:
            return ((curr_state >> core#H_LACTIVE) & 1)

    state := ((curr_state & core#H_LACTIVE_MASK) | state)
    writereg(XLG, core#CTRL_REG8, 1, @state)

PUB XLGSoftreset{} | tmp
' Perform soft-reset of accelerometer/gyroscope
    tmp := core#XLG_SW_RESET
    writereg(XLG, core#CTRL_REG8, 1, @tmp)
    time.msleep(10)

PUB setAccelInterrupt(axis, threshold, duration, overunder, andOr) | tmpregvalue, accelths, accelthsh, tmpths
'Configures the Accelerometer interrupt output to the INT_A/G pin.
'XXX LEGACY METHOD
    overunder &= $01
    andOr &= $01
    tmpregvalue := 0
    readreg(XLG, core#CTRL_REG4, 1, @tmpregvalue)
    tmpregvalue &= $FD
    writereg(XLG, core#CTRL_REG4, 1, @tmpregvalue)
    readreg(XLG, core#INT_GEN_CFG_XL, 1, @tmpregvalue)
    if andOr
        tmpregvalue |= $80
    else
        tmpregvalue &= $7F
    if (threshold < 0)
        threshold := -1 * threshold
    accelths := 0
    tmpths := 0
    tmpths := (_ares * threshold) >> 7
    accelths := tmpths & $FF

    case(axis)
        X_AXIS:
            tmpregvalue |= (1 <<(0 + overunder))
            writereg(XLG, core#INT_GEN_THS_X_XL, 1, @accelths)
        Y_AXIS:
            tmpregvalue |= (1 <<(2 + overunder))
            writereg(XLG, core#INT_GEN_THS_Y_XL, 1, @accelths)
        Z_AXIS:
            tmpregvalue |= (1 <<(4 + overunder))
            writereg(XLG, core#INT_GEN_THS_Z_XL, 1, @accelths)
        other:
            writereg(XLG, core#INT_GEN_THS_X_XL, 1, @accelths)
            writereg(XLG, core#INT_GEN_THS_Y_XL, 1, @accelths)
            writereg(XLG, core#INT_GEN_THS_Z_XL, 1, @accelths)
            tmpregvalue |= (%00010101 << overunder)
    writereg(XLG, core#INT_GEN_CFG_XL, 1, @tmpregvalue)
    if (duration > 0)
        duration := $80 | (duration & $7F)
    else
        duration := 0
    writereg(XLG, core#INT_GEN_DUR_XL, 1, @duration)
    readreg(XLG, core#INT1_CTRL, 1, @tmpregvalue)
    tmpregvalue |= $40
    writereg(XLG, core#INT1_CTRL, 1, @tmpregvalue)

PUB setGyroInterrupt(axis, threshold, duration, overunder, andOr) | tmpregvalue, gyroths, gyrothsh, gyrothsl
' Configures the Gyroscope interrupt output to the INT_A/G pin.
' XXX LEGACY METHOD
    overunder &= $01
    tmpregvalue := 0
    readreg(XLG, core#CTRL_REG4, 1, @tmpregvalue)
    tmpregvalue &= $FD
    writereg(XLG, core#CTRL_REG4, 1, @tmpregvalue)
    writereg(XLG, core#CTRL_REG4, 1, @tmpregvalue)
    readreg(XLG, core#INT_GEN_CFG_G, 1, @tmpregvalue)
    if andOr
        tmpregvalue |= $80
    else
        tmpregvalue &= $7F
    gyroths := 0
    gyrothsh := 0
    gyrothsl := 0
    gyroths := _gres * threshold 'TODO: REVIEW (use limit min/max operators and eliminate conditionals below?)

    if gyroths > 16383
        gyroths := 16383
    if gyroths < -16384
        gyroths := -16384
    gyrothsl := (gyroths & $FF)
    gyrothsh := (gyroths >> 8) & $7F

    case(axis)
        X_AXIS :
            tmpregvalue |= (1 <<(0 + overunder))
            writereg(XLG, core#INT_GEN_THS_XH_G, 1, @gyrothsh)
            writereg(XLG, core#INT_GEN_THS_XL_G, 1, @gyrothsl)
        Y_AXIS :
            tmpregvalue |= (1 <<(2 + overunder))
            writereg(XLG, core#INT_GEN_THS_YH_G, 1, @gyrothsh)
            writereg(XLG, core#INT_GEN_THS_YL_G, 1, @gyrothsl)
        Z_AXIS :
            tmpregvalue |= (1 <<(4 + overunder))
            writereg(XLG, core#INT_GEN_THS_ZH_G, 1, @gyrothsh)
            writereg(XLG, core#INT_GEN_THS_ZL_G, 1, @gyrothsl)
        OTHER :
            writereg(XLG, core#INT_GEN_THS_XH_G, 1, @gyrothsh)
            writereg(XLG, core#INT_GEN_THS_XL_G, 1, @gyrothsl)
            writereg(XLG, core#INT_GEN_THS_YH_G, 1, @gyrothsh)
            writereg(XLG, core#INT_GEN_THS_YL_G, 1, @gyrothsl)
            writereg(XLG, core#INT_GEN_THS_ZH_G, 1, @gyrothsh)
            writereg(XLG, core#INT_GEN_THS_ZL_G, 1, @gyrothsl)
            tmpregvalue |= (%00010101 << overunder)
    writereg(XLG, core#INT_GEN_CFG_G, 1, @tmpregvalue)
    if (duration > 0)
        duration := $80 | (duration & $7F)
    else
        duration := 0
    writereg(XLG, core#INT_GEN_DUR_G, 1, @duration)
    readreg(XLG, core#INT1_CTRL, 1, @tmpregvalue)
    tmpregvalue |= $80
    writereg(XLG, core#INT1_CTRL, 1, @tmpregvalue)

PRI adc2temp(temp_word): temp_cal
' Calculate temperature, using temperature word
'   Returns: temperature, in hundredths of a degree, in chosen scale
    temp_cal := ((temp_word * 10) / 16) + 2500
    case _temp_scale
        C:
            return
        F:
            return ((temp_cal * 90) / 50) + 32_00
        other:
            return FALSE

PRI addressAutoInc(state): curr_state
' Enable automatic address increment, for multibyte transfers (SPI and I2C)
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(XLG, core#CTRL_REG8, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state)) << core#IF_ADD_INC
        other:
            return (((curr_state >> core#IF_ADD_INC) & 1) == 1)

    state := ((curr_state & core#IF_ADD_INC) | state)
    writereg(XLG, core#CTRL_REG8, 1, @state)

PRI MagI2C(state): curr_state
' Enable Magnetometer I2C interface
'   Valid values: *TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    return booleanchoice(MAG, core#CTRL_REG3_M, core#M_I2C_DIS, {
}   core#M_I2C_DIS_MASK, core#CTRL_REG3_M_MASK, state, -1)

PRI setSPI3WireMode{} | tmp
' Set SPI interface to 3-wire mode
    tmp := core#XLG_3WSPI
    writereg(XLG, core#CTRL_REG8, 1, @tmp)
    tmp := core#M_3WSPI
    writereg(MAG, core#CTRL_REG3_M, 1, @tmp)

PRI swap(word_addr)

    byte[word_addr][3] := byte[word_addr][0]
    byte[word_addr][0] := byte[word_addr][1]
    byte[word_addr][1] := byte[word_addr][3]
    byte[word_addr][3] := 0

PRI booleanChoice(device, reg_nr, field, fieldmask, regmask, choice, invertchoice): bool
' Reusable method for writing a field that is of a boolean or on-off type
'   device: AG or MAG
'   reg: register
'   field: field within register to modify
'   fieldmask: bitmask that clears the bits in the field being modified
'   regmask: bitmask to ensure only valid bits within the register can be modified
'   choice: the choice (TRUE/FALSE, 1/0)
'   invertchoice: whether to invert the boolean logic (1 for normal, -1 for inverted)
    bool := 0
    readreg(device, reg_nr, 1, @bool)
    case ||(choice)
        0, 1:
            choice := ||(choice * invertchoice) << field
        other:
            return ((((bool >> field) & 1) == 1) * invertchoice)

    bool &= fieldmask
    bool := (bool | choice) & regmask
    choice := ((bool & fieldmask) | choice) & regmask
    writereg(device, reg_nr, 1, @choice)

PRI readReg(device, reg_nr, nr_bytes, ptr_buff) | tmp
' Read from device
' Validate register - allow only registers that are
'   not 'reserved' (ST states reading should only be performed on registers listed in
'   their datasheet to guarantee proper behavior of the device)
    case device
        XLG:
            case reg_nr
                $04..$0D, $0F..$24, $26..$37:
                    outa[_CS_AG] := 0
                    spi.wr_byte(reg_nr | READ)
                    spi.rdblock_lsbf(ptr_buff, nr_bytes)
                    outa[_CS_AG] := 1
                other:
                    return
        MAG:
            case reg_nr
                $05..$0A, $0F, $20..$24, $27..$2D, $30..$33:
                    reg_nr |= READ
                    reg_nr |= MS
                    outa[_CS_M] := 0
                    spi.wr_byte(reg_nr)
                    spi.rdblock_lsbf(ptr_buff, nr_bytes)
                    outa[_CS_M] := 1
                other:
                    return

        other:
            return

PRI writeReg(device, reg_nr, nr_bytes, ptr_buff) | tmp
' Write byte to device
'   Validate register - allow only registers that are
'       writeable, and not 'reserved' (ST claims writing to these can
'       permanently damage the device)
    case device
        XLG:
            case reg_nr
                $04..$0D, $10..$13, $1E..$21, $23, $24, $2E, $30..$37:
                    outa[_CS_AG] := 0
                    spi.wr_byte(reg_nr)
                    spi.wrblock_lsbf(ptr_buff, nr_bytes)
                    outa[_CS_AG] := 1
                core#CTRL_REG8:
                    outa[_CS_AG] := 0
                    spi.wr_byte(reg_nr)
                    ' enforce 3-wire SPI mode
                    byte[ptr_buff][0] := byte[ptr_buff][0] | (1 << core#SIM)
                    spi.wrblock_lsbf(ptr_buff, nr_bytes)
                    outa[_CS_AG] := 1
                other:
                    return
        MAG:
            case reg_nr
                $05..$0A, $0F, $20, $21, $23, $24, $27..$2D, $30..$33:
                    reg_nr |= WRITE
                    reg_nr |= MS
                    outa[_CS_M] := 0
                    spi.wr_byte(reg_nr)
                    spi.wrblock_lsbf(ptr_buff, nr_bytes)
                    outa[_CS_M] := 1
                core#CTRL_REG3_M:
                    reg_nr |= WRITE
                    outa[_CS_M] := 0
                    spi.wr_byte(reg_nr)
                    ' enforce 3-wire SPI mode
                    byte[ptr_buff][0] := byte[ptr_buff][0] | (1 << core#M_SIM)
                    spi.wrblock_lsbf(ptr_buff, nr_bytes)
                    outa[_CS_M] := 1
                other:
                    return
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
