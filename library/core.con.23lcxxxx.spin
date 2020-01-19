{
    --------------------------------------------
    Filename: core.con.23lcxxxx.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started May 20, 2019
    Updated Dec 14, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 0
    CLK_DELAY                   = 1
    MOSI_BITORDER               = 5             'MSBFIRST
    MISO_BITORDER               = 0             'MSBPRE

' Register definitions
    WRMR                        = $01
    WRMR_MASK                   = $C0
        FLD_WR_MODE             = 6
        BITS_WR_MODE            = %11

    WRITE                       = $02
    READ                        = $03
    RDMR                        = $05
    RDMR_MASK                   = $C0
        FLD_RD_MODE             = 6
        BITS_RD_MODE            = %11

    EQIO                        = $38
    EDIO                        = $3B
    RSTIO                       = $FF

PUB Null
' This is not a top-level object
