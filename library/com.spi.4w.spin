{
    --------------------------------------------
    Filename: com.spi.4w.spin
    Author: Jesse Burt
    Description: 1MHz SPI engine (PASM core)
        @80MHz Fsys:
            Write speed: 1MHz actual (40% duty - 0.4uS H : 0.6uS L)
            Read speed: 1.052MHz actual (31% duty - 0.3uS H : 0.65 L)
        Inter-byte times:
            WrBlock(), Wr_Word(), Wr_Long(): 61uS
            Wr_ByteX(): 88uS
            Read: 72uS
    Started 2009
    Updated Jul 3, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on SPI_Asm.spin,
        originally by Beau Schwabe
}

VAR

    long _SCK, _MOSI, _MISO
    long _cog, _command

PUB Null{}
' This is not a top-level object

PUB Init(SCK, MOSI, MISO, SPI_MODE): status
' Initialize SPI engine using custom pins
'   SCK, MOSI, MISO: 0..31 (each unique)
'   SPI_MODE: 0..3
'       0: CPOL 0, CPHA 0
'           SCK idles low
'           MISO shifted in on rising clock pulse
'           MOSI shifted out on falling clock pulse
'       1: CPOL 0, CPHA 1
'           SCK idles low
'           MISO shifted in on falling clock pulse
'           MOSI shifted out on rising clock pulse
'       2: CPOL 1, CPHA 0
'           SCK idles high
'           MISO shifted in on falling clock pulse
'           MOSI shifted out on rising clock pulse
'       3: CPOL 1, CPHA 1
'           SCK idles high
'           MISO shifted in on rising clock pulse
'           MOSI shifted out on falling clock pulse
'   NOTE: CS must be handled by the parent object
    longmove(@_SCK, @SCK, 3)
    mode(SPI_MODE)

    clkdelay := 1                               ' = ~ 1MHz
    status := _cog := cognew(@entry, @_command) + 1

PUB DeInit{}
' Deinitialize
'   Float I/O pins, clear out hub vars, and stop the PASM engine
    if _cog
        cogstop(_cog - 1)
        _cog := 0
    _command := 0
    dira[_SCK] := 0
    dira[_MOSI] := 0
    dira[_MISO] := 0

PUB RdBits_LSBF(nr_bits): val | SCK, MOSI, MISO
' Read arbitrary number of bits from SPI bus, least-significant bit first
'   nr_bits: 1 to 32
    longmove(@SCK, @_SCK, 3)
    val := 0
    case _spi_mode
        0, 2:
            val := shiftin(MISO, SCK, LSBPRE, nr_bits)
        1, 3:
            val := shiftin(MISO, SCK, LSBPOST, nr_bits)

PUB RdBits_MSBF(nr_bits): val | SCK, MOSI, MISO
' Read arbitrary number of bits from SPI bus, most-significant bit first
'   nr_bits: 1 to 32
    longmove(@SCK, @_SCK, 3)
    val := 0
    case _spi_mode
        0, 2:
            val := shiftin(MISO, SCK, MSBPRE, nr_bits)
        1, 3:
            val := shiftin(MISO, SCK, MSBPOST, nr_bits)

PUB RdBlock_LSBF(ptr_buff, nr_bytes) | SCK, MOSI, MISO, b_num, tmp
' Read block of data from SPI bus, least-significant byte first
    longmove(@SCK, @_SCK, 3)
    case _spi_mode
        0, 2:
            repeat b_num from 0 to nr_bytes-1
                byte[ptr_buff][b_num] := shiftin(MISO, SCK, MSBPRE, 8)
        1, 3:
            repeat b_num from 0 to nr_bytes-1
                byte[ptr_buff][b_num] := shiftin(MISO, SCK, MSBPOST, 8)

PUB RdBlock_MSBF(ptr_buff, nr_bytes) | SCK, MOSI, MISO, b_num, tmp
' Read block of data from SPI bus, most-significant byte first
    longmove(@SCK, @_SCK, 3)
    case _spi_mode
        0, 2:
            repeat b_num from nr_bytes-1 to 0
                byte[ptr_buff][b_num] := shiftin(MISO, SCK, MSBPRE, 8)
        1, 3:
            repeat b_num from nr_bytes-1 to 0
                byte[ptr_buff][b_num] := shiftin(MISO, SCK, MSBPOST, 8)

