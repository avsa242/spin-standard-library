{
    --------------------------------------------
    Filename: com.can.txrx.spin
    Description: CANbus engine (bi-directional, 500kbps)
    Author: Chris Gadd
    Created: 2015
    Updated: May 11, 2020
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is a derivative of CANbus controller 500Kbps.spin, originally by Chris Gadd.
        The original header is preserved below.

  ┌────────────────────────────────────┐ v1.0 Successfully combined writer and reader into one routine, able to parse messages while transmitting
  │ CANbus driver 500Kbps              │ v1.1 Added diagnostic methods and error recovery
  │ Author: Chris Gadd                 │ v1.2 Rewrote writer to drive outa high and low rather than rely on pullups
  │ Copyright (c) 2015 Chris Gadd      │ v1.3 Rewrote writer to use waitcnts for timing
  │ See end of file for terms of use.  │
  └────────────────────────────────────┘
}
#define _PASM_
CON

    BUSY_FLAG      = |< 0         ' Set by Spin, cleared at get_acknowledge / :Ack
    ERROR_FLAG     = |< 1         ' Set at reset if either tx error counter reaches 255, cleared after RxD idles for 128 x 11 bits
    TX_FLAG        = |< 2         ' Set at the end of Build_message, cleared at get_acknowledge
    RTR_FLAG       = |< 3         ' Set by parse_RTR, used to set bit31 of ident to indicate a remote-transmission request was received
    STUFFED_FLAG   = |< 4         ' Set by Next_bit if the next received bit should be stuffed, cleared when stuffed bit is receieved
    LOOPBACK_FLAG  = |< 5         ' Set by Spin, causes outgoing messages to be acknowledged and stored in receive buffers

OBJ

    ctr     : "core.con.counters"
  
VAR

    long    _clock_freq
    long    _pulse_width
    long    _mask, filter[5]
    long    _rx_ident[8]
    long    _tx_ident
    byte    _rx_data[9 * 8]
    byte    _tx_dlc
    byte    _tx_data[8]
    byte    _flags_var, _receive_errors, _acknowledge_errors, _arbitration_errors
    byte    _pins[2]
    byte    _index_array
    byte    _index_element
    byte    _cog

PUB Start(CAN_RX, CAN_TX, CAN_BPS): okay

    _pins[0] := can_rx
    _pins[1] := can_tx
    _clock_freq := fraction(CAN_BPS, clkfreq)
    _pulse_width := clkfreq / CAN_BPS                     ' Used by writer

    Stop
    if okay := _cog := cognew(@entry, @_clock_freq) + 1
        return @_rx_ident

PUB Stop

    if _cog
        cogstop(_cog~ - 1)

PUB AckError
' Count of transmitted messages that weren't ackowledged by other nodes
'   Returns: Number of acknowledge errors
'   NOTE: If counter reaches 255, the bus goes into recovery mode until RxD is idle for 128 x 11 bits.
'       During bus recovery, messages cannot be transmitted but can still be received.
'       The error counters are reset after bus recovery
    return _acknowledge_errors

PUB ArbError
' Count of messages that were interrupted by a received message with a higher priority
'   Returns: Number of arbitration errors
'   NOTE: Arbitration errors do not necessarily indicate a problem, merely that this object and another node attempted to transmit at the same time
'   NOTE: If counter reaches 255, the bus goes into recovery mode until RxD is idle for 128 x 11 bits.
'       During bus recovery, messages cannot be transmitted but can still be received.
'       The error counters are reset after bus recovery
    return _arbitration_errors

PUB CheckError

    if _flags_var & ERROR_FLAG
        return TRUE

PUB CheckReady

    if not _flags_var & BUSY_FLAG and not CheckError
        return TRUE

PUB CheckRTR
' Flag indicating the current receive buffer contains a remote-transmission request
'   Returns: TRUE (-1) or FALSE (0)
    if _rx_ident[_index_array] & $8000_0000
        return TRUE

PUB DataAddress
' Address of the current receive data buffer
'   NOTE: The address can be used as a length-prefaced string
    return @_rx_data[_index_array * 9]

PUB DataLength
' Number of data bytes stored in the current receive buffer
'   Returns: Number of bytes
    _index_element := 0
    return _rx_data[_index_array * 9]

