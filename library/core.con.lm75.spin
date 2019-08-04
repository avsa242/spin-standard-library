{
    --------------------------------------------
    Filename: core.con.lm75.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started May 19, 2019
    Updated May 20, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ        = 400_000                 'Change to your device's maximum bus rate, according to its datasheet
    SLAVE_ADDR          = $48 << 1                'Change to your device's slave address, according to its datasheet
                                                ' (7-bit format)

'' Register definitions
    TEMPERATURE         = $00
    TEMPERATURE_MASK    = $FF80

    CONFIGURATION       = $01
    CONFIGURATION_MASK  = $FF
        FLD_FAULTQ      = 3
        FLD_OS_POLARITY = 2
        FLD_COMP_INT    = 1
        FLD_SHUTDOWN    = 0
        BITS_FAULTQ     = %11
        MASK_FAULTQ     = CONFIGURATION_MASK ^ (1 << FLD_FAULTQ)
        MASK_OS_POLARITY= CONFIGURATION_MASK ^ (1 << FLD_OS_POLARITY)
        MASK_COMP_INT   = CONFIGURATION_MASK ^ (1 << FLD_COMP_INT)
        MASK_SHUTDOWN   = CONFIGURATION_MASK ^ (1 << FLD_SHUTDOWN)

    T_HYST              = $02
    T_HYST_MASK         = $FF80

    T_OS                = $03
    T_OS_MASK           = $FF80

PUB Null
'' This is not a top-level object
