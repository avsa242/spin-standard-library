{
----------------------------------------------------------------------------------------------------
    Filename:       SIRC-Demo.spin
    Description:    Demo of the SIRC IR-remote decoder
    Author:         Jesse Burt
    Started:        Jun 14, 2024
    Updated:        Jun 14, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq


OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sir:    "input.ir-remote.sirc" | IR_PIN=15  ' remote receiver I/O pin


PUB main() | sig, len

    setup()

    ser.strln(@"Waiting to receive remote control codes...")

    sir.enable_auto_repeat(true)                ' keep receiving repeated codes or just one
    repeat
        sig, len := sir.read_sirc()
        ser.clear()
        ser.pos_xy(0, 0)
        ser.printf2(@"Raw code: %08.8x (len: %d)\n\r", sig, len)

        case len
            12:
                ser.printf1(@"Address (5-bit): %02.2x\n\r", sir.address_5bit(sig))
            15:
                ser.printf1(@"Address (8-bit): %02.2x\n\r", sir.address_8bit(sig))
            20:
                ser.printf1(@"Address (5-bit): %02.2x\n\r", sir.address_5bit(sig))
                ser.printf1(@"Extended: %02.2x\n\r", sir.extended(sig))

        ser.printf1(@"Command: %02.2x\n\r", sir.command(sig))


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")


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


