{
    --------------------------------------------
    Filename: FINGERPRINT-8552-Demo.spin
    Author: Jesse Burt
    Description: Demo of the Fingerprint reader SKU#8552 driver
    Copyright (c) 2020
    Started May 18, 2020
    Updated Aug 9, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    FPRINT_RX   = 9
    FPRINT_TX   = 8
    FPRINT_BL   = 10
    FPRINT_RST  = 11
    FPRINT_BPS  = 19_200
' --

    PROMPT_X    = 0
    PROMPT_Y    = 20

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    fng     : "input.biometric.fingerprint-8552.uart"

PUB Main | uid, tmp, priv, usercnt, cmplevel, addpolicy, finished, stmp, priv_lvl

    setup

    cmplevel := 5                                           ' (most lenient) 0..9 (most strict)
    addpolicy := fng#PROHIBIT                               ' ALLOW (0), PROHIBIT (1)

    repeat
        ser.clear
        ser.position(0, 3)
        ser.str(string("Total user count: "))
        ser.dec(usercnt := fng.totalusercount)

        ser.position(50, 3)
        fng.comparisonlevel(cmplevel)
        ser.str(string("Comparison level: "))
        ser.dec(fng.comparisonlevel(-2))

        ser.position(50, 4)
        fng.addpolicy(addpolicy)
        ser.str(string("Duplicate print add policy: "))
        addpolicy := fng.addpolicy(-2)
        ser.str(lookupz(addpolicy: string("Allow"), string("Prohibit")))

        ser.position(0, 6)
        ser.str(string("Help:", ser#CR, ser#LF))
        ser.str(string("a, A: Add a fingerprint to the database", ser#CR, ser#LF))
        ser.str(string("l, L: Change comparison level", ser#CR, ser#LF))
        ser.str(string("p, P: Change fingerprint add policy", ser#CR, ser#LF))
        if usercnt
            ser.str(string("d: Delete a specific user from the database", ser#CR, ser#LF))
            ser.str(string("D: Delete all users from the database", ser#CR, ser#LF))
            ser.str(string("u, U: List users with their privilege levels", ser#CR, ser#LF))
            ser.str(string("m: Check fingerprint for match against specific user", ser#CR, ser#LF))
            ser.str(string("M: Check fingerprint for match against any user", ser#CR, ser#LF))
        ser.str(string("q, Q: Quit", ser#CR, ser#LF))

        case ser.CharIn
            "a", "A":
                repeat
                    ser.position(PROMPT_X, PROMPT_Y)
                    ser.str(string("Privilege level for user "))
                    uid := usercnt+1                        ' Get next available user id
                    ser.dec(uid)
                    ser.str(string("? (1..3) > "))
                    priv_lvl := ser.decin
                    ifnot lookdown(priv_lvl: 1..3)
                        quit
                    ser.str(string(" (3 scans will be required)", ser#CR, ser#LF))
                    stmp := fng.addprint(uid, priv_lvl)     ' Scanner requires 3 scans of a fingerprint
                    ser.newline
                    if stmp <> 0                            ' Scan failed for some reason:
                        ser.str(string("Scan was unsuccessful: "))
                        case stmp
                            $01:
                                ser.str(string("Non-specific failure"))
                            $06:
                                ser.str(string("User already exists"))
                            $07:
                                ser.str(string("Fingerprint already exists"))
                            $08:
                                ser.str(string("Timeout"))
                            OTHER:
                                ser.str(string("Exception error (BUG): "))
                                ser.dec(stmp)
                        ser.newline
                        ser.str(string("Retry? (y/n)> "))
                        case ser.charin
                            "y", "Y": finished := FALSE
                            OTHER: finished := TRUE
                    else
                        finished := TRUE
                until finished

            "d":
                if usercnt                                  ' Try to delete _only_ if there's
                    ser.position(PROMPT_X, PROMPT_Y)
                    ser.str(string("Delete user #> "))      '   at least one user stored in the
                    uid := ser.decin                        '   database
                    fng.deleteuser(uid)
                else
                    next

            "D":
                if usercnt
                    ser.position(PROMPT_X, PROMPT_Y)
                    ser.str(string("delete all users", ser#CR, ser#LF))
                    fng.deleteallusers
                else
                    next

            "l", "L":
                ser.position(PROMPT_X, PROMPT_Y)
                ser.str(string("Comparison level? (0..9)> "))
                tmp := ser.decin
                if lookdown(tmp: 0..9)
                    fng.comparisonlevel(cmplevel := tmp)

            "m":
                if usercnt
                    ser.position(PROMPT_X, PROMPT_Y)
                    ser.str(string("Check fingerprint against stored uid# (1.."))
                    ser.dec(usercnt)
                    ser.str(string(") > "))
                    uid := ser.decin
                    ifnot lookdown(uid: 1..usercnt)         ' User ID entered invalid? Skip below code
                        next
                    ser.dec(uid)
                    ser.newline
                    tmp := fng.printmatchesuser(uid)
                    ser.str(lookupz(||(tmp): string("Not a match"), string("Match")))
                    ser.clearline{}
                    ser.newline
                    pressanykey

            "M":
                if usercnt
                    ser.position(PROMPT_X, PROMPT_Y)
                    ser.str(string("Ready to match print to a user: "))
                    if tmp := fng.printmatch
                        ser.dec(tmp)
                    else
                        ser.str(string("Unrecognized"))
                    ser.newline
                    pressanykey

            "p", "P":
                addpolicy ^= 1
                fng.addpolicy(addpolicy)

            "q", "Q":
                ser.str(string("Halting"))
                quit

            "u", "U":
                if usercnt
                    repeat tmp from 1 to usercnt
                        ser.str(string("Privilege for uid "))
                        ser.dec(tmp)
                        ser.str(string(": "))
                        priv := fng.userpriv(tmp)
                        ser.dec(priv)
                        ser.newline
                    pressanykey

            OTHER:

    flashled(led, 100)

PRI PressAnyKey

    ser.str(string("Press any key to return"))
    repeat until ser.charin

PUB Setup

    repeat until ser.start (115_200)
    time.msleep(30)
    ser.clear
    ser.str(string("Serial terminal started", ser#CR, ser#LF))
    fng.start(FPRINT_TX, FPRINT_RX, FPRINT_BPS, FPRINT_BL, FPRINT_RST)
    ser.str(string("Fingerprint reader started", ser#CR, ser#LF))

#include "lib.utility.spin"

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
