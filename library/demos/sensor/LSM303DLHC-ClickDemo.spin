{
    --------------------------------------------
    Filename: LSM303DLHC-ClickDemo.spin
    Author: Jesse Burt
    Description: Demo of the LSM303DLHC driver
        click-detection functionality
    Copyright (c) 2020
    Started Aug 1, 2020
    Updated Aug 1, 2020
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    SCL_PIN     = 1
    SDA_PIN     = 2
    I2C_HZ      = 400_000
    SLAVE_OPT   = 1
' --

    TEXT_COL    = 0
    DAT_COL     = 20
    DEC         = 0
    BIN         = 1
    HEX         = 2
    STR         = 3
    NUL         = 0

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    int     : "string.integer"
    imu     : "sensor.imu.6dof.lsm303dlhc.i2c"

VAR

    long _overruns
    long _total, _doubles, _singles

PUB Main{} | dispmode, click_src, int_act, dclicked, sclicked, sign, z_clicked, y_clicked, x_clicked, row

    setup{}

    imu.acceladcres(12)                                   ' 8, 10, 12 (low-power, normal, high-res, resp.)
    imu.accelscale(4)                                     ' 2, 4, 8, 16 (g's)
    imu.acceldatarate(400)                                ' 0, 1, 10, 25, 50, 100, 200, 400, 1344, 1600
    imu.accelaxisenabled(%111)                            ' 0 or 1 for each bit (%xyz)
    imu.clickthresh(1_187500)                             ' Micro-g's (range depends on scale)
    imu.clickaxisenabled(%10_00_00)                       ' Assert interrupts bitmask: (1 to enable)
'                                                             [5..4]: Z-axis double-click..single-click
'                                                             [3..2]: Y-axis double-click..single-click
'                                                             [1..0]: X-axis double-click..single-click
'    imu.clickaxisenabled(%01_00_00)                       ' <- for detecting z-axis single-clicks only
    imu.clicktime(127_000)                                ' Microseconds (range depends on data rate)
    imu.doubleclickwindow(637_500)                        ' Microseconds (range depends on data rate)
    imu.clicklatency(150_000)                             ' Microseconds (range depends on data rate)
'    imu.clicklatency(637_500)                             ' more suitable for single-clicks
    imu.clickintenabled(TRUE)

    ser.newline{}
    ser.hidecursor{}

    row := 4
    showdatum(string("AccelADCRes: "), DEC, imu.acceladcres(-2), 2, string("bits"), row)
    showdatum(string("AccelScale: "), DEC, imu.accelscale(-2), 2, string("g"), ++row)
    showdatum(string("AccelDataRate: "), DEC, imu.acceldatarate(-2), 4, string("Hz"), ++row)
    showdatum(string("AccelAxisEnabled: "), BIN, imu.accelaxisenabled(-2), 3, NUL, ++row)
    showdatum(string("FIFOMode: "), STR, lookupz(imu.fifomode(-2): string("Bypass"), string("FIFO"), string("stream")), NUL, NUL, ++row)
    showdatum(string("IntThresh: "), DEC, imu.intthresh(-2), 12, string("u-g"), ++row)
    showdatum(string("IntMask: "), BIN, imu.intmask(-2), 6, NUL, ++row)
    showdatum(string("ClickThresh: "), DEC, imu.clickthresh(-2), 12, string("u-g"), ++row)
    showdatum(string("ClickAxisEnabled: "), BIN, imu.clickaxisenabled(-2), 3, NUL, ++row)
    showdatum(string("ClickTime: "), DEC, imu.clicktime(-2), 12, string("uS"), ++row)
    showdatum(string("DoubleClickWindow: "), DEC, imu.doubleclickwindow(-2), 12, string("uS"), ++row)
    showdatum(string("ClickLatency: "), DEC, imu.clicklatency(-2), 12, string("uS"), ++row)

    repeat
        click_src := imu.clickedint{}
        int_act := ((click_src >> 6) & 1)
        dclicked := ((click_src >> 5) & 1)
        sclicked := ((click_src >> 4) & 1)
        sign := ((click_src >> 3) & 1)
        z_clicked := ((click_src >> 2) & 1)
        y_clicked := ((click_src >> 1) & 1)
        x_clicked := (click_src & 1)
        row := 20
        showdatum(string("Click interrupt:"), STR, lookupz(int_act: string("No "), string("Yes")), NUL, NUL, row)

        showdatum(string("Double-clicked:"), STR, lookupz(dclicked: string("No "), string("Yes")), NUL, NUL, ++row)
        showdatum(string("Single-clicked:"), STR, lookupz(sclicked: string("No "), string("Yes")), NUL, NUL, ++row)
        showdatum(string("Click sign:"), STR, lookupz(sign: string("Pos"), string("Neg")), NUL, NUL, ++row)
        showdatum(string("Z-axis clicked:"), STR, lookupz(z_clicked: string("No "), string("Yes")), NUL, NUL, ++row)
        showdatum(string("Y-axis clicked:"), STR, lookupz(y_clicked: string("No "), string("Yes")), NUL, NUL, ++row)
        showdatum(string("X-axis clicked:"), STR, lookupz(x_clicked: string("No "), string("Yes")), NUL, NUL, ++row)

    ser.showcursor{}
    flashled(LED, 100)

PUB ShowDatum(ptr_msg, val_type, val, digits, ptr_suffix, text_row)

    ser.position(TEXT_COL, text_row)
    ser.str(ptr_msg)

    ser.position(DAT_COL, text_row)
    case val_type                                           ' Type of value
        DEC:
            ser.dec(val)
        BIN:
            ser.bin(val, digits)
        HEX:
            ser.hex(val, digits)
        STR:
            ser.str(val)

    case ptr_suffix                                         ' Text to display as a suffix
        NUL:                                                ' NUL (0) for nothing
            return
        OTHER:
            ser.str(ptr_suffix)

PUB Setup{}

    repeat until ser.startrxtx(SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if imu.startx(SCL_PIN, SDA_PIN, I2C_HZ)
        imu.defaults{}
        ser.str(string("LSM303DLHC driver started (I2C)", ser#CR, ser#LF))
    else
        ser.str(string("LSM303DLHC driver failed to start - halting", ser#CR, ser#LF))
        imu.stop{}
        time.msleep(5)
        ser.stop{}
        flashled(LED, 500)

#include "lib.utility.spin"

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
