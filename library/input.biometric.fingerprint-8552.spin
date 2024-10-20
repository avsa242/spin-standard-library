{
    --------------------------------------------
    Filename: input.biometric.fingerprint-8552.spin
    Author: Jesse Burt
    Description: Driver for Waveshare UART fingerprint reader SKU#8552
    Copyright (c) 2022
    Started May 18, 2020
    Updated Oct 31, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Fingerprint add user policies
    ALLOW       = 0
    PROHIBIT    = 1

VAR

    byte _response[8]
    byte _BL, _RST

OBJ

    uart    : "com.serial"
    core    : "core.con.fingerprint-8552"
    time    : "time"

PUB null{}
' This is not a top-level object

PUB startx(UART_RX, UART_TX, BL, RST): status
' Start using custom settings
'   BL, RST optional (outside of range 0..31 will be ignored)
'   UART_BPS max is 19_200
    if lookdown(UART_RX: 0..31) and lookdown(UART_TX: 0..31)
        if (status := uart.init(UART_RX, UART_TX, core#UART_MODE, core#UART_MAX_BPS))
            time.msleep(1)
            _BL := BL
            _RST := RST
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    uart.stop{}
    bytefill(@_response, 0, 10)

PUB defaults
' Set factory defaults
    policy_user_add(PROHIBIT)
    comparison_level(5)

PUB add_print(uid, priv): stat | tmp, user, idx
' Add a fingerprint to the database
'   Valid values:
'       uid: User ID, $001..$FFF
'       priv: Privilege level to assign: 1, 2, 3 (meaning is user defined)
'   Any other value returns the error ACK_FAIL (1)
    ifnot (lookdown(uid: $001..$FFF) or lookdown(priv: 1, 2, 3))
        return core#ACK_FAIL

    user.byte[0] := uid.byte[1]
    user.byte[1] := uid.byte[0]
    user.byte[2] := priv

    repeat idx from 0 to 2                      ' Acquire 3 fingerprints
        writecmd(core#ADD_FNGPRT_01 + idx, user.byte[0], user.byte[1], user.byte[2], $00)
        stat := _response[core#IDX_Q3]
        if (stat <> core#ACK_SUCCESS)           ' If the module doesn't return SUCCESS,
            return                              '   quit and return the response

PUB cmd_status{}: last_stat
' Return status of last command
    return _response[core#IDX_Q3]

PUB comparison_level(level): curr_lvl | tmp
' Set fingerprint comparison level
'   Valid values: 0..9 (0: Most lenient, 9: Most strict)
'   Any other value polls the device and returns the current setting
    curr_lvl := 0
    writecmd(core#CMP_LEVEL, $00, $00, core#CMP_LEVEL_R, $00)
    curr_lvl := _response[core#IDX_Q2]

    case level
        0..9:
        other:
            return curr_lvl

    writecmd(core#CMP_LEVEL, $00, level, $00, $00)
    return _response[core#IDX_Q3]

PUB delete_all_users = del_all_users
PUB del_all_users{}
' Delete all users in database
    writecmd(core#DEL_ALL_USERS, $00, $00, $00, $00)

PUB delete_user = del_user
PUB del_user(uid): stat | tmp
' Delete a user from the databse
'   Valid values:
'       uid (User ID): $001..$FFF
'   Any other value returns the error ACK_FAIL (1)
    case uid
        $001..$FFF:
            tmp.byte[0] := uid.byte[1]
            tmp.byte[1] := uid.byte[0]
            tmp.byte[2] := 0
        other:
            return core#ACK_FAIL

    writecmd(core#DEL_USER, tmp.byte[0], tmp.byte[1], tmp.byte[2], $00)
    return _response[core#IDX_Q3]

PUB policy_user_add(policy): curr_pol | tmp
' Set fingerprint add user policy
'   Valid values:
'       0: Allow the same fingerprint to add a new user
'       1: Prohibit adding the same fingerprint
'   Any other value polls the device and returns the current setting
    tmp := 0
    writecmd(core#FNGPRT_ADDMODE, $00, $00, core#ADDMODE_R, $00)
    tmp := _response[core#IDX_Q2]

    case policy
        0, 1:
        other:
            return tmp

    writecmd(core#FNGPRT_ADDMODE, $00, policy, core#ADDMODE_W, $00)
    return _response[core#IDX_Q2]

PUB print_matches_any{}: uid
' Compare fingerprint against entire database
'   Returns:
'       TRUE (Matching uid), if any
'       FALSE (0) otherwise
    writecmd(core#COMPARE1TON, $00, $00, $00, $00)
    uid.byte[0] := _response[core#IDX_Q2]
    uid.byte[1] := _response[core#IDX_Q1]

PUB print_matches_user(uid): ismatch
' Compare fingerprint against uid
'   Returns:
'       TRUE (-1) if fingerprint captured matches fingerprint recorded for uid
'       FALSE (0) otherwise
    writecmd(core#COMPARE1TO1, uid.byte[1], uid.byte[0], $00, $00)
    return ((_response[core#IDX_Q3]) ^ 1) == 1

PUB reset{}
' Reset the device
    if (lookdown(_RST: 0..31))
        outa[_RST] := 1
        dira[_RST] := 1

        outa[_RST] := 0
        time.msleep(500)
        outa[_RST] := 1

PUB response(ptr_resp)
' Read last response
'   Returns: Address of response data
    bytemove(ptr_resp, @_response, 8)
    bytefill(@_response, 0, 8)                  ' clear out response after read

PUB total_user_count{}: total
' Returns: Count of total number of users in database
    writecmd(core#RD_NR_USERS, $00, $00, $00, $00)
    total.byte[0] := _response[core#IDX_Q2]
    total.byte[1] := _response[core#IDX_Q1]

PUB user_priv(uid): priv
' Returns: User privilege of uid
    writecmd(core#RD_USER_PRIV, uid.byte[1], uid.byte[0], $00, $00)
    return _response[core#IDX_Q3]

PRI genChecksum(ptr_data, nr_bytes): cksum | tmp
' Generate checksum of nr_bytes from ptr_data
    cksum := 0
    repeat tmp from core#CKSUM_START to nr_bytes
        cksum ^= byte[ptr_data][tmp]

PRI readResp(nr_bytes, ptr_resp) | tmp
' Read response from fingerprint reader
    repeat tmp from 0 to nr_bytes-1
        byte[ptr_resp][tmp] := uart.charin{}
    uart.flush{}

PRI writeCmd(cmd, p0, p1, p2, p3) | cmd_pkt[2], tmp
' Write command with parameters to fingerprint reader
    cmd_pkt.byte[core#IDX_SOM] := core#SOM
    cmd_pkt.byte[core#IDX_CMD] := cmd
    cmd_pkt.byte[core#IDX_P1] := p0
    cmd_pkt.byte[core#IDX_P2] := p1
    cmd_pkt.byte[core#IDX_P3] := p2
    cmd_pkt.byte[core#IDX_0] := p3
    cmd_pkt.byte[core#IDX_CHK] := genchecksum(@cmd_pkt, 5)
    cmd_pkt.byte[core#IDX_EOM] := core#EOM

    repeat tmp from core#IDX_SOM to core#IDX_EOM
        uart.char(cmd_pkt.byte[tmp])

    readresp(8, @_response)

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

