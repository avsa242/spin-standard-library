{
    --------------------------------------------
    Filename: string.new.spin
    Author: Jesse Burt
    Description: String processing and formatting
    Copyright (c) 2022
    Started May 29, 2022
    Updated Jul 12, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on code originally written by the following sources:
        Parallax, inc.
        Eric Smith
        Dave Hein
        Peter Verkaik
}

{ if a maximum buffer size isn't defined at build-time, default to 100 bytes }
#ifndef FIELDSZ_MAX
#define FIELDSZ_MAX 100
#endif

#include "termcodes.spinh"

CON

    IBIN    = 2
    IOCT    = 8
    IDEC    = 10
    IHEX    = 16

OBJ

    ctype  : "char.type.new"

VAR

    word _tokenstr

    { scratch buffer for integer conversions }
    byte _tmp_buff[FIELDSZ_MAX]

    byte _caps

PUB Append(ptr_dest, ptr_src): ptr_new
' Append ptr_src string to the end of ptr_dest string
'   Returns: pointer to the new string
'   NOTE: Destination string must be larger or equal to size of ptr_src
'       string to prevent memory corruption.
    bytemove((ptr_dest + strsize(ptr_dest)), ptr_src, (strsize(ptr_src) + 1))
    return ptr_dest

PUB AtoI(ptr_str): val | sign, n
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

PUB AtoIb(ptr_str, base): val | n, digit
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

PUB Bin(val, digits): bin_str
' Convert binary value to string representation
    itoab(val, @_tmp_buff, IBIN)
    return @_tmp_buff

PUB Clear(ptr_str)
' Clear string (fill with 0/NUL)
    fill(ptr_str, NUL)

PUB Compare(ptr_str1, ptr_str2, case_s): cmpres
' Compare two strings
'   ptr_str1, ptr_str2: strings to compare
'   case_s: case-sensitive comparison
'       non-zero: case-sensitive
'       zero: not case-sensitive
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

PUB Copy(ptr_dest, ptr_src): ptr_new
' Copy a string from ptr_src to ptr_dest
'   ptr_dest: destination to copy to
'   ptr_src: source to copy from
'   Returns: pointer to the new string
'   NOTE: Destination string must be larger or equal to size of ptr_src string
    bytemove(ptr_dest, ptr_src, (strsize(ptr_src) + 1))
    return ptr_dest

PUB Dec(val): dec_str
' Convert decimal value to string representation
'   val: value to convert
'   Returns: pointer to string representation of value
    itoa(val, @_tmp_buff)
    return @_tmp_buff

PUB EndsWith(ptr_str, ptr_substr): ends
' Check if the string ptr_str ends with string ptr_substr
'   ptr_str: string to check
'   ptr_substr: string to look for at end of ptr_str
'   Returns:
'       TRUE (-1): ptr_str ends with ptr_substr
'       FALSE (0): ptr_str doesn't end with ptr_substr
    ends := (ptr_str + strsize(ptr_str) - strsize(ptr_substr))
    return (ends == find(ends, ptr_substr))

PUB Fill(ptr_str, char)
' Fill string with char
'   ptr_str: string to fill
'   char: character to fill string with
    bytefill(ptr_str, char, strsize(ptr_str))
    byte[ptr_str + strsize(ptr_str)] := NUL     ' null-terminate
    return ptr_str

PUB Find(ptr_str, ptr_srchstr): ptr_match | i, srch_sz, mismatch
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

PUB FindChar(ptr_str, char)
' Find first occurrence of character in string
'   Returns: pointer to character within ptr_str if found, or 0 if not found
    repeat strsize(ptr_str--)
        if (byte[++ptr_str] == char)
            return ptr_str

PUB GetField(ptr_str, field_nr, delim): ptr_flddata | char, i_idx, o_idx, cur_field
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

PUB GetFieldCount(ptr_str, delim): nr_flds | char, idx
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

PUB Hex(val, digits): hex_str
' Convert hexadecimal value to string representation
    itoab(val, @_tmp_buff, IHEX)
    return @_tmp_buff

PUB HexCase(hcase)
' Set case for hexadecimal number string generation
'   Valid values:
'       non-zero: upper-case
'       zero: lower-case
    _caps := hcase

PUB Hexs(val, digits) | idx
' Convert hexadecimal value to string representation (small/standalone implementation)
'   Returns: pointer to string
    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)
    idx := 0
    digits := 1 #> digits <# 8
    val <<= (8 - digits) << 2                   ' prep most significant digit
    repeat digits
        _tmp_buff[idx++] := lookupz((val <-= 4) & $F : "0".."9", "A".."F")
    return @_tmp_buff