PUB ID
' Ident stored in the current receive buffer, returns false if no ident is stored
'   Returns: 11 or 29-bit ident, or FALSE if no ident is stored or if ident is $000
    _index_element := 0
    return _rx_ident[_index_array] & !$8000_0000

PUB Loopback(state)
' Set loopback mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
    _flags_var := _flags_var &! LOOPBACK_FLAG | (LOOPBACK_FLAG & (||state == 1))

PUB NextID
' Clears the ident in the current receive buffer, advances index to the next receive buffer
'   Returns: The ident in the next receive buffer, or FALSE if no ident is stored
    _rx_ident[_index_array] := 0
    _index_array := (_index_array + 1) & 7
    _index_element := 0
    return _rx_ident[_index_array] & !$8000_0000

PUB ReadData
' Read byte from the current receive buffer; successive calls return the following bytes
'   NOTE: The ID, NextID, or DataLength method must be called before the initial call to ReadData - to set index_element to 0
' This method only returns values from the current read - will not return out-of-date data from previous reads
    if ++_index_element =< _rx_data[_index_array * 9]
        return _rx_data[_index_array * 9 + _index_element]

PUB RecError
' Count of received messages with improper stuffed bits or CRC mismatch
'   Returns: Number of receiver errors
'   NOTE: This counter is informative only - will not initiate a bus-recovery
    return _receive_errors

PUB Send(tx_id, bytes, d0, d1, d2, d3, d4, d5, d6, d7)
' Sends a standard or extended frame with up to 8 data bytes, passed as discrete values
    if CheckReady
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

PUB SendRTR(tx_id)
' Sends a remote-transmission request with an 11 or 29-bit identifier
    Send(tx_id | $8000_0000, 0, 0, 0, 0, 0, 0, 0, 0, 0)

PUB SendStr(tx_id, strPtr) | i
' Sends a standard or extended frame with up to 8 data bytes, passed as a length-prefaced string
    if CheckReady
        _tx_ident := tx_id
        _tx_dlc := byte[StrPtr]
        i := 0
        repeat byte[strPtr++]
            _tx_data[i++] := byte[strPtr++]
        _flags_var |= BUSY_FLAG
        return TRUE

PUB SetFilters(msk, f1, f2, f3, f4, f5) | i
' Configure a mask and up to five filters so that only certain messages are stored in the receive buffers
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

PRI Fraction(a, b) : f

    a <<= 1
    repeat 32
        f <<= 1
        if a => b
            a -= b
            f++
        a <<= 1

DAT                     org
entry
                        mov       t1,par
                        rdlong    frqa,t1
                        add       t1,#4
                        rdlong    tx_delay,t1
                        add       t1,#4                        
                        mov       mask_address,t1
                        add       t1,#4
                        mov       filter_address,t1
                        add       t1,#4 * 5
                        mov       rx_ident_address,t1                           ' Base address of reader idents longs
                        add       t1,#4 * 8
                        mov       tx_ident_address,t1                           ' Address of writer ident long
                        add       t1,#4
                        mov       rx_data_address,t1                            ' Base address of reader data bytes
                        add       t1,#9 * 8
                        mov       tx_dlc_address,t1                             ' Writer DLC
                        add       t1,#1
                        mov       tx_data_address,t1                            ' Writer data bytes
                        add       t1,#8
                        mov       flags_address,t1
                        add       t1,#1
                        mov       rec_address,t1
                        add       t1,#1
                        mov       ack_address,t1
                        add       t1,#1
                        mov       arb_address,t1
                        add       t1,#1                        
                        rdbyte    t2,t1
                        mov       rx_mask,#1
                        shl       rx_mask,t2
                        add       t1,#1
                        rdbyte    t2,t1
                        mov       tx_mask,#1
                        shl       tx_mask,t2
                        movi      ctra, ctr#LOGIC_ALWAYS                        ' Set ctra to logic mode
                        mov       builder_address,#Build_message
                        rdbyte    flags,flags_address
                        mov       rec_counter,#0
                        mov       arb_counter,#0
                        mov       ack_counter,#0
                        mov       array_index,#0
                        or        outa,tx_mask
                        or        dira,tx_mask
