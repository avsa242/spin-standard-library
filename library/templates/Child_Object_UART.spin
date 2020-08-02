{
    --------------------------------------------
    Filename:
    Author:
    Description:
    Copyright (c) 20__
    Started Month Day, Year
    Updated Month Day, Year
    See end of file for terms of use.
    --------------------------------------------
}

CON


VAR

OBJ

    uart    : "com.serial"                                      'PASM UART driver
    core    : "core.con.your_uart_device_here"                  'File containing your device's register set
    io      : "io"
    time    : "time"                                            'Basic timing functions

PUB Null
''This is not a top-level object

PUB Start(UART_RX, UART_TX, UART_BPS, UART_MODE): okay

        if okay := uart.StartRXTX(UART_RX, UART_TX, UART_MODE, UART_BPS)
            time.msleep(core#TPOR)                              ' Device startup time
            ' Device power-on-reset code here
            if deviceid{} == core#DEVID_RESP
                return okay
    return FALSE                                                ' If we got here, something went wrong

PUB Stop{}

PUB Defaults{}
' Set factory defaults

PUB DeviceID{}: id
' Read device identification

PUB Reset{}
' Reset the device

PRI readReg(reg_nr, nr_bytes, buff_addr) | tmp
' Read nr_bytes from register 'reg_nr' to address 'buff_addr'
    case reg_nr
        $00:                                                    ' Validate register number
        core#REG_NAME:
            'Special handling for register REG_NAME
        OTHER:
            return FALSE

' Example code to write to a device register - concept only
'   NOTE: Not representative of any actual device. Replace with code required to implement
'       your device's protocol.
    uart.char(reg_nr | R)
    repeat tmp from 0 to nr_bytes-1
        byte[buff_addr][tmp] := uart.charin{}

PRI writeReg(reg_nr, nr_bytes, buff_addr) | tmp
' Write nr_bytes to register 'reg_nr' stored at buff_addr
    case reg_nr
        $00:                                                    ' Validate register number
        core#REG_NAME:
            'Special handling for register REG_NAME
        OTHER:
            return FALSE

' Example code to write to a device register - concept only
'   NOTE: Not representative of any actual device. Replace with code required to implement
'       your device's protocol.
    uart.char(reg_nr | W)
    repeat tmp from 0 to nr_bytes-1
        byte[buff_addr][tmp] := uart.charin{}

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
