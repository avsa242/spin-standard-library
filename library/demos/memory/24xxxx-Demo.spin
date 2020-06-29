{
    --------------------------------------------
    Filename: 24xxxx-Demo.spin2
    Author: Jesse Burt
    Description: Demo of the 24xxxx driver
    Copyright (c) 2020
    Started May 9, 2020
    Updated Jun 29, 2020
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
    SER_BAUD    = 115200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 1_000_000
    READCNT     = 64
' --

    STATUS_LINE = 10
    CLK_FREQ    = (_clkmode >> 6) * _xinfreq
    CYCLES_USEC = CLK_FREQ / 1_000_000

    MEM_END     = 65535
    ERASED_CELL = $FF

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    io          : "io"
    time        : "time"
    mem         : "memory.eeprom.24xxxx.i2c"

VAR

    byte _buff[READCNT+1]

PUB Main | mem_base, stime, etime

    setup

    mem_base := 0
    repeat
        readtest(mem_base)

        ser.hexdump(@_buff, mem_base, READCNT, 16, 0, 5)
        ser.newline

        case ser.charin
            "[":
                mem_base := mem_base - READCNT
                if mem_base < 0
                    mem_base := 0
            "]":
                mem_base := mem_base + READCNT
                if mem_base > (MEM_END-READCNT)
                    mem_base := (MEM_END-READCNT)
            "s":
                mem_base := 0
            "e":
                mem_base := MEM_END-READCNT
            "w":
                writetest(mem_base)
            "x":
                erasetest(mem_base)
            "q":
                ser.str(string("Halting", ser#CR, ser#LF))
                quit
            OTHER:

    flashled(LED, 100)     ' Signal execution finished

PUB EraseTest(start_addr) | stime, etime

    bytefill(@_buff, ERASED_CELL, READCNT)
    ser.position(0, STATUS_LINE+2)
    ser.str(string("Erasing page..."))
    stime := cnt
    mem.writebytes(start_addr, READCNT, @_buff)
    etime := cnt-stime

    cycletime(etime)

PUB ReadTest(start_addr) | stime, etime

    bytefill(@_buff, 0, READCNT)
    ser.position(0, STATUS_LINE)
    ser.str(string("Reading page..."))
    stime := cnt
    mem.readbytes(start_addr, READCNT, @_buff)
    etime := cnt-stime

    cycletime(etime)

PUB WriteTest(start_addr) | stime, etime, tmp[2]

    bytemove(@tmp, string("TEST"), 4)
    ser.position(0, STATUS_LINE+1)
    ser.str(string("Writing test value..."))
    stime := cnt
    mem.writebytes(start_addr, 4, @tmp)
    etime := cnt-stime

    cycletime(etime)

PUB CycleTime(cycles)

    ser.dec(cycles)
    ser.str(string(" cycles ("))
    ser.dec(cycles / CYCLES_USEC)
    ser.str(string("usec)"))
    ser.clearline(ser#CLR_CUR_TO_END)
    return cycles / CYCLES_USEC

PUB Setup

    repeat until ser.startrxtx (SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    if mem.startx (I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str(string("24xxxx driver started", ser#CR, ser#LF))
    else
        ser.str(string("24xxxx driver failed to start - halting", ser#CR, ser#LF))
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
