{
    --------------------------------------------
    Filename: com.can.txrx.spin
    Description: CANbus engine (bi-directional, 500kbps)
    Author: Jesse Burt
    Created: 2015
    Updated: Oct 30, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on CANbus controller 500Kbps.spin, originally by Chris Gadd.
}
CON

    BUSY_FLAG      = |< 0           ' set by spin, cleared at get_ack / :ack
    ERROR_FLAG     = |< 1           ' set at reset if either tx error counter reaches 255,
                                    '   cleared after RxD idles for 128 x 11 bits
    TX_FLAG        = |< 2           ' set at the end of build_msg, cleared at get_ack
    RTR_FLAG       = |< 3           ' indicates a remote-transmission request was received
    STUFFED_FLAG   = |< 4           ' next received bit should be stuffed?
                                    '   cleared when stuffed bit is receieved
    LOOPBACK_FLAG  = |< 5           ' outgoing messages are ACK'd and stored in recv buffers

VAR

    long    _clock_freq
    long    _pulse_width
    long    _mask, filter[5]
    long    _rx_ident[8]
    long    _tx_ident
    byte    _rx_data[9 * 8]
    byte    _tx_dlc
    byte    _tx_data[8]
    byte    _flags_var, _recv_errs, _ack_errs, _arb_errs
    byte    _pins[2]
    byte    _index_array
    byte    _index_element
    byte    _cog

PUB startx(CAN_RX, CAN_TX, CAN_BPS): status
' Start the driver, using custom I/O settings
'   CAN_RX, CAN_TX: 0..31
'   CAN_BPS: 1..500_000
    _pins[0] := can_rx
    _pins[1] := can_tx
    _clock_freq := fraction(CAN_BPS, clkfreq)
    _pulse_width := clkfreq / CAN_BPS                     ' Used by writer

    stop{}
    if (status := _cog := cognew(@entry, @_clock_freq) + 1)
        return @_rx_ident

PUB stop
' Stop the driver
    if (_cog)
        cogstop(_cog~ - 1)

PUB ack_errs{}: errcnt
' Count of transmitted messages that weren't ackowledged by other nodes
'   Returns: Number of acknowledge errors
'   NOTE: If counter reaches 255, the bus goes into recovery mode until RxD is idle for
'       128 x 11 bits.
'   During bus recovery, messages cannot be transmitted but can still be received.
'   The error counters are reset after bus recovery
    return _ack_errs

PUB arb_errs{}: errcnt
' Count of messages that were interrupted by a received message with a higher priority
'   Returns: Number of arbitration errors
'   NOTE: Arbitration errors do not necessarily indicate a problem, merely that this object and
'       another node attempted to transmit at the same time
'   NOTE: If counter reaches 255, the bus goes into recovery mode until RxD is idle for
'       128 x 11 bits.
'   During bus recovery, messages cannot be transmitted but can still be received.
'   The error counters are reset after bus recovery
    return _arb_errs

PUB can_ready = can_rdy
PUB can_rdy{}
' Check engine for readiness
    ifnot (_flags_var & BUSY_FLAG) and not (check_err{})
        return TRUE

PUB check_error = check_err
PUB check_err{}
' Check engine for error status
    if (_flags_var & ERROR_FLAG)
        return TRUE

PUB check_rtr{}
' Flag indicating the current receive buffer contains a remote-transmission request
'   Returns: TRUE (-1) or FALSE (0)
    if (_rx_ident[_index_array] & $8000_0000)
        return TRUE

PUB rx_ptr{}: ptr
' Address of the current receive data buffer
'   NOTE: The address can be used as a length-prefaced string
    return @_rx_data[_index_array * 9]

PUB rx_len{}: len
' Number of data bytes stored in the current receive buffer
'   Returns: Number of bytes
    _index_element := 0
    return _rx_data[_index_array * 9]

