{
    --------------------------------------------
    Filename: Gray_Encoder.spin
    Author: Jesse Burt
    Description: Simple demo/test of the input.gray.spin Gray-code encoder driver
    Based on jm_grayenc_demo.spin, Copyright by Jon McPhalen
    Copyright (c) 2019
    Started May 18, 2019
    Updated May 18, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

    LED_PIN     = cfg#LED1                                          ' Pin with LED connected
    SWITCH_PIN  = 0                                                 ' Encoder switch pin, if equipped
    ENC_BASEPIN = 16                                                ' First of two consecutive I/O pins encoder
                                                                    '   is connected to
    ENC_DETENT  = TRUE                                              ' Encoder has detents? TRUE or FALSE
    ENC_LOW     = 0                                                 ' Low-end limit value returned by encoder driver
    ENC_HIGH    = 100                                               ' High-end limit value returned by encoder driver
    ENC_PRESET  = 50                                                ' Starting value returned by encoder driver

    #1, HOME, #8, BKSP, TAB, LF, CLREOL, CLRDN, CR, #16, CLS        ' Terminal formatting control

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    gray    : "input.gray"
    time    : "time"

VAR

    long _ser_cog, _gray_cog, _watch_cog
    long _swstack[50]

PUB Main | newlevel, oldlevel

    Setup
    time.MSleep (1)
    newlevel := gray.read                                           ' Read initial value
    repeat
        ser.Position (0, 3)                                         ' Display it
        ser.Str(string("Encoder: "))
        ser.Dec(newlevel)
        ser.Char (CLREOL)
        oldlevel := newlevel                                        ' Setup to detect change
        repeat
            newlevel := gray.read                                   ' Poll encoder
        until (newlevel <> oldlevel)                                '   until it changes

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#NL))
    if _gray_cog := gray.Start (ENC_BASEPIN, ENC_DETENT, ENC_LOW, ENC_HIGH, ENC_PRESET)
        ser.Str (string("Gray-code encoder input driver started"))
    else
        ser.Str (string("Gray-code encoder input driver failed to start - halting"))
        Stop
    _watch_cog := cognew(Watchsw, @_swstack)

PUB Stop

    time.MSleep (5)
    gray.Stop
    ser.Stop
    cogstop(_watch_cog)
    Flash (LED_PIN, 500)

PUB Flash(ledpin, delay_ms)

    dira[ledpin] := 1
    repeat
        !outa[ledpin]
        time.MSleep (delay_ms)

PUB Watchsw
' Watch for I/O pin connected to switch to go low
'   and light LED on LED_PIN if so
    dira[LED_PIN] := 1
    dira[SWITCH_PIN] := 0
    repeat
        ifnot ina[SWITCH_PIN]
            outa[LED_PIN] := 1
        else
            outa[LED_PIN] := 0
