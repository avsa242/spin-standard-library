{
---------------------------------------------------------------------------------------------------
    Filename:       Inclinometer-SSD1331.spin
    Description:    Simple inclinometer using an IMU and OLED display
    Author:         Jesse Burt
    Started:        May 29, 2022
    Updated:        Jan 27, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    Hardware required:
        * LSM9DS1 9DoF IMU (I2C or SPI)
        * SSD1331 OLED (SPI)

    Optional:
        * button/switch to pull I/O pin 16 high for use as a "zero"
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    { pull this pin high at any point while the app is running to trigger
        a reset of the inclinometer's zero }
    ZBTN_PIN    = 16
' --

' Uncomment these if the LSM9DS1 is connected using SPI
'#define LSM9DS1_SPI
'#pragma exportdef(LSM9DS1_SPI)

' Uncomment these to use the bytecode (cogless) SPI engine for the LSM9DS1
'#define LSM9DS1_SPI_BC
'#pragma exportdef(LSM9DS1_SPI_BC)



OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    fnt:    "font.5x8"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    imu:    "sensor.imu.9dof.lsm9ds1" | {I2C}SCL=28, SDA=29, I2C_FREQ=100_000, I2C_ADDR=0, ...
                                        {SPI}CS_AG=0, CS_M=1, SCK=2, MOSI=3, MISO=4
    ' NOTE: To use SPI, uncomment #define LSM9DS1_SPI above (I2C is used by default)
    ' NOTE: For 3-wire SPI, specify MOSI and MISO as the same pin
    oled:   "display.oled.ssd1331" | WIDTH=96, HEIGHT=64, CS=5, SCK=2, MOSI=3, DC=6, RST=7
    ' NOTE: RST can be specified as -1 if it's tied to the Propeller's RESn pin


VAR

    long _btn_stk[50]
    long _needs_cal


PUB main() | pitch, roll

    setup()

    oled.fgcolor($ffff)

    { set the accelerometer to a lower, less noisy data rate }
    imu.preset_active()
    imu.accel_data_rate(59)
    imu.accel_high_res_ena(true)

    oled.pos_xy(0, 0)
    oled.strln(@"Pitch: ")
    oled.str(@" Roll: ")

    repeat
        repeat until imu.accel_data_rdy()

        { clamp angles to +/- 90deg }
        pitch := -90_00 #> imu.pitch() <# 90_00
        roll := -90_00 #> imu.roll() <# 90_00

        oled.pos_xy(7, 0)
        oled.printf2(@"%d.%1.1d  ", pitch/100, ||(pitch//100)/10)
        oled.pos_xy(7, 1)
        oled.printf2(@"%d.%1.1d  ", roll/100, ||(roll//100)/10)
        oled.show()

        if (_needs_cal)
            set_zero()
            _needs_cal := false


PUB set_zero()
' Re-set the 'zero' of the inclinometer (set accelerometer bias offsets)
    oled.pos_xy(0, 3)
    oled.str(string("Setting zero..."))
    oled.show()
    imu.calibrate_accel()
    oled.pos_xy(0, 3)
    oled.str(string("               "))


PUB cog_button_inp()
' Wait for button press - trigger a reset of the inclinometer's zero
'   NOTE: Ensure the chip is lying on a flat surface and the package top
'   is facing up
    dira[ZBTN_PIN] := 0
    repeat
        waitpeq(|< ZBTN_PIN, |< ZBTN_PIN, 0)    ' wait for pin to go high
        time.msleep(20)
        if (ina[ZBTN_PIN])                      ' still high? ok, not a glitch
            _needs_cal := true
        else
            next
        repeat until (_needs_cal == false)


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    oled.start()
    oled.set_font(fnt.ptr(), fnt.setup())
    oled.preset_96x64()

    if ( imu.start() )
        ser.strln(@"LSM9DS1 driver started")
    else
        ser.strln(@"LSM9DS1 driver failed to start - halting")
        repeat

    cognew(cog_button_inp(), @_btn_stk)


DAT
{
Copyright 2024 Jesse Burt

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