'...............................................................................................................................
Reset
                        wrbyte    rec_counter,rec_address
                        cmp       ack_counter,#255            wz                
          if_e          or        flags,#ERROR_FLAG                             ' Setting the ERROR_FLAG removes the writer from the CANbus
                        wrbyte    ack_counter,ack_address
                        cmp       arb_counter,#255            wz
          if_e          or        flags,#ERROR_FLAG
                        wrbyte    arb_counter,arb_address
                        test      flags,#ERROR_FLAG           wz
          if_nz         andn      flags,#BUSY_FLAG                              ' Clear message so that it's not immediately resent on bus recovery
                        andn      flags,#STUFFED_FLAG                           ' cleared in Parse_stuffed - here just in case
                        rdbyte    t1,flags_address                              ' It is possible that Spin might set the busy flag while a message is being received
                        test      t1,#BUSY_FLAG               wc                '  This test is to fix a bug where the busy flag was being overwritten
          if_c          or        flags,#BUSY_FLAG                              '  BUSY_FLAG is cleared and written at get_acknowledge / :ack
                        wrbyte    flags,flags_address
                        mov       crc,#0                      wz                ' Contains the received bits xor'd with CRC_15
                        movs      Parse_bit,#Parse_SOF                          '  Set Z for use in Wait_for_break
                        neg       rx_history,#1
                        movs      Wait_for_break,#interframe_time               ' Wait for RxD to idle high for 10 bits
                        call      #Wait_for_break
                        test      flags,#ERROR_FLAG           wz
          if_z          jmp       #Check_for_SOF
                        movs      Wait_for_break,#bus_recovery_time             ' Initiate bus recovery - RxD must idle for 128 x 11 bits before
                        call      #Wait_for_break                               '  re-enabling transmitter
                        mov       rec_counter,#0
                        mov       arb_counter,#0
                        mov       ack_counter,#0
                        wrbyte    rec_counter,rec_address
                        wrbyte    arb_counter,arb_address
                        wrbyte    ack_counter,ack_address
                        andn      flags,#ERROR_FLAG
                        wrbyte    flags,flags_address
'.............................................................................................................................................
Check_for_SOF
                        test      rx_mask,ina                 wc                ' Check RxD for a low (SOF)
          if_nc         jmp       #Transition_detected
                        rdbyte    flags,flags_address                           ' Check for a BUSY_FLAG set by Spin
                        test      flags,#BUSY_FLAG            wc
          if_nc         jmp       #Check_for_SOF
                        jmp       builder_address                               ' Builder_address contains the address of Build_message initially
'.............................................................................................................................................
Send_bit                                                                        ' Send bit is first entered via Build_message
                        waitcnt   cnt,tx_delay
                        test      buffer_5,bit_31             wc
                        muxc      outa,tx_mask                wz                ' Output the bit, Z = dominant, NZ = recessive
                        shl       buffer_1,#1                 wc                   
                        rcl       buffer_2,#1                 wc
                        rcl       buffer_3,#1                 wc
                        rcl       buffer_4,#1                 wc
                        rcl       buffer_5,#1                 
                        test      rx_mask,ina                 wc                ' C = recessive, NC = dominant
          if_z_eq_c     andn      flags,#TX_FLAG                                ' Clear the TX_FLAG if a recessive output (Z) is read as a dominant input (NC)
          if_z_eq_c     add       arb_counter,#1                                '  also tests for a dominant output being read as a recessive input - shouldn't ever happen
                        jmp       #Process_bit                                  ' The arbitration check also serves as the RxD sample when transmitting
Read_bit
                        test      rx_history,#1               wz                ' z is clear if previous bit is high (recessive)
          if_nz         jmp       #Detect_transition_loop                       ' Only resync on recessive-to-dominant transitions
                        test      bit_31,phsa                 wz                
          if_nz         jmp       #$-1          
                        test      bit_31,phsa                 wz                ' Wait for 180° 
          if_z          jmp       #$-1
                        test      rx_mask,ina                 wc                ' Sample RxD
                        jmp       #Process_bit
