{{
  SPI interface routines for SD & SDHC & MMC cards

  Jonathan "lonesock" Dummer
  version 0.3.0  2009 July 19

  Using multiblock SPI mode exclusively.

  This is the "SAFE" version...uses
  * 1 instruction per bit writes
  * 2 instructions per bit reads

  For the fsrw project:
  fsrw.sf.net
}}

' Preprocessor switchable options (comment/uncomment as needed)
'#define DEBUG                                                  ' For debug logging
'#define MULTI_DRIVER                                           ' To use multiple copies of driver (uses VAR instead of DAT variables)
'#define TRISTATE_ALL_WHEN_DO_RELEASED                          ' If you're using pull-up resistors, and need all lines tristated (for Cluso99)

CON
' Possible card types
    type_MMC                        = 1
    type_SD                         = 2
    type_SDHC                       = 3

' Error codes
    ERR_CARD_NOT_RESET              = -1
    ERR_3v3_NOT_SUPPORTED           = -2
    ERR_OCR_FAILED                  = -3
    ERR_BLOCK_NOT_LONG_ALIGNED      = -4
'...
' These errors are for the assembly engine...they are negated inside, and need to be <= 511
    ERR_ASM_NO_READ_TOKEN           = 100
    ERR_ASM_BLOCK_NOT_WRITTEN       = 101
' NOTE: errors -128 to -255 are reserved for reporting R1 response errors
'...
    ERR_SPI_ENGINE_NOT_RUNNING      = -999
    ERR_CARD_BUSY_TIMEOUT           = -1000

' SDHC/SD/MMC command set for SPI
    CMD0                            = $40+0                     ' GO_IDLE_STATE
    CMD1                            = $40+1                     ' SEND_OP_COND (MMC)
    ACMD41                          = $C0+41                    ' SEND_OP_COND (SDC)
    CMD8                            = $40+8                     ' SEND_IF_COND
    CMD9                            = $40+9                     ' SEND_CSD
    CMD10                           = $40+10                    ' SEND_CID
    CMD12                           = $40+12                    ' STOP_TRANSMISSION
    CMD13                           = $40+13                    ' SEND_STATUS
    ACMD13                          = $C0+13                    ' SD_STATUS (SDC)
    CMD16                           = $40+16                    ' SET_BLOCKLEN
    CMD17                           = $40+17                    ' READ_SINGLE_BLOCK
    CMD18                           = $40+18                    ' READ_MULTIPLE_BLOCK
    CMD23                           = $40+23                    ' SET_BLOCK_COUNT (MMC)
    ACMD23                          = $C0+23                    ' SET_WR_BLK_ERASE_COUNT (SDC)
    CMD24                           = $40+24                    ' WRITE_BLOCK
    CMD25                           = $40+25                    ' WRITE_MULTIPLE_BLOCK
    CMD55                           = $40+55                    ' APP_CMD
    CMD58                           = $40+58                    ' READ_OCR
    CMD59                           = $40+59                    ' CRC_ON_OFF

#ifdef DEBUG
    LOG_SIZE                        = 256 << 1                  ' buffer size for my debug cmd log
#endif

#ifdef MULTI_DRIVER
VAR

    long SPI_engine_cog
  ' these are used for interfacing with the assembly engine | temporary initialization usage
    long SPI_command                                            ' "t", "r", "w", 0 =>done, <0 => error          | pin mask
    long SPI_block_index                                        ' which 512-byte block to read/write            | cnt at init
    long SPI_buffer_address                                     ' where to get/put the data in Hub RAM          | unused
#else
DAT
    SPI_engine_cog          long 0
' these are used for interfacing with the assembly engine | temporary initialization usage
    SPI_command             long 0                              ' "t", "r", "w", 0 =>done, <0 => error          | unused
    SPI_block_index         long 0                              ' which 512-byte block to read/write            | cnt at init
    SPI_buffer_address      long 0                              ' where to get/put the data in Hub RAM          | unused
#endif

#ifdef DEBUG
VAR
    byte log_cmd_resp[LOG_SIZE+1]                               ' for debug ONLY

