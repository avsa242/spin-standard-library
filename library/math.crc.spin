{
----------------------------------------------------------------------------------------------------
    Filename:       math.crc.spin
    Description:    A collection of CRC and checksum routines
    Author:         Jesse Burt
    Started:        Nov 19, 2017
    Updated:        Oct 17, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    ' predefined polynomials usable with CRC routines
    POLY8_ASAIR     = $131
    POLY8_DSMAX     = $8C
    POLY8_MEAS      = $31
    POLY8_SD        = $09
    POLY8_SENSIRION = $31
    POLY8_SILABS    = $131
    POLY16_DSMAX    = $A001
    POLY16_XYZMODEM = $1021
    POLY32_ZMODEM   = $EDB88320


PUB asaircrc8(ptr_data, len): crc
' CRC8 for ASAIR temp/RH sensors
    return crc8(ptr_data, len, $ff, 0, POLY8_ASAIR, false, false)


PUB inet_chksum(ptr_buff, len, pshdr_chk): cksum | i
' Checksum used in various internet datagrams
'   ptr_buff: pointer to buffer of data to calculate checksum
'   len: length of data
'   pshdr_chk: optional checksum to add to this checksum, e.g., the checksum of a
'       UDP or TCP pseudo-header. Specify 0, if unused.
    { checksum is word-oriented, so _always_ process two bytes at a time
      An even number required for len is thus implied; if the length of data
      is odd, pad the source data with a zero. }
    cksum := 0

    repeat i from 0 to (len-2) step 2
        cksum += (byte[ptr_buff][i] << 8) | byte[ptr_buff][i+1]

    { isolate the total carried, add it to the checksum and return
      the complement as the final result }
    cksum := ( !(cksum + cksum.word[1]) ) & $ffff

    { add the optional pseudo-header checksum to the result }
    cksum += pshdr_chk
    cksum.word[0] += cksum.word[1]


PUB meas_crc8(data, len): crc | currbyte, i, j
' Measurement specialties CRC8
    crc := $00
    repeat i from 0 to len-1
        currbyte := byte[data][(len-1)-i]
        crc := crc ^ currbyte

        repeat j from 0 to 7
            if (crc & $80)
                crc := (crc << 1) ^ POLY8_MEAS
            else
                crc := (crc << 1)
    crc ^= $00
    return crc & $FF


PUB sd_crc7(ptr_data, len): crc | byte_nr, bit_nr, curr_byte
' MMC/SD CRC7
    crc := $00
    repeat byte_nr from 0 to len-1
        curr_byte := byte[ptr_data][byte_nr]
        repeat bit_nr from 0 to 7
            crc <<= 1
            if ((curr_byte & $80) ^ (crc & $80))
                crc ^= POLY8_SD
            curr_byte <<= 1

    return ((crc << 1) | 1) & $FF


PUB sensirion_crc8(data, len): crc | currbyte, i, j

    crc := $FF
    repeat i from 0 to len-1
        currbyte := byte[data][(len-1)-i]
        crc := crc ^ currbyte

        repeat j from 0 to 7
            if (crc & $80)
                crc := (crc << 1) ^ POLY8_SENSIRION
            else
                crc := (crc << 1)
    crc ^= $00
    return crc & $FF


PUB silabs_crc8(data, len): crc | currbyte, i, j

    crc := $00
    repeat i from 0 to len-1
        currbyte := byte[data][(len-1)-i]
        crc := crc ^ currbyte

        repeat j from 0 to 7
            if (crc & $80)
                crc := (crc << 1) ^ POLY8_SILABS
            else
                crc := (crc << 1)
    crc ^= $00
    return crc & $FF


PUB dallas_maxim_crc8(data, len): crc | currbyte, i, j, mix

    crc := $00
    repeat i from 0 to len-1
        currbyte := byte[data][i]
        repeat j from 0 to 7
            mix := (crc ^ currbyte) & $01
            crc >>= 1
            if mix
                crc ^= POLY8_DSMAX
            currbyte >>= 1

    return


PUB dallas_maxim_crc16(data, len): crc | currbyte, i, j, mix

    crc := $00
    repeat i from 0 to len-1
        currbyte := byte[data][i]
        repeat j from 0 to 7
            mix := (crc ^ currbyte) & $01
            crc >>= 1
            if mix
                crc ^= POLY16_DSMAX
            currbyte >>= 1

    return


PUB xor_checksum(p_data, len, init=0): c
' XOR checksum
'   p_data: pointer to data to checksum
'   len:    length of data to checksum
'   init:   value to initialize checksum to (default is 0 if unspecified)
'   Returns:
'       checksum
    c := init
    repeat len
        c := (c ^ byte[p_data++])


PUB xyzm_crc16(ptr_data, len): crc
' X/Y/ZModem 16bit CRC
'   ptr_data: pointer to data
'   data_len: length of data, in bytes
    return crc16(ptr_data, len, $0000, 0, POLY16_XYZMODEM, false, false)


PUB zm_crc32(ptr_data, len): crc
' ZModem 32bit CRC
'   ptr_data: pointer to data
'   data_len: length of data, in bytes
    return crc32(ptr_data, len, $FFFFFFFF, true, POLY32_ZMODEM, false, false)


PUB crc8(ptr_data, data_len, init, xorout, poly, ireflect, oreflect): crc | curr_byte, bit
' Calculate CRC8
'   ptr_data: pointer to data
'   data_len: length of data, in bytes (u31)
'   init: value to initialize CRC with (u32)
'   xorout: value to XOR final CRC with (u32)
'   poly: polynomial to use in CRC calculation (u32)
'   ireflect: bitwise reverse initial value? (bool)
'   oreflect: bitwise reverse final value? (bool)
    crc := init
    if (ireflect)                               ' reflect initial value?
        crc ><= 8

    repeat curr_byte from 0 to (data_len-1)
        crc ^= byte[ptr_data][curr_byte]
        repeat bit from 0 to 7
            if (crc & $80)
                crc := (crc << 1) ^ poly
            else
                crc := (crc << 1)

    if (oreflect)                               ' reflect final value?
        crc ><= 8

    return (crc ^ xorout) & $ff


PUB crc16(ptr_data, data_len, init, xorout, poly, ireflect, oreflect): crc | curr_byte, bit
' Calculate CRC16
'   ptr_data: pointer to data
'   data_len: length of data, in bytes
'   init: value to initialize CRC with
'   poly: polynomial to use in CRC calculation
'   reflect: whether to bitwise-reverse data bytes read
    crc := init                                 ' initialize CRC
    if (ireflect)                               ' reflect initial value?
        crc ><= 16

    repeat curr_byte from 0 to data_len-1
        crc ^= (byte[ptr_data][curr_byte] << 8)
        repeat bit from 7 to 0
            if (crc & $8000)
                crc := (crc << 1) ^ poly
            else
                crc := (crc << 1)

    if (oreflect)                               ' reflect final value?
        crc ><= 16

    return ((crc ^ xorout) & $ffff)


PUB crc32(ptr_data, data_len, init, xorout, poly, ireflect, oreflect): crc | curr_byte, bit
' Calculate CRC32
'   ptr_data: pointer to data
'   data_len: length of data, in bytes (u31)
'   init: value to initialize CRC with (u32)
'   xorout: value to XOR final CRC with (u32)
'   poly: polynomial to use in CRC calculation (u32)
'   ireflect: bitwise reverse initial value? (bool)
'   oreflect: bitwise reverse final value? (bool)
    crc := init                                 ' initialize CRC
    if (ireflect)                               ' reflect initial value?
        crc ><= 32
    data_len--                                  ' pre-calc for loop
    repeat curr_byte from 0 to data_len
        crc ^= byte[ptr_data][curr_byte]
        repeat bit from 7 to 0
            if (crc & $01)
                crc := (crc >> 1) ^ poly
            else
                crc := (crc >> 1)

    if (oreflect)                               ' reflect final value?
        crc ><= 32

    return crc ^ xorout

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