Detect_transition_loop                                                          ' Loop until either a transition is detected or PHSA passes through 180°
:loop1                                                                          '  :loop1 will detect an early transition - before 0°
                        test      rx_mask,ina                 wc
          if_nc         jmp       #Transition_detected
                        test      bit_31,phsa                 wz
          if_nz         jmp       #:loop1
:loop2                                                                          '  :loop2 will detect a late transition - after 0°
                        test      rx_mask,ina                 wc
          if_nc         jmp       #Transition_detected
                        test      bit_31,phsa                 wz
          if_z          jmp       #:loop2
                        jmp       #Process_bit                                  ' No transition, C contains RxD at 180°
Transition_detected
                        mov       phsa,_90_degree                               ' Re-synchronize on recessive-to-dominant transitions
                        test      bit_31,phsa                 wz                '  Much better results when set to 90° rather than 0°
          if_z          jmp       #$-1                                         
Process_bit
                        rcl       rx_history,#1                                 ' Rotate current bit into history
                        test      flags,#STUFFED_FLAG         wz                ' Determine if current bit should be stuffed
          if_nz         jmp       #Parse_stuffed_bit
                        rcl       crc,#1                                        ' Rotate current bit into the CRC
                        test      crc,bit_15                  wc                  
          if_c          xor       crc,crc_15                                    ' Subtract CRC_15 from the CRC if bit 15 is set
                        test      rx_history,#1               wc                ' Restore the current bit into C
Parse_bit               jmp       #0-0                                          ' Initially jumps to Parse_SOF
                                                                                '  Parse_bit routines return to Next_bit
Parse_stuffed_bit
                        andn      flags,#STUFFED_FLAG                           ' Clear the STUFFED_FLAG
                        test      rx_history,#%11             wc                ' Check for a transition
          if_nc         jmp       #Receive_error                                '  Reset if no transition
Next_bit
                        and       rx_history,#%11111          wz                ' Limit history to five bits, set Z if all 0's
          if_nz         cmp       rx_history,#%11111          wz                '  if not all 0's, check for all 1's
          if_z          or        flags,#STUFFED_FLAG                           '  set STUFFED_FLAG if five consecutive 0's or 1's in history
                        test      flags,#TX_FLAG              wc
          if_c          jmp       #Send_bit
                        jmp       #Read_bit
'...............................................................................................................................
Receive_error
                        cmp       rec_counter,#255            wz                ' Receive_error increments for bit-stuffing violations and incorrect CRC
          if_ne         add       rec_counter,#1                                '  for monitoring purposes only - won't set the ERROR_FLAG
                        jmp       #Reset
'===============================================================================================================================
Wait_for_break          mov       t1,0-0                                   
                        mov       phsa,#0
:loop1                                                                          ' Loop while phsa is low
                        test      rx_mask,ina                 wc                
          if_z_and_nc   jmp       #Wait_for_break                               ' Reset if RxD goes low during interframe
          if_nz_and_nc  jmp       #Transition_detected                          ' Parse messages that are received during bus recovery
                        test      bit_31,phsa                 wc
          if_nc         jmp       #:loop1
:loop2                                                                          ' Loop while phsa is high
                        test      rx_mask,ina                 wc
          if_z_and_nc   jmp       #Wait_for_break                               ' Reset if RxD goes low during interframe
          if_nz_and_nc  jmp       #Transition_detected                          ' Parse messages that are received during bus recovery
                        test      bit_31,phsa                 wc
          if_c          jmp       #:loop2                        
                        djnz      t1,#:loop1
Wait_for_break_ret      ret
                        
DAT'===============================================================================================================================
Build_message
                        mov       buffer_1,#0                                   ' Only need to initialize buffer_1; buffer_1 gets rotated upward to other buffers
                        mov       tx_crc,#0                                     ' The writer and reader need separate crc registers in case message is received
                        mov       tx_bit_counter,#0                             '  while the builder is constructing a message to send
                        mov       stuffed_counter,#5                            ' Tx_bit_counter counts the total number of bits to send, including stuffed bits
'...............................................................................................................................
Add_SOF                                                                         ' This routine assembles the entire bitstream from SOF to the
                        mov       t4,#0                                         '  final bit of CRC into 5 registers (buffer_1 through buffer_5),
                        mov       t5,#1                                         '  and inserts stuffed bits as needed
                        call      #Add_bit                                      ' Only begins transmitting after the entire bitstream is in the buffers
