{
    --------------------------------------------
    Filename: ADXL345-ClickDemo.spin
    Author: Jesse Burt
    Description: Demo of the ADXL345 driver
        click-detection functionality
    Copyright (c) 2022
    Started May 30, 2021
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
    SDO_PIN     = 3                             ' SPI
    I2C_HZ      = 400_000                       ' I2C
    ADDR_BITS   = 0                             ' I2C
' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    accel   : "sensor.accel.3dof.adxl345"

VAR

    long _showclk_stack[60]
    long _s_cnt, _d_cnt
    long _click_src, _dclicked, _sclicked
    long _dc_wind

PUB Main{}

    setup{}
    accel.preset_clickdet{}                     ' preset settings for
'                                               ' click-detection
    _s_cnt := _d_cnt := 0
    _dc_wind := accel.doubleclickwindow(-2) / 1000
    repeat
        repeat until _click_src := accel.clickedint{}

        _dclicked := (_click_src & 1)
        _sclicked := ((_click_src >> 1) & 1)
        if _dclicked
            _click_src := 0
            _d_cnt++
            next
        if _sclicked
            _click_src := 0
            _s_cnt++

PRI cog_ShowClickStatus{}
' Secondary cog to display click status
    repeat
        ser.position(0, 3)
        ser.printf2(string("Double-clicked:  %s (%d)\n"), yesno(_dclicked), _d_cnt)
        ser.printf2(string("Single-clicked:  %s (%d)\n"), yesno(_sclicked), _s_cnt)
        _dclicked := _sclicked := false
        ' wait for double-click window time to elapse, so the display doesn't
        '   update too fast to be seen
        time.msleep(_dc_wind)

PRI YesNo(val): resp
' Return pointer to string "Yes" or "No" depending on value called with
    case ||(val)
        0:
            return string("No ")
        1:
            return string("Yes")

PUB Setup{}

    longfill(@_showclk_stack, 0, 65)
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

    cognew(cog_showclickstatus{}, @_showclk_stack)

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

