{
    --------------------------------------------
    Filename: string.spin
    Description: String manipulation functions
    Started Jan 5, 2016
    Updated Mar 25, 2021
    See end of file for terms of use.
    --------------------------------------------
}

' Derived from ASCII0_STREngine.spin
' Original author: Kwabena W. Agyeman, J Moxham

CON

#ifndef FIELDSZ_MAX
#define FIELDSZ_MAX 32
#endif

OBJ

    cc : "char.type"

VAR

    word _tokenstr
    byte _tmp_buff[FIELDSZ_MAX]

PUB Append(destination, source)
{{
    Append `source` string to the end of `destination` string.

    Returns a pointer to the new string.

    Destination string must be larger or equal to size of source
    string to prevent memory corruption.
}}

    bytemove((destination + strsize(destination)), source, (strsize(source) + 1))
    return destination

PUB Clear(s)

    Fill(s, 0)

PUB Compare(str1, str2, casesensitive)
{{
    Compare two strings.

    - Return zero if the two strings are equal.
    - Return positive value if `str1` comes after  `str2`.
    - Return negative value if `str1` comes before `str2`.

    If `casesensitive` is true, use case-sensitive comparison, or false for case-insensitive.
}}

    if casesensitive
        repeat
            result := (byte[str1] - byte[str2++])
        while(byte[str1++] and (not(result)))
    else
        repeat
            result := (cc.Lower(byte[str1]) - cc.Lower(byte[str2++]))
        while(byte[str1++] and (not(result)))

PUB Copy(destination, source)
{{
    Copies a string from one location to another.

    Returns a pointer to the new string.

    Destination string must be larger or equal to size of source string.
}}

    bytemove(destination, source, (strsize(source) + 1))
    return destination

PUB EndsWith(str, substr) | end
{{
    Checks if the string of characters ends with the specified characters.

    Returns true if yes and false if no.

    str - A pointer to the string of characters to search.
    substr - A pointer to the string of characters to find in the string of characters to search.
}}

    end := str + strsize(str) - strsize(substr)
    return (end == Find(end, substr))

PUB Fill(str, char)
{{
    Fills string with characters.
}}

    bytefill(str, char, strsize(str))
    byte[str + strsize(str)] := 0
    return str

PUB Find(str, substr) | i, size
{{
    Searches a string of characters for the first occurence of the specified string of characters.

    Returns the address of that string of characters if found and zero if not found.

    str - A pointer to the string of characters to search.
    substr - A pointer to the string of characters to find in the string of characters to search.
}}

    size := strsize(substr)
    if(size--)

        repeat strsize(str--)
            if(byte[++str] == byte[substr])

                repeat i from 0 to size
                    if(byte[str][i] <> byte[substr][i])
                        result := true
                        quit

                ifnot(result~)
                    return str

PUB FindChar(str, char)
{{
    Searches a string of characters for the first occurence of the specified character.

    Returns the address of that character if found and zero if not found.

    str - A pointer to the string of characters to search.
    char - The character to find in the string of characters to search.
}}

    repeat strsize(str--)
        if(byte[++str] == char)
            return str

PUB GetField(ptr_str, field_nr, delimiter): ptr_flddata | char, i_idx, o_idx, cur_field
' Get data field_nr from ptr_str
'   ptr_str: pointer to string to extract field data from
'   field_nr: which field number to return (zero-based)
'   delimiter: character to identify as a field delimiter (e.g., ",")
'
'   Returns: pointer to string containing field data
    bytefill(@_tmp_buff, 0, FIELDSZ_MAX)        ' clear working buffer
    longfill(@char, 0, 4)                       ' initialize in/out indices
    repeat
        char := byte[ptr_str][i_idx++]          ' get current char from source
        case char
            0:                                  ' NUL - end of string
                quit
            10, 13:                             ' newline - end of string
                cur_field++
                quit
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
' Get number of fields in ptr_str
'   ptr_str: pointer to string in which to count number of fields
'   delimiter: character to identify as a field delimiter (e.g., ",")
'
'   Returns: number of fields found in ptr_str
    idx := nr_fields := 0                       ' initialize index
    repeat
        char := byte[ptr_str][idx++]
        case char
            0:                                  ' NUL - end of string
                quit
            10, 13:                             ' newline - end of string
                nr_fields++                     '
                quit
            delimiter:                          ' sep. character (end of field)
                nr_fields++
            other:
                next

    return nr_fields

PUB IsEmpty(str)
{{
    Returns true if string contains no characters, otherwise false.
}}

    return (strsize(str) == 0)