Add_IdentA                                                       
                        rdlong    t4,tx_ident_address                           ' Read the Ident
                        andn      t4,bit_31                                     ' clear bit_31 - used as RTR
                        cmp       t4,extended_ID              wc                ' Determine if standard (11-bit) or extended (29-bit) frame
          if_ae         jmp       #Extended_frame
                        shl       t4,#32-11                                     ' Shift the ident to the most-significant bits                                           
                        mov       t5,#11                                        ' The add_bit subroutine reads from the msb of t4 
                        call      #Add_bit                                      '  and loops by the value in t5                   
                        jmp       #Add_RTR                                      ' Skip over the extended_frame section
Extended_frame
                        shl       t4,#32-29                                     ' Shift the extended_frame (29-bit) ID to the msb
                        mov       t5,#11                                        ' Ident_A is 11 bits
                        call      #Add_bit
Add_SRR_IDE
                        neg       t4,#1                                         ' negating #1 fills t4 with $FF_FF_FF_FF
                        mov       t5,#2                                         ' insert two 1's for SRR and IDE (IDE indicates extended frame)
                        call      #Add_bit                          
Add_IdentB
                        rdlong    t4,tx_ident_address                           ' Re-read the 29-bit Ident for Ident_B
                        shl       t4,#32-18                                     ' Ident_B is 18 bits
                        mov       t5,#18
                        call      #Add_bit
Add_RTR
                        rdlong    t4,tx_ident_address                           ' The RTR bit is encoded as bit31 of Ident
                        test      t4,bit_31                   wc
                        muxc      t4,#1
                        mov       t5,#1
                        call      #Add_bit          
Add_IDE_R0                                                               
                        mov       t4,#0                                         ' Insert two 0's for IDE, and R0
                        mov       t5,#2                                         ' In the extended frame these are R1, and R0
                        call      #Add_bit
Add_DLC
                        rdbyte    t4,tx_dlc_address                             ' Read the data length
                        mov       tx_byte_counter,t4                            ' Make a copy for use in the next section
                        shl       t4,#32-4                                      ' Shift data length to the high bits
                        mov       t5,#4                                         ' Data length is 4 bits 
                        call      #Add_bit
Add_Data
                        tjz       tx_byte_counter,#Finish_CRC                   ' Skip this section if data length is zero 
                        mov       byte_address,tx_data_address                  ' Initialize the loop with the starting address of the data
:loop
                        rdbyte    t4,byte_address                               ' Read a data byte
                        shl       t4,#32-8                                      ' Shift to the msb
                        mov       t5,#8                                         ' Each byte is 8 bits
                        call      #Add_bit
                        add       byte_address,#1                               ' Address the next byte
                        djnz      tx_byte_counter,#:loop                        ' Loop until all bytes are added
Finish_CRC
                        mov       t5,#15                                        ' Loop an additional 15 times to finish up the CRC calculation
:loop
                        jmpret    builder_address,#Check_for_SOF
                        shl       tx_crc,#1                                     ' The CRC calculation works by shifting the bitstream left
                        test      tx_crc,bit_15               wc                ' Checking bit 15 and if set, xor'ing the CRC_15 polynomial
          if_c          xor       tx_crc,crc_15                                 '  bitstream  - %1110110110101000
                        djnz      t5,#:loop                                     '  polynomial - %1100010110011001
                        mov       t4,tx_crc                                     '  result     - %0010100000110001
                        shl       t4,#32 - 15                                   
Add_CRC
                        mov       t5,#15                                        ' Add the CRC to the bitstream
                        call      #Add_bit
Add_CRC_delimiter
                        neg       t4,#1
                        mov       t5,#1
                        call      #Add_bit
'left_justify_bits
                        mov       t5,#5 * 32                                    ' Find number of unfilled bits in buffers
                        sub       t5,tx_bit_counter                             '  and shift bits until SOF is in high-bit of buffer_5