PUB get_log_pointer
    return @log_cmd_resp
#endif
  
PUB Start(basepin)
' This is a compatibility wrapper, and requires that the pins be
'   both consecutive, and in the order DO CLK DI CS.
    return start_explicit(basepin, basepin+1, basepin+2, basepin+3)

PUB Start_Explicit( DO, CLK, DI, CS ) : card_type | tmp, i
' Do all of the card initialization in SPIN, then hand off the pin
'   information to the assembly cog for hot SPI block R/W action!
  ' Start from scratch
    Stop
#ifdef DEBUG
    bytefill( @log_cmd_resp, 0, LOG_SIZE+1 )                    ' clear my log buffer
    dbg_ptr := @log_cmd_resp
    dbg_end := dbg_ptr + LOG_SIZE
#endif
    waitcnt(500 + (clkfreq>>8) + cnt)                           ' wait ~4 milliseconds
    pinDO := DO                                                 ' (start with cog variables, _BEFORE_ loading the cog)
    maskDO := |< DO
    pinCLK := CLK
    pinDI := DI
    maskDI := |< DI
    maskCS := |< CS
    adrShift := 9                                               ' block = 512 * index, and 512 = 1<<9
    maskAll := maskCS | (|<pinCLK) | maskDI                     ' pass the output pin mask via the command register
    dira |= maskAll  
    outa |= maskAll                                             ' get the card in a ready state: set DI and CS high, send => 74 clocks
    repeat 4096
        outa[CLK]~~
        outa[CLK]~

    SPI_block_index := cnt                                      ' time-hack
    tmp~                                                        ' reset the card
    repeat i from 0 to 9
        if tmp <> 1
            tmp := Send_Cmd_Slow( CMD0, 0, $95 )
            if (tmp & 4)
                if i & 1                                        ' the card said CMD0 ("go idle") was invalid, so we're possibly stuck in read or write mode
                    repeat 4                                    ' exit multiblock read mode
                        Read_32_Slow                            ' these extra clocks are required for some MMC cards
                    Send_Slow( $FD, 8 )                         ' stop token
                    Read_32_Slow
                    repeat while read_slow <> $FF
                else
                    Send_Cmd_Slow( CMD12, 0, $61 )              ' exit multiblock read mode
    if tmp <> 1
        crash( ERR_CARD_NOT_RESET )                             ' the reset command failed!
    if Send_Cmd_Slow( CMD8, $1AA, $87 ) == 1                    ' Is this a SD type 2 card?
        tmp := Read_32_Slow                                     ' Type2 SD, check to see if it's a SDHC card
        if (tmp & $1FF) <> $1AA                                 ' check the supported voltage
            crash( ERR_3v3_NOT_SUPPORTED )
        repeat while Send_Cmd_Slow( ACMD41, |<30, $77 )         ' try to initialize the type 2 card with the High Capacity bit
        if Send_Cmd_Slow( CMD58, 0, $FD ) <> 0                  ' the card is initialized, let's read back the High Capacity bit
            crash( ERR_OCR_FAILED )
        tmp := Read_32_Slow                                     ' get back the data
        if tmp & |<30                                           ' check the bit
            card_type := type_SDHC
            adrShift := 0
        else
            card_type := type_SD
    else
        if Send_Cmd_Slow( ACMD41, 0, $E5 ) < 2                  ' Either a type 1 SD card, or it's MMC, try SD 1st
            card_type := type_SD                                ' this is a type 1 SD card (1 means busy, 0 means done initializing)
            repeat while Send_Cmd_Slow( ACMD41, 0, $E5 )
        else
            card_type := type_MMC                               ' mark that it's MMC, and try to initialize
            repeat while Send_Cmd_Slow( CMD1, 0, $F9 )
        Send_Cmd_Slow( CMD16, 512, $15 )                        ' some SD or MMC cards may have the wrong block size, set it here
    Send_Cmd_Slow( CMD59, 0, $91 )                              ' card is mounted, make sure the CRC is turned off
    outa |= maskCS                                              ' done with the SPI bus for now
    writeMode := (%00100 << 26) | (DI << 0)                     ' Counter mode - writing: NCO single-ended mode, output on DI
    clockLineMode := (%00100 << 26) | (CLK << 0)                ' Counter mode - reading: NCO, 50% duty cycle
    N_in8_500ms := clkfreq >> constant(1+2+3)                   ' how many bytes (8 clocks, >>3) fit into 1/2 of a second (>>1), 4 clocks per instruction (>>2)?
    idle_limit := 125                                           ' how long should we wait before auto-exiting any multiblock mode? ms, NEVER make this > 1000
    idle_limit := clkfreq / (1000 / idle_limit)                 ' convert to counts
    bufAdr := @SPI_buffer_address                               ' Hand off control to the assembly engine's cog
    sdAdr := @SPI_block_index
    SPI_command := 0                                            ' just make sure it's not 1
    SPI_engine_cog := cognew( @SPI_engine_entry, @SPI_command ) + 1 ' start my driver cog and wait till I hear back that it's done
    if( SPI_engine_cog == 0 )
        crash( ERR_SPI_ENGINE_NOT_RUNNING )
    repeat while SPI_command <> -1
    dira &= !maskAll                                            ' and we no longer need to control any pins from here