PUB WrBits_LSBF(val, nr_bits) | SCK, MOSI, MISO
' Write arbitrary number of bits to SPI bus, least-significant byte first
'   nr_bits: 1 to 32
    longmove(@SCK, @_SCK, 4)
        shiftout(MOSI, SCK, LSBFIRST, nr_bits, val)

PUB WrBits_MSBF(val, nr_bits) | SCK, MOSI, MISO
' Write arbitrary number of bits to SPI bus, most-significant byte first
'   nr_bits: 1 to 32
    longmove(@SCK, @_SCK, 4)
        shiftout(MOSI, SCK, MSBFIRST, nr_bits, val)

PUB WrBlock_LSBF(ptr_buff, nr_bytes) | SCK, MOSI, MISO, b_num, tmp
' Write block of data to SPI bus from ptr_buff, least-significant byte first
    longmove(@SCK, @_SCK, 3)
    repeat b_num from 0 to nr_bytes-1
        shiftout(MOSI, SCK, MSBFIRST, 8, byte[ptr_buff][b_num])

PUB WrBlock_MSBF(ptr_buff, nr_bytes) | SCK, MOSI, MISO, b_num, tmp
' Write block of data to SPI bus from ptr_buff, most-significant byte first
    longmove(@SCK, @_SCK, 3)
    repeat b_num from nr_bytes-1 to 0
        shiftout(MOSI, SCK, MSBFIRST, 8, byte[ptr_buff][b_num])

PRI setCommand(cmd, argptr)
    _command := cmd << 16 + argptr              ' write cmd and pointer
    repeat while _command                       ' wait for cmd to complete

CON

    #0,MSBPRE,LSBPRE,MSBPOST,LSBPOST            ' Used for SHIFTIN routines
'                           
'       =0      =1     =2      =3
'
' MSBPRE   - Most Significant Bit first ; data is valid before the clock
' LSBPRE   - Least Significant Bit first ; data is valid before the clock
' MSBPOST  - Most Significant Bit first ; data is valid after the clock
' LSBPOST  - Least Significant Bit first ; data is valid after the clock


    #4,LSBFIRST,MSBFIRST                        ' Used for SHIFTOUT routines
'              
'       =4      =5
'
' LSBFIRST - Least Significant Bit first ; data is valid after the clock
' MSBFIRST - Most Significant Bit first ; data is valid after the clock



    #1,_SHIFTOUT,_SHIFTIN                       ' Used for operation Mode
'              
'       =1      =2

PUB SHIFTOUT(Dpin, Cpin, wrmode, Bits, Value)
' If SHIFTOUT is called with 'Bits' set to Zero, then the COG will shut
' down.  Another way to shut the COG down is to call 'stop' from Spin.
    setcommand(_SHIFTOUT, @Dpin)

PUB SHIFTIN(Dpin, Cpin, rdmode, Bits) | Value, Flag
' If SHIFTIN is called with 'Bits' set to Zero, then the COG will shut
' down.  Another way to shut the COG down is to call 'stop' from Spin.

    Flag := 1                                   ' Set Flag
    setcommand(_SHIFTIN, @Dpin)
    repeat until Flag == 0                      ' Wait for Flag to clear ... data is ready

    Result := Value

#include "com.spi-common.spinh"                 ' R/W methods common to all SPI engines

DAT
                org
entry
loop            rdlong  ptr_params, par wz      ' wait for command
        if_z    jmp     #loop
                movd    :arg,       #arg0       ' get 5 arguments; arg0 to arg4
                mov     t2,         ptr_params
                mov     t3,         #5
:arg            rdlong  arg0,       t2
                add     :arg,       d0
                add     t2,         #4
                djnz    t3,         #:arg
                mov     address,    ptr_params  ' preserve address location for passing
                                                ' variables back to Spin language.
                wrlong  zero,       par         ' zero command to signify command received
                ror     ptr_params, #16+2       ' lookup command address
                add     ptr_params, #jumps
                movs    :table,     ptr_params
                rol     ptr_params, #2
                shl     ptr_params, #3
:table          mov     t2,         0
                shr     t2,         ptr_params
                and     t2,         #$FF
                jmp     t2                      ' jump to command
jumps           byte    0                       ' 0
                byte    SHIFTOUT_               ' 1
                byte    SHIFTIN_                ' 2
                byte    NotUsed_                ' 3
NotUsed_        jmp     #loop

