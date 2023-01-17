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

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef XXXXX_I2C_BC
    uart : "com.serial.nocog"                   ' BC UART engine (19.2kbps max)
#else
    uart : "com.serial"                         ' PASM UART engine (250kbps TX/RX; 1Mbps TX only)
#endif
    core : "core.con.your_uart_device_here"     ' File containing your device's register set
    time : "time"                               ' Basic timing functions

PUB null
' This is not a top-level object

PUB startx(UART_RX, UART_TX, UART_BPS, UART_MODE): status
' Start the driver, using custom I/O settings
'   UART_RX: UART receive pin (from the Propeller's point of view) - in from other device
'   UART_TX: UART transmit pin (from the Propeller's point of view) - out to other device
'   UART_BPS: UART bitrate
'   UART_MODE: UART signalling mode:
'       bit 0 - invert rx
'       bit 1 - invert tx
'       bit 2 - open drain/source tx
'       bit 3 - ignore tx echo on rx
    if (status := uart.init(UART_RX, UART_TX, UART_MODE, UART_BPS))
        time.msleep(core#TPOR)                  ' Device startup time
        ' Device power-on-reset code here
        if (dev_id{} == core#DEVID_RESP)
            return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver

PUB defaults{}
' Set factory defaults

PUB dev_id{}: id
' Read device identification

PUB reset{}
' Reset the device

PRI readreg(reg_nr, nr_bytes, buff_addr) | tmp
' Read device register(s)
'   reg_nr: register number
'   nr_bytes: number of consecutive bytes to read
'   ptr_buff: pointer to buffer to read device data into
    case reg_nr
        $00:                                    ' validate register number
            ' read code here
            ' .
            ' .
            ' .
        other:
            return -1                           ' bad register num

PRI writereg(reg_nr, nr_bytes, ptr_buff) | tmp
' Write value(s) to device register
'   reg_nr: register number
'   nr_bytes: number of consecutive bytes to write
'   ptr_buff: pointer to data to write to device
    case reg_nr
        $00:                                    ' validate register number
            ' write code here
            ' .
            ' .
            ' .
        other:
            return -1

DAT
{
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