PUB IsAlpha(ptr_str): flag
' Flag indicating entire string is alphabetic
'   Returns:
'       TRUE (-1) if string contains only alphabetic chars, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isalpha(byte[ptr_str++]))
            return false

    return true

PUB IsAlphaNum(ptr_str): flag
' Flag indicating entire string is alphanumeric
'   Returns:
'       TRUE (-1) if string contains only alphanumeric chars, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isalphanumeric(byte[ptr_str++]))
            return false

    return true

PUB IsDigit(ptr_str): flag
' Flag indicating entire string is decimal
'   Returns:
'       TRUE (-1) if string contains only decimal digit(s), FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isdigit(byte[ptr_str++]))
            return false

    return true

PUB IsEmpty(ptr_str): empty
' Flag indicating string contains no characters
'   Returns:
'       TRUE (-1) if string is empty, FALSE (0) otherwise
    return (strsize(ptr_str) == 0)

PUB IsLower(ptr_str): flag
' Flag indicating entire string is lowercase
'   Returns:
'       TRUE (-1) if string contains only lowercase chars, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.islower(byte[ptr_str++]))
            return false

    return true

PUB IsSpace(ptr_str):flag
' Flag indicating entire string is whitespace
'   Returns:
'       TRUE (-1) if string contains only whitespace, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isspace(byte[ptr_str++]))
            return false

    return true

PUB IsUpper(ptr_str): flag
' Flag indicating entire string is uppercase
'   Returns:
'       TRUE (-1) if string contains only uppercase chars, FALSE (0) otherwise
    repeat strsize(ptr_str)
        ifnot (ctype.isupper(byte[ptr_str++]))
            return false

    return true

PUB ItoA(num, ptr_str) | str0, dvsr, temp
' Convert number (signed) to string representation
'   num: integer value to convert
'   ptr_str: string to copy output to
    str0 := ptr_str
    if (num < 0)
        byte[ptr_str++] := "-"
        if (num == $80000000)
            byte[ptr_str++] := "2"
            num += 2_000_000_000
        num := -num
    elseif (num == 0)
        byte[ptr_str++] := "0"
        byte[ptr_str] := 0
        return 1
    dvsr := 1_000_000_000
    repeat while (dvsr > num)
        dvsr /= 10
    repeat while (dvsr > 0)
        temp := num / dvsr
        byte[ptr_str++] := temp + "0"
        num -= temp * dvsr
        dvsr /= 10
    byte[ptr_str++] := 0
    return ptr_str - str0 - 1

