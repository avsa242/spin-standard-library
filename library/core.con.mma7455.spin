{
    --------------------------------------------
    Filename: core.con.mma7455.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2021
    Started Nov 27, 2019
    Updated Jan 1, 2021
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
        PERR            = 2
        DOVR            = 1
        DRDY            = 0

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
        DRPD            = 6
        SPI3W           = 5
        STON            = 4
        GLVL            = 2
        MODE            = 0
        GLVL_BITS       = %11
        MODE_BITS       = %11
        DRPD_MASK       = (1 << DRPD) ^ MCTL_MASK
        SPI3W_MASK      = (1 << SPI3W) ^ MCTL_MASK
        STON_MASK       = (1 << STON) ^ MCTL_MASK
        GLVL_MASK       = (GLVL_BITS << GLVL) ^ MCTL_MASK
        MODE_MASK       = MODE_BITS ^ MCTL_MASK

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
