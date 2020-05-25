{
    --------------------------------------------
    Filename: tiny.signal.dac.ad8803.spi.spin
    Author: Beau Schwabe
    Modified by: Jesse Burt
    Description: Driver for the AD8803 Octal 8-bit trim DAC
        (SPIN-only)
    Started 2007
    Updated May 25, 2020
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This is a derivative of AD8803.spin,
        by Beau Schwabe.
        The original header is preserved below
}

{{
*****************************************
* AD8803 Octal 8-Bit Trim DAC Demo v1.0 *
* Author: Beau Schwabe                  *
* Copyright (c) 2007 Parallax           *
* See end of file for terms of use.     *
*****************************************
}}
OBJ

    io  : "io"

PUB Set(CS, SDI, CLK, DACaddress, DACvalue)

    CS         := 0 #> CS         <# 31                 ' Limit CS's         range from 0-31
    SDI        := 0 #> SDI        <# 31                 ' Limit SDI's        range from 0-31
    CLK        := 0 #> CLK        <# 31                 ' Limit CLK's        range from 0-31
    DACaddress := 0 #> DACaddress <# 7                  ' Limit DACaddress's range from 0- 7

    io.Output(CS)                                       ' Make  CS  pin an output
    io.Output(SDI)                                      ' Make  SDI pin an output
    io.Output(CLK)                                      ' Make  CLK pin an output

    io.Low(CLK)                                         ' Bring CLK low ; load AD8803 data
    io.Low(CS)                                          ' Bring CS low

    SendData(SDI, CLK, 3, DACaddress)                   ' Select Address
    SendData(SDI, CLK, 8, DACvalue)                     ' Select Value

    io.High(CS)                                         ' Bring CS high ; latch AD8803 data

PRI SendData(SDI,CLK,Bits,Data) | temp                  ' Send DATA MSB first

    temp := 1 << ( Bits - 1 )
    repeat Bits
        io.Set(SDI, (Data & temp) / temp)               ' Set bit value
        io.High(CLK)                                    ' Clock bit
        io.Low(CLK)                                     ' Clock bit
        temp := temp >> 1

