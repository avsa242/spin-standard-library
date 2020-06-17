{
    --------------------------------------------
    Filename: core.con.mcp320x.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Nov 26, 2019
    Updated Jun 17, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 0             ' Actually works with either
    CLK_DELAY                   = 1
    SCK_MAX_FREQ_5V             = 1_800_000
    SCK_MAX_FREQ_2_7V           = 0_900_000
    MOSI_BITORDER               = 5             'MSBFIRST
    MISO_BITORDER               = 0             'MSBPRE

' Register definitions
    CONFIG                      = $00
        FLD_START               = 3
        FLD_SGL_DIFF            = 2
        FLD_ODD_SIGN            = 1
        FLD_MSBF                = 0

        START                   = 1 << FLD_START

        SINGLE_ENDED            = 1 << FLD_SGL_DIFF
        PSEUDO_DIFF             = 0 << FLD_SGL_DIFF

        CH1                     = 1 << FLD_ODD_SIGN
        CH0                     = 0 << FLD_ODD_SIGN

        IN0POS_IN1NEG           = 1 << FLD_ODD_SIGN
        IN0NEG_IN1POS           = 0 << FLD_ODD_SIGN

        MSBFIRST                = 1 << FLD_MSBF
        LSBFIRST                = 0 << FLD_MSBF


PUB Null
' This is not a top-level object
