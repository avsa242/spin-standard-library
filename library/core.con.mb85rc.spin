{
    --------------------------------------------
    Filename: core.con.mb85rc.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Oct 27, 2019
    Updated Oct 27, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ        = 1_000_000
    SLAVE_ADDR          = $50 << 1

' Register definitions
    RSVD_SLAVE_W        = $F8
    RSVD_SLAVE_R        = $F9

PUB Null
' This is not a top-level object
