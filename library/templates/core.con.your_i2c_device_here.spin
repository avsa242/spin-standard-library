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

' I2C Configuration
    I2C_MAX_FREQ    = 100_000                   ' device max I2C bus freq
    SLAVE_ADDR      = $00 << 1                  ' 7-bit format slave address
    T_POR           = 0                         ' startup time (usecs)

    DEVID_RESP      = $00                       ' device ID expected response

' Register definitions
    REG_NAME        = $00

PUB Null{}
' This is not a top-level object