PUB id{}: ident
' Ident stored in the current receive buffer, returns false if no ident is stored
'   Returns: 11 or 29-bit ident, or FALSE if no ident is stored or if ident is $000
    _index_element := 0
    return (_rx_ident[_index_array] & !$8000_0000)

PUB loopback_ena(state)
' Enable loopback mode
'   Valid values: TRUE (non-zero), FALSE (0)
    _flags_var := _flags_var &! LOOPBACK_FLAG | (LOOPBACK_FLAG & ((state <> 0) & 1))

PUB next_id{}
' Clear the ident in the current receive buffer and advance index to the next receive buffer
'   Returns: The ident in the next receive buffer, or FALSE if no ident is stored
    _rx_ident[_index_array] := 0
    _index_array := ((_index_array + 1) & 7)
    _index_element := 0
    return (_rx_ident[_index_array] & !$8000_0000)

PUB rd_byte{}
' Read byte from the current receive buffer; successive calls return the following bytes
'   NOTE: The id(), next_id(), or rx_len() method must be called before the initial call
'       to rd_byte(), to set index_element to 0
' This method only returns values from the current read - will not return out-of-date data
'   from previous reads
    if (++_index_element =< _rx_data[_index_array * 9])
        return (_rx_data[(_index_array * 9) + _index_element])

PUB recv_errs{}: errcnt
' Count of received messages with improper stuffed bits or CRC mismatch
'   Returns: Number of receiver errors
'   NOTE: This counter is informative only - will not initiate a bus-recovery
    return _recv_errs

PUB send(tx_id, bytes, d0, d1, d2, d3, d4, d5, d6, d7)
' Send a standard or extended frame with up to 8 data bytes, passed as discrete values
    if (can_rdy{})
        _tx_ident := tx_id
        _tx_dlc := bytes
        _tx_data[0] := d0
        _tx_data[1] := d1
        _tx_data[2] := d2
        _tx_data[3] := d3
        _tx_data[4] := d4
        _tx_data[5] := d5
        _tx_data[6] := d6
        _tx_data[7] := d7
        _flags_var  |= BUSY_FLAG
        return TRUE

PUB send_rtr(tx_id)
' Send a remote-transmission request with an 11 or 29-bit identifier
    send(tx_id | $8000_0000, 0, 0, 0, 0, 0, 0, 0, 0, 0)

PUB send_str(tx_id, ptr_str) | i
' Send a standard or extended frame with up to 8 data bytes, passed as a length-prefaced string
    if (can_rdy{})
        _tx_ident := tx_id
        _tx_dlc := byte[ptr_str]
        i := 0
        repeat byte[ptr_str++]
            _tx_data[i++] := byte[ptr_str++]
        _flags_var |= BUSY_FLAG
        return TRUE

PUB set_filters(msk, f1, f2, f3, f4, f5) | i
' Configure a mask and up to five filters so that only certain messages are stored in the
'   receive buffers
'
'   Mask Bit     Filter Bit  Message bit     Accept or Reject bit
'
'   0            X           X               Accept
'   1            0           0               Accept
'   1            0           1               Reject
'   1            1           0               Reject
'   1            1           1               Accept
    _mask := msk
    repeat i from 0 to 4
        filter[i] := f1[i]

PRI fraction(a, b): f

    a <<= 1
    repeat 32
        f <<= 1
        if (a => b)
            a -= b
            f++
        a <<= 1

#define _PASM_
#include "core.con.counters.spin"

