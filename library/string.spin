{
    --------------------------------------------
    Filename: string.spin
    Description: String manipulation functions
    Started Jan 5, 2016
    Updated May 31, 2021
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on ASCII0_STREngine.spin,
        originally by Kwabena W. Agyeman, J. Moxham
}

CON

#ifndef FIELDSZ_MAX
#define FIELDSZ_MAX 32
#endif

OBJ

    cc : "char.type"

VAR

    word _tokenstr
    byte _tmp_buff[FIELDSZ_MAX]

PUB Null{}
' This is not a top-level object

PUB Append(ptr_dest, ptr_src): ptr_new
' Append `ptr_src` string to the end of `ptr_dest` string
'   Returns: pointer to the new string
'   NOTE: Destination string must be larger or equal to size of ptr_src
'       string to prevent memory corruption.

    bytemove((ptr_dest + strsize(ptr_dest)), ptr_src, (strsize(ptr_src) + 1))
    return ptr_dest

PUB Clear(ptr_str)
' Clear string (fill with 0/NUL)
    fill(ptr_str, 0)

PUB Compare(ptr_str1, ptr_str2, casesensitive): cmpres
' Compare two strings
'   `casesensitive`
'       TRUE (-1): case-sensitive comparison
'       FALSE (0): case-insensitive comparison
' Returns:
'   zero if the two strings are equal
'   positive value if `ptr_str1` comes after `ptr_str2`
'   negative value if `ptr_str1` comes before `ptr_str2`
    if casesensitive
        repeat
            cmpres := (byte[ptr_str1] - byte[ptr_str2++])
        while(byte[ptr_str1++] and (not(cmpres)))
    else
        repeat
            cmpres := (cc.Lower(byte[ptr_str1]) - cc.Lower(byte[ptr_str2++]))
        while(byte[ptr_str1++] and (not(cmpres)))

PUB Copy(ptr_dest, ptr_src): ptr_new
' Copy a string from ptr_src to ptr_dest
'   Returns: pointer to the new string
'   NOTE: Destination string must be larger or equal to size of ptr_src string
    bytemove(ptr_dest, ptr_src, (strsize(ptr_src) + 1))
    return ptr_dest

PUB EndsWith(ptr_str, ptr_substr): ends | end
' Check if the string `ptr_str` ends with string `ptr_substr`
'   Returns:
'       TRUE (-1): yes
'       FALSE (0): no
    end := ptr_str + strsize(ptr_str) - strsize(ptr_substr)
    return (end == find(end, ptr_substr))

PUB Fill(ptr_str, char)
' Fill string with `char`
    bytefill(ptr_str, char, strsize(ptr_str))
    byte[ptr_str + strsize(ptr_str)] := 0
    return ptr_str

PUB Find(ptr_str, ptr_srchstr): ptr_match | i, srch_sz, mismatch
' Search string at `ptr_str` for the first occurrence of `ptr_srchstr`
'   Returns: pointer to string of characters if found, or 0 if not found
    ptr_match := mismatch := 0                  ' initialize vars to 0
    srch_sz := strsize(ptr_srchstr)             ' get size of search string
    if (srch_sz--)
        repeat strsize(ptr_str--)
            if(byte[++ptr_str] == byte[ptr_srchstr])
            ' if the current char in the source string matches the first char
            ' of the search string, then it could be a match
                repeat i from 0 to srch_sz
                ' walk through each char of the source string to see if it
                ' matches the next char of the search string
                    if(byte[ptr_str][i] <> byte[ptr_srchstr][i])
                        mismatch := true        ' no - they're different;
                        quit                    ' set flag: there's no match

                ifnot(mismatch~)                ' flag is clear
                    return ptr_str              ' return updated pointer

PUB FindChar(ptr_str, char)
' Search string at `ptr_str` for first occurrence of `char`
'   Returns: pointer to character within `ptr_str` if found, or 0 if not found
    repeat strsize(ptr_str--)
        if(byte[++ptr_str] == char)
            return ptr_str

