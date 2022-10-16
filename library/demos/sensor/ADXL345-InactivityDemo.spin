{
    --------------------------------------------
    Filename: ADXL345-InactivityDemo.spin
    Author: Jesse Burt
    Description: Demo of the ADXL345 driver
        Inactivity interrupt functionality
    Copyright (c) 2022
    Started Aug 29, 2021
    Updated Oct 1, 2022
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DADXL345_SPI
        -DADXL345_SPI_BC
        -DADXL345_I2C (default if none specified)
        -DADXL345_I2C_BC
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    { I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
    ADDR_BITS   = 0                             ' 0, 1

    { SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1                             ' SCL
    MOSI_PIN    = 2                             ' SDA
    MISO_PIN    = 3                             ' SDO
'   NOTE: If ADXL345_SPI is #defined, and MOSI_PIN and MISO_PIN are the same,
'   the driver will attempt to start in 3-wire SPI mode.
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    accel   : "sensor.accel.3dof.adxl345"

PUB main{} | i

    setup{}
    accel.preset_active{}                       ' default settings, but enable
                                                ' sensor data acquisition and
                                                ' set scale factor
    accel.act_inact_link(TRUE)
    accel.act_set_thresh(0_500000)
    accel.inact_set_thresh(0_125000)
    accel.inact_set_time(3)
    accel.act_axis_ena(%110)
    accel.inact_axis_ena(%110)
    accel.int_set_mask(accel#INT_ACTIV | accel#INT_INACT)
    accel.auto_sleep_ena(TRUE)
    accel.calibrate_accel{}

    ser.printf1(string("Activity threshold: %dug\n\r"), accel.act_thresh{})
    ser.printf1(string("Inactivity threshold: %dug\n\r"), accel.inact_thresh{})
    ser.printf1(string("Inactivity time: %dsecs\n\r"), accel.inact_time{})
    ser.printf1(string("Auto-sleep enabled: %d\n\r"), accel.auto_sleep_ena(-2))
    ser.str(string("Activity axes enabled (%XYZ): %"))
    ser.bin(accel.act_axis_ena(-2), 3)
    ser.newline{}
    ser.printf1(string("Inactivity axes enabled (%XYZ): %b\n\r"), accel.inact_axis_ena(-2))
    ser.strln(string("Move the sensor to awaken it."))
    ser.strln(string("This can be done again, once it reports INACTIVE."))

    repeat
        i := accel.interrupt{}
        if (i & accel#INT_INACT)
            ser.strln(string("INACTIVE"))
        if (i & accel#INT_ACTIV)
            ser.strln(string("ACTIVE"))

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef ADXL345_SPI
    if (accel.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
#else
    if (accel.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS))
#endif
        ser.strln(string("ADXL345 driver started"))
    else
        ser.strln(string("ADXL345 driver failed to start - halting"))
        repeat

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

