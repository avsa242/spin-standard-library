{
    --------------------------------------------
    Filename: core.con.mma7455.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Nov 27, 2019
    Updated Jan 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ        = 400_000
    SLAVE_ADDR          = $1D << 1
    DEVID_RESP          = $55

' Register definitions
    XOUTL               = $00
    XOUTH               = $01
    YOUTL               = $02
    YOUTH               = $03
    ZOUTL               = $04
    ZOUTH               = $05
    XOUT8               = $06
    YOUT8               = $07
    ZOUT8               = $08

    STATUS              = $09
    STATUS_MASK         = $07
        FLD_PERR        = 2
        FLD_DOVR        = 1
        FLD_DRDY        = 0

    DETSRC              = $0A
    TOUT                = $0B
' RESERVED - $0C
    I2CAD               = $0D
    USRINF              = $0E
    WHOAMI              = $0F
    XOFFL               = $10
    XOFFH               = $11
    YOFFL               = $12
    YOFFH               = $13
    ZOFFL               = $14
    ZOFFH               = $15

    MCTL                = $16
    MCTL_MASK           = $7F
        FLD_DRPD        = 6
        FLD_SPI3W       = 5
        FLD_STON        = 4
        FLD_GLVL        = 2
        FLD_MODE        = 0
        BITS_GLVL       = %11
        BITS_MODE       = %11
        MASK_DRPD       = MCTL_MASK ^ (1 << FLD_DRPD)
        MASK_SPI3W      = MCTL_MASK ^ (1 << FLD_SPI3W)
        MASK_STON       = MCTL_MASK ^ (1 << FLD_STON)
        MASK_GLVL       = MCTL_MASK ^ (BITS_GLVL << FLD_GLVL)
        MASK_MODE       = MCTL_MASK ^ (BITS_MODE << FLD_MODE)

    INTRST              = $17
    CTL1                = $18
    CTL2                = $19
    LDTH                = $1A
    PDTH                = $1B
    PW                  = $1C
    LT                  = $1D
    TW                  = $1E
' RESERVED - $1F


PUB Null
'' This is not a top-level object
