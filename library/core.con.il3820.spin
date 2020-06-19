{
    --------------------------------------------
    Filename: core.con.il3820.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Nov 30, 2019
    Updated Feb 9, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    SCK_CPOL                    = 0
    CLK_DELAY                   = 1
    SCK_MAX_FREQ                = 4_000_000
    MOSI_BITORDER               = 5             'MSBFIRST

' Register definitions
    DRIVER_OUT_CTRL             = $01
    SH_DRIVER_OUT_CTRL          = $00   '00..02

    GATEDRV_VOLT_CTRL           = $03
    GATEDRV_VOLT_CTRL_MASK      = $FF
    SH_GATEDRV_VOLT_CTRL        = $03
        FLD_VGH                 = 4
        FLD_VGL                 = 0
        BITS_VGH                = %1111
        BITS_VGL                = %1111
        MASK_VGH                = GATEDRV_VOLT_CTRL_MASK ^ (BITS_VGH << FLD_VGH)
        MASK_VGL                = GATEDRV_VOLT_CTRL_MASK ^ (BITS_VGL << FLD_VGL)

    SRCDRV_VOLT_CTRL            = $04
    SH_SRCDRV_VOLT_CTRL         = $04

    DISPLAY_CTRL                = $07
    SH_DISPLAY_CTRL             = $05

    GATE_SRC_NONOVERLAP         = $0B
    SH_GATE_SRC_NONOVERLAP      = $06

    BOOSTER_SOFTST_CTRL         = $0C
    SH_BOOSTER_SOFTST_CTRL      = $07   '07..09

    GATE_SCAN_START             = $0F
    SH_GATE_SCAN_START          = $0A   '0A..0B

    DEEP_SLEEP                  = $10
    SH_DEEP_SLEEP               = $0C

    DATA_ENTRY_MODE             = $11
    DATA_ENTRY_MODE_MASK        = $07
    SH_DATA_ENTRY_MODE          = $0D
        FLD_AM                  = 3
        FLD_ID                  = 0
        BITS_ID                 = %11
        MASK_AM                 = DATA_ENTRY_MODE_MASK ^ (1 << FLD_AM)
        MASK_ID                 = DATA_ENTRY_MODE_MASK ^ (BITS_ID << FLD_ID)

    SWRESET                     = $12

    TEMP_CTRL_W                 = $1A
    SH_TEMP_CTRL_W              = $0E   '0E..0F

    TEMP_CTRL_R                 = $1B
    SH_TEMP_CTRL_R              = $10   '10..11

    TEMP_CTRL_W_CMD             = $1C
    SH_TEMP_CTRL_W_CMD          = $12   '12..14



    MASTER_ACT                  = $20

    DISP_UPDATE_CTRL1           = $21
    DISP_UPDATE_CTRL1_MASK      = $9F
    SH_DISP_UPDATE_CTRL1        = $15
        FLD_OLDRAM_BYPASS       = 7
        FLD_BYPASS_VAL          = 4
        FLD_INITUPDATE          = 0
        BITS_INITUPDATE         = %11
        MASK_OLDRAM_BYPASS      = DISP_UPDATE_CTRL1_MASK ^ (1 << FLD_OLDRAM_BYPASS)
        MASK_BYPASS_VAL         = DISP_UPDATE_CTRL1_MASK ^ (1 << FLD_BYPASS_VAL)
        MASK_INITUPDATE         = DISP_UPDATE_CTRL1_MASK ^ (BITS_INITUPDATE << FLD_INITUPDATE)

    DISP_UPDATE_CTRL2           = $22
    SH_DISP_UPDATE_CTRL2        = $16
        SEQ_ALL                 = $FF
        SEQ_CLKEN               = $80
        SEQ_CLK_CP_EN           = $C0
        SEQ_INITIAL_PATTERN_DISP= $0C
        SEQ_INITIAL_DISP        = $08
        SEQ_PATTERN_DISP        = $04
        SEQ_CLK_CP_DIS          = $03
        SEQ_CLK_DIS             = $01

    WRITE_RAM                   = $24

    VCOM_SENSE_DUR              = $29
    SH_VCOM_SENSE_DUR           = $17

    WRITE_VCOM_REG              = $2C
    SH_WRITE_VCOM_REG           = $18

    WRITE_LUT_REG               = $32

    DUMMY_LINE_PER              = $3A
    DUMMY_LINE_PER_MASK         = $7F
    SH_DUMMY_LINE_PER           = $19


    GATE_LINE_WIDTH             = $3B
    SH_GATE_LINE_WIDTH          = $1A

    BORDER_WAVEFM_CTRL          = $3C
    BORDER_WAVEFM_CTRL_MASK     = $F3
    SH_BORDER_WAVEFM_CTRL       = $1B
        FLD_FOLLOWSRC           = 7
        FLD_VBD                 = 6
        FLD_VBD_LEVEL           = 4
        FLD_VBD_TRANS           = 0

    RAM_X_ST_END                = $44
    RAM_Y_ST_END                = $45
    RAM_X_ADDR_AC               = $4E
    RAM_Y_ADDR_AC               = $4F
    NOOP                        = $FF

PUB Null
' This is not a top-level object