PUB ReadBlock(block_index, buffer_address)

    if SPI_engine_cog == 0
        abort ERR_SPI_ENGINE_NOT_RUNNING
    if (buffer_address & 3)
        abort ERR_BLOCK_NOT_LONG_ALIGNED
    SPI_block_index := block_index
    SPI_buffer_address := buffer_address
    SPI_command := "r"
    repeat while SPI_command == "r"
    if SPI_command < 0
        abort SPI_command

PUB WriteBlock(block_index, buffer_address)

    if SPI_engine_cog == 0
        abort ERR_SPI_ENGINE_NOT_RUNNING
    if (buffer_address & 3)
        abort ERR_BLOCK_NOT_LONG_ALIGNED
    SPI_block_index := block_index
    SPI_buffer_address := buffer_address
    SPI_command := "w"
    repeat while SPI_command == "w"
    if SPI_command < 0
        abort SPI_command

PUB Get_Seconds

    if SPI_engine_cog == 0
        abort ERR_SPI_ENGINE_NOT_RUNNING
    SPI_command := "t"
    repeat while SPI_command == "t"
    return SPI_block_index                                      ' secods are in SPI_block_index, remainder is in SPI_buffer_address

PUB Get_Milliseconds : ms

    if SPI_engine_cog == 0
        abort ERR_SPI_ENGINE_NOT_RUNNING
    SPI_command := "t"
    repeat while SPI_command == "t"
    ms := SPI_block_index * 1000                                ' secods are in SPI_block_index, remainder is in SPI_buffer_address
    ms += SPI_buffer_address * 1000 / clkfreq

PUB Release
' I do not want to abort if the cog is not
'   running, as this is called from stop, which
'   is called from start/ [8^)  
    if SPI_engine_cog
        SPI_command := "z"
        repeat while SPI_command == "z"

PUB Stop
' Kill the assembly driver cog.
    release
    if SPI_engine_cog
        cogstop( SPI_engine_cog~ - 1 )

PRI Crash(abort_code)
' In case of Bad Things(TM) happening,
'   exit as gracefully as possible.
'   and we no longer need to control any pins from here
    dira &= !maskAll
    abort abort_code                                            ' and report our error

