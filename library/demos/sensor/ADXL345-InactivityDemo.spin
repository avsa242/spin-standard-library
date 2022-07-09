{
    --------------------------------------------
    Filename: ADXL345-InactivityDemo.spin
    Author: Jesse Burt
    Description: Demo of the ADXL345 driver
        Inactivity interrupt functionality
    Copyright (c) 2022
    Started Aug 29, 2021
    Updated Jul 9, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_PIN      = 0                             ' SPI
    SCL_PIN     = 1                             ' SPI, I2C
    SDA_PIN     = 2                             ' SPI, I2C
    SDO_PIN     = 3                             ' SPI (4-wire only)
    I2C_HZ      = 400_000                       ' I2C (max: 400_000)
    ADDR_BITS   = 0                             ' I2C
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    accel   : "sensor.accel.3dof.adxl345"

PUB Main{} | i

    setup{}
    accel.preset_active{}                       ' default settings, but enable
                                                ' sensor data acquisition and
                                                ' set scale factor
    accel.actinactlink(TRUE)
    accel.actthresh(0_500000)
    accel.inactthresh(0_125000)
    accel.inacttime(3)
    accel.actaxisenabled(%110)
    accel.inactaxisenabled(%110)
    accel.intmask(accel#INT_ACTIV | accel#INT_INACT)
    accel.autosleep(TRUE)
    accel.calibrateaccel{}

    ser.printf1(string("ActThresh(): %d\n"), accel.actthresh(-2))
    ser.printf1(string("InactThresh(): %d\n"), accel.inactthresh(-2))
    ser.printf1(string("InactTime(): %d\n"), accel.inacttime(-2))
    ser.printf1(string("AutoSleep(): %d\n"), accel.autosleep(-2))
    ser.str(string("ActAxisEnabled() (%XYZ): %"))
    ser.bin(accel.actaxisenabled(-2), 3)
    ser.newline{}
    ser.str(string("InactAxisEnabled() (%XYZ): %"))
    ser.bin(accel.inactaxisenabled(-2), 3)
    ser.newline{}
    ser.strln(string("Move the sensor to awaken it."))
    ser.strln(string("This can be done again, once it reports INACTIVE."))

    repeat
        i := accel.interrupt{}
        if i & accel#INT_INACT
            ser.strln(string("INACTIVE"))
        if i & accel#INT_ACTIV
            ser.strln(string("ACTIVE"))

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef ADXL345_SPI
    if accel.startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.strln(string("ADXL345 driver started (SPI)"))
#else
    if accel.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS)
        ser.strln(string("ADXL345 driver started (I2C)"))
#endif
    else
        ser.strln(string("ADXL345 driver failed to start - halting"))
        repeat

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

