{
    --------------------------------------------
    Filename: sensor.accel.3dof.adxl345.spin
    Author: Jesse Burt
    Description: Driver for the Analog Devices ADXL345 3DoF Accelerometer
    Copyright (c) 2022
    Started Mar 14, 2020
    Updated Nov 5, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#include "sensor.accel.common.spinh"

CON

' Constants used for I2C mode only
    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF       = 3
    GYRO_DOF        = 0
    MAG_DOF         = 0
    BARO_DOF        = 0
    DOF             = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

    R               = 0
    W               = 1

' Scales and data rates used during calibration/bias/offset process
    CAL_XL_SCL      = 2
    CAL_G_SCL       = 0
    CAL_M_SCL       = 0
    CAL_XL_DR       = 100
    CAL_G_DR        = 0
    CAL_M_DR        = 0

' Scale factors used to calculate various register values
    SCL_TAPTHRESH   = 0_062500  {THRESH_TAP: 0.0625 mg/LSB}
    SCL_TAPDUR      = 625       {DUR: 625 usec/LSB}
    SCL_TAPLAT      = 1250      {LATENT: 1250 usec/LSB}
    SCL_DTAPWINDOW  = 1250      {WINDOW: 1250 usec/LSB}

' Operating modes
    STANDBY         = 0
    MEAS            = 1
    LOWPWR          = 3

' FIFO modes
    BYPASS          = %00
    FIFO            = %01
    STREAM          = %10
    TRIGGER         = %11

' ADC resolution
    FULL            = 1

' Interrupts
    INT_DRDY        = 1 << 7
    INT_SNGTAP      = 1 << 6
    INT_DBLTAP      = 1 << 5
    INT_ACTIV       = 1 << 4
    INT_INACT       = 1 << 3
    INT_FFALL       = 1 << 2
    INT_WTRMARK     = 1 << 1
    INT_OVRRUN      = 1

' Axis symbols for use throughout the driver
    X_AXIS          = 0
    Y_AXIS          = 1
    Z_AXIS          = 2

' Interrupt active state
    LOW             = 0
    HIGH            = 1

VAR

    long _CS

OBJ

{ SPI? }
#ifdef ADXL345_SPI
{ decide: Bytecode SPI engine, or PASM? Default is PASM if BC isn't specified }
#ifdef ADXL345_SPI_BC
    spi : "com.spi.25khz.nocog"                       ' BC SPI engine
#else
    spi : "com.spi.1mhz"                          ' PASM SPI engine
#endif
#else
{ no, not SPI - default to I2C }
#define ADXL345_I2C
{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef ADXL345_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif

#endif
    core: "core.con.adxl345"                    ' HW-specific constants
    time: "time"                                ' timekeeping methods

PUB null{}
' This is not a top-level object

#ifdef ADXL345_I2C
PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom I/O pin settings (I2C)
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)
            i2c.write($FF)
            repeat 2
                i2c.stop{}
            spimode(4)
            if (dev_id{} == core#DEVID_RESP)
                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#elseifdef ADXL345_SPI
PUB startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN): status
' Start using custom I/O pin settings (SPI-4 wire)
    if lookdown(CS_PIN: 0..31) and lookdown(SCL_PIN: 0..31) and {
}   lookdown(SDA_PIN: 0..31) and lookdown(SDO_PIN: 0..31)
        if (status := spi.init(SCL_PIN, SDA_PIN, SDO_PIN, core#SPI_MODE))
            time.msleep(1)
            _CS := CS_PIN

            outa[_CS] := 1                      ' ensure CS starts high
            dira[_CS] := 1
            if (SDA_PIN == SDO_PIN)
                spimode(3)
            else
                spimode(4)
            if (dev_id{} == core#DEVID_RESP)
                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#endif

PUB stop{}
' Stop the driver
#ifdef ADXL345_I2C
    i2c.deinit{}
#elseifdef ADXL345_SPI
    spi.deinit{}
#endif
    _CS := 0

PUB defaults{}
' Factory default settings
    accel_adc_res(10)
    accel_data_rate(100)
    accel_scale(2)
    accel_self_test(FALSE)
    fifo_mode(BYPASS)
    accel_int_set_mask(%00000000)
    accel_opmode(STANDBY)

PUB preset_active{}
' Like defaults(), but sensor measurement active
    defaults{}
    accel_opmode(MEAS)

PUB preset_clickdet{}
' Presets for click-detection
    accel_opmode(MEAS)
    accel_adc_res(FULL)
    accel_scale(4)
    accel_data_rate(100)
    click_set_thresh(2_500000)                  ' must be > 2.5g to be a tap
    click_axis_ena(%001)                        ' watch z-axis only
    click_set_time(5_000)                       ' must be < 5ms to be a tap
    click_set_latency(100_000)                  ' wait for 100ms after 1st tap
                                                '   to check for second tap
    dbl_click_set_win(300_000)                  ' check second tap for 300ms
    click_int_ena(TRUE)

PUB preset_freefall{}
' Preset settings for free-fall detection
    accel_data_rate(100)
    accel_scale(2)
    freefall_set_time(100_000)                  ' 100_000us/100ms min time
    freefall_set_thresh(0_315000)               ' 0.315g's
    accel_opmode(MEAS)
    accel_int_set_mask(INT_FFALL)               ' enable free-fall interrupt

PUB accel_adc_res(bits): curr_res
' Set accelerometer ADC resolution, in bits
'   Valid values:
'       10: 10bit ADC resolution (AccelScale determines maximum g range and scale factor)
'       FULL: Output resolution increases with the g range, maintaining a 4mg/LSB scale factor
'   Any other value polls the chip and returns the current setting
    curr_res := 0
    readreg(core#DATA_FORMAT, 1, @curr_res)
    case bits
        10:
            bits := 0
        FULL:
            bits <<= core#FULL_RES
        other:
            return ((curr_res >> core#FULL_RES) & 1)

    bits := ((curr_res & core#FULL_RES_MASK) | bits)
    writereg(core#DATA_FORMAT, 1, @bits)

PUB accel_bias(x, y, z) | tmp, scl_fact
' Read accelerometer calibration offset values
'   x, y, z: pointers to copy offsets to
    scl_fact := (15_600 / _ares)
    tmp := 0
    readreg(core#OFSX, 3, @tmp)
    long[x] := ~tmp.byte[X_AXIS] * scl_fact
    long[y] := ~tmp.byte[Y_AXIS] * scl_fact
    long[z] := ~tmp.byte[Z_AXIS] * scl_fact

PUB accel_set_bias(x, y, z) | scl_fact
' Write accelerometer calibration offset values
'   Valid values: -128..127 (clamped to range)
    scl_fact := (15_600 / _ares)
    x := -128 #> ((x * 1_000) / scl_fact) <# 127
    y := -128 #> ((y * 1_000) / scl_fact) <# 127
    z := -128 #> ((z * 1_000) / scl_fact) <# 127
    writereg(core#OFSX, 1, @x)
    writereg(core#OFSY, 1, @y)
    writereg(core#OFSZ, 1, @z)

PUB accel_data(ptr_x, ptr_y, ptr_z) | tmp[2]
' Reads the Accelerometer output registers
    longfill(@tmp, 0, 2)
    readreg(core#DATAX0, 6, @tmp)

    long[ptr_x] := ~~tmp.word[X_AXIS]
    long[ptr_y] := ~~tmp.word[Y_AXIS]
    long[ptr_z] := ~~tmp.word[Z_AXIS]

PUB accel_data_overrun{}: flag
' Flag indicating previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overflowed/been overwritten, FALSE otherwise
    flag := 0
    readreg(core#INT_SOURCE, 1, @flag)
    return ((flag & 1) == 1)

PUB accel_data_rate(rate): curr_rate
' Set accelerometer output data rate, in Hz
'   Valid values: See case table below
'   Any other value polls the chip and returns the current setting
'   NOTE: Values containing an underscore represent fractional settings.
'       Examples: 0_10 == 0.1Hz, 12_5 == 12.5Hz
    curr_rate := 0
    readreg(core#BW_RATE, 1, @curr_rate)
    case rate
        0_10, 0_20, 0_39, 0_78, 1_56, 3_13, 6_25, 12_5, 25, 50, 100, 200, 400,{
}       800, 1600, 3200:
            rate := lookdownz(rate: 0_10, 0_20, 0_39, 0_78, 1_56, 3_13, 6_25,{
}           12_5, 25, 50, 100, 200, 400, 800, 1600, 3200)
        other:
            curr_rate &= core#RATE_BITS
            return lookupz(curr_rate: 0_10, 0_20, 0_39, 0_78, 1_56, 3_13,{
}           6_25, 12_5, 25, 50, 100, 200, 400, 800, 1600, 3200)

    rate := ((curr_rate & core#RATE_MASK) | rate)
    writereg(core#BW_RATE, 1, @rate)

PUB accel_data_rdy{}: flag
' Flag indicating accelerometer data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    flag := 0
    readreg(core#INT_SOURCE, 1, @flag)
    return (((flag >> core#DATA_RDY) & 1) == 1)

PUB accel_int{}: int_src
' Flag indicating interrupt(s) asserted
'   Bits: 76543210
'       7: Data Ready
'       6: Single-tap
'       5: Double-tap
'       4: Activity
'       3: Inactivity
'       2: Free-fall
'       1: Watermark
'       0: Overrun
'   NOTE: Calling this method clears all interrupts
    int_src := 0
    readreg(core#INT_SOURCE, 1, @int_src)

PUB accel_int_mask{}: mask
' Get interrupt mask
'   Bits: 76543210
'       7: Data Ready (Always enabled, regardless of setting)
'       6: Single-tap
'       5: Double-tap
'       4: Activity
'       3: Inactivity
'       2: Free-fall
'       1: Watermark (Always enabled, regardless of setting)
'       0: Overrun (Always enabled, regardless of setting)
    mask := 0
    readreg(core#INT_ENABLE, 1, @mask)

PUB accel_int_polarity(state): curr_state
' Set interrupt pin active state/logic level
'   Valid values: LOW (0), HIGH (1)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#DATA_FORMAT, 1, @curr_state)
    case state
        LOW, HIGH:
            ' invert the passed param;
            '   0 is active high, 1 is active low
            state := ((state ^ 1) << core#INT_INVERT)
        other:
            return (((curr_state ^ 1) >> core#INT_INVERT) & 1)

    state := ((curr_state & core#INT_INVERT_MASK) | state)
    writereg(core#DATA_FORMAT, 1, @state)

PUB accel_int_set_mask(mask)
' Set interrupt mask
'   Bits: 76543210
'       7: Data Ready (Always enabled, regardless of setting)
'       6: Single-tap
'       5: Double-tap
'       4: Activity
'       3: Inactivity
'       2: Free-fall
'       1: Watermark (Always enabled, regardless of setting)
'       0: Overrun (Always enabled, regardless of setting)
'   Valid values: %00000000..%11111111 (other bits masked off)
    mask &= %1111_1111
    writereg(core#INT_ENABLE, 1, @mask)

PUB accel_int_routing{}: mask
' Get interrupt pin routing mask
'   Bit clear (0): route to INT1 pin, set (1): route to INT2 pin
'   Bits: 76543210
'       7: Data Ready
'       6: Single-tap
'       5: Double-tap
'       4: Activity
'       3: Inactivity
'       2: Free-fall
'       1: Watermark
'       0: Overrun
    mask := 0
    readreg(core#INT_MAP, 1, @mask)

PUB accel_int_set_routing(mask)
' Set interrupt pin routing mask
'   Bit clear (0): route to INT1 pin, set (1): route to INT2 pin
'   Bits: 76543210
'       7: Data Ready
'       6: Single-tap
'       5: Double-tap
'       4: Activity
'       3: Inactivity
'       2: Free-fall
'       1: Watermark
'       0: Overrun
'   Valid values: %00000000..%11111111 (other bits masked off)
    mask &= %1111_1111
    writereg(core#INT_MAP, 1, @mask)

PUB accel_opmode(mode): curr_mode | curr_lp, lpwr
' Set operating mode
'   Valid values:
'       STANDBY (0): Standby
'       MEAS (1): Measurement mode
'       LOWPWR (3): Low-power measurement mode
'   NOTE: LOWPWR reduces power consumption, but has somewhat higher noise
'   Any other value polls the chip and returns the current setting
    curr_mode := curr_lp := 0
    readreg(core#PWR_CTL, 1, @curr_mode)
    readreg(core#BW_RATE, 1, @curr_lp)          ' read current LOW_POWER bit
    case mode
        STANDBY, MEAS, LOWPWR:
            lpwr := ((mode & 2) >> 1) << core#LOW_PWR
            mode := (mode & 1) << core#MEAS     ' only LSB used in PWR_CTRL
        other:
            curr_lp := (curr_lp >> core#LOW_PWR) & 1
            return ((curr_mode >> core#MEAS) & 1) | (curr_lp << 1)

    mode := ((curr_mode & core#MEAS_MASK) | mode)
    lpwr := ((curr_lp & core#LOW_PWR_MASK) | lpwr)
    writereg(core#PWR_CTL, 1, @mode)
    writereg(core#BW_RATE, 1, @lpwr)

PUB accel_scale(scale): curr_scl
' Set measurement range of the accelerometer, in g's
'   Valid values: 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    curr_scl := 0
    readreg(core#DATA_FORMAT, 1, @curr_scl)
    case scale
        2, 4, 8, 16:
            scale := lookdownz(scale: 2, 4, 8, 16)
            if (accel_adc_res(-2) == FULL)      ' ADC full-res scale factor
'                _ares := 3_500                  ' min
                _ares := 3_900                  '   is always 3.9mg/LSB (typ)
'                _ares := 4_300                  ' max
            else                                ' 10-bit res is scale-dependent
'                _ares := lookupz(scale: 3_500, 7_100, 14_100, 28_600)   ' min
                _ares := lookupz(scale: 3_900, 7_800, 15_600, 31_200)   ' typ
'                _ares := lookupz(scale: 4_300, 8_700, 17_500, 34_500)   ' max
        other:
            curr_scl &= core#RANGE_BITS
            return lookupz(curr_scl: 2, 4, 8, 16)

    scale := ((curr_scl & core#RANGE_MASK) | scale)
    writereg(core#DATA_FORMAT, 1, @scale)

PUB accel_self_test(state): curr_state
' Enable self-test mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#DATA_FORMAT, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#SELF_TEST
        other:
            return (((curr_state >> core#SELF_TEST) & 1) == 1)

    state := ((curr_state & core#SELF_TEST_MASK) | state)
    writereg(core#DATA_FORMAT, 1, @state)

PUB act_axis_ena(mask): curr_mask
' Enable activity threshold interrupt per axis, using bitmask
'   Valid values:
'       Bits 2..0 (%XYZ):
'           1: axis enabled
'           0: axis disabled
'   Any other value polls the chip and returns the current setting
'   NOTE: Functionally, enabled axes are logically OR'd (i.e., the interrupt
'       will trigger when _any_ of the axes exceeds the act_set_thresh() setting)
    curr_mask := 0
    readreg(core#ACT_INACT_CTL, 1, @curr_mask)
    case mask
        %000..%111:
            mask <<= core#ACT_EN
        other:
            return ((curr_mask >> core#ACT_EN) & core#ACT_EN_BITS)

    mask := ((curr_mask & core#ACT_EN_MASK) | mask)
    writereg(core#ACT_INACT_CTL, 1, @mask)

PUB act_inact_link(state): curr_state | opmode_orig
' Serially link activity and inactivity functions
'   Valid values:
'       FALSE (0): inactivity and activity functions operate concurrently
'       TRUE (-1 or 1): activity function delayed until inactivity is detected
'           Once activity is detected, inactivity detection begins again
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#PWR_CTL, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#LINK
        other:
            return (((curr_state >> core#LINK) & 1) == 1)

    opmode_orig := accel_opmode(-2)             ' cache user's operating mode

    state := ((curr_state & core#LINK_MASK) | state)
    writereg(core#PWR_CTL, 1, @state)

    accel_opmode(STANDBY)                       ' set to standby temporarily
    accel_opmode(opmode_orig)                   ' restore user's operating mode

PUB act_thresh{}: curr_thr
' Get activity threshold
'   Returns: micro-g's
    curr_thr := 0
    readreg(core#THRESH_ACT, 1, @curr_thr)
    return (curr_thr * 62_500)

PUB act_set_thresh(thresh)
' Set activity threshold, in micro-g's
'   Valid values: 0..15_937500 (15.9375g)
'   Any other value polls the chip and returns the current setting
'   NOTE: If the activity interrupt is enabled, setting this to 0 may
'       result in undesirable behavior.
    thresh := (0 #> thresh <# 15_937500) / 62_500
    writereg(core#THRESH_ACT, 1, @thresh)

PUB auto_sleep_ena(state): curr_state | opmode_orig
' Enable automatic transition to sleep state when inactive
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
'   NOTE: act_inact_link() must be set to TRUE for this to function
'   NOTE: Transition back to normal operating mode will also occur
'       if the activity interrupt is also set
    curr_state := 0
    readreg(core#PWR_CTL, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#AUTO_SLP
        other:
            return (((curr_state >> core#AUTO_SLP) & 1) == 1)

    opmode_orig := accel_opmode(-2)             ' cache user's operating mode

    state := ((curr_state & core#AUTO_SLP_MASK) | state)
    writereg(core#PWR_CTL, 1, @state)

    accel_opmode(STANDBY)                       ' set to standby temporarily
    accel_opmode(opmode_orig)                   ' restore user's operating mode

PUB click_axis_ena(mask): curr_mask
' Enable click detection, per axis bitmask
'   Valid values: %000..%111 (%xyz)
'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readreg(core#TAP_AXES, 1, @curr_mask)
    case mask
        %000..%111:
        other:
            return curr_mask & core#TAPXYZ_BITS

    mask := ((curr_mask & core#TAPXYZ_MASK) | mask)
    writereg(core#TAP_AXES, 1, @mask)

PUB clicked{}: flag
' Flag indicating the sensor was single-clicked
'   NOTE: Calling this method clears all interrupts
    return ((accel_int{} & INT_SNGTAP) <> 0)

PUB clicked_int{}: intstat
' Clicked interrupt status
'   NOTE: Calling this method clears all interrupts
    return (accel_int{} >> core#TAP) & core#TAP_BITS

PUB clicked_x{}: flag
' Flag indicating click event on X axis
'   Returns: TRUE (-1) if click event detected
    flag := 0
    readreg(core#ACT_TAP_STATUS, 1, @flag)
    return (((flag >> core#TAP_X_SRC) & 1) == 1)

PUB clicked_y{}: flag
' Flag indicating click event on Y axis
'   Returns: TRUE (-1) if click event detected
    flag := 0
    readreg(core#ACT_TAP_STATUS, 1, @flag)
    return (((flag >> core#TAP_X_SRC) & 1) == 1)

PUB clicked_z{}: flag
' Flag indicating click event on Z axis
'   Returns: TRUE (-1) if click event detected
    flag := 0
    readreg(core#ACT_TAP_STATUS, 1, @flag)
    return (((flag >> core#TAP_X_SRC) & 1) == 1)

PUB clicked_xyz{}: mask
' Mask indicating which axes click event occurred on
'   Returns: %xyz event bitmask (0 = no click, 1 = clicked)
    mask := 0
    readreg(core#ACT_TAP_STATUS, 1, @mask)
    return (mask & core#TAP_SRC_BITS)

PUB click_int_ena(state): curr_state | tmp
' Enable click interrupts
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := accel_int_mask{}
    case ||(state)
        0:
        1:
            state := %11 << core#TAP            ' enable both single & dbl tap
        other:
            return ((curr_state >> core#TAP) & core#TAP_BITS)

    state := ((curr_state & core#TAP_MASK) | state)
    accel_int_set_mask(state)

PUB click_latency{}: latency
' Get minimum interval/wait between detection of first click and start of window during which a
'   second click can be detected, in usec
    latency := 0
    readreg(core#LATENT, 1, @latency)
    return (latency * SCL_TAPLAT)

PUB click_set_latency(latency)
' Set minimum interval/wait between detection of first click and start of window during which a
'   second click can be detected, in usec
'   Valid values: 0..318_750 (rounded to nearest multiple of 1_250; clamped to range)
    latency := (0 #> latency <# 318_750) / SCL_TAPLAT
    writereg(core#LATENT, 1, @latency)

PUB click_thresh{}: thresh
' Set threshold for recognizing a click, in micro-g's
    thresh := 0
    readreg(core#THRESH_TAP, 1, @thresh)
    return (thresh * SCL_TAPTHRESH)

PUB click_set_thresh(thresh)
' Set threshold for recognizing a click, in micro-g's
'   Valid values: 0..16_000_000 (rounded to nearest multiple of 62_500; clamped to range)
    thresh := (0 #> thresh <# 16_000_000) / SCL_TAPTHRESH
    writereg(core#THRESH_TAP, 1, @thresh)

PUB click_time{}: ctime
' Get maximum elapsed interval between start of click and end of click
'   Returns: microseconds
    ctime := 0
    readreg(core#DUR, 1, @ctime)
    return (ctime * SCL_TAPDUR)

PUB click_set_time(ctime)
' Set maximum elapsed interval between start of click and end of click, in uSec
' Events longer than this will not be considered a click
'   Valid values: 0..159_375 (rounded to nearest multiple of 625; clamped to range)
    ctime := (0 #> ctime <# 159_375) / SCL_TAPDUR
    writereg(core#DUR, 1, @ctime)

PUB dev_id{}: id
' Read device identification
    id := 0
    readreg(core#DEVID, 1, @id)

PUB dbl_clicked{}: flag
' Flag indicating sensor was double-clicked
'   NOTE: Calling this method clears all interrupts
    return ((accel_int{} & INT_DBLTAP) <> 0)

PUB dbl_click_win{}: dctime
' Get window of time after click_latency() elapses that a second click can be detected
    dctime := 0
    readreg(core#WINDOW, 1, @dctime)
    return (dctime * SCL_DTAPWINDOW)

PUB dbl_click_set_win(dctime)
' Set window of time after click_latency() elapses that a second click can be detected
'   Valid values: 0..318_750 (rounded to nearest multiple of 1_250; clamped to range)
    dctime := (0 #> dctime <# 318_750) / SCL_DTAPWINDOW
    writereg(core#WINDOW, 1, @dctime)

PUB fifo_mode(mode): curr_mode
' Set FIFO operation mode
'   Valid values:
'      *BYPASS (%00): Don't use the FIFO functionality
'       FIFO (%01): FIFO enabled (stops collecting data when full, but device continues to operate)
'       STREAM (%10): FIFO enabled (continues accumulating samples; holds latest 32 samples)
'       TRIGGER (%11): FIFO enabled (holds latest 32 samples. When trigger event occurs, the last n samples,
'           set by fifo_thresh(), are kept. The FIFO then collects samples as long as it isn't full.
'   Any other value polls the chip and returns the current setting
'   NOTE: FIFO data is read by reading accel_data(), or any scaled unit method
'       A complete dataset (x, y, z) is equivalent to one FIFO sample
    curr_mode := 0
    readreg(core#FIFO_CTL, 1, @curr_mode)
    case mode
        BYPASS, FIFO, STREAM, TRIGGER:
            mode <<= core#FIFO_MODE
        other:
            return (curr_mode >> core#FIFO_MODE) & core#FIFO_MODE_BITS

    mode := ((curr_mode & core#FIFO_MODE_MASK) | mode)
    writereg(core#FIFO_CTL, 1, @mode)

PUB fifo_thresh(level): curr_lvl
' Set FIFO watermark/threshold level
'   Valid values: 0..31
    curr_lvl := 0
    readreg(core#FIFO_CTL, 1, @curr_lvl)
    case level
        0..31:
        other:
            return (curr_lvl & core#SAMPLES_BITS)

    level := ((curr_lvl & core#SAMPLES_MASK) | level)
    writereg(core#FIFO_CTL, 1, @level)

PUB fifo_triggered{}: flag   ' XXX tentatively named
' Flag indicating FIFO trigger interrupt asserted
'   Returns: TRUE (-1) or FALSE (0)
    flag := 0
    readreg(core#FIFO_STATUS, 1, @flag)
    return (((flag >> core#FIFO_TRIG) & 1) == 1)

PUB fifo_trig_int_routing(pin): curr_pin   ' XXX tentatively named
' Set routing of FIFO Trigger interrupt to INT1 or INT2 pin
'   Valid values: INT1 (1), INT2 (2)
'   Any other value polls the chip and returns the current setting
    curr_pin := 0
    readreg(core#FIFO_CTL, 1, @curr_pin)
    case pin
        1, 2:
            pin := (pin -1) << core#TRIGGER
        other:
            return (((curr_pin >> core#TRIGGER) & 1) + 1)

    pin := ((curr_pin & core#TRIGGER_MASK) | pin)
    writereg(core#FIFO_CTL, 1, @pin)

PUB fifo_nr_unread{}: nr_samples
' Number of unread samples stored in FIFO
'   Returns: 0..32
    nr_samples := 0
    readreg(core#FIFO_STATUS, 1, @nr_samples)
    nr_samples &= core#ENTRIES_BITS

PUB freefall_thresh{}: thresh
' Get free-fall threshold
'   Returns: micro-g's
    thresh := 0
    readreg(core#THRESH_FF, 1, @thresh)
    return (thresh * 0_062500)

PUB freefall_set_thresh(thresh)
' Set free-fall threshold, in micro-g's
'   Valid values: 0..15_937500 (0..15.9g's; clamped to range)
    thresh := (0 #> thresh <# 15_937500) / 0_062500
    writereg(core#THRESH_FF, 1, @thresh)

PUB freefall_time{}: fftime
' Get minimum time duration required to recognize free-fall
'   Returns: microseconds
    fftime := 0
    readreg(core#TIME_FF, 1, @fftime)
    return (fftime * 5_000)

PUB freefall_set_time(fftime)
' Set minimum time duration required to recognize free-fall, in microseconds
'   Valid values: 0..1_275_000 (clamped to range)
    fftime := (0 #> fftime <# 1_275_000) / 5_000
    writereg(core#TIME_FF, 1, @fftime)

PUB inact_axis_ena(mask): curr_mask
' Enable inactivity threshold interrupt per axis, using bitmask
'   Valid values:
'       Bits 2..0 (%XYZ):
'           1: axis enabled
'           0: axis disabled
'   Any other value polls the chip and returns the current setting
'   NOTE: Functionally, enabled axes are logically AND'd (i.e., the interrupt
'       will trigger only when _all_ of the axes falls below the inact_set_thresh()
'       setting for the time set by inact_set_time())
    curr_mask := 0
    readreg(core#ACT_INACT_CTL, 1, @curr_mask)
    case mask
        %000..%111:
            mask <<= core#INACT_EN
        other:
            return ((curr_mask >> core#INACT_EN) & core#INACT_EN_BITS)

    mask := ((curr_mask & core#INACT_EN_MASK) | mask)
    writereg(core#ACT_INACT_CTL, 1, @mask)

PUB inact_thresh{}: thresh
' Get inactivity threshold
'   Returns: micro-g's
    thresh := 0
    readreg(core#THRESH_INACT, 1, @thresh)
    return (thresh * 62_500)

PUB inact_set_thresh(thresh)
' Set inactivity threshold, in micro-g's
'   Valid values: 0..15_937500 (15.9375g)
'   NOTE: If the inactivity interrupt is enabled, setting this to 0 may
'       result in undesirable behavior.
    thresh := (0 #> thresh <# 15_937500) / 62_500
    writereg(core#THRESH_INACT, 1, @thresh)

PUB inact_time{}: itime
' Get inactivity time
'   Returns: seconds
    itime := 0
    readreg(core#TIME_INACT, 1, @itime)

PUB inact_set_time(itime)
' Set inactivity time, in seconds
'   Valid values: 0..255
'   NOTE: Setting this to 0 will generate an interrupt when the acceleration measures less than
'       that set with inact_set_thresh()
    itime := 0 #> itime <# 255
    writereg(core#TIME_INACT, 1, @itime)

PUB in_freefall{}: flag
' Flag indicating device is in free-fall
'   Returns:
'       TRUE (-1): device is in free-fall
'       FALSE (0): device isn't in free-fall
    flag := 0
    return ((accel_int{} & INT_FFALL) == INT_FFALL)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from slave device into ptr_buff
    case reg_nr
        $00, $1D..$31, $38, $39:
        $32..$37:                               ' accel data regs; set the
#ifdef ADXL345_SPI
            reg_nr |= core#MB                   '   multi-byte transaction bit
#endif
        other:
            return

#ifdef ADXL345_I2C
    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start{}
    i2c.wr_byte(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}
#elseifdef ADXL345_SPI
    outa[_CS] := 0
    spi.wr_byte(reg_nr | core#R)
    spi.rdblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1
#endif

PRI spimode(mode): curr_mode
' Set SPI interface mode
'   Valid values:
'       3: 3-wire SPI
'       4: 4-wire SPI
    case mode
        3:
            mode := 1 << core#SPI
        4:
            mode := 0
        other:
            return
    writereg(core#DATA_FORMAT, 1, @mode)

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes from ptr_buff to slave device
    case reg_nr
        $1D..$2A, $2C..$2F, $31, $38:
#ifdef ADXL345_I2C
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
            i2c.stop{}
#elseifdef ADXL345_SPI
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
#endif
        other:
            return

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