DAT                 org
entry
                    mov     t1, par
                    rdlong  frqa, t1
                    add     t1, #4
                    rdlong  tx_delay, t1
                    add     t1, #4
                    mov     mask_addr, t1
                    add     t1, #4
                    mov     filt_addr, t1
                    add     t1, #4 * 5
                    mov     rx_ident_addr, t1           ' base address of reader idents longs
                    add     t1, #4 * 8
                    mov     tx_ident_addr, t1           ' address of writer ident long
                    add     t1, #4
                    mov     rx_data_addr, t1            ' base address of reader data bytes
                    add     t1, #9 * 8
                    mov     tx_dlc_addr, t1             ' writer DLC
                    add     t1, #1
                    mov     tx_data_addr, t1            ' writer data bytes
                    add     t1, #8
                    mov     flags_addr, t1
                    add     t1, #1
                    mov     rec_addr, t1
                    add     t1, #1
                    mov     ack_addr, t1
                    add     t1, #1
                    mov     arb_addr, t1
                    add     t1, #1
                    rdbyte  t2, t1
                    mov     rx_mask, #1
                    shl     rx_mask, t2
                    add     t1, #1
                    rdbyte  t2, t1
                    mov     tx_mask, #1
                    shl     tx_mask, t2
                    movi    ctra, #LOGIC_ALWAYS         ' set ctra to logic mode
                    mov     builder_addr, #build_msg
                    rdbyte  flags, flags_addr
                    mov     recv_cnt, #0
                    mov     arb_cnt, #0
                    mov     ack_cnt, #0
                    mov     array_idx, #0
                    or      outa, tx_mask
                    or      dira, tx_mask

reset
                    wrbyte  recv_cnt, rec_addr
                    cmp     ack_cnt, #255           wz
    if_e            or      flags, #ERROR_FLAG          ' ERROR_FLAG: removes writer from the bus
                    wrbyte  ack_cnt, ack_addr
                    cmp     arb_cnt, #255           wz
    if_e            or      flags, #ERROR_FLAG
                    wrbyte  arb_cnt, arb_addr
                    test    flags, #ERROR_FLAG      wz
    if_nz           andn    flags, #BUSY_FLAG           ' clear msg so that it's not immediately
'                                                          resent on bus recovery
                    andn    flags, #STUFFED_FLAG        ' cleared in parse_stuffed - here just in case
                    rdbyte  t1, flags_addr              ' spin might set the busy flag while a
'                                                          message is being received
                    test    t1, #BUSY_FLAG          wc  ' fix a bug where the busy flag was being
                                                        '  overwritten
    if_c            or      flags, #BUSY_FLAG           ' cleared, written at get_ack / :ack
                    wrbyte  flags, flags_addr
                    mov     crc, #0                 wz  ' recv'd bits xor'd with CRC_15
                    movs    parse_bit, #parse_SOF       '  set Z for use in wait_for_brk
                    neg     rx_history, #1
                    movs    wait_for_brk, #interfrm_time' wait for RxD to idle high for 10 bits
                    call    #wait_for_brk
                    test    flags, #ERROR_FLAG      wz
    if_z            jmp     #check_for_sof
                    movs    wait_for_brk, #bus_recov_time' initiate bus recovery: RxD must idle for
                    call    #wait_for_brk               '  128x11 bits before re-enabling xmitter
                    mov     recv_cnt, #0
                    mov     arb_cnt, #0
                    mov     ack_cnt, #0
                    wrbyte  recv_cnt, rec_addr
                    wrbyte  arb_cnt, arb_addr
                    wrbyte  ack_cnt, ack_addr
                    andn    flags, #ERROR_FLAG
                    wrbyte  flags, flags_addr

check_for_sof
                    test    rx_mask, ina            wc  ' check RxD for a low (SOF)
    if_nc           jmp     #trans_det
                    rdbyte  flags, flags_addr           ' check for a BUSY_FLAG set by spin
                    test    flags, #BUSY_FLAG       wc
    if_nc           jmp     #check_for_sof
                    jmp     builder_addr                ' builder_addr: addr of build_msg initially

send_bit                                                ' send bit is first entered via build_msg
                    waitcnt cnt, tx_delay
                    test    buff_5, bit_31          wc
                    muxc    outa, tx_mask           wz  ' output bit: Z = dominant, NZ = recessive
                    shl     buff_1, #1              wc
                    rcl     buff_2, #1              wc
                    rcl     buff_3, #1              wc
                    rcl     buff_4, #1              wc
                    rcl     buff_5, #1
                    test    rx_mask, ina            wc  ' C = recessive, NC = dominant
    if_z_eq_c       andn    flags, #TX_FLAG             ' clear the TX_FLAG if a recessive output
