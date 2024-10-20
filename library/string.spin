{
---------------------------------------------------------------------------------------------------
    Filename:       string.spin
    Description:    String processing and formatting
    Author:         Jesse Burt
    Started:        May 29, 2022
    Updated:        Mar 23, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------

    NOTE: This is based on code originally written by the following sources:
        Parallax, inc.
        Eric Smith
        Dave Hein
        Peter Verkaik
}

{ if a maximum buffer size isn't defined at build-time, default to 100 bytes }
#ifndef FIELDSZ_MAX
#   define FIELDSZ_MAX 100
#endif

#include "termcodes.spinh"

CON

    IBIN    = 2
    IOCT    = 8
    IDEC    = 10
    IHEX    = 16

OBJ

    ctype:  "char.type"

VAR

    long _ptr                                   ' scratch buffer current pointer

    word _tokenstr

    { scratch buffer for integer conversions }
    byte _tmp_buff[FIELDSZ_MAX]

    byte _caps

PUB append(ptr_dest, ptr_src): ptr_new
' Append ptr_src string to the end of ptr_dest string
'   Returns: pointer to the new string
'   NOTE: Destination string must be larger or equal to size of ptr_src
'       string to prevent memory corruption.
    bytemove((ptr_dest + strsize(ptr_dest)), ptr_src, (strsize(ptr_src) + 1))
    return ptr_dest

PUB atoi(ptr_str): val | sign, n
' Convert string representation of decimal number to signed integer
'   ptr_str: string holding decimal number
'   Returns: Value of signed decimal string
    repeat while ctype.isspace(byte[ptr_str])
        ++ptr_str                               ' skip over any white space
    sign := 1                                   ' assume positive
    case byte[ptr_str]
        "-":
            sign := -1                          ' is negative
            ++ptr_str                           ' advance only if sign (- or +) present
        "+": ++ptr_str
    n := 0
    repeat while ctype.isdigit(byte[ptr_str])
        n := (10*n) + (byte[ptr_str++] - "0")   ' calculate value
    val := sign * n                             ' adjust for sign

PUB atoib(ptr_str, base): val | n, digit
' Convert string representation of unsigned integer to unsigned integer using specific base
'   ptr_str: string containing unsigned integer
'   base: Base for conversion (2=binary, 8=octal, 10=decimal, 16=hexadecimal)
'   Returns: Unsigned integer value
    n := 0
    repeat while ctype.isspace(byte[ptr_str])
        ++ptr_str
    digit := (byte[ptr_str++] & 127)
    repeat while digit => "0"
        if (digit => "a")
            digit -= ("a"-10)
        else
            if (digit => "A")
                digit -= ("A"-10)
            else
                digit -= "0"
        if (digit => base)
            quit
        n := (base * n) + digit
        if (byte[ptr_str] == 0)
            quit
        digit := (byte[ptr_str++] & 127)
    return n

PUB bin(val, digits): bin_str
' Convert binary value to string representation
    itoabp(val, @_tmp_buff, IBIN, digits, "0")
    return @_tmp_buff

PUB clear(ptr_str)
' Clear string (fill with 0/NUL)
    fill(ptr_str, NUL)


PUB clear_scratch_buff()
' Clear the scratch/working buffer, and reset the pointer
    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)
    _ptr := 0


PUB compare(ptr_str1, ptr_str2, case_s=0): cmpres
' Compare two strings
'   ptr_str1, ptr_str2: strings to compare
'   case_s: (optional) case-sensitive comparison
'       non-zero: case-sensitive
'       zero: not case-sensitive (default, if not specified)
'   Returns:
'       0 if the two strings are equal
'       1 if ptr_str1 comes after ptr_str2
'       -1 if ptr_str1 comes before ptr_str2
    if (case_s)
        repeat
            cmpres := (byte[ptr_str1] - byte[ptr_str2++])
        while ( byte[ptr_str1++] and (not(cmpres)) )
    else
        repeat
            cmpres := (ctype.tolower(byte[ptr_str1]) - ctype.tolower(byte[ptr_str2++]))
        while ( byte[ptr_str1++] and (not(cmpres)) )

