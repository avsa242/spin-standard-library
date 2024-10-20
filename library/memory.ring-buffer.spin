{
    --------------------------------------------
    Filename: memory.ring-buffer.spin
    Author: Jesse Burt
    Description: Generic ring buffer
    Started Sep 30, 2023
    Updated Dec 22, 2023
    Copyright 2023
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based partly on qring.spin,
        originally by Harrison Pham
}

con

    { limits }
    RBUFF_SZ    = 32                            ' must be a power of 2 (can override in parent obj)
    RBUFF_MASK  = RBUFF_SZ-1

    { error codes }
    EBUFF_FULL  = -32768                        ' no space left in buffer
    EBUFF_EMPTY = -32769                        ' buffer is empty
    EBUFF_UNDER = -32770                        ' buffer underflow


var

    long rdblk_lsbf                             ' pointer to rdblk_lsbf function
    long wrblk_lsbf                             ' pointer to wrblk_lsbf function


    { pointers within the buffer }
    word _ptr_head, _ptr_tail

    { the ring buffer }
    byte _ring_buff[RBUFF_SZ]


pub set_func_rdblk_lsbf(fptr)    'xxx API not finalized
' Set pointer to external rdblk_lsbf function
'   NOTE: For use with xreceive()
    rdblk_lsbf := fptr


pub set_func_wrblk_lsbf(fptr)    'xxx API not finalized
' Set pointer to external rdblk_lsbf function
'   NOTE: For use with xreceive()
    wrblk_lsbf := fptr


pub bytes_queued = available
pub available(): q
' Get the number of unread bytes available in the buffer
    return ||( _ptr_head - _ptr_tail )


pub bytes_free(): b
' Get the number of bytes free in the ring buffer
    return RBUFF_MASK - ( (_ptr_head - _ptr_tail) & RBUFF_MASK )


pub flush(): b
' Flush the ring buffer and reset the pointers
'   Returns: the number of bytes in the buffer before being flushed
    b := available()
    bytefill(@_ring_buff, 0, RBUFF_SZ)
    _ptr_head := _ptr_tail := 0