:loop
                        jmpret    builder_address,#Check_for_SOF
                        shl       buffer_1,#1                 wc            
                        rcl       buffer_2,#1                 wc
                        rcl       buffer_3,#1                 wc
                        rcl       buffer_4,#1                 wc
                        rcl       buffer_5,#1
                        djnz      t5,#:loop
                        mov       builder_address,#Build_message                ' Reset address for next message
                        or        flags,#TX_FLAG                                ' Begin transmitting
                        mov       cnt,#17
                        add       cnt,cnt
                        mov       phsa,#0                                       ' Reset phsa for sampling RxD, in case writer loses arbitration
                        jmp       #Send_bit
'........................................................................................................................................
Add_bit
                        jmpret    builder_address,#Check_for_SOF               
                        add       tx_bit_counter,#1
                        shl       t4,#1                       wc                ' t4 contains data (ID, DLC, Data) to be transmitted - left justified
                        rcl       tx_crc,#1                                     ' Each bit gets rotated into the crc
                        rcl       buffer_1,#1                 wc                '  and the transmit buffers
                        rcl       buffer_2,#1                 wc                
                        rcl       buffer_3,#1                 wc
                        rcl       buffer_4,#1                 wc
                        rcl       buffer_5,#1                 
                        test      tx_crc,bit_15               wc                
          if_c          xor       tx_crc,crc_15
                        test      buffer_1,#%11               wc                ' Check for a transition (%01 or %10)
          if_c          mov       stuffed_counter,#5                            '  reset stuffed counter if transition occurred
                        djnz      stuffed_counter,#Add_next_bit                 ' Check for a stuffed bit
                        mov       stuffed_counter,#4
:add_stuffed            
                        jmpret    builder_address,#Check_for_SOF
                        add       tx_bit_counter,#1          
                        shl       buffer_1,#1                 wc                   
                        rcl       buffer_2,#1                 wc
                        rcl       buffer_3,#1                 wc
                        rcl       buffer_4,#1                 wc
                        rcl       buffer_5,#1                 wc
                        test      buffer_1,#%10               wc                ' Test the just-added bit and add the opposite bit
          if_nc         add       buffer_1,#1
Add_next_bit
                        djnz      t5,#Add_bit
Add_bit_ret             ret
                        
DAT'===============================================================================================================================
Parse_SOF
                        movs      Parse_bit,#Parse_Ident                        
                        jmp       #Next_bit
'...............................................................................................................................
Parse_Ident
                        movs      Parse_bit,#Parse_Ident_loop
                        mov       temp_ident,#0
                        mov       t2,#11                                        ' Ident-A is 11 bits long
Parse_Ident_loop
                        rcl       temp_ident,#1                                 ' C contains received bit
                        djnz      t2,#Next_bit
                        movs      Parse_bit,#Parse_RTR
                        jmp       #Next_bit         
'...............................................................................................................................
Parse_RTR                                                                       ' SRR in extended frame
                        muxc      flags,#RTR_FLAG                               ' C is set for a remote frame
                        movs      Parse_bit,#Parse_IDE                          ' Extended remote frame overwrites this flag
                        jmp       #Next_bit
'...............................................................................................................................
Parse_IDE
          if_c          movs      Parse_bit,#Parse_Ident_B                      ' C is set if extended-frame message
          if_nc         movs      Parse_bit,#Parse_R0                           '  clear if standard-frame
                        jmp       #Next_bit
'...............................................................................................................................
Parse_Ident_B
                        movs      Parse_bit,#Parse_Ident_B_loop
                        mov       t2,#18                                        ' Ident-B is 18 bits long
Parse_Ident_B_loop
                        rcl       temp_ident,#1                                 ' C contains received bit
                        djnz      t2,#Next_bit
                        movs      Parse_bit,#Parse_Extended_RTR
                        jmp       #Next_bit
'...............................................................................................................................
Parse_Extended_RTR
                        muxc      flags,#RTR_FLAG                               ' C is set for an extended remote frame
                        movs      Parse_bit,#Parse_R1
                        jmp       #Next_bit
'...............................................................................................................................
Parse_R1
                        movs      Parse_bit,#Parse_R0
                        jmp       #Next_bit
'...............................................................................................................................
Parse_R0                                                                        ' Standard and extended frames rejoin here
                        movs      Parse_bit,#Parse_DLC
                        jmp       #Next_bit