PRI Send_Cmd_Slow( cmd, val, crc ) : reply | time_stamp
' Send down a command and return the reply.
' Note: slow is an understatement!
' Note: this uses the assembly DAT variables for pin IDs,
'   which means that if you run this multiple times (say for
'   multiple SD cards), these values will change for each one.
'   But this is OK as all of these functions will be called
'   during the initialization only, before the PASM engine is
'   running.
    if (cmd & $80)                                              ' if this is an application specific command, handle it
        cmd &= $7F                                              ' ACMD<n> is the command sequense of CMD55-CMD<n>
        reply := Send_Cmd_Slow( CMD55, 0, $65 )
        if (reply > 1)
            return reply
    outa |= maskCS                                              ' the CS line needs to go low during this operation
    outa &= !maskCS
    read_32_Slow                                                ' give the card a few cocks to finish whatever it was doing
    Send_Slow( cmd, 8 )                                         ' send the command byte
    Send_Slow( val, 32 )                                        ' send the value long
    Send_Slow( crc, 8 )                                         ' send the CRC byte
    if cmd == CMD12                                             ' is this a CMD12?, if so, stuff byte
        Read_Slow
    time_stamp := 9                                             ' read back the response (spec declares 1-8 reads max for SD, MMC is 0-8)
    repeat
        reply := read_slow
    while( reply & $80 ) and ( time_stamp-- )                   ' done, and 'reply' is already pre-loaded

PRI Send_Slow(value, bits_to_send)

    value ><= bits_to_send
    repeat bits_to_send
        outa[pinCLK]~
        outa[pinDI] := value
        value >>= 1
        outa[pinCLK]~~

PRI Read_32_Slow : r

    repeat 4
        r <<= 8
        r |= Read_Slow

PRI Read_Slow : r
' Read back 8 bits from the card
    outa[pinDI]~~                                               ' we need the DI line high so a read can occur
    repeat 8                                                    ' get 8 bits (remember, r is initialized to 0 by SPIN)
        outa[pinCLK]~
        outa[pinCLK]~~
        r += r + ina[pinDO]
    if( (cnt - SPI_block_index) > (clkfreq << 2) )              ' error check
        crash( ERR_CARD_BUSY_TIMEOUT )

DAT
' This is the assembly engine for doing fast block
'   reads and writes.  This is *ALL* it does!
{
l       c       i       o                   f
}
                org     0
SPI_engine_entry
                mov     ctra, writeMode                         ' Counter A drives data out
                mov     ctrb, clockLineMode                     ' Counter B will always drive my clock line
                mov     dira, maskAll                           ' set our output pins to match the pin mask
                neg     user_request, #1                        ' handshake that we now control the pins
                wrlong  user_request, par
                mov     last_time, cnt                          ' start my seconds' counter here

waiting_for_command
                call    #handle_time                            ' update my seconds counter, but also track the idle time so we can to release the card after timeout.
                rdlong  user_request, par                       ' read the command, and make sure it's from the user (> 0)
                cmps    user_request, #0    wz, wc
        if_be   jmp     #waiting_for_command
                cmp     user_request, #"r"  wz                  ' handle our card based commands
        if_z    jmp     #read_ahead
                cmp     user_request, #"w"  wz
        if_z    jmp     #write_behind
                cmp     user_request, #"z"  wz
        if_z    jmp     #release_card
                cmp     user_request, #"t"  wz                  ' time requests are handled differently
        if_z    wrlong  seconds,sdAdr                           ' seconds goes into the SD index register
        if_z    wrlong  dtime,bufAdr                            ' the remainder goes into the buffer address register
                mov     user_request, #0                        ' in all other cases, clear the user's request
                wrlong  user_request, par
                jmp     #waiting_for_command

release_card
                mov     user_cmd, #"z"                          ' request a release
                neg     lastIndexPlus, #1                       ' reset the last block index 
                neg     user_idx, #1                            ' and make this match it 
                call    #handle_command
                mov     user_request, user_cmd
                wrlong  user_request, par
                jmp     #waiting_for_command

read_ahead
                rdlong  user_idx, sdAdr
                mov     tmp1, user_idx                          ' if the correct block is not already loaded, load it
                add     tmp1, #1
                cmp     tmp1, lastIndexPlus wz
        if_z    cmp     lastCommand, #"r"   wz
        if_z    jmp     #:get_on_with_it
                mov     user_cmd, #"r"
                call    #handle_command
:get_on_with_it
                movi    transfer_long, #%000010_000             ' copy the data up into Hub RAM - set to wrlong
                call    #hub_cog_transfer
                mov     user_request, user_cmd                  ' signify that the data is ready, Spin can continue
                wrlong  user_request, par
                mov     user_cmd, #"r"                          ' request the next block
                add     user_idx, #1
                call    #handle_command
                jmp     #waiting_for_command                    ' done

