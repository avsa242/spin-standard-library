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

    BUFFER_LENGTH = 64                                      ' Recommended as 64 or higher, but can be 2, 4, 8, 16, 32, 64, 128 or 256.
    BUFFER_MASK   = BUFFER_LENGTH - 1

VAR

    long    cog                                             ' Cog flag/id

    long    rx_head                                         ' 9 contiguous longs (must keep order)
    long    rx_tail
    long    tx_head
    long    tx_tail
    long    rx_pin
    long    tx_pin
    long    rxtx_mode
    long    bit_ticks
    long    buffer_ptr

    byte    rx_buffer[BUFFER_LENGTH]                        ' Receive and transmit buffers
    byte    tx_buffer[BUFFER_LENGTH]

PUB Start(baudrate) : okay
{{
    Start communication with the Parallax Serial Terminal using the Propeller's programming connection.
    Waits 1 second for connection, then clears screen.

    Parameters:
        baudrate -  bits per second.  Make sure it matches the Parallax Serial Terminal's
                    Baud Rate field.

    Returns True (non-zero) if cog started, or False (0) if no cog is available.
}}

    okay := StartRxTx(31, 30, 0, baudrate)

PUB StartRxTx(rxpin, txpin, mode, baudrate) : okay
{{
    Start serial communication with designated pins, mode, and baud.

    Parameters:
        rxpin - input pin; receives signals from external device's TX pin.
        txpin - output pin; sends signals to  external device's RX pin.
        mode  - signaling mode (4-bit pattern).
                   bit 0 - inverts rx.
                   bit 1 - inverts tx.
                   bit 2 - open drain/source tx.
                   bit 3 - ignore tx echo on rx.
        baudrate - bits per second.

    Returns    : True (non-zero) if cog started, or False (0) if no cog is available.
}}

    stop
    longfill(@rx_head, 0, 4)
    longmove(@rx_pin, @rxpin, 3)
    bit_ticks := clkfreq / baudrate
    buffer_ptr := @rx_buffer
    okay := cog := cognew(@entry, @rx_head) + 1

PUB Stop
{{
    Stop serial communication; frees a cog.
}}

    if cog
        cogstop(cog~ - 1)
    longfill(@rx_head, 0, 9)

PUB Count
{{
    Get count of characters in receive buffer.

    Returns: number of characters waiting in receive buffer.
}}

    result := rx_head - rx_tail
    result -= BUFFER_LENGTH*(result < 0)

PUB Flush
{{
    Flush receive buffer.
}}

    repeat while rxcheck => 0

PUB Char(ch)
{{
    Send single-byte character.  Waits for room in transmit buffer if necessary.

    Parameter:
        bytechr - character (ASCII byte value) to send.
}}

    repeat until (tx_tail <> ((tx_head + 1) & BUFFER_MASK))
    tx_buffer[tx_head] := ch
    tx_head := (tx_head + 1) & BUFFER_MASK

    if rxtx_mode & %1000
        CharIn

PUB CharIn
{{
    Receive single-byte character.  Waits until character received.

    Returns: $00..$FF
}}

#ifdef __FLEXSPIN__
    result := rxcheck
    repeat while result < 0
        result := rxcheck
#else
    repeat while (result := RxCheck) < 0
#endif

PUB RxCheck
{
    Check if character received; return immediately.

    Returns: -1 if no byte received, $00..$FF if character received.
}

    result~~
    if rx_tail <> rx_head
        result := rx_buffer[rx_tail]
        rx_tail := (rx_tail + 1) & BUFFER_MASK

DAT
                        org


entry                   mov     t1,par                'get structure address
                        add     t1,#4 << 2            'skip past heads and tails

                        rdlong  t2,t1                 'get rx_pin
                        mov     rxmask,#1
                        shl     rxmask,t2

                        add     t1,#4                 'get tx_pin
                        rdlong  t2,t1
                        mov     txmask,#1
                        shl     txmask,t2

                        add     t1,#4                 'get rxtx_mode
                        rdlong  rxtxmode,t1

                        add     t1,#4                 'get bit_ticks
                        rdlong  bitticks,t1

                        add     t1,#4                 'get buffer_ptr
                        rdlong  rxbuff,t1
                        mov     txbuff,rxbuff
                        add     txbuff,#BUFFER_LENGTH

                        test    rxtxmode,#%100  wz    'init tx pin according to mode
                        test    rxtxmode,#%010  wc
        if_z_ne_c       or      outa,txmask
        if_z            or      dira,txmask

                        mov     txcode,#transmit      'initialize ping-pong multitasking



receive                 jmpret  rxcode,txcode         'run chunk of tx code, then return

                        test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                        test    rxmask,ina      wc
        if_z_eq_c       jmp     #receive

                        mov     rxbits,#9             'ready to receive byte
                        mov     rxcnt,bitticks
                        shr     rxcnt,#1
                        add     rxcnt,cnt

:bit                    add     rxcnt,bitticks        'ready next bit period

:wait                   jmpret  rxcode,txcode         'run chunk of tx code, then return

                        mov     t1,rxcnt              'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        test    rxmask,ina      wc    'receive bit on rx pin
                        rcr     rxdata,#1
                        djnz    rxbits,#:bit

                        shr     rxdata,#32-9          'justify and trim received byte
                        and     rxdata,#$FF
                        test    rxtxmode,#%001  wz    'if rx inverted, invert byte
        if_nz           xor     rxdata,#$FF

                        rdlong  t2,par                'save received byte and inc head
                        add     t2,rxbuff
                        wrbyte  rxdata,t2
                        sub     t2,rxbuff
                        add     t2,#1
                        and     t2,#BUFFER_MASK
                        wrlong  t2,par

                        jmp     #receive              'byte done, receive next byte



transmit                jmpret  txcode,rxcode         'run chunk of rx code, then return

                        mov     t1,par                'check for head <> tail
                        add     t1,#2 << 2
                        rdlong  t2,t1
                        add     t1,#1 << 2
                        rdlong  t3,t1
                        cmp     t2,t3           wz
        if_z            jmp     #transmit

                        add     t3,txbuff             'get byte and inc tail
                        rdbyte  txdata,t3
                        sub     t3,txbuff
                        add     t3,#1
                        and     t3,#BUFFER_MASK
                        wrlong  t3,t1

                        or      txdata,#$100          'ready byte to transmit
                        shl     txdata,#2
                        or      txdata,#1
                        mov     txbits,#11
                        mov     txcnt,cnt

:bit                    test    rxtxmode,#%100  wz    'output bit on tx pin
                        test    rxtxmode,#%010  wc    'according to mode
        if_z_and_c      xor     txdata,#1
                        shr     txdata,#1       wc
        if_z            muxc    outa,txmask
        if_nz           muxnc   dira,txmask
                        add     txcnt,bitticks        'ready next cnt

:wait                   jmpret  txcode,rxcode         'run chunk of rx code, then return

                        mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        djnz    txbits,#:bit          'another bit to transmit?

                        jmp     #transmit             'byte done, transmit next byte



t1                      res     1
t2                      res     1
t3                      res     1

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1

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