PUB ItoAb(num, ptr_str, base) | lowbit, sorg
' Convert number (unsigned) in base to string representation
'   num: integer value to convert
'   ptr_str: string to copy output to
'   base: base/radix of number to copy to string
'       (e.g., ItoAb(32, @mystr, 16) would copy the number 32 to mystr
'           as a string in base-16, or hex: 1F)
    sorg := ptr_str
    base := (base >> 1) & $f
    repeat                                      ' generate digits/letters in reverse order
        lowbit := (num & 1)
        num := (num >> 1) & $7FFFFFFF
        byte[ptr_str] := ( (num // base) << 1 ) + lowbit
        if (byte[ptr_str] < 10)
            byte[ptr_str] += "0"
        else
            if (_caps)
                byte[ptr_str] += ("A"-10)
            else
                byte[ptr_str] += ("a"-10)
        ++ptr_str
        num := (num / base)
    until (num == 0)
    byte[ptr_str] := NUL                        ' trailing null
    reverse(sorg)

PUB Left(ptr_str, count): ptr_new
' Copy left-most characters
'   ptr_str: source string
'   count: left-most number of chars from source to copy
'   Returns: pointer to substring
    return mid(ptr_str, 0, count)

PUB Match(ptr_str1, ptr_str2): ismatch
' Flag indicating strings match
'   ptr_str1, ptr_str2: strings to test
'   Returns:
'       TRUE (-1) if string match, FALSE (0) otherwise
    return (compare(ptr_str1, ptr_str2, true) == 0)

PUB Mid(ptr_str, start, count): ptr_new
' Copy substring of characters
'   ptr_str: source string
'   start: offset within source string to start copying
'   count: number of chars from ptr_src to copy
'   Returns: pointer to substring
    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)        ' clear working buffer
    bytemove(@_tmp_buff, (ptr_str + start), count)
    _tmp_buff[count] := 0
    return @_tmp_buff

PUB Replace(ptr_str, ptr_substr, ptr_newsubstr): ptr_next | size
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

PUB ReplaceAll(ptr_str, ptr_substr, ptr_newsubstr)
' Replace all occurrences of a string
'   ptr_str: string to find substrings to replace
'   ptr_substr: string to replace
'   ptr_newsubstr: string to replace existing string with
'   Returns:
'       pointer to next character after string of characters replaced
'       zero, if none replaced
'   NOTE: Will not enlarge or shrink a string of characters
    repeat while(ptr_str)
        ptr_str := replace(ptr_str, ptr_substr, ptr_newsubstr)

PUB ReplaceAllChars(ptr_str, char, newchar)
' Replace all occurences of character
'   ptr_str: string to find chars to replace
'   char: character to replace
'   newchar: character to replace existing char with
    repeat while(ptr_str)
        ptr_str := replacechar(ptr_str, char, newchar)

PUB ReplaceChar(ptr_str, char, newchar): ptr_next
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

PUB Reverse(ptr_str) | c, k
' Reverse string in place
'   ptr_str: string to reverse
    k := ptr_str + strsize(ptr_str) - 1               ' address of last character
    repeat while (ptr_str < k)
        c := byte[ptr_str]
        byte[ptr_str++] := byte[k]
        byte[k--] := c

PUB Right(ptr_str, count): ptr_new
' Copy rightmost characters
'   ptr_str: source string
'   count: right-most number of chars from source to copy
'   Returns: pointer to substring
    return mid(ptr_str, strsize(ptr_str) - count, count)

PUB SPrintF(ptr_str, fmt, ptr_args): index | pad, len, maxlen, minlen, bi, leftj, strtype, sorg, arg
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

PUB SPrintF1(str, fmt, arg1): idx
' 1-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB SPrintF2(str, fmt, arg1, arg2): idx
' 2-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB SPrintF3(str, fmt, arg1, arg2, arg3): idx
' 3-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB SPrintF4(str, fmt, arg1, arg2, arg3, arg4): idx
' 4-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB SPrintF5(str, fmt, arg1, arg2, arg3, arg4, arg5): idx
' 5-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB SPrintF6(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6): idx
' 6-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB SPrintF7(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7): idx
' 7-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB SPrintF8(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8): idx
' 8-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB SPrintF9(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9): idx
' 9-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB SPrintF10(str, fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10): idx
' 10-argument variant of sprintf()
    return sprintf(str, fmt, @arg1)

PUB StartsWith(ptr_str, ptr_substr): starts
' Flag indicating string at ptr_str starts with the string at ptr_substr
'   Returns:
'       TRUE (-1): ptr_substr starts with ptr_substr
'       FALSE (0): ptr_substr doesn't start with ptr_substr
    return (ptr_str == find(ptr_str, ptr_substr))

PUB Strip(ptr_str): ptr_new
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

PUB StripChar(ptr_str, stripchr): newstr | chr, idx, sz, nextchr, lastchr, movecnt, mcnt
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

PUB Tokenize(ptr_str): ptr_strtok
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

PUB ToLower(ptr_str): ptr_new
' Convert all uppercase characters in string at ptr_str to lowercase
'   NOTE: This function operates on the original string and does not
'       make a copy
    ptr_new := ptr_str
    repeat strsize(ptr_str)
        byte[ptr_str++] := ctype.tolower(byte[ptr_str])

PUB ToUpper(ptr_str): ptr_new
' Convert all lowercase characters in string at ptr_str to uppercase
    ptr_new := ptr_str
    repeat strsize(ptr_str)
        byte[ptr_str++] := ctype.toupper(byte[ptr_str])

PRI IgnoreSpace(ptr_str): ptr_new

    ptr_new := ptr_str
    repeat strsize(ptr_str--)
        case byte[++ptr_str]
            BS..CR, " ", DEL:
            other:
                return ptr_str

{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