write_behind
                rdlong  user_idx, sdAdr
                movi    transfer_long, #%000010_001             ' copy data in from Hub RAM - set to rdlong
                call    #hub_cog_transfer
                mov     user_request, user_cmd                  ' signify that we have the data, Spin can continue
                wrlong  user_request, par
                mov     user_cmd, #"w"                          ' write out the block
                call    #handle_command
                jmp     #waiting_for_command                    ' done

{{
  Set user_cmd and user_idx before calling this
}}
handle_command
                cmp     lastIndexPlus, user_idx wz              ' Can we stay in the old mode? (address = old_address+1) && (old mode == new_mode)
        if_z    cmp     user_cmd,lastCommand    wz
        if_z    jmp     #:execute_block_command
                cmp     lastCommand, #"w"       wz              ' we fell through, must exit the old mode! (except if the old mode was "release")
        if_z    call    #stop_mb_write
                cmp     lastCommand, #"r"       wz
        if_z    call    #stop_mb_read
                cmp     user_cmd, #"w"          wz              ' and start up the new mode!
        if_z    call    #start_mb_write
                cmp     user_cmd, #"r"          wz
        if_z    call    #start_mb_read
                cmp     user_cmd, #"z"          wz
        if_z    call    #release_DO
:execute_block_command
                mov     lastIndexPlus, user_idx                 ' track the (new) last index and command
                add     lastIndexPlus, #1
                mov     lastCommand, user_cmd
                cmp     user_cmd, #"w"          wz              ' do the block read or write or terminate!
        if_z    call    #write_single_block
                cmp     user_cmd, #"r"          wz
        if_z    call    #read_single_block
                cmp     user_cmd, #"z"          wz
        if_z    mov     user_cmd, #0
handle_command_ret                                              ' done
                ret   

{=== these PASM functions get me in and out of multiblock mode ===}
release_DO
                or      outa, maskCS                            ' we're already out of multiblock mode, so
                call    #in8                                    ' deselect the card and send out some clocks
                call    #in8
#ifdef TRISTATE_ALL_WHEN_DO_RELEASED
                mov     dira, #0                                ' If you're using pull-up resistors, and need all lines tristated (for Cluso99)
#endif
release_DO_ret
                ret
        
start_mb_read  
                movi    block_cmd, #CMD18<<1
                call    #send_SPI_command_fast       
start_mb_read_ret
                ret

stop_mb_read
                movi    block_cmd, #CMD12<<1
                call    #send_SPI_command_fast
                call    #busy_fast
stop_mb_read_ret
                ret

start_mb_write  
                movi    block_cmd, #CMD25<<1
                call    #send_SPI_command_fast
start_mb_write_ret
                ret

stop_mb_write
                call    #busy_fast
                mov     tmp1, #16                               ' only some cards need these extra clocks
:loopity
                call    #in8         
                djnz    tmp1, #:loopity
                movi    phsa, #$FD<<1                           ' done with hack
                call    #out8
                call    #in8                                    ' stuff byte
                call    #busy_fast
stop_mb_write_ret
                ret

send_SPI_command_fast
                mov     dira, maskAll                           ' make sure we have control of the output lines
                or      outa, maskCS                            ' make sure the CS line transitions low  
                andn    outa, maskCS
                call    #in8                                    ' 8 clocks
                mov     phsa, block_cmd                         ' Send the data. Do which ever block command this is (already in the top 8 bits)
                call    #out8                                   ' write the byte
                mov     phsa, user_idx                          ' read in the desired block index
                shl     phsa, adrShift                          ' this will multiply by 512 (bytes/sector) for MMC and SD
                call    #out8                                   ' move out the 1st MSB
                rol     phsa, #1
                call    #out8                                   ' move out the 1st MSB
                rol     phsa, #1
                call    #out8                                   ' move out the 1st MSB
                rol     phsa, #1
                call    #out8                                   ' move out the 1st MSB
                call    #in8                                    ' bogus CRC value. in8 looks like out8 with $FF
                shr     block_cmd, #24                          ' CMD12 requires a stuff byte
                cmp     block_cmd, #CMD12       wz
        if_z    call    #in8                                    ' 8 clocks
                mov     tmp1, #9                                ' get the response