PUB copy(ptr_dest, ptr_src): ptr_new
' Copy a string from ptr_src to ptr_dest
'   ptr_dest: destination to copy to
'   ptr_src: source to copy from
'   Returns: pointer to the new string
'   NOTE: Destination string must be larger or equal to size of ptr_src string
    bytemove(ptr_dest, ptr_src, (strsize(ptr_src) + 1))
    return ptr_dest

PUB dec(val): dec_str
' Convert decimal value to string representation
'   val: value to convert
'   Returns: pointer to string representation of value
    itoa(val, @_tmp_buff)
    return @_tmp_buff

PUB decpadded = decpads
PUB decpads(val, digits): dec_str
' Convert decimal value to string representation, with space padding
'   val: value to convert
'   Returns: pointer to string representation of value
    itoap(val, @_tmp_buff, digits, " ")
    return @_tmp_buff

PUB deczeroed = decpadz
PUB decpadz(val, digits): dec_str
' Convert decimal value to string representation, with zero padding
'   val: value to convert
'   Returns: pointer to string representation of value
    itoap(val, @_tmp_buff, digits, "0")
    return @_tmp_buff

PUB endswith(ptr_str, ptr_substr): ends
' Check if the string ptr_str ends with string ptr_substr
'   ptr_str: string to check
'   ptr_substr: string to look for at end of ptr_str
'   Returns:
'       TRUE (-1): ptr_str ends with ptr_substr
'       FALSE (0): ptr_str doesn't end with ptr_substr
    ends := (ptr_str + strsize(ptr_str) - strsize(ptr_substr))
    return (ends == find(ends, ptr_substr))

PUB fill(ptr_str, char): ptr
' Fill string with char
'   ptr_str: string to fill
'   char: character to fill string with
    bytefill(ptr_str, char, strsize(ptr_str))
    byte[ptr_str + strsize(ptr_str)] := NUL     ' null-terminate
    return ptr_str

PUB find(ptr_str, ptr_srchstr): ptr_match | i, srch_sz, mismatch
' Find string
'   ptr_str: string to search
'   ptr_srchstr: string to search for
'   Returns: pointer to string if found, or 0 if not found
    ptr_match := mismatch := 0
    srch_sz := strsize(ptr_srchstr)             ' get size of search string
    if (srch_sz--)
        repeat strsize(ptr_str--)
            if (byte[++ptr_str] == byte[ptr_srchstr])
            { if the current char in the source string matches the first char
              of the search string, then it could be a match }
                repeat i from 0 to srch_sz
                { walk through each char of the source string to see if it
                  matches the next char of the search string }
                    if (byte[ptr_str][i] <> byte[ptr_srchstr][i])
                        mismatch := true        ' no - they're different;
                        quit                    ' set flag: there's no match
                ifnot (mismatch~)               ' flag is clear
                    return ptr_str              ' return updated pointer

PUB findchar(ptr_str, char): ptr
' Find first occurrence of character in string
'   Returns: pointer to character within ptr_str if found, or 0 if not found
    repeat strsize(ptr_str--)
        if (byte[++ptr_str] == char)
            return ptr_str

PUB getfield(ptr_str, field_nr, delim): ptr_flddata | char, i_idx, o_idx, cur_field
' Get field from string containing multiple data separated by delimiter
'   ptr_str: string to extract field data from
'   field_nr: which field number to return (zero-based)
'   delim: character to identify as a field delimiter (e.g., ",")
'
'   Returns: pointer to string containing field data
    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)        ' clear working buffer
    longfill(@char, 0, 4)                       ' initialize in/out indices
    repeat
        char := byte[ptr_str][i_idx++]          ' get current char from ptr_src
        case char
            NUL:                                ' NUL - end of string
                quit
            LF, CR:                             ' newline
                next
            delim:                              ' delimiter char (end of field)
                if (cur_field == field_nr)      ' found the requested field #?
                    quit
                else                            ' not the right field; clear
                    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)
                    cur_field++                 '   the buffer and keep going
                    o_idx := 0                  ' reset the output index
            other:
                _tmp_buff[o_idx++] := char      ' field text
    return @_tmp_buff