SHIFTOUT_                                       ' SHIFTOUT Entry
                mov     t4,         arg3 wz     ' Load number of data bits
    if_z        jmp     #Done                   ' '0' number of Bits = Done
                mov     ptr_params, #1 wz       ' Configure DataPin
                shl     ptr_params, arg0
                muxz    outa,       ptr_params  ' PreSet DataPin LOW
                muxnz   dira,       ptr_params  ' Set DataPin to an OUTPUT
                mov     t2,         #1 wz       ' Configure ClockPin
                shl     t2,         arg1        ' Set Mask
                test    clkstate,   #1 wc       ' Determine Starting State
    if_nc       muxz    outa,       t2          ' PreSet ClockPin LOW
    if_c        muxnz   outa,       t2          ' PreSet ClockPin HIGH
                muxnz   dira,       t2          ' Set ClockPin to an OUTPUT
                sub     _LSBFIRST,  arg2 wz,nr  ' Detect LSBFIRST mode for SHIFTOUT
    if_z        jmp     #LSBFIRST_
                sub     _MSBFIRST,  arg2 wz,nr  ' Detect MSBFIRST mode for SHIFTOUT
    if_z        jmp     #MSBFIRST_
                jmp     #loop                   ' Go wait for next command


SHIFTIN_                                        ' SHIFTIN Entry
                mov     t4,         arg3 wz     ' Load number of data bits
    if_z        jmp     #done                   ' '0' number of Bits = Done
                mov     ptr_params, #1 wz       ' Configure DataPin
                shl     ptr_params, arg0
                muxz    dira,       ptr_params  ' Set DataPin to an INPUT
                mov     t2,         #1 wz       ' Configure ClockPin
                shl     t2,         arg1        ' Set Mask
                test    clkstate,   #1 wc       ' Determine Starting State
    if_nc       muxz    outa,       t2          ' PreSet ClockPin LOW
    if_c        muxnz   outa,       t2          ' PreSet ClockPin HIGH
                muxnz   dira,       t2          ' Set ClockPin to an OUTPUT
                sub     _MSBPRE,    arg2 wz,nr  ' Detect MSBPRE mode for SHIFTIN
    if_z        jmp     #MSBPRE_
                sub     _LSBPRE,    arg2 wz,nr  ' Detect LSBPRE mode for SHIFTIN
    if_z        jmp     #LSBPRE_
                sub     _MSBPOST,   arg2 wz,nr  ' Detect MSBPOST mode for SHIFTIN
    if_z        jmp     #MSBPOST_
                sub     _LSBPOST,   arg2 wz,nr  ' Detect LSBPOST mode for SHIFTIN
    if_z        jmp     #LSBPOST_
                jmp     #loop                   ' Go wait for next command


MSBPRE_                                         ' Receive Data MSBPRE
Rd_MSBPre       test    ptr_params, ina wc      ' Read Data Bit into 'C' flag
                rcl     t3,         #1          ' rotate "C" flag into return value
                call    #preclk                 ' Send clock pulse
                djnz    t4,         #rd_msbpre  ' Decrement t4 ; jump if not Zero
                jmp     #rdlong_hub             ' Pass received data to SHIFTIN receive variable

LSBPRE_                                         ' Receive Data LSBPRE
                add     t4,         #1
Rd_LSBPre       test    ptr_params, ina wc      ' Read Data Bit into 'C' flag
                rcr     t3,         #1          ' rotate "C" flag into return value
                call    #preclk                 ' Send clock pulse
                djnz    t4,         #rd_lsbpre  ' Decrement t4 ; jump if not Zero
                mov     t4,         #32         ' For LSB shift data right 32 - #Bits when done
                sub     t4,         arg3
                shr     t3,         t4
                jmp     #rdlong_hub             ' Pass received data to SHIFTIN receive variable

MSBPOST_                                        ' Receive Data MSBPOST
Rd_MSBPost      call    #postclk                ' Send clock pulse
                test    ptr_params, ina wc      ' Read Data Bit into 'C' flag
                rcl     t3,         #1          ' rotate "C" flag into return value
                djnz    t4,         #rd_msbpost ' Decrement t4 ; jump if not Zero
                jmp     #rdlong_hub             ' Pass received data to SHIFTIN receive variable

LSBPOST_                                        ' Receive Data LSBPOST
                add     t4,         #1
Rd_LSBPost      call    #postclk                ' Send clock pulse
                test    ptr_params, ina wc      ' Read Data Bit into 'C' flag
                rcr     t3,         #1          ' rotate "C" flag into return value
                djnz    t4,         #rd_lsbpost ' Decrement t4 ; jump if not Zero
                mov     t4,         #32         ' For LSB shift data right 32 - #Bits when done
                sub     t4,         arg3
                shr     t3,         t4
                jmp     #rdlong_hub             ' Pass received data to SHIFTIN receive variable