:cmd_response
                call    #in8
                test    readback, #$80          wc, wz
        if_c    djnz    tmp1, #:cmd_response
        if_nz   neg     user_cmd, readback
send_SPI_command_fast_ret                                       ' done
                ret    

busy_fast
                mov     tmp1, N_in8_500ms
:still_busy
                call    #in8
                cmp     readback, #$FF          wz
        if_nz   djnz    tmp1, #:still_busy
busy_fast_ret
                ret

out8
                andn    outa, maskDI 
                'movi phsb, #%11_0000000
                mov     phsb, #0
                movi    frqb, #%01_0000000        
                rol     phsa, #1
                rol     phsa, #1
                rol     phsa, #1
                rol     phsa, #1
                rol     phsa, #1
                rol     phsa, #1
                rol     phsa, #1
                mov     frqb, #0                                ' don't shift out the final bit...already sent, but be aware 
                                                                '   of this when sending consecutive bytes (send_cmd, for e.g.) 
out8_ret
                ret

in8
                neg     phsa, #1                                ' DI high
                mov     readback, #0
                movi    phsb, #%011_000000                      ' set up my clock, and start it
                movi    frqb, #%001_000000
                test    maskDO, ina             wc              ' keep reading in my value
                rcl     readback, #1
                test    maskDO, ina             wc
                rcl     readback, #1
                test    maskDO, ina             wc
                rcl     readback, #1
                test    maskDO, ina             wc
                rcl     readback, #1
                test    maskDO, ina             wc
                rcl     readback, #1
                test    maskDO, ina             wc
                rcl     readback, #1
                test    maskDO, ina             wc
                rcl     readback, #1
                test    maskDO, ina             wc
                mov     frqb, #0                                ' stop the clock
                rcl     readback, #1
                mov     phsa, #0                                ' DI low
in8_ret
                ret

' this is called more frequently than 1 Hz, and
' is only called when the user command is 0.
handle_time        
                mov     tmp1, cnt                               ' get the current timestamp
                add     idle_time, tmp1                         ' add the current time to my idle time counter
                sub     idle_time, last_time                    ' subtract the last time from my idle counter (hence delta)    
                add     dtime, tmp1                             ' add to my accumulator, 
                sub     dtime, last_time                        ' and subtract the old (adding delta)
                mov     last_time, tmp1                         ' update my "last timestamp"        
                rdlong  tmp1, #0                                ' what is the clock frequency?
                cmpsub  dtime, tmp1             wc              ' if I have more than a second in my accumulator
                addx    seconds, #0                             ' then add it to "seconds"
                cmp     idle_time, idle_limit   wz, wc          ' this part is to auto-release the card after a timeout
        if_b    jmp     #handle_time_ret                        ' don't clear if we haven't hit the limit
                mov     user_cmd, #"z"                          ' we can't overdo it, the command handler makes sure
                neg     lastIndexPlus, #1                       ' reset the last block index 
                neg     user_idx, #1                            ' and make this match it 
                call    #handle_command                         ' release the card, but don't mess with the user's request register
handle_time_ret
                ret

hub_cog_transfer
                mov     ctrb, clockXferMode                     ' setup for all 4 passes
                mov     frqb, #1 
                rdlong  buf_ptr, bufAdr
                mov     ops_left, #4
                movd    transfer_long, #speed_buf
four_transfer_passes
                rdlong  tmp1, tmp1                              ' sync to the Hub RAM access
                mov     tmp1, #(512 / 4 / 4)                    ' how many long to move on this pass? (512 bytes / 4)longs / 4 passes
                mov     phsb, buf_ptr                           ' get my starting address right (phsb is incremented 1 per clock, so 16 each Hub access)
