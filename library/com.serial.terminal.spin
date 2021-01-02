{
    --------------------------------------------
    Filename: com.serial.terminal.spin
    Maintainer: Jesse Burt
        (based on FullDuplexSerial.spin, originally by
        Jeff Martin, Andy Lindsay, Chip Gracey)
    Description: Parallax Serial Terminal-compatible
        serial terminal driver
    Started 2006
    Updated Jan 1, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    ' Control Character Constants
    HM =  1                                     ' HoMe cursor
    PC =  2                                     ' Position Cursor in x,y
    ML =  3                                     ' Move cursor Left
    MR =  4                                     ' Move cursor Right
    MU =  5                                     ' Move cursor Up
    MD =  6                                     ' Move cursor Down
    BS =  8                                     ' BackSpace
    TB =  9                                     ' TaB
    LF = 10                                     ' Line Feed
    CE = 11                                     ' Clear to End of line
    CB = 12                                     ' Clear lines Below
    NL = 13                                     ' Carriage-return/New Line
    PX = 14                                     ' Position cursor in X
    PY = 15                                     ' Position cursor in Y
    CS = 16                                     ' Clear Screen

CON

   MAXSTR_LENGTH = 49                           ' Maximum length of received
                                                '   numerical string (not
                                                '   including zero terminator)

OBJ

    ser : "com.serial"
    int : "string.integer"

VAR

    byte    _str_buffer[MAXSTR_LENGTH+1]        ' Buffer for numerical strings

PUB Start(baudrate): okay
{{
    Start communication with the Parallax Serial Terminal using the Propeller's programming connection.
    Waits 1 second for connection, then clears screen.

    Parameters:
        baudrate -  bits per second.  Make sure it matches the Parallax Serial Terminal's
                    Baud Rate field.

    Returns True (non-zero) if cog started, or False (0) if no cog is available.
}}
    okay := ser.start(baudrate)
    clear
    return okay

PUB StartRxTx(rxpin, txpin, mode, baudrate)
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
    return ser.startrxtx(rxpin, txpin, mode, baudrate)

PUB Stop
{{
    Stop serial communication; frees a cog.
}}
    ser.stop

PUB Bin(value, digits)
{{
    Send value as binary characters up to digits in length.

    Parameters:
        value  - byte, word, or long value to send as binary characters.
        digits - number of binary digits to send.  Will be zero padded if necessary.
}}
    str(int.bin(value,digits))

PUB BinIn
{{
    Receive carriage return terminated string of characters representing a binary value.

    Returns: the corresponding binary value.
}}
    strinmax(@_str_buffer, MAXSTR_LENGTH)
    return int.strtobase(@_str_buffer, 2)

PUB Char(ch)
{{
    Send single-byte character.  Waits for room in transmit buffer if necessary.
}}
    ser.char(ch)

PUB CharIn
{{
    Receive single-byte character.  Waits until character received.
}}
    return ser.charin

PUB Chars(ch, size)
{{
    Send string of size `size` filled with `bytechr`.
}}
    repeat size
        ser.char(ch)

PUB Clear
{{
    Clear screen and place cursor at top-left.
}}
    ser.char(CS)

PUB ClearLine
' Clear from cursor to end of line
    ser.char(CE)

PUB Count
{{
    Get count of characters in receive buffer.
}}
    return ser.count

PUB Dec(value)
{{
    Send value as decimal characters.
    Parameter:
        value - byte, word, or long value to send as decimal characters.
}}
    str(int.dec(value))

PUB DecIn
{{
    Receive carriage return terminated string of characters representing a decimal value.

    Returns: the corresponding decimal value.
}}
    strinmax(@_str_buffer, MAXSTR_LENGTH)
    return int.strtobase(@_str_buffer, 10)

PUB Flush
{{
    Flush receive buffer.
}}
    ser.flush

PUB Hex(value, digits)
{{
    Send value as hexadecimal characters up to digits in length.
    Parameters:
        value  - byte, word, or long value to send as hexadecimal characters.
        digits - number of hexadecimal digits to send.  Will be zero padded if necessary.
}}
    str(int.hex(value, digits))

PUB HexIn
{{
    Receive carriage return terminated string of characters representing a hexadecimal value.

    Returns: the corresponding hexadecimal value.
}}
    strinmax(@_str_buffer, MAXSTR_LENGTH)
    return int.strtobase(@_str_buffer, 16)

PUB MoveDown(y)
{{
    Move cursor down y lines.
}}
    repeat y
        ser.char(MD)

PUB MoveLeft(x)
{{
    Move cursor left x characters.
}}
    repeat x
        ser.char(ML)

PUB MoveRight(x)
{{
    Move cursor right x characters.
}}
    repeat x
        ser.char(MR)

PUB MoveUp(y)
{{
    Move cursor up y lines.
}}
    repeat y
        ser.char(MU)

PUB NewLine
{{
    Clear screen and place cursor at top-left.
}}
    ser.char(NL)

PUB Position(x, y)
{{
    Position cursor at column x, row y (from top-left).
}}
    ser.char(PC)
    ser.char(x)
    ser.char(y)

PUB PositionX(x)
{{
    Position cursor at column x of current row.
}}
    ser.char(PX)
    ser.char(x)

PUB PositionY(y)
{{
    Position cursor at row y of current column.
}}
    ser.char(PY)
    ser.char(y)

PUB ReadLine(line, maxline): size | c
' Read a line of text, terminated by a newline, or 'maxline' characters
    repeat
        case c := charin
            BS:     if size
                        size--
                        char(c)
            NL, LF: byte[line][size] := 0
                    char(c)
                    quit
            other:  if size < maxline
                        byte[line][size++] := c
                        char(c)

PUB RxCheck
' Check if character received; return immediately.
'   Returns: -1 if no byte received, $00..$FF if character received.
    return ser.rxcheck

PUB Str(stringptr)
{{
    Send zero-terminated string.
    Parameter:
        stringptr - pointer to zero terminated string to send.
}}
    repeat strsize(stringptr)
        ser.char(byte[stringptr++])

PUB StrIn(stringptr)
{{
    Receive a string (carriage return terminated) and stores it (zero terminated) starting at stringptr.
    Waits until full string received.

    Parameter:
        stringptr - pointer to memory in which to store received string characters.
                    Memory reserved must be large enough for all string characters plus a zero terminator.
}}
    strinmax(stringptr, -1)

PUB StrInMax(stringptr, maxcount)
{{
    Receive a string of characters (either carriage return terminated or maxcount in
    length) and stores it (zero terminated) starting at stringptr.  Waits until either
    full string received or maxcount characters received.

    Parameters:
        stringptr - pointer to memory in which to store received string characters.
                    Memory reserved must be large enough for all string characters plus a zero terminator (maxcount + 1).
        maxcount  - maximum length of string to receive, or -1 for unlimited.
}}
    repeat while (maxcount--)                                                     'While maxcount not reached
        if (byte[stringptr++] := ser.charin) == NL                                      'Get chars until NL
            quit
    byte[stringptr+(byte[stringptr-1] == NL)]~                                    'Zero terminate string; overwrite NL or append 0 char

PUB StrLn(ptr_str)
' Send zero-terminated string, followed by a newline
    str(ptr_str)
    newline{}
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
