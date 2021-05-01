{
    --------------------------------------------
    Filename: CommandLine.spin
    Author: Brett Weir
    Description: Simulated commandline interface
    Copyright (c) 2021
    Started Jan 8, 2016
    Updated May 1, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

' -- User-modifiable constants
    SER_BAUD    = 115_200

' --
    MAX_LINE    = 40
    MAX_CMDS    = 10

OBJ

    term    : "com.serial.terminal.ansi"
    str     : "string"
    time    : "time"

VAR

    long _argc
    word _argv[MAX_CMDS]                        ' max 10 arguments
    byte _line[MAX_LINE]
    byte _prompt[70]
    byte _directory[64]

PUB Main{}

    term.start(SER_BAUD)
    time.msleep(30)
    term.clear{}

    setdir(string("~"))

    term.str(@data_signon)

    repeat
        term.flush{}
        term.str(@_prompt)

        term.readline(@_line, MAX_LINE)
        term.newline{}
        if process(@_line)
            term.str(@data_usage)
            next

PUB Process(s)

    _argc := 0
    _argv[_argc] := str.tokenize(s)
    repeat while _argv[_argc]
        _argv[++_argc] := str.tokenize(0)

    if _argc < 1
        return

    if match(_argv[0], string("ls"))
        liststuff{}

    elseif match(_argv[0], string("cd"))
        changedir{}

    elseif match(_argv[0], string("pwd"))
        printworkingdirectory{}

    elseif match(_argv[0], string("bizz"))
        bizz{}

    elseifnot str.compare(_argv[0], string("help"), false)
        return true

    else
        term.str(string("Bad command or file name!", term#CR, term#LF))


PUB PrintWorkingDirectory{}

    term.str(@_directory)
    term.newline{}

PUB ListStuff{} | i

    if match(@_directory, string("~/another"))
        term.str(@data_dir2)
    else
        term.str(@data_dir1)

PUB ChangeDir{} | i

    if match(@_directory, string("~"))

        if match(_argv[1], string("another")) or match(_argv[1], string("another/"))
            setdir(string("~/another"))
        else
            term.strln(string("Not a directory!"))

    elseif match(@_directory, string("~/another"))

        if match(_argv[1], string(".."))
            setdir(string("~"))
        else
            term.strln(string("Not a directory!"))

    elseif str.isempty(_argv[1]) or match(_argv[1], string("~"))

        setdir(string("~"))
        term.strln(string("Not a directory!"))

PRI SetDir(d)

    str.copy(@_directory, d)
    setprompt{}

PUB Bizz{} | ran

    ran := cnt

    term.strln(string("RUNNING BIZZ BANG 4.0 in"))
    term.strln(string("3..."))

    time.msleep(500)

    term.strln(string("2..."))

    time.msleep(500)

    term.strln(string("1..."))

    time.msleep(500)

    repeat 1000
        term.char(((ran? & $FF) // 64) + 32)
        repeat 100

PUB SetPrompt{}

    str.copy(@_prompt, string("user@propeller:"))
    str.append(@_prompt, @_directory)
    str.append(@_prompt, string("$ "))

PRI Match(s1, s2)

    return (str.compare(s1, s2, true) == 0)

DAT

data_usage
    byte    "Commands:", term#CR, term#LF
    byte    "   ls      list files", term#CR, term#LF
    byte    "   pwd     print working directory", term#CR, term#LF
    byte    "   cd      change directory", term#CR, term#LF
    byte    "   bizz    frobnicate the bar library", term#CR, term#LF
    byte    term#CR, term#LF,0

data_dir1
    byte    "another/", term#CR, term#LF
    byte    "coolmusic.mp3", term#CR, term#LF
    byte    "file1.txt", term#CR, term#LF
    byte    "file2.txt", term#CR, term#LF
    byte    0

data_dir2
    byte    "..", term#CR, term#LF
    byte    "morestuff.txt", term#CR, term#LF
    byte    0

data_signon
    byte    "Type 'help' for commands", term#CR, term#LF
    byte    0

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

