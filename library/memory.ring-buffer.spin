{
    --------------------------------------------
    Filename: memory.ring-buffer.spin
    Author: Jesse Burt
    Description: Generic ring buffer
    Started Sep 30, 2023
    Updated Sep 30, 2023
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


var

    { pointers within the buffer }
    word _ptr_head, _ptr_tail

    { the ring buffer }
    byte _ring_buff[RBUFF_SZ]


pub available(): b
' Get the number of bytes available in the ring buffer
    return RBUFF_MASK - ( (_ptr_head - _ptr_tail) & RBUFF_MASK )


pub flush(): b
' Flush the ring buffer and reset the pointers
'   Returns: the number of bytes in the buffer before being flushed
    b := unread_bytes()
    bytefill(@_ring_buff, 0, RBUFF_SZ)
    _ptr_head := _ptr_tail := 0


pub getchar(): ch
' Get a character from the buffer
    if ( unread_bytes() )
        { copy a byte from the ring buffer if there is one }
        ch := byte[@_ring_buff][_ptr_tail]
        byte[@_ring_buff][_ptr_tail++] := 0
        if ( _ptr_tail => RBUFF_SZ )
            _ptr_tail := 0                       ' wrap around to the buffer beginning
    else
        return EBUFF_EMPTY


pub head(): p
' Get the current head (write) pointer
    return _ptr_head


pub is_empty(): f
' Flag indicating the ring buffer is empty
'   Returns: TRUE (-1) or FALSE (0)
    return ( _ptr_head == _ptr_tail )


pub ptr_ringbuff(): p
' Get a pointer to the ring buffer
    return @_ring_buff


pub receive(src_buff, len): n
' Copy data into the ring buffer
'   src_buff: pointer to buffer to receive data from
'   len: number of bytes to receive
'   Returns: number of bytes received, or ENOSPACE if there isn't enough space in the buffer
    if ( len > available() )
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


pub tail(): p
' Get the current tail (read) pointer
    return _ptr_tail


pub unread_bytes(): q
' Get the number of unread bytes in the buffer
'   Returns:
'       positive numbers: count of unread bytes (head > tail)
'       negative numbers: count of unread bytes (head < tail)
'       0: empty
    return ( _ptr_head - _ptr_tail )


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

