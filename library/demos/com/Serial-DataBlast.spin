{
    --------------------------------------------
    Filename: Serial-DataBlast.spin
    Description: Simple serial demo that sends all
        printable characters to the terminal
    Author: Unknown
    Modified by: Jesse Burt
    Copyright (c) 2022
    Started: Unknown
    Updated: Oct 22, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115200
' --

OBJ

    cfg : "boardcfg.flip"
    ser : "com.serial.terminal.ansi"

PUB main{} | ch

    ser.start(SER_BAUD)
    ch := 32

    repeat
        if (ch > 127)
            ch := 32
        ser.putchar(ch++)
        repeat 10000