PUB getfieldcount(ptr_str, delim): nr_flds | char, idx
' Get number of delimiter-separated fields in ptr_str
'   ptr_str: pointer to string in which to count number of fields
'   delim: character to identify as a field delimiter (e.g., ",")
'
'   Returns:
'       number of fields found in ptr_str
'       0, if no fields found (e.g., NUL before a delimiter character was
'           ever encountered)
    idx := 0                                    ' initialize index
    nr_flds := 1
    repeat
        char := byte[ptr_str][idx++]
        case char
            NUL:                                ' end of string
                if (nr_flds == 1)               ' no delimiter chars found yet
                    nr_flds := 0                '   but NUL found? 0 fields found
                quit
            LF, CR:                             ' newline
                next
            delim:                              ' delimiter char (end of field)
                nr_flds++
            other:
                next

    return nr_flds

PUB hex(val, digits): hex_str
' Convert hexadecimal value to string representation
    itoabp(val, @_tmp_buff, IHEX, digits, "0")
    return @_tmp_buff

PUB hexcase(hcase)
' Set case for hexadecimal number string generation
'   Valid values:
'       non-zero: upper-case
'       zero: lower-case
    _caps := hcase

PUB hexs(val, digits): ptr | idx
' Convert hexadecimal value to string representation (small/standalone implementation)
'   Returns: pointer to string
    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)
    idx := 0
    digits := 1 #> digits <# 8
    val <<= (8 - digits) << 2                   ' prep most significant digit
    repeat digits
        _tmp_buff[idx++] := lookupz((val <-= 4) & $F : "0".."9", "a".."f")
    return @_tmp_buff

PUB iptostr(ip): ptr | tmp, i
' Convert 32-bit IP address to "dotted-quad" string representation
'   ip: 32-bit IP address (LSB-first)
'   Returns: pointer to string
    repeat i from 0 to 3
        tmp := itoa(    ip.byte[i], ...         ' copy each byte to the end of the string
                        @_tmp_buff+strsize(@_tmp_buff) )
        if ( i < 3 )                            ' place a dot between each octet
            append(@_tmp_buff, @".")
    return @_tmp_buff

PUB isalpha(ptr_str): flag
' Flag indicating entire string is alphabetic
'   Returns:
'       TRUE (-1) if string contains only alphabetic chars, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isalpha(byte[ptr_str++]))
            return false

    return true

PUB isalphanum(ptr_str): flag
' Flag indicating entire string is alphanumeric
'   Returns:
'       TRUE (-1) if string contains only alphanumeric chars, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isalphanumeric(byte[ptr_str++]))
            return false

    return true

PUB isdigit(ptr_str): flag
' Flag indicating entire string is decimal
'   Returns:
'       TRUE (-1) if string contains only decimal digit(s), FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isdigit(byte[ptr_str++]))
            return false

    return true

PUB isempty(ptr_str): flag
' Flag indicating string contains no characters
'   Returns:
'       TRUE (-1) if string is empty, FALSE (0) otherwise
    return (strsize(ptr_str) == 0)

PUB islower(ptr_str): flag
' Flag indicating entire string is lowercase
'   Returns:
'       TRUE (-1) if string contains only lowercase chars, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.islower(byte[ptr_str++]))
            return false

    return true

PUB isspace(ptr_str): flag
' Flag indicating entire string is whitespace
'   Returns:
'       TRUE (-1) if string contains only whitespace, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isspace(byte[ptr_str++]))
            return false

    return true

