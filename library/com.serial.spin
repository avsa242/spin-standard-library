{
----------------------------------------------------------------------------------------------------
    Filename:       com.serial.spin
    Description:    UART/async serial engine
    Author:         Jesse Burt
    Started:        2009
    Updated:        Jun 28, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------

    NOTE: This is based on Parallax Serial Terminal.spin,
    originally by Jeff Martin, Andy Lindsay, Chip Gracey

    Specs/Limits:
        @80MHz Fsys:
            TX/RX: 250kbps
            TX-only: 1Mbps
}

CON

    { I/O configuration - these can be overridden by the parent object }
    RX_PIN          = DEF_RX_PIN
    TX_PIN          = DEF_TX_PIN
    SIG_MODE        = DEF_SIG_MODE
    SER_BAUD        = DEF_BAUD
    UART_BUFF_SZ    = DEF_UART_BUFF_SZ


    { defaults }
    DEF_RX_PIN      = 31
    DEF_TX_PIN      = 30
    DEF_SIG_MODE    = %0000
    DEF_BAUD        = 115_200


    { set size of RX and TX buffers: 2, 4, 8, 16, 32, 64, 128, 256 (64 or higher recommended) }
    DEF_UART_BUFF_SZ= 64
    BUFFER_MASK     = UART_BUFF_SZ - 1


    { signalling modes - bitwise-OR together as desired }
    INV_RX          = %0001                     ' invert RX
    INV_TX          = %0010                     ' invert TX
    OD_SRC_TX       = %0100                     ' open-drain/source TX
    IGNORE_TXECHO   = %1000                     ' ignore TX echo on RX


VAR

    long _cog                                   ' Cog flag/id

    long _rx_head                               ' 9 contiguous longs
    long _rx_tail                               ' (order is important)
    long _tx_head
    long _tx_tail
    long _rx_pin
    long _tx_pin
    long _rxtx_mode
    long _bit_ticks
    long _ptr_buff

    byte _rx_buff[UART_BUFF_SZ]                ' Receive and transmit buffers
    byte _tx_buff[UART_BUFF_SZ]


PUB start = init_def
PUB init_def(baudrate=SER_BAUD): status
' Start UART engine with default parameters (RX: P31, TX: P30, mode: %0000)
'   Returns: (cogid+1) of cog running PASM engine, or 0 if unsuccessful
    return init(RX_PIN, TX_PIN, SIG_MODE, baudrate)


PUB startrxtx = init
PUB init(rxpin, txpin, mode, baudrate): status
' Start UART engine with custom parameters
'   rxpin: input pin; receives signals from external device's TX pin.
'   txpin: output pin; sends signals to  external device's RX pin.
'   mode: signaling mode (4-bit pattern).
'       INV_RX (%0000): invert rx
'       INV_TX (%0010): invert tx
'       OD_SRC_TX (%0100): open drain/source tx
'       IGNORE_TXECHO (%1000): ignore tx echo on rx
'   baudrate - bits per second
'   Returns: (cogid+1) of cog running PASM engine, or 0 if unsuccessful
    deinit()
    longfill(@_rx_head, 0, 4)                   ' initialize vars to 0
    longmove(@_rx_pin, @rxpin, 3)               ' copy pins to vars
    _bit_ticks := (clkfreq / baudrate)          ' calc bit time for baud rate
    _ptr_buff := @_rx_buff
    return (_cog := cognew(@entry, @_rx_head) + 1)


PUB stop = deinit
PUB deinit()
' Stop UART engine cog
    if (_cog)                                   ' check for a running cog first
        cogstop(_cog - 1)
    longfill(@_cog, 0, 10)                      ' clear hub vars


PUB count = fifo_rx_bytes
PUB fifo_rx_bytes(): nr_chars
' Get count of characters in receive buffer
'   Returns: number of characters waiting in receive buffer
    nr_chars := (_rx_head - _rx_tail)
    nr_chars -= ( UART_BUFF_SZ * (nr_chars < 0) )


PUB flush = flush_rx
PUB flush_rx()
' Flush receive buffer
    repeat while ( getchar_noblock() => 0 )


PUB tx = putchar
PUB char = putchar
PUB putchar(ch)
' Send single-byte character (blocking)
'   ch: character (ASCII byte value) to send
    repeat until ( _tx_tail <> ( (_tx_head + 1) & BUFFER_MASK) )
    _tx_buff[_tx_head] := ch
    _tx_head := (_tx_head + 1) & BUFFER_MASK

    if ( _rxtx_mode & IGNORE_TXECHO )
        getchar()


PUB rx = getchar
PUB charin = getchar
PUB getchar: ch
' Receive a single byte (blocking)
'   Returns: $00..$FF
    repeat
        ch := getchar_noblock()
    while (ch == -1)


