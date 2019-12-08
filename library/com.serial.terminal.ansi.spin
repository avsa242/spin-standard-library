' Original Authors: Jeff Martin, Andy Lindsay, Chip Gracey

{{
    This object adds extra features specific to Parallax serial terminals.

    This object is heavily based on FullDuplexSerialPlus (by Andy Lindsay), which is itself
    heavily based on FullDuplexSerial (by Chip Gracey).

    # Usage

    -   Call Start, or StartRxTx, first.
    -   Be sure to set the Parallax Serial Terminal software to the baudrate specified in Start, and the proper COM port.
    -   At 80 MHz, this object properly receives/transmits at up to 250 Kbaud, or performs transmit-only at up to 1 Mbaud.
}}

CON

    '' Control Character Constants

    ESC             = 27
    CS              = 16  ' Clear Screen
    CE              = 11  ' Clear to End of line
    CB              = 12  ' Clear lines Below

    CR              = 13  ' New Line
    LF              = 10  ' Line Feed
    TB              =  9  ' TaB
    BS              =  8  ' BackSpace

    MAXSTR_LENGTH   = 49                                   ' Maximum length of received numerical string (not including zero terminator).

OBJ

    ser : "com.serial"
    num : "string.integer"

VAR

    byte    str_buffer[MAXSTR_LENGTH+1]                     ' String buffer for numerical strings

PUB Start(baudrate) : okay
{{
    Start communication with the Parallax Serial Terminal using the Propeller's programming connection.
    Waits 1 second for connection, then clears screen.

    Parameters:
        baudrate -  bits per second.  Make sure it matches the Parallax Serial Terminal's
                    Baud Rate field.

    Returns True (non-zero) if cog started, or False (0) if no cog is available.
}}

    okay := ser.Start(baudrate)
    Clear
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

    return ser.StartRxTx(rxpin, txpin, mode, baudrate)

PUB Stop
{{
    Stop serial communication; frees a cog.
}}

    ser.Stop

PUB Bin(value, digits)
{{
    Send value as binary characters up to digits in length.

    Parameters:
        value  - byte, word, or long value to send as binary characters.
        digits - number of binary digits to send.  Will be zero padded if necessary.
}}

    Str(num.Bin(value,digits))

PUB BinIn
{{
    Receive carriage return terminated string of characters representing a binary value.

    Returns: the corresponding binary value.
}}

    StrInMax(@str_buffer, MAXSTR_LENGTH)
    return num.StrToBase(@str_buffer, 2)

PUB Char(ch)
{{
    Send single-byte character.  Waits for room in transmit buffer if necessary.
}}

    ser.Char(ch)

PUB CharIn
{{
    Receive single-byte character.  Waits until character received.
}}

    return ser.CharIn

PUB Chars(ch, size)
{{
    Send string of size `size` filled with `bytechr`.
}}

    repeat size
        ser.Char(ch)

PUB Count
{{
    Get count of characters in receive buffer.
}}

    return ser.Count

PUB Dec(value)
{{
    Send value as decimal characters.
    Parameter:
        value - byte, word, or long value to send as decimal characters.
}}

    Str(num.Dec(value))

PUB DecIn
{{
    Receive carriage return terminated string of characters representing a decimal value.

    Returns: the corresponding decimal value.
}}

    StrInMax(@str_buffer, MAXSTR_LENGTH)
    return num.StrToBase(@str_buffer, 10)

PUB Flush
{{
    Flush receive buffer.
}}

    ser.Flush

PUB Hex(value, digits)
{{
    Send value as hexadecimal characters up to digits in length.
    Parameters:
        value  - byte, word, or long value to send as hexadecimal characters.
        digits - number of hexadecimal digits to send.  Will be zero padded if necessary.
}}

    Str(num.Hex(value, digits))

PUB HexIn
{{
    Receive carriage return terminated string of characters representing a hexadecimal value.

    Returns: the corresponding hexadecimal value.
}}

    StrInMax(@str_buffer, MAXSTR_LENGTH)
    return num.StrToBase(@str_buffer, 16)

PUB NewLine
{{
    Clear screen and place cursor at top-left.
}}

    Str(string(CR, LF))

PUB ReadLine(line, maxline) : size | c

    repeat
        case c := CharIn
            BS:     if size
                        size--
                        Char(c)
            CR, LF: byte[line][size] := 0
                    Char(c)
                    quit
            other:  if size < maxline
                        byte[line][size++] := c
                        Char(c)

PUB Str(stringptr)
{{
    Send zero-terminated string.
    Parameter:
        stringptr - pointer to zero terminated string to send.
}}

    repeat strsize(stringptr)
        ser.Char(byte[stringptr++])

PUB StrIn(stringptr)
{{
    Receive a string (carriage return terminated) and stores it (zero terminated) starting at stringptr.
    Waits until full string received.

    Parameter:
        stringptr - pointer to memory in which to store received string characters.
                    Memory reserved must be large enough for all string characters plus a zero terminator.
}}

    StrInMax(stringptr, -1)

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
        if (byte[stringptr++] := ser.CharIn) == CR                                      'Get chars until NL
            quit
    byte[stringptr+(byte[stringptr-1] == CR)]~                                    'Zero terminate string; overwrite NL or append 0 char

#include "lib.ansiterminal.spin"