'...............................................................................................................................
Parse_DLC
                        movs      Parse_bit,#Parse_DLC_loop
                        mov       temp_DLC,#0                                   ' Store DLC in a temporary register
                        mov       t2,#4                                         ' DLC is 4 bits long
Parse_DLC_loop
                        rcl       temp_DLC,#1
                        djnz      t2,#Next_bit
                        tjz       temp_DLC,#Bypass_Data                         ' Just in case a message contains 0 data bytes
                        movs      Parse_bit,#Parse_Data
                        jmp       #Next_bit         
'...............................................................................................................................
Parse_Data
                        movs      Parse_bit,#Parse_Data_loop
                        mov       t2,temp_DLC                                   ' Use t2 as a data byte counter
                        mov       rx_bit_counter,#8                             ' Each byte is 8 bits long
                        movd      Store_Data,#Temp_Data                         ' Use indirect addressing to store in Temp_buffer
Parse_Data_loop
                        rcl       t1,#1
                        djnz      rx_bit_counter,#Next_bit                      ' Loop until all 8 bits received
                        mov       rx_bit_counter,#8                             ' Reset for another 8 bits
Store_Data              mov       0-0,t1                                        ' Store received byte in Temp buffer location
                        add       Store_Data,bit_9                              ' Advance to next Temp buffer location
                        djnz      t2,#Next_bit                                  ' Loop until all bytes received
Bypass_Data
                        movs      Parse_bit,#Parse_CRC
                        jmp       #Next_bit
'...............................................................................................................................
Parse_CRC
                        movs      Parse_bit,#Parse_CRC_loop
                        mov       t2,#15                                        ' CRC is 15 bits long
Parse_CRC_loop
                        djnz      t2,#Next_bit                                  ' Loop until all CRC bits have been xor'd with CRC_15
                        tjnz      crc,#Receive_error                            ' Reset if CRC is not 0
                        movs      Parse_bit,#Parse_CRC_delimiter
                        jmp       #Next_bit
'...............................................................................................................................
Parse_CRC_delimiter
                        test      bit_31,phsa                 wc
          if_nc         jmp       #$-1
                        test      bit_31,phsa                 wc               
          if_c          jmp       #$-1
'...............................................................................................................................
                        test      flags,#TX_FLAG              wc                ' Send an acknowledge if receiving  
          if_nc         jmp       #Parse_Acknowledge
                        test      flags,#LOOPBACK_FLAG        wc                
          if_nc         jmp       #Get_Acknowledge                              ' Check for an acknowledge if transmitting
                        andn      flags,#BUSY_FLAG                              
                        wrbyte    flags,flags_address
                        jmp       #Check_filters
Get_Acknowledge
                        andn      flags,#TX_FLAG                                
                        test      bit_31,phsa                 wc               
          if_nc         jmp       #$-1
                        test      rx_mask,ina                 wc                ' Check for an acknowledgement
          if_c          jmp       #:NAK
:ACK
                        andn      flags,#BUSY_FLAG                              ' Clear the BUSY_FLAG to allow the Spin handler to transmit another message
                        wrbyte    flags,flags_address
                        cmpsub    arb_counter,#1                                ' Decrement transmit error counters on successful transmission
                        cmpsub    ack_counter,#1
                        jmp       #Reset
:NAK
                        add       ack_counter,#1                               
                        jmp       #Reset
Parse_Acknowledge
                        andn      outa,tx_mask                                  ' Output an acknowledge pulse
                        test      bit_31,phsa                 wc                
          if_nc         jmp       #$-1
                        test      bit_31,phsa                 wc                
          if_c          jmp       #$-1
                        or        outa,tx_mask
                        cmpsub    rec_counter,#1                                ' Decrement receive error counter on successful reception
'...............................................................................................................................
Check_filters
                        mov       t1,temp_ident
                        rdlong    t2,mask_address             wz                
          if_z          jmp       #Write_buffer
                        and       t1,t2                      
                        mov       t3,filter_address
                        mov       rx_bit_counter,#5                             ' Using rx_bit_counter to check the five filters
:loop     
                        rdlong    t2,t3
                        cmp       t1,t2                       wz
          if_e          jmp       #Write_buffer
                        add       t3,#4
                        djnz      rx_bit_counter,#:loop
                        jmp       #Reset