transfer_long
                rdlong  0-0, phsb                               ' write the longs, stride 4...low 2 bits of phsb are ignored
                add     transfer_long, incDest4
                djnz    tmp1, #transfer_long
                sub     transfer_long, decDestNminus1           ' go back to where I started, but advanced 1 long
                add     buf_ptr, #4                             ' offset my Hub pointer by one long per pass
                djnz    ops_left, #four_transfer_passes         ' do all 4 passes
                mov     frqb, #0                                ' restore the counter mode
                mov     phsb, #0
                mov     ctrb, clockLineMode
hub_cog_transfer_ret
                ret

read_single_block
                movd    :store_read_long, #speed_buf            ' where am I sending the data?
                mov     ops_left, #128
                mov     tmp1, N_in8_500ms                       ' wait until the card is ready
:get_resp
                call    #in8
                cmp     readback, #$FE          wz        
        if_nz   djnz    tmp1, #:get_resp
        if_nz   neg     user_cmd, #ERR_ASM_NO_READ_TOKEN
        if_nz   jmp     #read_single_block_ret
                neg     phsa, #1                                ' set DI high
                mov     ops_left, #128                          ' read the data
:read_loop
                mov     tmp1, #4
                movi    phsb, #%011_000000
:in_byte        
                movi    frqb, #%001_000000                      ' Start my clock
                test    maskDO, ina             wc              ' keep reading in my value, BACKWARDS!  (Brilliant idea by Tom Rokicki!)
                rcl     readback, #8
                test    maskDO, ina             wc
                muxc    readback, #2
                test    maskDO, ina             wc
                muxc    readback, #4
                test    maskDO, ina             wc
                muxc    readback, #8
                test    maskDO, ina             wc
                muxc    readback, #16
                test    maskDO, ina             wc
                muxc    readback, #32
                test    maskDO, ina             wc
                muxc    readback, #64
                test    maskDO, ina             wc
                mov     frqb, #0                                ' stop the clock
                muxc    readback, #128
                djnz    tmp1, #:in_byte                         ' go back for more
                rev     readback, #0                            ' make it...NOT backwards [8^)
:store_read_long
                mov     0-0, readback                           ' due to some counter weirdness, we need this mov
                add     :store_read_long, const512
                djnz    ops_left, #:read_loop
                mov     phsa, #0                                ' set DI low
                call    #in8                                    ' now read 2 trailing bytes (CRC). out8 is 2x faster than in8
                call    #in8                                    ' and I'm not using the CRC anyway
                call    #in8                                    ' give an extra 8 clocks in case we pause for a long time. in8 looks like out8($FF)
                mov     idle_time, #0                           ' all done successfully
                mov     user_cmd, #0               
read_single_block_ret
                ret

write_single_block               
                movs    :write_loop, #speed_buf                 ' where am I getting the data? (all 512 bytes / 128 longs of it?)
                mov     ops_left, #128                          ' read in 512 bytes (128 longs) from Hub RAM and write it to the card 
                call    #busy_fast                              ' just hold your horses 
                movi    phsa, #$FC<<1                           ' $FC for multiblock, $FE for single block
                call    #out8
                mov     phsb, #0                                ' make sure my clock accumulator is right