'                                                          (Z) is read as a dominant input (NC)
    if_z_eq_c       add     arb_cnt, #1                 '  also tests for a dominant output being
'                                                          read as a recessive input
'                                                          (shouldn't ever happen)
                    jmp     #proc_bit                   ' The arb check also serves as the RxD
read_bit                                                '  sample when transmitting
                    test    rx_history, #1          wz  ' z is clear if previous bit is high (recessive)
    if_nz           jmp     #det_trans_loop             ' only resync on recessive-to-dominant
                    test    bit_31, phsa            wz  '   transitions
    if_nz           jmp     #$-1
                    test    bit_31, phsa            wz  ' wait for 180°
    if_z            jmp     #$-1
                    test    rx_mask, ina            wc  ' sample RxD
                    jmp     #proc_bit

det_trans_loop
{ loop until either a transition is detected or PHSA passes through 180° }
:loop1                                                  ' detect an early transition - before 0°
                    test    rx_mask, ina            wc
    if_nc           jmp     #trans_det
                    test    bit_31, phsa            wz
    if_nz           jmp     #:loop1
:loop2                                                  ' detect a late transition - after 0°
                    test    rx_mask, ina            wc
    if_nc           jmp     #trans_det
                    test    bit_31, phsa            wz
    if_z            jmp     #:loop2
                    jmp     #proc_bit                   ' no transition, C contains RxD at 180°
trans_det
                    mov     phsa, _90_degree            ' re-sync: recessive-to-dominant transition
                    test    bit_31, phsa            wz  '  much better results when set to 90°
    if_z            jmp     #$-1                        '  rather than 0°
proc_bit
                    rcl     rx_history, #1              ' rotate current bit into history
                    test    flags, #STUFFED_FLAG    wz  ' should current bit be stuffed?
    if_nz           jmp     #parse_stuffed_bit
                    rcl     crc, #1                     ' rotate current bit into the CRC
                    test    crc, bit_15             wc
    if_c            xor     crc, crc_15                 ' sub CRC_15 from the CRC if bit 15 is set
                    test    rx_history, #1          wc  ' restore the current bit into C
parse_bit           jmp     #0-0                        ' initially jumps to parse_SOF
                                                        '  parse_bit routines return to next_bit
parse_stuffed_bit
                    andn    flags, #STUFFED_FLAG        ' clear the STUFFED_FLAG
                    test    rx_history, #%11        wc  ' check for a transition
    if_nc           jmp     #recv_err                   '  reset if no transition
next_bit
                    and     rx_history, #%11111     wz  ' limit history to 5 bits, set Z if all 0s
    if_nz           cmp     rx_history, #%11111     wz  '  if not all 0s, check for all 1s
    if_z            or      flags, #STUFFED_FLAG        '  STUFFED_FLAG: five consecutive 0s or 1s
                    test    flags, #TX_FLAG         wc
    if_c            jmp     #send_bit
                    jmp     #read_bit

recv_err
                    cmp     recv_cnt, #255          wz  ' recv_err increments for bit-stuffing
    if_ne           add     recv_cnt, #1                '   violations and incorrect CRC for
                                                        '   monitoring purposes only (won't set the
                                                        '   ERROR_FLAG)
                    jmp     #reset

wait_for_brk        mov     t1, 0-0
                    mov     phsa, #0
:loop1                                                  ' loop while phsa is low
                    test    rx_mask, ina            wc
    if_z_and_nc     jmp     #wait_for_brk               ' reset if RxD goes low during interframe
    if_nz_and_nc    jmp     #trans_det                  ' parse messages recv'd during bus recovery
                    test    bit_31, phsa            wc
    if_nc           jmp     #:loop1
