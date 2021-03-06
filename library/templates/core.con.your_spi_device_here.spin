{
    --------------------------------------------
    Filename:
    Author:
    Description:
    Copyright (c) 20__
    Started Month Day, Year
    Updated Month Day, Year
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    SPI_MAX_FREQ    = 1_000_000                 ' device max SPI bus freq
    SPI_MODE        = 0                         ' 0..3
    T_POR           = 0                         ' startup time (usecs)

    DEVID_RESP      = $00                       ' device ID expected response

' Register definitions
    REG_NAME        = $00

PUB Null{}
' This is not a top-level object

