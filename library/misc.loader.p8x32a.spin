{
    --------------------------------------------
    Filename: misc.loader.p8x32a.spin
    Author: Chip Gracey
    Modified by: Jesse Burt
    Description: Object to use a host Propeller to load
        firmware to another Propeller
    Copyright (c) 2020
    Started Jun 13, 2006
    Updated May 25, 2020
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is a derivative of PropellerLoader,
        originally by Chip Gracey. The original header
        is preserved below.
}

''***************************************
''*  Propeller Loader v1.0              *
''*  Author: Chip Gracey                *
''*  Copyright (c) 2006 Parallax, Inc.  *
''*  See end of file for terms of use.  *
''***************************************

' v1.0 - 13 June 2006 - original version

''_____________________________________________________________________________
''
''This object lets a Propeller chip load up another Propeller chip in the same
''way the PC normally does.
''
''To do this, the program to be loaded into the other Propeller chip must be
''compiled using "F8" (be sure to enable "Show Hex") and then a "Save Binary
''File" must be done. This binary file must then be included so that it will be
''resident and its address can be conveyed to this object for loading.
''
''Say that the file was saved as "loadme.binary". Also, say that the Propeller
''which will be performing the load/program operation has its pins 0..2 tied to
''the other Propeller's pins RESn, _P31, and _P30, respectively. And we'll say
''we're working with version 1 chips and you just want to load and execute the
''program. Your code would look something like this:
''
''
''OBJ loader : "misc.loader.p8x32a"
''
''DAT loadme file "loadme.binary"
''
''PUB LoadPropeller
''
''  loader.Connect(0, 1, 2, 1, loader#LOADRUN, @loadme)
''
''
''This object drives the other Propeller's RESn line, so it is recommended that
''the other Propeller's BOEn pin be tied high and that its RESn pin be pulled
''to VSS with a 1M resistor to keep it on ice until showtime.
''_____________________________________________________________________________
''

CON

    #1, ERRORCONNECT, ERRORVERSION, ERRORCHECKSUM, ERRORPROGRAM, ERRORVERIFY
    #0, SHUTDOWN, LOADRUN, PROGRAMSHUTDOWN, PROGRAMRUN

VAR

    long _P31, _P30, _LFSR, Ver, _echo

OBJ

    time    : "time"

PUB Connect(RESN_PIN, P31_PIN, P30_PIN, version, command, ptr_code): error

    _P31 := P31_PIN                                             ' Set P31 and P30
    _P30 := P30_PIN

    outa[RESN_PIN] := 0                                         ' RESn low
    dira[RESN_PIN] := 1

    outa[P31_PIN] := 1                                          ' P31 high (our TX)
    dira[P31_PIN] := 1

    dira[P30_PIN] := 0                                          ' P30 input (our RX)

    outa[RESN_PIN] := 1                                         ' RESn high

    time.MSleep(100)                                            ' Wait 100ms

    if error := \Communicate(version, command, ptr_code)        ' Communicate (may abort with error code)
        dira[RESN_PIN] := 0

    dira[P31_PIN] := 0                                          ' P31 float

PRI Communicate(version, command, ptr_code) | bytecount

    BitsOut(%01, 2)                                             ' Output calibration pulses

    _LFSR := "P"                                                ' Send LFSR pattern
    repeat 250
        BitsOut(Iterate_LFSR, 1)

    repeat 250                                                  ' Receive and verify LFSR pattern
        if WaitBit(1) <> Iterate_LFSR
            abort ERRORCONNECT

    repeat 8                                                    ' Receive chip version
        Ver := WaitBit(1) << 7 + Ver >> 1

    if Ver <> version                                           ' If version mismatch, shutdown and abort
        BitsOut(SHUTDOWN, 32)
        abort ERRORVERSION

    BitsOut(command, 32)                                        ' Send command

    if command                                                  ' Handle command details
        bytecount := byte[ptr_code][8] | byte[ptr_code][9] << 8 ' Send long count
        BitsOut(bytecount >> 2, 32)

        repeat bytecount                                        ' Send bytes
            BitsOut(byte[ptr_code++], 8)

        if WaitBit(25)                                          ' Allow 250ms for positive checksum response
            abort ERRORCHECKSUM

        if command > 1                                          ' EEPROM program command
            if WaitBit(500)                                     ' Allow 5s for positive program response
                abort ERRORPROGRAM
            if WaitBit(200)                                     ' Allow 2s for positive verify response
                abort ERRORVERIFY

PRI Iterate_LFSR: bit

    bit := _LFSR & 1                                            ' Get return bit
                                                                ' Iterate LFSR (8-bit, $B2 taps)
    _LFSR := _LFSR << 1 | (_LFSR >> 7 ^ _LFSR >> 5 ^ _LFSR >> 4 ^ _LFSR >> 1) & 1

PRI WaitBit(Hundredths): bit | prior_echo

    repeat Hundredths                                           ' Output 1t pulse
        BitsOut(1, 1)
        bit := ina[_P30]                                        ' Sample bit and echo
        prior_echo := _echo
        BitsOut(0, 1)                                           ' Output 2t pulse

        if not prior_echo                                       ' If echo was low, got bit
            return
        time.MSleep(10)                                         ' Wait 10ms

    abort ERRORCONNECT                                          ' Timeout, abort

PRI BitsOut(value, bits)

    repeat bits
        if value & 1                                            ' Output '1' (1t pulse)
            outa[_P31] := 0
            _echo := ina[_P30]
            outa[_P31] := 1
        else                                                    ' Output '0' (2t pulse)
            outa[_P31] := 0
            outa[_P31] := 0
            _echo := ina[_P30]
            _echo := ina[_P30]
            outa[_P31] := 1
        value >>= 1

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