:loop2                                                  ' loop while phsa is high
                    test    rx_mask, ina            wc
    if_z_and_nc     jmp     #wait_for_brk               ' reset if RxD goes low during interframe
    if_nz_and_nc    jmp     #trans_det                  ' parse messages recv'd during bus recovery
                    test    bit_31, phsa            wc
    if_c            jmp     #:loop2
                    djnz    t1, #:loop1
wait_for_brk_ret    ret

DAT
build_msg
                    mov     buff_1, #0                  ' only need to init buff_1; gets rotated
                                                        '   upward to other buffers
                    mov     tx_crc, #0                  ' the writer and reader need separate crc
                                                        '   regs in case a message is received
                    mov     tx_bit_cnt, #0              '   while the builder is constructing one
                    mov     stuffed_cnt, #5             ' tx_bit_cnt: total number of bits to send,
                                                        '   including stuffed bits

add_sof
{ assemble the entire bitstream from SOF to the final bit of CRC into 5 regs: buff_1..buff_5 }
                    mov     t4, #0
                    mov     t5, #1                      '  and inserts stuffed bits as needed
                    call    #add_bit                    ' only begin transmitting after the entire
'                                                          bitstream is in the buffers
add_identa
                    rdlong  t4, tx_ident_addr           ' read the Ident
                    andn    t4, bit_31                  ' clear bit_31 - used as RTR
                    cmp     t4, extd_id             wc  ' standard (11-bit) or ext'd (29-bit) frame
    if_ae           jmp     #extd_frame
                    shl     t4, #32-11                  ' shift the ident to the msbits
                    mov     t5, #11                     ' the add_bit sub reads from the msb of t4
                    call    #add_bit                    '  and loops by the value in t5
                    jmp     #Add_rtr                    ' skip over the extd_frame section
extd_frame
                    shl     t4, #32-29                  ' shift extd_frame (29-bit) ID to the msb
                    mov     t5, #11                     ' ident_a is 11 bits
                    call    #add_bit
add_srr_ide
                    neg     t4, #1                      ' negating #1 fills t4 with $FF_FF_FF_FF
                    mov     t5, #2                      ' insert two 1s for SRR and IDE
                    call    #add_bit                    '   (IDE indicates ext'd frame)
add_identb
                    rdlong  t4, tx_ident_addr           ' re-read the 29-bit ident for ident_b
                    shl     t4, #32-18                  ' ident_b is 18 bits
                    mov     t5, #18
                    call    #add_bit
add_rtr
                    rdlong  t4, tx_ident_addr           ' RTR bit is encoded as bit31 of ident
                    test    t4, bit_31              wc
                    muxc    t4, #1
                    mov     t5, #1
                    call    #add_bit
add_ide_r0
                    mov     t4, #0                      ' insert two 0s for IDE, and R0
                    mov     t5, #2                      ' in the ext'd frame these are R1, and R0
                    call    #add_bit
add_dlc
                    rdbyte  t4, tx_dlc_addr             ' read the data length
                    mov     tx_byte_cnt, t4             ' make a copy for use in the next section
                    shl     t4, #32-4                   ' shift data length to the high bits
                    mov     t5, #4                      ' data length is 4 bits
                    call    #add_bit
add_data
                    tjz     tx_byte_cnt, #finish_crc    ' skip this section if data length is zero
                    mov     byte_addr, tx_data_addr     ' init loop with start addr of the data
:loop
                    rdbyte  t4, byte_addr               ' read a data byte
                    shl     t4, #32-8                   ' shift to the msb
                    mov     t5, #8                      ' each byte is 8 bits
                    call    #add_bit
                    add     byte_addr, #1               ' address the next byte
                    djnz    tx_byte_cnt, #:loop         ' loop until all bytes are added
finish_crc
                    mov     t5, #15                     ' loop 15 more times (finish the CRC calc)
