{
    --------------------------------------------
    Filename: Gray_Encoder.spin
    Modified by: Jesse Burt
    Description: Simple demo/test of the
        input.encoder.graycode.spin Gray-code encoder driver
    Started May 18, 2019
    Updated Dec 24, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on jm_grayenc_demo.spin, originally
        by Jon McPhalen.
}


CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

' -- User-modifiable constants
    LED         = cfg#LED1                      ' Pin with LED connected
    SER_BAUD    = 115_200

    SWITCH_PIN  = 23                            ' Encoder switch pin, if equipped
    ENC_BASEPIN = 24                            ' First of two consecutive I/O pins encoder
                                                '   is connected to
    SW_LED_PIN  = cfg#LED2

' Gray-code encoder driver parameters:
    ENC_DETENT  = TRUE                          ' Encoder has detents?

' value limits returned by encoder driver
    ENC_LOW     = 0
    ENC_HIGH    = 100
    ENC_PRESET  = 50
' --

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    encoder : "input.encoder.graycode"
    time    : "time"

VAR

    long _swstack[50]

PUB main{} | newlevel, oldlevel

    setup{}
    newlevel := encoder.read                    ' Read initial value
    repeat
        ser.pos_xy(0, 3)                      ' Display it
        ser.printf1(string("Encoder: %d"), newlevel)
        ser.clear_ln{}
        oldlevel := newlevel                    ' Setup to detect change
        repeat
            newlevel := encoder.read{}          ' Poll encoder
        until (newlevel <> oldlevel)            '   until it changes

PUB cog_watchswitch{}
' Watch for I/O pin connected to switch to go low
'   and light LED if so
    outa[SW_LED_PIN] := 0
    dira[SW_LED_PIN] := 1
    dira[SWITCH_PIN] := 0

    repeat
        waitpne(|< SWITCH_PIN, |< SWITCH_PIN, 0)' wait for pin to go low
        outa[SW_LED_PIN] := 1                   ' turn on the LED
        waitpeq(|< SWITCH_PIN, |< SWITCH_PIN, 0)' wait for pin to go high
        outa[SW_LED_PIN] := 0                   ' turn off the LED

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    encoder.start(ENC_BASEPIN, ENC_DETENT, ENC_LOW, ENC_HIGH, ENC_PRESET)
    ser.strln(string("Gray-code encoder input driver started"))

    cognew(cog_watchswitch{}, @_swstack)

DAT
{
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