PUB GetField(ptr_str, field_nr, delimiter): ptr_flddata | char, i_idx, o_idx, cur_field
' Get field from string containing multiple data separated by delimiter
'   ptr_str: pointer to string to extract field data from
'   field_nr: which field number to return (zero-based)
'   delimiter: character to identify as a field delimiter (e.g., ",")
'
'   Returns: pointer to string containing field data
    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)        ' clear working buffer
    longfill(@char, 0, 4)                       ' initialize in/out indices
    repeat
        char := byte[ptr_str][i_idx++]          ' get current char from ptr_src
        case char
            0:                                  ' NUL - end of string
                quit
            10, 13:                             ' newline
                next
            delimiter:                          ' delimiter char (end of field)
                if cur_field == field_nr        ' found the requested field #?
                    quit
                else                            ' not the right field; clear
                    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)
                    cur_field++                 '   the buffer and keep going
                    o_idx := 0                  ' reset the output index
            other:
                _tmp_buff[o_idx++] := char      ' field text
    return @_tmp_buff

PUB GetFieldCount(ptr_str, delimiter): nr_fields | char, idx
' Get number of delimiter-separated fields in ptr_str
'   ptr_str: pointer to string in which to count number of fields
'   delimiter: character to identify as a field delimiter (e.g., ",")
'
'   Returns:
'       number of fields found in ptr_str (1-based)
'       0, if no fields found (e.g., NUL before a delimiter character was
'           ever encountered)
    idx := 0                                    ' initialize index
    nr_fields := 1
    repeat
        char := byte[ptr_str][idx++]
        case char
            0:                                  ' NUL - end of string
                if nr_fields == 1               ' no delimiter chars found yet
                    nr_fields := 0              ' but NUL found? 0 fields found
                quit
            10, 13:                             ' newline
                next
            delimiter:                          ' sep. character (end of field)
                nr_fields++
            other:
                next

    return nr_fields

PUB IsEmpty(ptr_str): empty
' Flag indicating string at `ptr_str` contains no characters
'   Returns:
'       TRUE (-1) if string is empty, FALSE (0) otherwise
    return (strsize(ptr_str) == 0)

PUB Left(ptr_dest, ptr_src, count): ptr_left
' Copy the `count` leftmost characters of string at `ptr_src` to string
'   at `ptr_dest`
'   Returns: pointer to resulting string
    return mid(ptr_dest, ptr_src, 0, count)

PUB Lower(ptr_str): ptr_new
' Convert all uppercase characters in string at `ptr_str` to lowercase
'   NOTE: This function operates on the original string and does not
'       make a copy
    ptr_new := ptr_str
    repeat strsize(ptr_str)
        byte[ptr_str++] := cc.lower(byte[ptr_str])

PUB Match(ptr_str1, ptr_str2): ismatch
' Flag indicating strings at `ptr_str1` and `ptr_str2` match
'   Returns:
'       TRUE (-1) if string match, FALSE (0) otherwise
    return (compare(ptr_str1, ptr_str2, true) == 0)

PUB Mid(ptr_dest, ptr_src, start, count)
' Return substring of `ptr_src` starting at offset `start` with
'   `count` characters
    bytemove(ptr_dest, ptr_src + start, count)
    byte[ptr_dest + count] := 0
    return ptr_dest

PUB Replace(ptr_str, ptr_substr, ptr_newsubstr): ptr_next | size
' Replace the first occurrence of the string at `ptr_substr` in `ptr_str` with
'   string at `ptr_newsubstr`
'   Returns:
'       pointer to next character after string of characters replaced
'       zero, if failed
'   NOTE: Will not enlarge or shrink a string of characters
    ptr_next := find(ptr_str, ptr_substr)
    if ptr_next
        size := strsize(ptr_newsubstr) <# strsize(ptr_substr)
        bytemove(ptr_next, ptr_newsubstr, size)
        ptr_next += size

PUB ReplaceAll(ptr_str, ptr_substr, ptr_newsubstr)
' Replace all occurrences of the string at `ptr_substr` in `ptr_str` with
'   string at `ptr_newsubstr`
'   NOTE: Will not enlarge or shrink a string of characters
    repeat while(ptr_str)
        ptr_str := replace(ptr_str, ptr_substr, ptr_newsubstr)