:loop
                    jmpret  builder_addr, #check_for_sof
                    shl     tx_crc, #1                  ' CRC calc works by shifting the bits left
                    test    tx_crc, bit_15          wc  ' check bit 15: set? xor the CRC_15 poly
    if_c            xor     tx_crc, crc_15              '  bitstream  - %1110110110101000
                    djnz    t5, #:loop                  '  polynomial - %1100010110011001
                    mov     t4, tx_crc                  '  result     - %0010100000110001
                    shl     t4, #32 - 15
add_crc
                    mov     t5, #15                     ' add the CRC to the bitstream
                    call    #add_bit
add_crc_delimiter
                    neg     t4, #1
                    mov     t5, #1
                    call    #add_bit
'left_justify_bits
                    mov     t5, #5 * 32                 ' find number of unfilled bits in buffers
                    sub     t5, tx_bit_cnt              '  and shift until SOF is in msb of buff_5
:loop
                    jmpret  builder_addr, #check_for_sof
                    shl     buff_1, #1              wc
                    rcl     buff_2, #1              wc
                    rcl     buff_3, #1              wc
                    rcl     buff_4, #1              wc
                    rcl     buff_5, #1
                    djnz    t5, #:loop
                    mov     builder_addr, #build_msg    ' reset address for next message
                    or      flags, #TX_FLAG             ' begin transmitting
                    mov     cnt, #17
                    add     cnt, cnt
                    mov     phsa, #0                    ' reset phsa for sampling RxD,
                    jmp     #send_bit                   '   in case writer loses arbitration

add_bit
                    jmpret  builder_addr, #check_for_sof
                    add     tx_bit_cnt, #1
                    shl     t4, #1                  wc  ' t4: ID, DLC, Data to transmit (left-just)
                    rcl     tx_crc, #1                  ' each bit gets rotated into the crc
                    rcl     buff_1, #1              wc  '  and the transmit buffers
                    rcl     buff_2, #1              wc
                    rcl     buff_3, #1              wc
                    rcl     buff_4, #1              wc
                    rcl     buff_5, #1
                    test    tx_crc, bit_15          wc
    if_c            xor     tx_crc, crc_15
                    test    buff_1, #%11            wc  ' check for a transition (%01 or %10)
    if_c            mov     stuffed_cnt, #5             ' reset stuffed ctr if transition occurred
                    djnz    stuffed_cnt, #add_next_bit  ' check for a stuffed bit
                    mov     stuffed_cnt, #4
:add_stuffed            
                    jmpret  builder_addr, #check_for_sof
                    add     tx_bit_cnt, #1
                    shl     buff_1, #1              wc
                    rcl     buff_2, #1              wc
                    rcl     buff_3, #1              wc
                    rcl     buff_4, #1              wc
                    rcl     buff_5, #1              wc
                    test    buff_1, #%10            wc  ' test the just-added bit, add opposite bit
    if_nc           add     buff_1, #1
add_next_bit
                    djnz    t5, #add_bit
add_bit_ret         ret

DAT
parse_sof
                    movs    parse_bit, #parse_ident
                    jmp     #next_bit

parse_ident
                    movs    parse_bit, #parse_ident_loop
                    mov     tmp_ident, #0
                    mov     t2, #11                     ' Ident-A is 11 bits long
parse_ident_loop
                    rcl     tmp_ident, #1               ' C contains received bit
                    djnz    t2, #next_bit
                    movs    parse_bit, #parse_rtr
                    jmp     #next_bit

parse_rtr                                               ' SRR in extended frame
                    muxc    flags, #RTR_FLAG            ' C: set for a remote frame
                    movs    parse_bit, #parse_ide       ' ext'd remote frame overwrites this flag
                    jmp     #next_bit

parse_ide
    if_c            movs    parse_bit, #parse_ident_b   ' C: set if extended-frame message
    if_nc           movs    parse_bit, #parse_r0        '    clear if standard-frame
                    jmp     #next_bit

parse_ident_b
                    movs    parse_bit, #parse_ident_b_loop
                    mov     t2, #18                     ' ident-B is 18 bits long
