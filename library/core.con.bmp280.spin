{
    --------------------------------------------
    Filename: core.con.bmp280.spin
    Description: BMP280 low-level driver constants
    Author: Jesse Burt
    Copyright (c) 2018
    Created: Sep 16, 2018
    Updated: Mar 9, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_ADDR      = $77 << 1
    I2C_DEF_FREQ    = 400_000
    I2C_MAX_FREQ    = 3_400_000

' Compensation values
    DIG_T1_LSB      = $88   'US SH  CALIB00
    DIG_T1_MSB      = $89   'US SH
    DIG_T2_LSB      = $8A   'S SH
    DIG_T2_MSB      = $8B   'S SH
    DIG_T3_LSB      = $8C   'S SH
    DIG_T3_MSB      = $8D   'S SH
    DIG_P1_LSB      = $8E   'US SH
    DIG_P1_MSB      = $8F   'US SH
    DIG_P2_LSB      = $90   'S SH
    DIG_P2_MSB      = $91   'S SH
    DIG_P3_LSB      = $92   'S SH
    DIG_P3_MSB      = $93   'S SH
    DIG_P4_LSB      = $94   'S SH
    DIG_P4_MSB      = $95   'S SH
    DIG_P5_LSB      = $96   'S SH
    DIG_P5_MSB      = $97   'S SH
    DIG_P6_LSB      = $98   'S SH
    DIG_P6_MSB      = $99   'S SH
    DIG_P7_LSB      = $9A   'S SH
    DIG_P7_MSB      = $9B   'S SH
    DIG_P8_LSB      = $9C   'S SH
    DIG_P8_MSB      = $9D   'S SH
    DIG_P9_LSB      = $9E   'S SH
    DIG_P9_MSB      = $9F   'S SH   CALIB23
    
'' Register Map
    ID                  = $D0   ' SHOULD RETURN $58
        ID_EXPECTED     = $58

    RESET               = $E0   ' WRITE $B6 TO RESET - ALL OTHER VALUES IGNORED. ALWAYS READS $00
        DO_RESET        = $B6

    STATUS              = $F3
    STATUS_MASK         = $09
        FLD_MEASURING   = 3
        MASK_MEASURING  = STATUS_MASK ^ (1 << FLD_MEASURING)
        FLD_IM_UPDATE   = 0
        MASK_IM_UPDATE  = STATUS_MASK ^ (1 << FLD_IM_UPDATE)

    CTRL_MEAS           = $F4
    CTRL_MEAS_MASK      = $FF
        FLD_MODE        = 0
        FLD_OSRS_P      = 2
        FLD_OSRS_T      = 5
        BITS_MODE       = %11
        BITS_OSRS_P     = %111
        BITS_OSRS_T     = %111
        MASK_MODE       = CTRL_MEAS_MASK ^ (BITS_MODE << FLD_MODE)
        MASK_OSRS_P     = CTRL_MEAS_MASK ^ (BITS_OSRS_P << FLD_OSRS_P)
        MASK_OSRS_T     = CTRL_MEAS_MASK ^ (BITS_OSRS_T << FLD_OSRS_T)

    CONFIG              = $F5
    CONFIG_MASK         = $FD
        FLD_SB          = 5
        FLD_FILTER      = 2
        BITS_SB         = %111
        BITS_FILTER     = %111
        MASK_SB         = CONFIG_MASK ^ (BITS_SB << FLD_SB)
        MASK_FILTER     = CONFIG_MASK ^ (BITS_FILTER << FLD_FILTER)

    PRESS_MSB       = $F7
    PRESS_LSB       = $F8
    PRESS_XLSB      = $F9
    TEMP_MSB        = $FA
    TEMP_LSB        = $FB
    TEMP_XLSB       = $FC
    
    MODE_SLEEP      = %00   ' No measurements / low-power mode
    MODE_FORCED1    = %01   ' "One-shot" measurement mode
    MODE_FORCED2    = %10   ' ditto
    MODE_NORMAL     = %11   ' Measure continuously
    
PUB Null
'' This is not a top-level object