:write_loop
                mov     phsa, speed_buf                         ' read 4 bytes
                add     :write_loop, #1
                rol     phsa, #24                               ' LE long is DCBA. Move A7 into position, so I can do the swizzled version
                movi    frqb, #%010000000                       ' start the clock (remember A7 is already in place)
                rol     phsa, #1                                ' A7 is going out, at the end of this instr, A6 is in place
                rol     phsa, #1                                ' A5
                rol     phsa, #1                                ' A4
                rol     phsa, #1                                ' A3
                rol     phsa, #1                                ' A2
                rol     phsa, #1                                ' A1
                rol     phsa, #1                                ' A0
                rol     phsa, #17                               ' B7
                rol     phsa, #1                                ' B6
                rol     phsa, #1                                ' B5
                rol     phsa, #1                                ' B4
                rol     phsa, #1                                ' B3
                rol     phsa, #1                                ' B2
                rol     phsa, #1                                ' B1
                rol     phsa, #1                                ' B0
                rol     phsa, #17                               ' C7
                rol     phsa, #1                                ' C6
                rol     phsa, #1                                ' C5
                rol     phsa, #1                                ' C4
                rol     phsa, #1                                ' C3
                rol     phsa, #1                                ' C2
                rol     phsa, #1                                ' C1
                rol     phsa, #1                                ' C0
                rol     phsa, #17                               ' D7
                rol     phsa, #1                                ' D6
                rol     phsa, #1                                ' D5
                rol     phsa, #1                                ' D4
                rol     phsa, #1                                ' D3
                rol     phsa, #1                                ' D2
                rol     phsa, #1                                ' D1
                rol     phsa, #1                                ' D0 will be in place _after_ this instruction
                mov     frqb, #0                                ' shuts the clock off, _after_ this instruction
                djnz    ops_left, #:write_loop
                call    #in8                                    ' write out my two (bogus, using $FF) CRC bytes
                call    #in8
                call    #in8                                    ' now read response (I need this response, so can't spoof using out8)
                and     readback, #$1F
                cmp     readback, #5            wz
        if_z    mov     user_cmd, #0                            ' great
        if_nz   neg     user_cmd, #ERR_ASM_BLOCK_NOT_WRITTEN    ' oops
                call    #in8                                    ' send out another 8 clocks
                mov     idle_time, #0                           ' all done
write_single_block_ret
                ret

{=== Assembly Interface Variables ===}
pinDO         long 0                                            ' pin is controlled by a counter
pinCLK        long 0                                            ' pin is controlled by a counter
pinDI         long 0                                            ' pin is controlled by a counter
maskDO        long 0                                            ' mask for reading the DO line from the card
maskDI        long 0                                            ' mask for setting the pin high while reading
maskCS        long 0                                            ' mask = (1<<pin), and is controlled directly
maskAll       long 0
adrShift      long 9                                            ' will be 0 for SDHC, 9 for MMC & SD
bufAdr        long 0                                            ' where in Hub RAM is the buffer to copy to/from?
sdAdr         long 0                                            ' where on the SD card does it read/write?
writeMode     long 0                                            ' the counter setup in NCO single ended, clocking data out on pinDI
'clockOutMode  long 0                                           ' the counter setup in NCO single ended, driving the clock line on pinCLK
N_in8_500ms   long 1_000_000                                    ' used for timeout checking in PASM
'readMode      long 0
clockLineMode long 0
clockXferMode long %11111 << 26
const512      long 512
const1024     long 1024
incDest4      long 4 << 9
decDestNminus1 long (512 / 4 - 1) << 9         

{=== Initialized PASM Variables ===}
seconds       long 0
dtime         long 0
idle_time     long 0
idle_limit    long 0

{=== Multiblock State Machine ===}
lastIndexPlus long -1                                           ' state handler will check against lastIndexPlus, which will not have been -1
lastCommand   long 0                                            ' this will never be the last command.

{=== Debug Logging Pointers ===}
#ifdef DEBUG
dbg_ptr       long 0
dbg_end       long 0
#endif

{=== Assembly Scratch Variables ===}
ops_left      res 1                                             ' used as a counter for bytes, words, longs, whatever (start w/ # byte clocks out)
readback      res 1                                             ' all reading from the card goes through here
tmp1          res 1                                             ' this may get used in all subroutines...don't use except in lowest 
user_request  res 1                                             ' the main command variable, read in from Hub: "r"-read single, "w"-write single
user_cmd      res 1                                             ' used internally to handle actual commands to be executed
user_idx      res 1                                             ' the pointer to the Hub RAM where the data block is/goes
block_cmd     res 1                                             ' one of the SD/MMC command codes, no app-specific allowed
buf_ptr       res 1                                             ' moving pointer to the Hub RAM buffer
last_time     res 1                                             ' tracking the timestamp

{{
  496 longs is my total available space in the cog,
  and I want 128 longs for eventual use as one 512-
  byte buffer.   This gives me a total of 368 longs
  to use for umount, and a readblock and writeblock
  for both Hub RAM and Cog buffers.
}}
speed_buf     res 128                                           ' 512 bytes to be used for read-ahead / write-behind

FIT 496

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