parse_ident_b_loop
                    rcl     tmp_ident, #1               ' C contains received bit
                    djnz    t2, #next_bit
                    movs    parse_bit, #parse_extd_rtr
                    jmp     #next_bit

parse_extd_rtr
                    muxc    flags, #RTR_FLAG            ' C: set for an extended remote frame
                    movs    parse_bit, #parse_r1
                    jmp     #next_bit

parse_r1
                    movs    parse_bit, #parse_r0
                    jmp     #next_bit

parse_r0                                                ' standard and extended frames rejoin here
                    movs    parse_bit, #parse_dlc
                    jmp     #next_bit

parse_dlc
                    movs    parse_bit, #parse_dlc_loop
                    mov     tmp_dlc, #0                 ' store DLC in a temporary register
                    mov     t2, #4                      ' DLC is 4 bits long
parse_dlc_loop
                    rcl     tmp_dlc, #1
                    djnz    t2, #next_bit
                    tjz     tmp_dlc, #bypass_data       ' check if message contains 0 data bytes
                    movs    parse_bit, #parse_data
                    jmp     #next_bit

parse_data
                    movs    parse_bit, #parse_data_loop
                    mov     t2,tmp_dlc                  ' t2: data byte counter
                    mov     rx_bit_cnt, #8              ' each byte is 8 bits long
                    movd    store_data, #tmp_data       ' store in temp buffer (indirect)
parse_data_loop
                    rcl     t1, #1
                    djnz    rx_bit_cnt, #next_bit       ' loop until all 8 bits received
                    mov     rx_bit_cnt, #8              ' reset for another 8 bits
store_data          mov     0-0, t1                     ' store recvd byte in temp buffer location
                    add     store_data, bit_9           ' advance to next temp buffer location
                    djnz    t2, #next_bit               ' loop until all bytes received
bypass_data
                    movs    parse_bit, #parse_crc
                    jmp     #next_bit

parse_crc
                    movs    parse_bit, #parse_crc_loop
                    mov     t2, #15                     ' CRC is 15 bits long
parse_crc_loop
                    djnz    t2, #next_bit               ' loop for all bits
                    tjnz    crc, #recv_err              ' reset if CRC is not 0
                    movs    parse_bit, #parse_crc_delim
                    jmp     #next_bit

parse_crc_delim
                    test    bit_31, phsa            wc
    if_nc           jmp     #$-1
                    test    bit_31, phsa            wc
    if_c            jmp     #$-1

                    test    flags, #TX_FLAG         wc  ' send an ACK if receiving
    if_nc           jmp     #parse_ack
                    test    flags, #LOOPBACK_FLAG   wc
    if_nc           jmp     #get_ack                    ' check for an ACK if transmitting
                    andn    flags, #BUSY_FLAG
                    wrbyte  flags, flags_addr
                    jmp     #check_filts
get_ack
                    andn    flags, #TX_FLAG
                    test    bit_31, phsa            wc
    if_nc           jmp     #$-1
                    test    rx_mask, ina            wc  ' check for an ACK
    if_c            jmp     #:NAK
:ACK
                    andn    flags, #BUSY_FLAG           ' clear to transmit another msg
                    wrbyte  flags, flags_addr
                    cmpsub  arb_cnt, #1                 ' successful transmit? xmit err cnt--
                    cmpsub  ack_cnt, #1
                    jmp     #reset
:NAK
                    add     ack_cnt, #1
                    jmp     #reset
parse_ack
                    andn    outa, tx_mask               ' ACK pulse
                    test    bit_31, phsa            wc
    if_nc           jmp     #$-1
                    test    bit_31, phsa            wc
    if_c            jmp     #$-1
                    or      outa, tx_mask
                    cmpsub  recv_cnt, #1                ' successful reception? recv error cnt--

check_filts
                    mov     t1, tmp_ident
                    rdlong  t2, mask_addr           wz
    if_z            jmp     #wr_buff
                    and     t1, t2
                    mov     t3, filt_addr
                    mov     rx_bit_cnt, #5              ' use rx_bit_cnt to check the five filters