PUB ReplaceChar(ptr_str, char, newchar): ptr_next
' Replace the first occurence of character `char` in string at `ptr_str`
'   with `newchar`
'   Returns:
'       pointer to the next character after the character replaced
'       zero, if failed
    ptr_next := findchar(ptr_str, char)
    if ptr_next
        byte[ptr_next++] := newchar

PUB ReplaceAllChars(ptr_str, char, newchar)
' Replace all occurences of character `char` in string at `ptr_str`
'   with `newchar`
    repeat while(ptr_str)
        ptr_str := replacechar(ptr_str, char, newchar)

PUB Right(ptr_dest, ptr_src, count): ptr_right
' Copy the `count` rightmost characters of string at `ptr_src` to `ptr_dest`
'   Returns: pointer to resulting string
    return mid(ptr_dest, ptr_src, strsize(ptr_src) - count, count)

PUB StartsWith(ptr_str, ptr_substr): starts
' Flag indicating string at `ptr_str` starts with the string at `ptr_substr`
'   Returns:
'       TRUE (-1): ptr_substr starts with ptr_substr
'       FALSE (0): ptr_substr doesn't start with ptr_substr
    return (ptr_str == find(ptr_str, ptr_substr))

PUB Strip(ptr_str): ptr_new
' Remove white space and new lines around the outside of string at `ptr_str`
'   Returns: pointer to the trimmed string
'   NOTE: Removes ASCII 8..13, 32, 127
    ptr_new := ignorespace(ptr_str)
    ptr_str := (ptr_new + ((strsize(ptr_new) - 1) #> 0))

    repeat
        case byte[ptr_str]
            8..13, 32, 127:
                byte[ptr_str--] := 0
            other:
                quit

PUB StripChar(ptr_str, stripchr): matchcnt | chr, idx, sz, nextchr, lastchr, movecnt
' Strip all occurrences of `stripchr` from string at `ptr_str`
'   Returns: number of matches found/stripped, or 0
    matchcnt := 0
    longfill(@chr, 0, 6)                        ' initialize variables
    sz := strsize(ptr_str)                      ' size of source string
    repeat idx from 0 to sz-1
        chr := ptr_str+idx                      ' ptr to current working char
        case byte[chr]
            stripchr:                           ' matches char to strip
                matchcnt++                      ' count matches found
                nextchr := chr+1                ' start pos of string to move
                lastchr := sz-1                 ' offset of very last char
                movecnt := (lastchr-idx)        ' = # bytes in string to move
                ' starting with the next character, move the remains left,
                '   over the the matched stripchr
                bytemove(chr, nextchr, movecnt)
                ' clear out after the end of the newly modified string
                bytefill(ptr_str+sz-matchcnt, 0, matchcnt)
            other:                              ' some other char? skip it
                next

PUB Tokenize(ptr_str): ptr_strtok
' Remove white space and new lines around the inside of string at ptr_str
'   ptr_str: pointer to a string of characters to be tokenized,
'       or null to continue tokenizing a string of characters
'   Returns: pointer to the tokenized string of characters,
'       or null when out of tokenized strings of characters
    if ptr_str
        _tokenstr := ptr_str

    _tokenstr := ignorespace(_tokenstr)

    if strsize(_tokenstr)
        ptr_strtok := _tokenstr

    repeat while(byte[_tokenstr])
        case byte[_tokenstr++]
            8 .. 13, 32, 127:
                byte[_tokenstr - 1] := 0
                quit

PUB Upper(ptr_str): ptr_new
' Convert all lowercase characters in string at `ptr_str` to uppercase
    ptr_new := ptr_str
    repeat strsize(ptr_str)
        byte[ptr_str++] := cc.upper(byte[ptr_str])

PRI IgnoreSpace(ptr_str): ptr_new

    ptr_new := ptr_str
    repeat strsize(ptr_str--)
        case byte[++ptr_str]
            8 .. 13, 32, 127:
            other: return ptr_str

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