PUB Left(destination, source, count)
{{
    returns the left number of characters
}}
    return Mid(destination, source, 0, count)

PUB Lower(str)
{{
    Converts all uppercase characters in string to lowercase.

    Note: This function operates on the original string and does not make a copy.
}}
    result := str
    repeat strsize(str)
        byte[str++] := cc.Lower (byte[str])

PUB Match(s1, s2)
{{
    Returns true if strings match, otherwise false.

    This is a convenience function for Compare(s1, s2).
}}

    return (Compare (s1, s2, true) == 0)

PUB Mid(destination, source, start, count)
{{
    returns strings starting at start with number characters
}}

    bytemove(destination, source + start, count)
    byte[destination + count] := 0
    return destination

PUB Replace(str, substr, newsubstr) | size
{{
    Replaces the first occurence of the specified string of characters in a string of characters with another string of
    characters. Will not enlarge or shrink a string of characters.

    Returns the address of the next character after the string of characters replaced on success and zero on failure.

    str - A pointer to the string of characters to search.
    substr - A pointer to the string of characters to find in the string of characters to search.
    newsubstr - A pointer to the string of characters that will replace the string of characters found in the
                          string of characters to search.
}}

    result := Find(str, substr)
    if result
        size := strsize(newsubstr) <# strsize(substr)
        bytemove(result, newsubstr, size)
        result += size

PUB ReplaceAll(str, substr, newsubstr)
{{
    Replaces all occurences of the specified string of characters in a string of characters with another string of
    characters. Will not enlarge or shrink a string of characters.

    str - A pointer to the string of characters to search.
    substr - A pointer to the string of characters to find in the string of characters to search.
    newsubstr - A pointer to the string of characters that will replace the string of characters found in the
                          string of characters to search.
}}

    repeat while(str)
        str := Replace(str, substr, newsubstr)

PUB ReplaceChar(str, char, newchar)
{{
    Replaces the first occurence of the specified character in a string of characters with another character.

    Returns the address of the next character after the character replaced on success and zero on failure.

    str - A pointer to the string of characters to search.
    char - The character to find in the string of characters to search.
    newchar - The character to replace the character found in the string of characters to search.
}}

    result := FindChar(str, char)
    if result
        byte[result++] := newchar

PUB ReplaceAllChars(str, char, newchar)
{{
    Replaces all occurences of the specified character in a string of characters with another character.

    str - A pointer to the string of characters to search.
    char - The character to find in the string of characters to search.
    newchar - The character to replace the character found in the string of characters to search.
}}

    repeat while(str)
        str := ReplaceChar(str, char, newchar)

PUB Right(destination, source, count)
{{
    Copies the `count` rightmost characters of `source` string to `destination` string.

    Returns resulting string.
}}

    return Mid(destination, source, strsize(source) - count, count)

PUB StartsWith(str, substr)
{{
    Checks if the string of characters starts with the specified characters.
}}
    return (str == Find(str, substr))

PUB Strip(str)
{{
    Removes white space and new lines arround the outside of string of characters.

    Returns a pointer to the trimmed string of characters.
}}

    result := IgnoreSpace(str)
    str := (result + ((strsize(result) - 1) #> 0))

    repeat
        case byte[str]
            8 .. 13, 32, 127: byte[str--] := 0
            other: quit

PUB StripChar(ptr_str, stripchr): matchcnt | chr, idx, sz, nextchr, lastchr, movecnt
' Strip all occurrences of stripchr from string at ptr_str
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

PUB Tokenize(str)
{{
    Removes white space and new lines arround the inside of a string of characters.

    Returns a pointer to the tokenized string of characters, or null when out of tokenized strings of characters.

    str - A pointer to a string of characters to be tokenized, or null to continue tokenizing a string of characters.
}}

    if str
        _tokenstr := str

    _tokenstr := IgnoreSpace(_tokenstr)

    if strsize(_tokenstr)
        result := _tokenstr

    repeat while(byte[_tokenstr])
        case byte[_tokenstr++]
            8 .. 13, 32, 127:
                byte[_tokenstr - 1] := 0
                quit

PUB Upper(str)
{{
    Converts all lowercase characters in string to uppercase.
}}

    result := str
    repeat strsize(str)
        byte[str++] := cc.Upper (byte[str])

PRI IgnoreSpace(str)

    result := str
    repeat strsize(str--)
        case byte[++str]
            8 .. 13, 32, 127:
            other: return str
