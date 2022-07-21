{
    --------------------------------------------
    Filename: Inclinometer-SSD1331.spin
    Author: Jesse Burt
    Description: Simple inclinometer using an LSM9DS1 IMU
        (SSD1331 OLED display)
    Copyright (c) 2022
    Started May 29, 2022
    Updated Jul 21, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    { pull this pin high at any point while the app is running to trigger
        a reset of the inclinometer's zero }
    ZBTN_PIN    = 16

    { OLED configuration }
    OLED_CS     = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2
    DC_PIN      = 3
    RES_PIN     = 4
    ADDR_BITS   = 0                             ' 0, 1

    { I2C & SPI configuration }
    CS_M_PIN    = 0                             ' SPI
    CS_AG_PIN   = 1                             ' SPI
    SCL_PIN     = 28                             ' I2C, SPI
    SDA_PIN     = 29                             ' I2C, SPI
    SDO_PIN     = 4                             ' SPI
                                                ' (define same as SDA_PIN for 3-wire SPI)
    I2C_HZ      = 400_000
' --

    WIDTH       = 96
    HEIGHT      = 64

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    imu     : "sensor.imu.9dof.lsm9ds1"
    oled    : "display.oled.ssd1331"
    fnt     : "font.5x8"

VAR

    long _btn_stk[50]
    long _needs_cal
    word _disp_buff[WIDTH*HEIGHT]

PUB Main{} | pitch, roll

    setup{}

    oled.fgcolor($ffff)

    { set the accelerometer to a lower, less noisy data rate }
    imu.preset_active{}
    imu.acceldatarate(59)
    imu.accelhighres(true)

    oled.position(0, 0)
    oled.strln(@"Pitch: ")
    oled.str(@" Roll: ")

    repeat
        repeat until imu.acceldataready{}

        { clamp angles to +/- 90deg }
        pitch := -90_00 #> imu.pitch{} <# 90_00
        roll := -90_00 #> imu.roll{} <# 90_00

        oled.position(7, 0)
        oled.printf2(@("%d.%1.1d  "), pitch/100, ||(pitch//100)/10)
        oled.position(7, 1)
        oled.printf2(@("%d.%1.1d  "), roll/100, ||(roll//100)/10)
        oled.update

        if (_needs_cal)
            setzero{}
            _needs_cal := false

PRI setZero{}
' Re-set the 'zero' of the inclinometer (set accelerometer bias offsets)
    oled.position(0, 3)
    oled.str(string("Setting zero..."))
    oled.update{}
    imu.calibrateaccel{}
    oled.position(0, 3)
    oled.str(string("               "))

PUB cog_ButtonInp{}
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

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    oled.startx(OLED_CS, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, @_disp_buff)
    oled.fontspacing(1, 0)
    oled.fontscale(1)
    oled.fontsize(fnt#WIDTH, fnt#HEIGHT)
    oled.fontaddress(fnt.baseaddr{})
    oled.preset_96x64{}

#ifdef LSM9DS1_SPI
    if imu.startx(CS_AG_PIN, CS_M_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
#else
    if imu.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS)
#endif
        ser.strln(string("LSM9DS1 driver started"))
    else
        ser.strln(string("LSM9DS1 driver failed to start - halting"))
        repeat

    cognew(cog_buttoninp{}, @_btn_stk)

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
