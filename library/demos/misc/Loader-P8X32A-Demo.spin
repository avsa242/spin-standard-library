{
    --------------------------------------------
    Filename: Loader-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the misc.loader.p8x32a object
        Loads another connected Propeller with a binary
    Copyright (c) 2021
    Started May 25, 2020
    Updated Apr 27, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

' Pins your destination Propeller is connected to
    PROP_RES    = 18
    PROP_P31    = 16
    PROP_P30    = 17
' --

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
'    ser     : "com.serial.terminal"             ' PST-compatible terminal
    time    : "time"
    loader  : "misc.loader.p8x32a"

PUB main{} | status, errmsg

    setup{}
    ser.str(string("Loading file..."))
    status := loader.connect(PROP_RES, PROP_P31, PROP_P30, 1, loader#LOADRUN, @_binary_def)

    case status
        0:
            ser.str(string("complete"))

        loader#ERRORCONNECT, loader#ERRORVERSION, loader#ERRORCHECKSUM, {
}       loader#ERRORPROGRAM, loader#ERRORVERIFY:
            ser.str(string("Load failed: "))
            errmsg := lookup(status: string("Error connecting"), {
}           string("Version mismatch"), string("Checksum mismatch"), {
}           string("Error during programming"), string("Verification failed"))
            ser.str(errmsg)

        other:
            ser.str(string("Load failed: Exception error"))
            repeat

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

DAT
' Binary file to load to destination Propeller
'   NOTE: Binary must be small enough that it fits in _this_ Propeller's RAM, along
'       with this program.
    _binary_def     file    "dummy.binary"

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

