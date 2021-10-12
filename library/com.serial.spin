{
    --------------------------------------------
    Filename: com.serial.spin
    Author: Jesse Burt
    Description: UART engine
        (@80MHz Fsys: 250kbps TX/RX, or 1Mbps TX-only)
    Started 2009
    Updated Oct 12, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Parallax Serial Terminal.spin,
    originally by Jeff Martin, Andy Lindsay, Chip Gracey
}

CON

    ' default I/O configuration
    DEF_RX          = 31
    DEF_TX          = 30
    DEF_MODE        = %0000

    ' set size of RX and TX buffers
    ' recommended: 64 or higher
    BUFFER_LENGTH   = 64                        ' 2, 4, 8, 16, 32, 64, 128, 256
    BUFFER_MASK     = BUFFER_LENGTH - 1

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

    byte _rx_buff[BUFFER_LENGTH]                ' Receive and transmit buffers
    byte _tx_buff[BUFFER_LENGTH]

PUB Start(baudrate): status
' Start UART engine with default parameters (RX: P31, TX: P30, mode: %0000)
'   Returns: (cogid+1) of cog running PASM engine, or 0 if unsuccessful
    return startrxtx(DEF_RX, DEF_TX, DEF_MODE, baudrate)

PUB StartRxTx(rxpin, txpin, mode, baudrate): status
' Start UART engine with custom parameters
'   rxpin: input pin; receives signals from external device's TX pin.
'   txpin: output pin; sends signals to  external device's RX pin.
'   mode: signaling mode (4-bit pattern).
'       bit 0 - invert rx
'       bit 1 - invert tx
'       bit 2 - open drain/source tx
'       bit 3 - ignore tx echo on rx
'   baudrate - bits per second
'   Returns: (cogid+1) of cog running PASM engine, or 0 if unsuccessful
    stop
    longfill(@_rx_head, 0, 4)                   ' initialize vars to 0
    longmove(@_rx_pin, @rxpin, 3)               ' copy pins to vars
    _bit_ticks := (clkfreq / baudrate)          ' calc bit time for baud rate
    _ptr_buff := @_rx_buff
    return (_cog := cognew(@entry, @_rx_head) + 1)

PUB Stop
' Stop UART engine cog
    if _cog                                     ' check for a running cog first
        cogstop(_cog - 1)
    longfill(@_cog, 0, 10)                      ' clear hub vars

PUB Count: nr_chars
' Get count of characters in receive buffer
'   Returns: number of characters waiting in receive buffer
    nr_chars := (_rx_head - _rx_tail)
    nr_chars -= (BUFFER_LENGTH * (nr_chars < 0))

PUB Flush
' Flush receive buffer
    repeat while rxcheck => 0

PUB Char(ch)
' Send single-byte character
'   ch: character (ASCII byte value) to send
'   NOTE: This method will block while waiting for room in transmit buffer,
'       if necessary
    repeat until (_tx_tail <> ((_tx_head + 1) & BUFFER_MASK))
    _tx_buff[_tx_head] := ch
    _tx_head := (_tx_head + 1) & BUFFER_MASK

    if _rxtx_mode & %1000
        charin

PUB CharIn
' Receive single-byte character
'   Returns: $00..$FF
'   NOTE: This method will block while waiting for a character
#ifdef __FLEXSPIN__
    result := rxcheck
    repeat while result < 0
        result := rxcheck
#else
    repeat while (result := rxcheck) < 0
#endif

PUB RxCheck: ch_rx
' Check if character received
'   Returns:
'       -1: no byte received
'       $00..$FF if character received
'   NOTE: This method doesn't block, i.e., will return immediately
    ch_rx := -1
    if (_rx_tail <> _rx_head)
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
                add     txbuff,#BUFFER_LENGTH

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

