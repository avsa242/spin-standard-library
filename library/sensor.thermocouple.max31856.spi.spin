{
    --------------------------------------------
    Filename: sensor.thermocouple.max31856.spi.spin
    Author: Jesse Burt
    Description: Driver object for Maxim's MAX31856 thermocouple amplifier
    Copyright (c) 2020
    Created: Sep 30, 2018
    Updated: Dec 6, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Sensor resolution (deg C per LSB, scaled up)
'    TC_RES          = 0_0078125                 ' 0.0078125 * 10_000_000
    TC_RES          = 0_00781                   ' 0.00781 * 100_000
    CJ_RES          = 0_15625                   ' 0.15625 * 100_000

' Operating modes
    SINGLE          = 0
    CONT            = 1

' Interrupt modes
    COMP            = 0                         ' comparator mode
    INTR            = 1                         ' interrupt mode

' Thermocouple types
    B               = %0000
    E               = %0001
    J               = %0010
    K               = %0011
    N               = %0100
    R               = %0101
    S               = %0110
    T               = %0111
    VOLTMODE_GAIN8  = %1000
    VOLTMODE_GAIN32 = %1100

' Interrupt mask bits (OR together any combination for use with IntMask())
    CJ_HIGH         = 1 << core#CJ_HIGH
    CJ_LOW          = 1 << core#CJ_LOW
    TC_HIGH         = 1 << core#TC_HIGH
    TC_LOW          = 1 << core#TC_LOW
    OV_UV           = 1 << core#OV_UV
    OPEN            = 1 << core#OPEN

' Temperature scales
    C               = 0
    F               = 1

VAR

    long _CS, _SCK, _MOSI, _MISO
    byte _temp_scale

OBJ

    core    : "core.con.max31856"
    spi     : "com.spi.4w"

PUB Null{}
' This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, SDI_PIN, SDO_PIN): okay

    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and{
}   lookdown(SDI_PIN: 0..31) and lookdown(SDO_PIN: 0..31)
        if okay := spi.start(core#CLK_DELAY, core#CPOL)
            longmove(@_CS, @CS_PIN, 4)
            outa[_CS] := 1
            dira[_CS] := 1
            return okay
    return FALSE                                ' something above failed

PUB Stop{}

    spi.stop{}

PUB CJIntHighThresh(thresh): curr_thr
' Set Cold-Junction HIGH fault threshold
'   Valid values: -128..127 (default: 127)
'   Any other value polls the chip and returns the current setting
    case thresh
        -128..127:
            writereg(core#CJHF, 1, @thresh)
        other:
            readreg(core#CJHF, 1, @curr_thr)
            return ~~curr_thr

PUB CJIntLowThresh(thresh): curr_thr
' Set Cold-Junction LOW fault threshold
'   Valid values: -128..127 (default: -64)
'   Any other value polls the chip and returns the current setting
    case thresh
        -128..127:
            writereg(core#CJLF, 1, @thresh)
        other:
            readreg(core#CJLF, 1, @curr_thr)
            return ~~curr_thr

PUB CJSensorEnabled(state): curr_state
' Enable the on-chip Cold-Junction temperature sensor
'   Valid values: *TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) ^ 1) << core#CJ ' logic is inverted in the reg
        other:                                  ' so flip the bit
            return (((curr_state >> core#CJ) & %1) ^ 1) == 1

    state := ((curr_state & core#CJ_MASK) | state) & core#CR0_MASK
    writereg(core#CR0, 1, @state)

PUB ColdJuncBias(offset): curr_offs 'XXX Make param units degrees
' Set Cold-Junction temperature sensor offset (default: 0)
    case offset
        -128..127:  '-8C..7.9375C
            writereg(core#CJTO, 1, @offset) 'xxx lsb is 0.0625C
        other:
            readreg(core#CJTO, 1, @curr_offs)
            return ~~curr_offs

PUB ColdJuncTemp{}: cjtemp
' Current cold-junction temperature
    readreg(core#CJTH, 2, @cjtemp)
    cjtemp ~>= 2                                ' shift right but keep sign bit
    cjtemp := (cjtemp * CJ_RES) / 10_000
    case _temp_scale
        C:
        F:
            cjtemp := ((cjtemp * 90) / 50) + 32_00

PUB IntClear{} | tmp
' Clear fault status
'   NOTE: This has no effect when FaultMode is set to FAULTMODE_COMP
    readreg(core#CR0, 1, @tmp)
    tmp &= core#FAULTCLR_MASK
    tmp := (tmp | (1 << core#FAULTCLR)) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB Interrupt{}: src
' Return interrupt status
'   Returns: (for each individual bit)
'       0: No fault detected
'       1: Fault detected
'
'   Bit 7   Cold-junction out of normal operating range
'       6   Thermcouple out of normal operating range
'       5   Cold-junction above HIGH temperature threshold
'       4   Cold-junction below LOW temperature threshold
'       3   Thermocouple temperature above HIGH temperature threshold
'       2   Thermocouple temperature below LOW temperature threshold
'       1   Over-voltage or Under-voltage
'       0   Thermocouple open-circuit
'   NOTE: Asserted interrupts will always be flagged in this register,
'       regardless of the set interrupt mask
'   NOTE: FAULT pin is active low
    readreg(core#SR, 1, @src)

PUB IntMask(mask): curr_mask
' Set interrupt mask (affects FAULT pin only)
'   Valid values:
'   Bits: 543210 (For each bit, 0: disable interrupt, 1: enable interrupt)
'       Bit 5   Cold-junction interrupt HIGH threshold
'           4   Cold-junction interrupt LOW threshold
'           3   Thermocouple temperature interrupt HIGH threshold
'           2   Thermocouple temperature interrupt LOW threshold
'           1   Over-voltage or under-voltage input
'           0   Thermocouple open-circuit
'   Example: %000010 would assert the /FAULT pin when an over-voltage or
'       under-voltage condition is detected
'   Any other value polls the chip and returns the current setting
'   NOTE: FAULT pin is active low
    case mask
        %000000..%111111:
            ' the chip considers cleared bits as enabled and set bits
            ' as masked off, so invert the mask set by the user
            ' before actually writing it to the chip
            mask := (mask ^ core#FAULTMASK_MASK)
            mask |= (core#RSVD_BITS << core#RSVD)
            writereg(core#FAULTMASK, 1, @mask)
        other:
            readreg(core#FAULTMASK, 1, @curr_mask)
            return (curr_mask ^ core#FAULTMASK_MASK)

PUB IntMode(mode): curr_mode
' Set interrupt mode
'   Valid values:
'       *COMP (0): Comparator mode - fault flag will be asserted
'       when fault condition is true, and will clear when the condition is
'       no longer true, _with a 2deg C hysteresis._
'
'       INTR (1): Interrupt mode - fault flag will be asserted when
'       fault condition is true, and will remain asserted until fault status
'       is explicitly cleared with IntClear().
'       NOTE: If the fault condition is still true when the status is cleared,
'       the flag will be asserted again immediately.
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @curr_mode)
    case mode
        COMP, INTR:
            mode := mode << core#FAULT
        other:
            return ((curr_mode >> core#FAULT) & 1)

    mode := ((curr_mode & core#FAULT_MASK) | mode) & core#CR0_MASK
    writereg(core#CR0, 1, @curr_mode)

PUB Measure{} | tmp
' Perform single cold-junction and thermocouple conversion
'   NOTE: Single conversion is performed only if OpMode() is set to SINGLE
' Approximate conversion times:
'   Filter Setting      Time
'   60Hz                143ms
'   50Hz                169ms
'   NOTE: Conversion times will be reduced by approximately 25ms if the
'       cold-junction sensor is disabled
    readreg(core#CR0, 1, @tmp)
    tmp &= core#ONESHOT_MASK
    tmp := (tmp | (1 << core#ONESHOT)) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB NotchFilter(freq): curr_freq | opmode_orig
' Select noise rejection filter frequency, in Hz
'   Valid values: 50, 60*
'   Any other value polls the chip and returns the current setting
'   NOTE: The conversion mode will be temporarily set to Normally Off when changing notch filter settings
'       per MAX31856 datasheet, if it isn't already.
    opmode_orig := opmode(-2)                   ' store user's OpMode
    opmode(SINGLE)
    readreg(core#CR0, 1, @curr_freq)
    case freq
        50, 60:
            freq := lookdownz(freq: 60, 50)
        other:
            opmode(opmode_orig)
            curr_freq &= %1
            return lookupz(curr_freq: 60, 50)

    freq := ((curr_freq & core#NOTCHFILT_MASK) | freq) & core#CR0_MASK
    writereg(core#CR0, 1, @freq)

    opmode(opmode_orig)                         ' restore user's OpMode

PUB OCFaultTestTime(time_ms): curr_time 'XXX Note recommendations based on circuit design
' Sets open-circuit fault detection test time, in ms
'   Valid values: 0 (disable fault detection), 10, 32, 100
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @curr_time)
    case time_ms
        0, 10, 32, 100:
            time_ms := lookdownz(time_ms: 0, 10, 32, 100) << core#OCFAULT
        other:
            result := ((curr_time >> core#OCFAULT) & core#OCFAULT_BITS)
            return lookupz(result: 0, 10, 32, 100)

    time_ms := ((curr_time & core#OCFAULT_MASK) | time_ms) & core#CR0_MASK
    writereg(core#CR0, 1, @time_ms)

PUB OpMode(mode): curr_mode
' Set operating mode
'   Valid values:
'       SINGLE (0): Single-shot/normally off
'       CONT (1): Continuous conversion
'   Any other value polls the chip and returns the current setting
'   NOTE: In CONT mode, conversions occur continuously approx. every 100ms
    readreg(core#CR0, 1, @curr_mode)
    case mode
        SINGLE, CONT:
            mode := (mode << core#CMODE)
        other:
            return (curr_mode >> core#CMODE) & %1

    mode := ((curr_mode & core#CMODE_MASK) | mode) & core#CR0_MASK
    writereg(core#CR0, 1, @mode)

PUB TCIntHighThresh(thresh): curr_thr
' Set thermocouple interrupt high threshold
'   Valid values: -32768..32767 (default: 32767)
'   Any other value polls the chip and returns the current setting
    case thresh
        -32768..32767:
            writereg(core#LTHFTH, 2, @thresh)
        other:
            readreg(core#LTHFTH, 2, @curr_thr)
            return ~~curr_thr

PUB TCIntLowThresh(thresh): curr_thr
' Set thermocouple interrupt low threshold
'   Valid values: -32768..32767 (default: -32768)
'   Any other value polls the chip and returns the current setting
    case thresh
        -32768..32767:
            writereg(core#LTLFTH, 2, @thresh)
        other:
            readreg(core#LTLFTH, 2, @curr_thr)
            return ~~curr_thr

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

PUB ThermoCoupleAvg(samples): curr_smp
' Set number of samples averaged during thermocouple conversion
'   Valid values: *1, 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    readreg(core#CR1, 1, @curr_smp)
    case samples
        1, 2, 4, 8, 16:
            samples := lookdownz(samples: 1, 2, 4, 8, 16) << core#AVGSEL
        other:
            curr_smp := (curr_smp >> core#AVGSEL) & core#AVGSEL_BITS
            return lookupz(curr_smp: 1, 2, 4, 8, 16)

    samples := ((curr_smp & core#AVGSEL_MASK) | samples) & core#CR1_MASK
    writereg(core#CR1, 1, @samples)

PUB ThermocoupleTemp{}: temp | sign
' Read the Thermocouple temperature
    temp := 0
    readreg(core#LTCBH, 3, @temp)
    temp ~>= 5                                  ' shift right, but keep
    temp := (temp * TC_RES) / 1000              ' sign bit
    case _temp_scale
        C:
        F:
            temp := ((temp * 90) / 50) + 32_00

PUB ThermoCoupleType(type): curr_type
' Set type of thermocouple
'   Valid values: B (0), E (1), J (2), *K (3), N (4), R (5), S (6), T (7)
'   Any other value polls the chip and returns the current setting
    readreg(core#CR1, 1, @curr_type)
    case type
        B, E, J, K, N, R, S, T:
        other:
            return curr_type & core#TC_TYPE_BITS

    type := ((curr_type & core#TC_TYPE_MASK) | type) & core#CR1_MASK
    writereg(core#CR1, 1, @type)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | tmp
' Read nr_bytes from device into ptr_buff
    case reg_nr                                 ' validate register
        core#CR0..core#SR:
        other:                                  ' invalid; return
            return

    outa[_CS] := 0                              ' shift out reg number
    spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg_nr)
    repeat tmp from nr_bytes-1 to 0             ' then read the data, MSB-first
        byte[ptr_buff][tmp] := spi.shiftin(_MISO, _SCK, core#MISO_BITORDER, 8)
    outa[_CS] := 1

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | tmp
' Write nr_bytes from ptr_buff to device
    case reg_nr
        core#CR0..core#CJTL:
            reg_nr |= core#WRITE_REG            ' OR reg_nr with $80 to write
        other:
            return

    outa[_CS] := 0
    spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg_nr)
    repeat tmp from nr_bytes-1 to 0
        spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[ptr_buff][tmp])
    outa[_CS] := 1

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