Write_buffer            
                        mov       t1,rx_ident_address                           ' Base address of the Ident array
                        mov       t2,array_index                                ' Index is 0 - 7
                        shl       t2,#2                                         ' Multiply copy of index by 4 (each Ident register is 32 bits long)
                        add       t1,t2                                         ' Add the base address to the offset to locate the current ID register
                        rdlong    t3,t1                       wz                ' t1 contains the address of the current Ident register, t3 is throwaway here
          if_nz         jmp       #Reset                                        ' Discard new data if buffer is full
                        mov       t3,rx_data_address
                        mov       t2,array_index                                ' Each data array is 9 bytes (1 DLC + up to 8 data)
                        shl       t2,#3                                         ' Array offset = index * 8 + index  
                        add       t2,array_index
                        add       t3,t2                                         ' t3 contains the base address of the current data array
                        mov       t2,temp_DLC                                   ' Store the number of bytes into t2
                        wrbyte    temp_DLC,t3                                   ' Write the number of bytes into hub memory
                        tjz       temp_DLC,#:end                                ' End if no data bytes
                        movd      :loop,#Temp_Data                              
                        add       t3,#1                                         ' Address the next data register
:loop                   wrbyte    0-0,t3                                        ' Write the data bytes into hub memory
                        add       :loop,bit_9
                        add       t3,#1                                         ' Address the next data register
                        djnz      t2,#:loop
:end
                        test      flags,#RTR_FLAG             wc
                        muxc      temp_ident,bit_31
                        wrlong    temp_ident,t1                                 ' Writing the Ident signals the parent object that new data is ready
                                                                                '  therefore, this should be written last
                        add       array_index,#1                                ' Increment the index
                        and       array_index,#7                                ' Keep it in range 0 to 7
                        jmp       #Reset

DAT'===============================================================================================================================
_90_degree              long      $40000000
extended_ID             long      %1_00000000000
crc_15                  long      %11000101_10011001
bit_31                  long      |< 31
bit_15                  long      |< 15
bit_9                   long      |< 9
interframe_time         long      10
bus_recovery_time       long      128 * 11
tx_delay                res       1
builder_address         res       1
rx_ident_address        res       1                                             ' base address of 8 longs used for storing incoming Idents
tx_ident_address        res       1                                             ' address of Ident to send
rx_data_address         res       1                                             ' base address of 8 arrays of 9 bytes for storing incoming data bytes
tx_dlc_address          res       1                                             ' address of DLC to send
tx_data_address         res       1                                             ' base address of 8 data bytes to send
array_index             res       1                                             ' Used by reader to keep track of current array
mask_address            res       1                                             ' Address of a filter mask used by the reader
filter_address          res       1                                             ' base address of the filters
rx_mask                 res       1                                             ' Connected to RxD
tx_mask                 res       1                                             ' Connected to TxD
rx_history              res       1                                             ' Preserves that last five bits, used mainly for stuffed bit checking
rx_bit_counter          res       1                                             ' Used in Parse_data to count number of bits received in current byte
buffer_1                res       1                                             ' Message to be transmitted is first assembled into these five longs
buffer_2                res       1                                             '  Provides a maximum message length of 160 bits
buffer_3                res       1                                             '
buffer_4                res       1                                             '
buffer_5                res       1                                             '
tx_byte_counter         res       1                                             ' Counts the number of data bytes to write to the message
tx_bit_counter          res       1                                             ' Counts the number of bits loaded into buffer_1 through buffer_5
stuffed_counter         res       1                                             ' Counts the number of consecutive 0's or 1's loaded into buffer_1
tx_crc                  res       1                                             ' Stores the crc calculation when building a message
byte_address            res       1
temp_ident              res       1
temp_dlc                res       1
temp_data               res       8
crc                     res       1
t1                      res       1
t2                      res       1
t3                      res       1
t4                      res       1
t5                      res       1
flags                   res       1
ack_counter             res       1
arb_counter             res       1
rec_counter             res       1
flags_address           res       1
rec_address             res       1
ack_address             res       1
arb_address             res       1

                        fit

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

