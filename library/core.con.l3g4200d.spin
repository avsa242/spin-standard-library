{
    --------------------------------------------
    Filename: core.con.l3g4200d.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Nov 27, 2019
    Updated Nov 29, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 1
    CLK_DELAY                   = 1
    SCK_MAX_FREQ                = 10_000_000
    MOSI_BITORDER               = 5             'MSBFIRST
    MISO_BITORDER               = 2             'MSBPRE

' Register definitions
    WHO_AM_I                    = $0F

    CTRL_REG1                   = $20
    CTRL_REG1_MASK              = $FF
        FLD_DR                  = 6
        FLD_BW                  = 4
        FLD_PD                  = 3
        FLD_ZEN                 = 2
        FLD_YEN                 = 1
        FLD_XEN                 = 0
        FLD_XYZEN               = 0
        BITS_DR                 = %11
        BITS_BW                 = %11
        BITS_XYZEN              = %111
        MASK_DR                 = CTRL_REG1_MASK ^ (BITS_DR << FLD_DR)
        MASK_BW                 = CTRL_REG1_MASK ^ (BITS_BW << FLD_BW)
        MASK_PD                 = CTRL_REG1_MASK ^ (1 << FLD_PD)
        MASK_ZEN                = CTRL_REG1_MASK ^ (1 << FLD_ZEN)
        MASK_YEN                = CTRL_REG1_MASK ^ (1 << FLD_YEN)
        MASK_XEN                = CTRL_REG1_MASK ^ (1 << FLD_XEN)
        MASK_XYZEN              = CTRL_REG1_MASK ^ (BITS_XYZEN << FLD_XYZEN)

    CTRL_REG2                   = $21
    CTRL_REG2_MASK              = $3F
        FLD_HPM                 = 4
        FLD_HPCF                = 0
        BITS_HPM                = %11
        BITS_HPCF               = %1111
        MASK_HPM                = CTRL_REG2_MASK ^ (BITS_HPM << FLD_HPM)
        MASK_HPCF               = CTRL_REG2_MASK ^ (BITS_HPCF << FLD_HPCF)

    CTRL_REG3                   = $22
    CTRL_REG3_MASK              = $FF
        FLD_I1_INT1             = 7
        FLD_I1_BOOT             = 6
        FLD_INT1                = 6
        FLD_H_LACTIVE           = 5
        FLD_PP_OD               = 4
        FLD_I2_DRDY             = 3
        FLD_I2_WTM              = 2
        FLD_I2_ORUN             = 1
        FLD_I2_EMPTY            = 0
        FLD_INT2                = 0
        BITS_INT1               = %11
        BITS_INT2               = %1111
        MASK_I1_INT1            = CTRL_REG3_MASK ^ (1 << FLD_I1_INT1)
        MASK_I1_BOOT            = CTRL_REG3_MASK ^ (1 << FLD_I1_BOOT)
        MASK_H_LACTIVE          = CTRL_REG3_MASK ^ (1 << FLD_H_LACTIVE)
        MASK_INT1               = CTRL_REG3_MASK ^ (BITS_INT1 << FLD_INT1)
        MASK_PP_OD              = CTRL_REG3_MASK ^ (1 << FLD_PP_OD)
        MASK_I2_DRDY            = CTRL_REG3_MASK ^ (1 << FLD_I2_DRDY)
        MASK_I2_WTM             = CTRL_REG3_MASK ^ (1 << FLD_I2_WTM)
        MASK_I2_ORUN            = CTRL_REG3_MASK ^ (1 << FLD_I2_ORUN)
        MASK_I2_EMPTY           = CTRL_REG3_MASK ^ (1 << FLD_I2_EMPTY)
        MASK_INT2               = CTRL_REG3_MASK ^ (BITS_INT2 << FLD_INT2)

    CTRL_REG4                   = $23
    CTRL_REG4_MASK              = $F7
        FLD_BDU                 = 7
        FLD_BLE                 = 6
        FLD_FS                  = 4
        FLD_ST                  = 1
        FLD_SIM                 = 0
        BITS_FS                 = %11
        BITS_ST                 = %11
        MASK_BDU                = CTRL_REG4_MASK ^ (1 << FLD_BDU)
        MASK_BLE                = CTRL_REG4_MASK ^ (1 << FLD_BLE)
        MASK_FS                 = CTRL_REG4_MASK ^ (BITS_FS << FLD_FS)
        MASK_ST                 = CTRL_REG4_MASK ^ (BITS_ST << FLD_ST)
        MASK_SIM                = CTRL_REG4_MASK ^ (1 << FLD_SIM)

    CTRL_REG5                   = $24
    CTRL_REG5_MASK              = $DF
        FLD_BOOT                = 7
        FLD_FIFO_EN             = 6
        FLD_HPEN                = 4
        FLD_INT1_SEL            = 2
        FLD_OUT_SEL             = 0
        BITS_INT1_SEL           = %11
        BITS_OUT_SEL            = %11
        MASK_BOOT               = CTRL_REG5_MASK ^ (1 << FLD_BOOT)
        MASK_FIFO_EN            = CTRL_REG5_MASK ^ (1 << FLD_FIFO_EN)
        MASK_HPEN               = CTRL_REG5_MASK ^ (1 << FLD_HPEN)
        MASK_INT1_SEL           = CTRL_REG5_MASK ^ (BITS_INT1_SEL << FLD_INT1_SEL)
        MASK_OUT_SEL            = CTRL_REG5_MASK ^ (BITS_OUT_SEL << FLD_OUT_SEL)

    REFERENCE                   = $25
    REFERENCE_MASK              = $FF
        BITS_REF                = %11111111

    OUT_TEMP                    = $26

    STATUS_REG                  = $27
        FLD_ZYXOR               = 7
        FLD_ZOR                 = 6
        FLD_YOR                 = 5
        FLD_XOR                 = 4
        FLD_ZYXDA               = 3
        FLD_ZDA                 = 2
        FLD_YDA                 = 1
        FLD_XDA                 = 0

    OUT_X_L                     = $28
    OUT_X_H                     = $29
    OUT_Y_L                     = $2A
    OUT_Y_H                     = $2B
    OUT_Z_L                     = $2C
    OUT_Z_H                     = $2D

    FIFO_CTRL_REG               = $2E
    FIFO_SRC_REG                = $2F

    INT1_CFG                    = $30
    INT1_SRC                    = $31

    INT1_THS_XH                 = $32
    INT1_THS_XL                 = $32
    INT1_THS_X_MASK             = $7FFF

    INT1_THS_YH                 = $32
    INT1_THS_YL                 = $32
    INT1_THS_Y_MASK             = $7FFF

    INT1_THS_ZH                 = $32
    INT1_THS_ZL                 = $32
    INT1_THS_Z_MASK             = $7FFF

    INT1_DURATION               = $32
    INT1_DURATION_MASK          = $FF
        FLD_WAIT                = 7
        FLD_D                   = 0
        BITS_D                  = %1111111
        MASK_WAIT               = INT1_DURATION_MASK ^ (1 << FLD_WAIT)
        MASK_D                  = INT1_DURATION_MASK ^ (BITS_D << FLD_D)


PUB Null
' This is not a top-level object