LSBFIRST_                                       ' Send Data LSBFIRST
                mov     t3,         arg4        ' Load t3 with DataValue
Wr_LSB          test    t3,         #1 wc       ' Test LSB of DataValue
                muxc    outa,       ptr_params  ' Set DataBit HIGH or LOW
                shr     t3,         #1          ' Prepare for next DataBit
                call    #postclk                ' Send clock pulse
                djnz    t4,         #wr_lsb     ' Decrement t4 ; jump if not Zero
                mov     t3,         #0 wz       ' Force DataBit LOW
                muxnz   outa,       ptr_params
                jmp     #loop                   ' Go wait for next command

MSBFIRST_                                       ' Send Data MSBFIRST
                mov     t3,         arg4        ' Load t3 with DataValue
                mov     t5,         #%1         ' Create MSB mask; load t5 with "1"
                shl     t5,         arg3        ' Shift "1" N number of bits to the left.
                shr     t5,         #1          ' Shifting the number of bits left actually puts
                                                ' us one more place to the left than we want. To
                                                ' compensate we'll shift one position right.
Wr_MSB          test    t3,         t5 wc       ' Test MSB of DataValue
                muxc    outa,       ptr_params  ' Set DataBit HIGH or LOW
                shr     t5,         #1          ' Prepare for next DataBit
                call    #postclk                ' Send clock pulse
                djnz    t4,         #wr_msb     ' Decrement t4 ; jump if not Zero
                mov     t3,         #0 wz       ' Force DataBit LOW
                muxnz   outa,       ptr_params

                jmp     #loop                   ' Go wait for next command

RdLong_hub
                mov     ptr_params, address     ' Write data back to Arg4
                add     ptr_params, #16         ' Arg0 = #0 ; Arg1 = #4 ; Arg2 = #8 ; Arg3 = #12 ; Arg4 = #16
                wrlong  t3,         ptr_params
                add     ptr_params, #4          ' Point ptr_params to Flag ... Arg4 + #4
                wrlong  zero,       ptr_params  ' Clear Flag ... indicates SHIFTIN data is ready
                jmp     #loop                   ' Go wait for next command

PreClk
                mov     t2,         #0      nr  ' Clock Pin
                test    t2,         ina     wz  ' Read ClockPin
                muxz    outa,       t2          ' Set ClockPin to opposite  of read value
                call    #clkdly
                muxnz   outa,       t2          ' Restore ClockPin to original read value
                call    #clkdly
PreClk_ret      ret                             ' return

PostClk
                mov     t2,         #0      nr  ' Clock Pin
                test    t2,         ina     wz  ' Read ClockPin
                call    #clkdly
                muxz    outa,       t2          ' Set ClockPin to opposite  of read value
                call    #clkdly
                muxnz   outa,       t2          ' Restore ClockPin to original read value
PostClk_ret     ret                             ' return

ClkDly
                mov     t6,         clkdelay
ClkPause        djnz    t6,         #clkpause
ClkDly_ret      ret

Done                                            ' Shut COG down
                mov     t2,         #0          ' Preset temp variable to Zero
                mov     ptr_params, par         ' Read the address of the first perimeter
                add     ptr_params, #4          ' Add offset for the second perimeter ; The 'Flag' variable
                wrlong  t2,         ptr_params  ' Reset the 'Flag' variable to Zero
                cogid   ptr_params              ' read cog ID
                cogstop ptr_params

' Initialized variables
zero            long    0                       'constants
d0              long    $200

' SHIFTIN bit order/phase
_MSBPRE         long    0
_LSBPRE         long    1
_MSBPOST        long    2
_LSBPOST        long    3

' SHIFTOUT bit order/phase
_LSBFIRST       long    4
_MSBFIRST       long    5

clkdelay        long    0
clkstate        long    0

' temporary variables
ptr_params      long    0                       ' Used for DataPin mask     and     COG shutdown
t2              long    0                       ' Used for CLockPin mask    and     COG shutdown
t3              long    0                       ' Used to hold DataValue SHIFTIN/SHIFTOUT
t4              long    0                       ' Used to hold # of Bits
t5              long    0                       ' Used for temporary data mask
t6              long    0                       ' Used for Clock Delay
address         long    0                       ' Used to hold return address of first Argument passed

arg0            long    0                       'arguments passed to/from high-level Spin
arg1            long    0
arg2            long    0
arg3            long    0
arg4            long    0

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