PUB isupper(ptr_str): flag
' Flag indicating entire string is uppercase
'   Returns:
'       TRUE (-1) if string contains only uppercase chars, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isupper(byte[ptr_str++]))
            return false

    return true

PUB itoa(num, ptr_dest): ptr | str0, dvsr, temp
' Convert number (signed) to string representation
'   num: integer value to convert
'   ptr_dest: string to copy output to
'   Returns: pointer to converted string
    str0 := ptr_dest
    if (num < 0)
        byte[ptr_dest++] := "-"
        if (num == $80000000)
            byte[ptr_dest++] := "2"
            num += 2_000_000_000
        num := -num
    elseif (num == 0)
        byte[ptr_dest++] := "0"
        byte[ptr_dest] := NUL
        return 1
    dvsr := 1_000_000_000
    repeat while (dvsr > num)
        dvsr /= 10
    repeat while (dvsr > 0)
        temp := num / dvsr
        byte[ptr_dest++] := temp + "0"
        num -= temp * dvsr
        dvsr /= 10
    byte[ptr_dest++] := NUL
    return ptr_dest - str0 - 1

PUB itoab(num, ptr_dest, base) | lowbit, sorg
' Convert number (unsigned) in base to string representation
'   num: integer value to convert
'   ptr_dest: string to copy output to
'   base: base/radix of number to copy to string
'       (e.g., itoab(32, @mystr, 16) would copy the number 32 to mystr
'           as a string in base-16, or hex: 1F)
    sorg := ptr_dest
    base := (base >> 1) & $f
    repeat                                      ' generate digits/letters in reverse order
        lowbit := (num & 1)
        num := (num >> 1) & $7FFFFFFF
        byte[ptr_dest] := ( (num // base) << 1 ) + lowbit
        if (byte[ptr_dest] < 10)
            byte[ptr_dest] += "0"
        else
            if (_caps)
                byte[ptr_dest] += ("A"-10)
            else
                byte[ptr_dest] += ("a"-10)
        ++ptr_dest
        num := (num / base)
    until (num == 0)
    byte[ptr_dest] := NUL                        ' trailing null
    reverse(sorg)

PUB itoabp(num, ptr_dest, base, digits, pad_ch): ptr | numlen, byte tmp[33]
' Convert number (unsigned) in base to string representation, with padding
'   num: integer value to convert
'   ptr_dest: string to copy output to
'   base: base/radix of number to copy to string
'       (e.g., itoabp($beef, @mystr, 16, 8, "0") would copy the number $beef to mystr
'           as a 0-padded (to 8 places) string in base-16, or hex: $0000beef)
'   digits: number of digits to pad number string with (or to truncate to)
'   pad_ch: character to pad digits with (e.g., " ", "0", etc)
    itoab(num, @tmp, base)
    numlen := strsize(@tmp)
    if ( digits < numlen )
        { number of digits called for is shorter than the number, so truncate most-significant
            digits of the number }
        bytemove(ptr_dest, @tmp+(numlen-digits), digits)
    else
        repeat digits-numlen                    ' output enough pad chars to make up the length
            byte[ptr_dest++] := pad_ch
        bytemove(ptr_dest, @tmp, numlen)
    return @tmp

PUB itoap(num, ptr_dest, digits, pad_ch): ptr | numlen, byte tmp[33]
' Convert number (signed) to string representation, with padding
'   num: integer value to convert
'   ptr_dest: string to copy output to
'   digits: number of digits to output (number will be padded to this width)
'   pad_ch: character to pad digits with (e.g., " ", "0", etc)
'   Returns: pointer to converted string
    if ( digits )                                   ' do something only if digits isn't 0
        itoa(num, @tmp)
        numlen := strsize(@tmp)
        if ( digits < numlen )
            { number of digits called for is shorter than the number, so truncate most-significant
                digits of the number }
            bytemove(ptr_dest, @tmp+(numlen-digits), digits)
        else
            repeat digits-numlen                    ' output enough pad chars to make up the length
                byte[ptr_dest++] := pad_ch
            bytemove(ptr_dest, @tmp, numlen)
    return @tmp

PUB left(ptr_str, count, clr_a=true): ptr_new
' Copy left-most characters
'   ptr_str: source string
'   count: left-most number of chars from source to copy
'   clr_a: (optional) flag indicating the scratch/working buffer should be cleared after
'       (default is true if unspecified)
'   Returns: pointer to substring
    return mid(ptr_str, 0, count, clr_a)

PUB mactostr(ptr_mac): ptr | tmp, i
' Convert 6-byte array to colon-delimited (":") string representation of a MAC address
'   ptr_mac: pointer to 6-byte array containing integer representation of MAC address
'   Returns: pointer to string
    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)
    repeat i from 0 to 5
        itoabp( byte[ptr_mac][i], ...           ' copy each byte to
                @_tmp_buff+strsize(@_tmp_buff), ...   '   the end of the string
                IHEX, ...                       ' we want hexadecimal/base-16
                2, ...                          ' pad width
                "0")                            ' pad with 0's
        if ( i < 5 )
            append(@_tmp_buff, @":")
    return @_tmp_buff

PUB match(ptr_str1, ptr_str2): ismatch
' Flag indicating strings match
'   ptr_str1, ptr_str2: strings to test
'   Returns:
'       TRUE (-1) if string match, FALSE (0) otherwise
    return (compare(ptr_str1, ptr_str2, true) == 0)


PUB mid(ptr_str, start, len, clr_a=true): p_new
' Copy substring of characters
'   ptr_str: source string
'   start: offset within source string to start copying
'   len: number of chars from (ptr_str+start) to copy
'   clr_a: (optional) flag indicating the scratch/working buffer should be cleared after
'       (default is true if unspecified)
'   Returns: pointer to substring, or -1 if the string is too large to fit in the scratch buffer
    if ( (_ptr + len) => FIELDSZ_MAX )
        return -1                               ' error: not enough space in working buffer

    p_new := @_tmp_buff+_ptr                    ' adjust for current working buffer pointer
    bytemove(p_new, (ptr_str + start), len)     ' copy the substring into it
    byte[p_new][len] := NUL                     ' null-terminate it
    _ptr += len+1                               ' advance pointer by substr length + null

    if ( clr_a )
        clear_scratch_buff()                    ' clear the scratch buffer if asked (default: yes)


PUB replace(ptr_str, ptr_substr, ptr_newsubstr): ptr_next | size
' Replace the first occurrence of a string
'   ptr_str: string to find substrings to replace
'   ptr_substr: string to replace
'   ptr_newsubstr: string to replace existing string with
'   Returns:
'       pointer to next character after string of characters replaced
'       zero, if none replaced
'   NOTE: Will not enlarge or shrink a string of characters
    ptr_next := find(ptr_str, ptr_substr)
    if (ptr_next)
        size := strsize(ptr_newsubstr) <# strsize(ptr_substr)
        bytemove(ptr_next, ptr_newsubstr, size)
        ptr_next += size

PUB replaceall(ptr_str, ptr_substr, ptr_newsubstr)
' Replace all occurrences of a string
'   ptr_str: string to find substrings to replace
'   ptr_substr: string to replace
'   ptr_newsubstr: string to replace existing string with
'   NOTE: Will not enlarge or shrink a string of characters
    repeat while(ptr_str)
        ptr_str := replace(ptr_str, ptr_substr, ptr_newsubstr)

PUB replaceallchars(ptr_str, char, newchar)
' Replace all occurences of character
'   ptr_str: string to find chars to replace
'   char: character to replace
'   newchar: character to replace existing char with
    repeat while(ptr_str)
        ptr_str := replacechar(ptr_str, char, newchar)

PUB replacechar(ptr_str, char, newchar): ptr_next
' Replace the first occurence of character
'   ptr_str: string to find char to replace
'   char: character to replace
'   newchar: character to replace existing char with
'   Returns:
'       pointer to the next character after the character replaced
'       zero, if none replaced
    ptr_next := findchar(ptr_str, char)
    if (ptr_next)
        byte[ptr_next++] := newchar

PUB reverse(ptr_str) | c, k
' Reverse string in place
'   ptr_str: string to reverse
    k := ptr_str + strsize(ptr_str) - 1               ' address of last character
    repeat while (ptr_str < k)
        c := byte[ptr_str]
        byte[ptr_str++] := byte[k]
        byte[k--] := c

PUB right(ptr_str, count, clr_a=true): ptr_new
' Copy rightmost characters
'   ptr_str: source string
'   count: right-most number of chars from source to copy
'   clr_a: (optional) flag indicating the scratch/working buffer should be cleared after
'       (default is true if unspecified)
'   Returns: pointer to substring
    return mid(ptr_str, strsize(ptr_str) - count, count, clr_a)

PUB sprintf(ptr_str, fmt, ptr_args): index | pad, len, maxlen, minlen, bi, leftj, strtype, sorg, arg
' Print string to buffer, with specified formatting
'   ptr_str: string to copy format to
'   fmt: formatting specification
'   ptr_args: pointer to arguments used in formatting specification
'
'   Escape codes:
'       \\: backslash
'       \t: tab
'       \n: line-feed (next line, same column)
'       \r: carriage-return (first column of current line)
'           (combine \n\r for start of next line)
'       \###: 3-digit/1-byte octal code for non-printable chars (e.g., \033 for ESC)
'
'   Formatting specifiers:
'       %%: percent-sign
'       %c: character
'       %d, %i: decimal (signed)
'       %b: binary
'       %o: octal
'       %u: decimal (unsigned)
'       %x, %X: hexadecimal (lower-case, upper-case)
'       %f: IEEE-754 float (not yet implemented)
'       %s: string
'
'   Optionally precede formatting spec letter with the following:
'       0: pad numbers with zeroes (e.g., %0d for zero-padded decimal)
'           (default padding character is space, when padding is necessary)
'       #.#: minimum field width.maximum field width (e.g. %2.5d for decimal with 2..5 digits)
'       -: left-justify (e.g. %-4.8x for left-justified hex with 4..8 digits)
    arg := long[ptr_args]
    ptr_args += 4
    sorg := ptr_str                             ' save start addr of output buffer
    len := 0
    repeat while byte[fmt] <> NUL               ' keep going until end of string
        if (byte[fmt] <> "%")
            if (byte[fmt] <> "\")               ' escape codes
                byte[ptr_str++] := byte[fmt++]
            else
                fmt++
                case byte[fmt]
                    "\":
                        byte[ptr_str++] := "\"  ' backslash (literal)
                        fmt++
                    "t":
                        byte[ptr_str++] := TB
                        fmt++
                    "n":
                        byte[ptr_str++] := LF
                        fmt++
                    "r":
                        byte[ptr_str++] := CR
                        fmt++
                    "0".."3":                   ' octal number (byte)
                        bi := 0
                        repeat 3                ' only process 3 digits
                            if ( ctype.isdigit(byte[fmt]) )
                                _tmp_buff[bi++] := byte[fmt++]
                        _tmp_buff[bi] := NUL
                        byte[ptr_str++] := atoib(@_tmp_buff, IOCT)
                    other:
                        byte[ptr_str++] := "\"  ' output skipped backslash
                        byte[ptr_str++] := byte[fmt++]
            next
        else
            fmt++
        if (byte[fmt] == "%")
            byte[ptr_str++] := byte[fmt++]      ' % (literal)
            next
        if (byte[fmt] == "-")                   ' leftj-justify
            leftj := true
            ++fmt                               ' skip -
        else
            leftj := false
        if (byte[fmt] == "0")                   ' set pad char to '0'
            pad := "0"
        else
            pad := " "                          ' set pad char to ' '
        if ( ctype.isdigit(byte[fmt]) )         ' minimum field width
            bi := 0
            repeat while ctype.isdigit(byte[fmt])
                _tmp_buff[bi++] := byte[fmt++]
            _tmp_buff[bi] := NUL
            minlen := atoi(@_tmp_buff)
        else
            minlen := 0
        if (byte[fmt] == ".")                   ' maximum field width
            ++fmt                               ' skip .
            bi := 0
            repeat while ctype.isdigit(byte[fmt])
                _tmp_buff[bi++] := byte[fmt++]
            _tmp_buff[bi] := NUL
            maxlen := atoi(@_tmp_buff)
        else
            maxlen := 0
        strtype := false                        ' assume no string value
        case byte[fmt++]
            "c":
                _tmp_buff[0] := arg             ' character
                _tmp_buff[1] := NUL
                len := 1
            "d", "i":
                itoa(arg, @_tmp_buff)           ' signed decimal
                len := strsize(@_tmp_buff)
            "b":
                itoab(arg, @_tmp_buff, IBIN)    ' binary
                len := strsize(@_tmp_buff)
            "o":
                itoab(arg, @_tmp_buff, IOCT)    ' octal
                len := strsize(@_tmp_buff)
            "u":
                itoab(arg, @_tmp_buff, IDEC)    ' unsigned decimal
                len := strsize(@_tmp_buff)
            "x":
                itoab(arg, @_tmp_buff, IHEX)    ' hexadecimal
                len := strsize(@_tmp_buff)
            "X":                                ' hexadecimal (upper-case)
                hexcase(1)
                itoab(arg, @_tmp_buff, IHEX)    ' hexadecimal
                len := strsize(@_tmp_buff)
            "f":                                ' IEEE-754 floating point
                _tmp_buff[0] := NUL             '   (not yet implemented)
                len := 0
            "s":
                strtype := true
                len := strsize(arg)             ' string
            other:
                _tmp_buff[0] := NUL             ' no valid format specifier
                len := 0
        if (maxlen <> 0) and (maxlen < len)
            len := maxlen
        if (minlen > len)
            minlen := minlen - len
        else
            minlen := 0
        bi := 0
        if (leftj == false)
            if (_tmp_buff[bi] == "-") and (pad == "0")
                byte[ptr_str++] := _tmp_buff[bi++]
                len--
            repeat while (minlen > 0)
                minlen--
                byte[ptr_str++] := pad
        repeat while (len > 0)
            len--
            if (strtype == false)
                { copy ASCII string of value }
                byte[ptr_str++] := _tmp_buff[bi++]
            else
                if (byte[arg] == NUL)
                    quit
                { copy string argument }
                byte[ptr_str++] := byte[arg++]
        if (leftj == true)
            repeat while (minlen > 0)
                minlen--
                byte[ptr_str++] := pad
        arg := long[ptr_args]                   ' get next arg
        ptr_args += 4
    return ptr_str-sorg

PUB sprintf1(str, fmt, arg1): idx
' 1-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB sprintf2(str, fmt, arg1, arg2): idx
' 2-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB sprintf3(str, fmt, arg1, arg2, arg3): idx
' 3-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB sprintf4(str, fmt, arg1, arg2, arg3, arg4): idx
' 4-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB sprintf5(str, fmt, arg1, arg2, arg3, arg4, arg5): idx
' 5-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB sprintf6(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6): idx
' 6-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB sprintf7(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7): idx
' 7-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB sprintf8(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8): idx
' 8-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB sprintf9(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9): idx
' 9-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB sprintf10(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10): idx
' 10-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB startswith(ptr_str, ptr_substr): flag
' Flag indicating string at ptr_str starts with the string at ptr_substr
'   Returns:
'       TRUE (-1): ptr_substr starts with ptr_substr
'       FALSE (0): ptr_substr doesn't start with ptr_substr
    return (ptr_str == find(ptr_str, ptr_substr))

PUB strip(ptr_str): ptr_new
' Remove white space and new lines around the outside of a string
'   ptr_str: string to remove whitespace from
'   Returns: pointer to the trimmed string
'   NOTE: Removes ASCII 8..13, 32, 127
    ptr_new := ignorespace(ptr_str)
    ptr_str := (ptr_new + ((strsize(ptr_new) - 1) #> 0))

    repeat
        case byte[ptr_str]
            BS..CR, " ", DEL:
                byte[ptr_str--] := NUL
            other:
                quit

PUB stripchar(ptr_str, stripchr): newstr | chr, idx, sz, nextchr, lastchr, movecnt, mcnt
' Strip all occurrences of stripchr from string
'   ptr_str: string to remove characters from
'   stripchr: character to remove from string
'   Returns: pointer to modified string
    mcnt := 0
    longfill(@chr, 0, 6)
    sz := strsize(ptr_str)
    repeat idx from 0 to sz-1
        chr := ptr_str+idx                      ' current working char
        case byte[chr]
            stripchr:                           ' matches char to strip
                mcnt++                          ' count matches found
                nextchr := chr+1                ' start pos of string to move
                lastchr := sz-1                 ' offset of very last char
                movecnt := (lastchr-idx)        ' = # bytes in string to move
                { starting with the next character, move the remains left,
                   over the the matched stripchr }
                bytemove(chr, nextchr, movecnt)
            other:                              ' some other char? skip it
                next
    { clear out after the end of the newly modified string }
    bytefill(ptr_str+sz-mcnt, 0, mcnt)
    return ptr_str

PUB strtoip(ptr): ip | o
' Convert string "dotted-quad" representation to a 32-bit IP address
'   ptr: pointer to string representation of IP address
'   Returns: 32-bit IP address (LSB-first)
    repeat o from 0 to 3
        ip.byte[o] := atoi( getfield(ptr, o, ".") )

PUB strtomac(pstr, dest): ptr_mac | o
' Convert string representation of a MAC address to the equivalent array of integers
'   pstr: pointer to MAC address string (e.g., @"01:02:03:04:05:06" )
'   dest: destination to copy the byte array to
'   Returns: pointer to start of integer/byte array
    repeat o from 0 to 5
        byte[dest][o] := atoib( getfield(pstr, o, ":"), ...
                                IHEX )          ' convert each hex number
    return dest

PUB tokenize(ptr_str): ptr_strtok
' Remove white space and new lines around the inside of string at ptr_str
'   ptr_str: pointer to a string of characters to be tokenized,
'       or null to continue tokenizing a string of characters
'   Returns: pointer to the tokenized string of characters,
'       or null when out of tokenized strings of characters
    if (ptr_str)
        _tokenstr := ptr_str

    _tokenstr := ignorespace(_tokenstr)

    if (strsize(_tokenstr))
        ptr_strtok := _tokenstr

    repeat while (byte[_tokenstr])
        case byte[_tokenstr++]
            BS..CR, " ", DEL:
                byte[_tokenstr - 1] := NUL
                quit

PUB tolower(ptr_str): ptr_new
' Convert all uppercase characters in string at ptr_str to lowercase
'   NOTE: This function operates on the original string and does not
'       make a copy
    ptr_new := ptr_str
    repeat strsize(ptr_str)
        byte[ptr_str++] := ctype.tolower(byte[ptr_str])

PUB toupper(ptr_str): ptr_new
' Convert all lowercase characters in string at ptr_str to uppercase
    ptr_new := ptr_str
    repeat strsize(ptr_str)
        byte[ptr_str++] := ctype.toupper(byte[ptr_str])

PRI ignorespace(ptr_str): ptr_new

    ptr_new := ptr_str
    repeat strsize(ptr_str--)
        case byte[++ptr_str]
            BS..CR, " ", DEL:
            other:
                return ptr_str

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
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