PUB rxcheck = rx_check
PUB rx_check = getchar_noblock
PUB getchar_noblock(): ch_rx
' Check if character received (non-blocking)
'   Returns:
'       -1: no byte received
'       $00..$FF if character received
    ch_rx := -1
    if ( _rx_tail <> _rx_head )
        ch_rx := _rx_buff[_rx_tail]
        _rx_tail := (_rx_tail + 1) & BUFFER_MASK


DAT
                org


entry           mov     t1,par                  ' get structure address
                add     t1,#4 << 2              ' skip past heads and tails

                rdlong  t2,t1                   ' get _rx_pin
                mov     rxmask,#1
                shl     rxmask,t2

                add     t1,#4                   ' get _tx_pin
                rdlong  t2,t1
                mov     txmask,#1
                shl     txmask,t2

                add     t1,#4                   ' get _rxtx_mode
                rdlong  rxtxmode,t1

                add     t1,#4                   ' get _bit_ticks
                rdlong  bitticks,t1

                add     t1,#4                   ' get _ptr_buff
                rdlong  rxbuff,t1
                mov     txbuff,rxbuff
                add     txbuff,#UART_BUFF_SZ

                test    rxtxmode,#%100 wz       ' init tx pin according to mode
                test    rxtxmode,#%010 wc
    if_z_ne_c   or      outa,txmask
    if_z        or      dira,txmask

                mov     txcode,#transmit        ' initialize ping-pong multitasking



receive         jmpret  rxcode,txcode           ' run chunk of tx code, then return

                test    rxtxmode,#%001 wz       ' wait for start bit on rx pin
                test    rxmask,ina     wc
    if_z_eq_c   jmp     #receive

                mov     rxbits,#9               ' ready to receive byte
                mov     rxcnt,bitticks
                shr     rxcnt,#1
                add     rxcnt,cnt

:bit            add     rxcnt,bitticks          ' ready next bit period

:wait           jmpret  rxcode,txcode           ' run chunk of tx code, then return

                mov     t1,rxcnt                ' check if bit receive period done
                sub     t1,cnt
                cmps    t1,#0           wc
    if_nc       jmp     #:wait

                test    rxmask,ina      wc      ' receive bit on rx pin
                rcr     rxdata,#1
                djnz    rxbits,#:bit

                shr     rxdata,#32-9            ' justify and trim received byte
                and     rxdata,#$FF
                test    rxtxmode,#%001  wz      ' if rx inverted, invert byte
    if_nz       xor     rxdata,#$FF

                rdlong  t2,par                  ' save received byte and inc head
                add     t2,rxbuff
                wrbyte  rxdata,t2
                sub     t2,rxbuff
                add     t2,#1
                and     t2,#BUFFER_MASK
                wrlong  t2,par

                jmp     #receive                ' byte done, receive next byte



transmit        jmpret  txcode,rxcode           ' run chunk of rx code, then return

                mov     t1,par                  ' check for head <> tail
                add     t1,#2 << 2
                rdlong  t2,t1
                add     t1,#1 << 2
                rdlong  t3,t1
                cmp     t2,t3           wz
    if_z        jmp     #transmit

                add     t3,txbuff               ' get byte and inc tail
                rdbyte  txdata,t3
                sub     t3,txbuff
                add     t3,#1
                and     t3,#BUFFER_MASK
                wrlong  t3,t1

                or      txdata,#$100            ' ready byte to transmit
                shl     txdata,#2
                or      txdata,#1
                mov     txbits,#11
                mov     txcnt,cnt

:bit            test    rxtxmode,#%100  wz      ' output bit on tx pin
                test    rxtxmode,#%010  wc      ' according to mode
    if_z_and_c  xor     txdata,#1
                shr     txdata,#1       wc
    if_z        muxc    outa,txmask
    if_nz       muxnc   dira,txmask
                add     txcnt,bitticks          ' ready next cnt

:wait           jmpret  txcode,rxcode           ' run chunk of rx code, then return

                mov     t1,txcnt                ' check if bit transmit period done
                sub     t1,cnt
                cmps    t1,#0           wc
    if_nc       jmp     #:wait

                djnz    txbits,#:bit            ' another bit to transmit?

                jmp     #transmit               ' byte done, transmit next byte



t1              res     1
t2              res     1
t3              res     1

rxtxmode        res     1
bitticks        res     1

rxmask          res     1
rxbuff          res     1
rxdata          res     1
rxbits          res     1
rxcnt           res     1
rxcode          res     1

txmask          res     1
txbuff          res     1
txdata          res     1
txbits          res     1
txcnt           res     1
txcode          res     1

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
}

