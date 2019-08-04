{
    --------------------------------------------
    Filename: core.con.bme680.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started May 26, 2019
    Updated May 26, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ            = 3_400_000
    SLAVE_ADDR              = $76 << 1
                                            ' (7-bit format)

' Register definitions

    EAS_STATUS_0            = $1D

    PRESS                   = $1F
    PRESS_MSB               = $1F
    PRESS_LSB               = $20
    PRESS_XLSB              = $21

    TEMP                    = $22
    TEMP_MSB                = $22
    TEMP_LSB                = $23
    TEMP_XLSB               = $24

    HUM                     = $25
    HUM_MSB                 = $25
    HUM_LSB                 = $26

    GAS                     = $2A
    GAS_R_MSB               = $2A
    GAS_R_LSB               = $2B

    IDAC_HEAT_0             = $50
    IDAC_HEAT_1             = $51
    IDAC_HEAT_2             = $52
    IDAC_HEAT_3             = $53
    IDAC_HEAT_4             = $54
    IDAC_HEAT_5             = $55
    IDAC_HEAT_6             = $56
    IDAC_HEAT_7             = $57
    IDAC_HEAT_8             = $58
    IDAC_HEAT_9             = $59

    RES_HEAT_0              = $5A
    RES_HEAT_1              = $5B
    RES_HEAT_2              = $5C
    RES_HEAT_3              = $5D
    RES_HEAT_4              = $5E
    RES_HEAT_5              = $5F
    RES_HEAT_6              = $60
    RES_HEAT_7              = $61
    RES_HEAT_8              = $62
    RES_HEAT_9              = $63

    GAS_WAIT                = $64
    GAS_WAIT_MASK           = $FF
        FLD_GAS_WAIT        = 0
        FLD_GAS_WAIT_MULT   = 6
        BITS_GAS_WAIT       = %111111
        BITS_GAS_WAIT_MULT  = %11
        MASK_GAS_WAIT       = GAS_WAIT_MASK ^ (BITS_GAS_WAIT << FLD_GAS_WAIT)
        MASK_GAS_WAIT_MULT  = GAS_WAIT_MASK ^ (BITS_GAS_WAIT_MULT << FLD_GAS_WAIT_MULT)

    GAS_WAIT_0              = $64
    GAS_WAIT_1              = $65
    GAS_WAIT_2              = $66
    GAS_WAIT_3              = $67
    GAS_WAIT_4              = $68
    GAS_WAIT_5              = $69
    GAS_WAIT_6              = $6A
    GAS_WAIT_7              = $6B
    GAS_WAIT_8              = $6C
    GAS_WAIT_9              = $6D

    CTRL_GAS_0              = $70
    CTRL_GAS_1              = $71

    CTRL_HUM                = $72
    CTRL_HUM_MASK           = $47
        FLD_OSRS_H          = 0
        BITS_OSRS_H         = %111
        MASK_OSRS_H         = CTRL_HUM_MASK ^ (BITS_OSRS_H << FLD_OSRS_H)

    CTRL_MEAS               = $74
    CTRL_MEAS_MASK          = $FF
        FLD_MODE            = 0
        FLD_OSRS_P          = 2
        FLD_OSRS_T          = 5
        BITS_MODE           = %11
        BITS_OSRS_P         = %111
        BITS_OSRS_T         = %111
        MASK_MODE           = CTRL_MEAS_MASK ^ (BITS_MODE << FLD_MODE)
        MASK_OSRS_P         = CTRL_MEAS_MASK ^ (BITS_OSRS_P << FLD_OSRS_P)
        MASK_OSRS_T         = CTRL_MEAS_MASK ^ (BITS_OSRS_T << FLD_OSRS_T)

    CONFIG                  = $75

    ID                      = $D0
    ID_EXPECT_RESP          = $61

    RESET                   = $E0
        SOFT_RESET          = $B6

    STATUS                  = $73

    RES_HEAT_VAL            = $00
    RES_HEAT_RANGE          = $02
    RANGE_SW_ERR            = $04
    COEFF_1                 = $89
    COEFF_1_LEN             = 25
    COEFF_2                 = $E1
    COEFF_2_LEN             = 16

' Coefficient positions
    T2_LSB                  = 1
    T2_MSB                  = 2
    T3                      = 3
    P1_LSB                  = 5
    P1_MSB                  = 6
    P2_LSB                  = 7
    P2_MSB                  = 8
    P3                      = 9
    P4_LSB                  = 11
    P4_MSB                  = 12
    P5_LSB                  = 13
    P5_MSB                  = 14
    P7                      = 15
    P6                      = 16
    P8_LSB                  = 19
    P8_MSB                  = 20
    P9_LSB                  = 21
    P9_MSB                  = 22
    P10                     = 23
    H2_MSB                  = 25
    H2_LSB                  = 26
    H1_LSB                  = 26
    H1_MSB                  = 27
    H3                      = 28
    H4                      = 29
    H5                      = 30
    H6                      = 31
    H7                      = 32
    T1_LSB                  = 33
    T1_MSB                  = 34
    GH2_LSB                 = 35
    GH2_MSB                 = 36
    GH1                     = 37
    GH3                     = 38

    HUM_REG_SHIFT_VAL       = 4

PUB Null
' This is not a top-level object