:loop     
                    rdlong  t2, t3
                    cmp     t1, t2                  wz
    if_e            jmp     #wr_buff
                    add     t3, #4
                    djnz    rx_bit_cnt, #:loop
                    jmp     #reset
wr_buff
                    mov     t1, rx_ident_addr           ' base address of the ident array
                    mov     t2, array_idx               ' index is 0 - 7
                    shl     t2, #2                      ' index *= 4 (ident reg is 32 bits)
                    add     t1, t2                      ' base address + offset = current ID reg
                    rdlong  t3, t1                  wz  ' t1: address of the current Ident register
    if_nz           jmp     #reset                      ' Discard new data if buffer is full
                    mov     t3, rx_data_addr
                    mov     t2, array_idx               ' array is 9 bytes (1 DLC + up to 8 data)
                    shl     t2, #3                      ' array offset = index * 8 + index
                    add     t2, array_idx
                    add     t3, t2                      ' t3: base address of the current data array
                    mov     t2, tmp_dlc                 ' t2: # bytes
                    wrbyte  tmp_dlc, t3                 ' write the number of bytes into hub memory
                    tjz     tmp_dlc, #:end              ' end if no data bytes
                    movd    :loop, #tmp_data
                    add     t3, #1                      ' address the next data register
:loop               wrbyte  0-0, t3                     ' write the data bytes into hub memory
                    add     :loop, bit_9
                    add     t3, #1                      ' address the next data register
                    djnz    t2, #:loop
:end
                    test    flags, #RTR_FLAG        wc
                    muxc    tmp_ident, bit_31
                    wrlong  tmp_ident, t1               ' write ident (implies new data is ready)
                    add     array_idx, #1               ' increment the index
                    and     array_idx, #7               ' keep it in range 0 to 7
                    jmp     #reset

DAT
_90_degree          long    $40000000
extd_id             long    %1_00000000000
crc_15              long    %11000101_10011001
bit_31              long    |< 31
bit_15              long    |< 15
bit_9               long    |< 9
interfrm_time       long    10
bus_recov_time      long    128 * 11
tx_delay            res     1
builder_addr        res     1
rx_ident_addr       res     1                           ' base add of 8 longs: incoming idents
tx_ident_addr       res     1                           ' address of Ident to send
rx_data_addr        res     1                           ' base addr of 8x9 bytes: incoming data
tx_dlc_addr         res     1                           ' address of DLC to send
tx_data_addr        res     1                           ' base addr of 8 data bytes to send
array_idx           res     1                           ' reader: keep track of current array
mask_addr           res     1                           ' addr of filter mask used by the reader
filt_addr           res     1                           ' base addr of the filters
rx_mask             res     1                           ' connected to RxD
tx_mask             res     1                           ' connected to TxD
rx_history          res     1                           ' last five bits, for stuffed bit checking
rx_bit_cnt          res     1                           ' parse_data: bits recv'd in current byte
buff_1              res     1                           ' msg to be transmitted (160 bits max)
buff_2              res     1                           '   .
buff_3              res     1                           '   .
buff_4              res     1                           '   .
buff_5              res     1                           '   .
tx_byte_cnt         res     1                           ' # data bytes to write to the message
tx_bit_cnt          res     1                           ' # bits loaded into buff_1 through buff_5
stuffed_cnt         res     1                           ' # consecutive 0s or 1s in buff_1
tx_crc              res     1                           ' crc calculation from built message
byte_addr           res     1
tmp_ident           res     1
tmp_dlc             res     1
tmp_data            res     8
crc                 res     1
t1                  res     1
t2                  res     1
t3                  res     1
t4                  res     1
t5                  res     1
flags               res     1
ack_cnt             res     1
arb_cnt             res     1
recv_cnt            res     1
flags_addr          res     1
rec_addr            res     1
ack_addr            res     1
arb_addr            res     1

                    fit

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