pub get(ptr_buff, len): l
' Get some data from the ring buffer
'   ptr_buff: buffer to copy data into
'   len: number of bytes to copy
'   Returns: number of bytes actually copied
'   NOTE: length of data copied will be limited by what is actually available in the buffer
    len := ( len <# available() )            ' limit request to what's actually available

    if ( len )                                  ' don't do anything if the buffer's empty
        if ( (len + _ptr_tail) > RBUFF_SZ )
            { case 1: current read pointer + length requested goes past the 'end' of the buffer:
                read what we can... }
            bytemove(ptr_buff, (@_ring_buff+_ptr_tail), (RBUFF_SZ-_ptr_tail) )

            { ...now wrap around to the beginning and get the rest }
            ptr_buff += (RBUFF_SZ-_ptr_tail)
            bytemove(ptr_buff, @_ring_buff, (len-(RBUFF_SZ-_ptr_tail)) )
            _ptr_tail := ( _ptr_tail + len) & RBUFF_MASK
        else
            { case 2: all of the data lies between the current pointer and the end }
            bytemove(ptr_buff, (@_ring_buff + _ptr_tail), len)
            _ptr_tail := ( _ptr_tail + len ) & RBUFF_MASK

    return len


pub getchar(): ch
' Get a character from the buffer
'   Returns: character, or -1 if none available
    ch := -1
    get(@ch, 1)


pub head(): p
' Get the current head (write) pointer
    return _ptr_head


pub is_empty(): f
' Flag indicating the ring buffer is empty
'   Returns: TRUE (-1) or FALSE (0)
    return ( _ptr_head == _ptr_tail )


pub is_full(): f
' Flag indicating the ring buffer is full
'   Returns: TRUE (-1) or FALSE (0)
    return ( bytes_free() == 0 )


pub ptr_ringbuff(): p
' Get a pointer to the ring buffer
    return @_ring_buff


pub put(src_buff, len): n
' Copy data into the ring buffer
'   src_buff: pointer to buffer to receive data from
'   len: number of bytes to receive
'   Returns: number of bytes received, or EBUFF_FULL if there isn't enough space in the buffer
    if ( len > bytes_free() )
        { don't bother doing anything if there isn't enough space in the buffer }
        return EBUFF_FULL

    if ( (len + _ptr_head) > RBUFF_SZ )
        { current write pointer + length requested doesn't fit in the 'end' of the buffer:
            fit what we can... }
        bytemove( (@_ring_buff + _ptr_head), src_buff, (RBUFF_SZ-_ptr_head) )
        src_buff += (RBUFF_SZ-_ptr_head)        ' advance source data pointer

        { ...now wrap around to the beginning and write the rest }
        bytemove(@_ring_buff, src_buff, (len-(RBUFF_SZ-_ptr_head)) )
        _ptr_head := ( _ptr_head + len) & RBUFF_MASK
    else
        { all of the data fits - simply write it }
        bytemove( (@_ring_buff + _ptr_head), src_buff, len)
        _ptr_head := ( _ptr_head + len) & RBUFF_MASK

    return len


pub putchar(ch): s
' Put one character into the ring buffer
'   ch: character to put
'   Returns: 1 on success, 0 on failure
    return put(@ch, 1)


pub tail(): p
' Get the current tail (read) pointer
    return _ptr_tail


pub xget(len): n   'xxx API not finalized
' Get data from the ring buffer into external buffer or device
'   (like get(), but from the other device's point of view)
'   len: number of bytes to send
'   Returns: number of bytes written, or EBUFF_UNDER if the buffer contains less than 'len'
'   NOTE: set_wrblk_lsbf() MUST be called before using this method (behavior will be otherwise
'       unpredictable)
'   NOTE: The external data buffer's write pointer is _NOT_ incremented here, so it _MUST_ be
'       handled by the buffer itself.
    len := ( len <# available() )            ' limit request to what's actually available

    if ( len )                                  ' don't do anything if the buffer's empty
        if ( (len + _ptr_tail) > RBUFF_SZ )
            { current read pointer + length requested goes past the 'end' of the buffer:
                write what we can... }
            wrblk_lsbf( (@_ring_buff+_ptr_tail), (RBUFF_SZ-_ptr_tail) )

            { ...now wrap around to the beginning and write the rest }
            wrblk_lsbf( @_ring_buff, (len-(RBUFF_SZ-_ptr_tail)) )
            _ptr_tail := ( _ptr_tail + len) & RBUFF_MASK
        else
            { all of the data is writeable in one shot }
            wrblk_lsbf( (@_ring_buff + _ptr_tail), len)
            _ptr_tail := ( _ptr_tail + len ) & RBUFF_MASK

    return len


pub xput(len): n    'xxx API not finalized
' Put data into the ring buffer from an external buffer or device
'   (like put(), but from the external device's point of view)
'   len: number of bytes to receive
'   Returns: number of bytes received, or ENOSPACE if there isn't enough space in the buffer
'   NOTE: set_rdblk_lsbf() MUST be called before using this method (behavior will be otherwise
'       unpredictable)
'   NOTE: The external data source's read pointer is _NOT_ incremented here, so it _MUST_ be
'       handled by the source itself.
    if ( len > bytes_free() )
        { don't bother doing anything if there isn't enough space in the buffer }
        return EBUFF_FULL

    if ( (len + _ptr_head) > RBUFF_SZ )
        { current write pointer + length requested doesn't fit in the 'end' of the buffer:
            fit what we can... }
        rdblk_lsbf( (@_ring_buff + _ptr_head), (RBUFF_SZ-_ptr_head) )

        { ...now wrap around to the beginning and write the rest }
        rdblk_lsbf(@_ring_buff, (len-(RBUFF_SZ-_ptr_head)) )
        _ptr_head := ( _ptr_head + len) & RBUFF_MASK
    else
        { all of the data fits - simply write it }
        rdblk_lsbf( (@_ring_buff + _ptr_head), len)
        _ptr_head := ( _ptr_head + len) & RBUFF_MASK

    return len

{ Add common terminal code so methods like str(), dec(), printf() etc can be used to
    manipulate buffer data }
#include "terminal.common.spinh"


DAT
{
Copyright 2023 Jesse Burt

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

