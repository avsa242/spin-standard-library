{
    --------------------------------------------
    Filename: Gray_Encoder.spin
    Modified by: Jesse Burt
    Description: Simple demo/test of the input.encoder.graycode.spin Gray-code encoder driver
    Started May 18, 2019
    Updated Aug 9, 2020
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is a derivative of jm_grayenc_demo.spin, by
        Jon McPhalen.
}


CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200
    LED         = cfg#LED1                                          ' Pin with LED connected

    SWITCH_PIN  = 15                                                ' Encoder switch pin, if equipped
    ENC_BASEPIN = 11                                                ' First of two consecutive I/O pins encoder
                                                                    '   is connected to
    SW_LED_PIN  = cfg#LED2

    ENC_DETENT  = TRUE                                              ' Encoder has detents? TRUE or FALSE
    ENC_LOW     = 0                                                 ' Low-end limit value returned by encoder driver
    ENC_HIGH    = 100                                               ' High-end limit value returned by encoder driver
    ENC_PRESET  = 50                                                ' Starting value returned by encoder driver

    #1, HOME, #8, BKSP, TAB, LF, CLREOL, CLRDN, CR, #16, CLS        ' Terminal formatting control

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    encoder : "input.encoder.graycode"
    time    : "time"
    io      : "io"

VAR

    long _ser_cog, _encoder_cog, _watch_cog
    long _swstack[50]

PUB Main | newlevel, oldlevel

    Setup
    time.MSleep (1)
    newlevel := encoder.read                                        ' Read initial value
    repeat
        ser.Position (0, 3)                                         ' Display it
        ser.Str(string("Encoder: "))
        ser.Dec(newlevel)
        ser.clearline{}
        oldlevel := newlevel                                        ' Setup to detect change
        repeat
            newlevel := encoder.read                                ' Poll encoder
        until (newlevel <> oldlevel)                                '   until it changes

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#CR, ser#LF))
    if _encoder_cog := encoder.Start (ENC_BASEPIN, ENC_DETENT, ENC_LOW, ENC_HIGH, ENC_PRESET)
        ser.Str (string("Gray-code encoder input driver started"))
    else
        ser.Str (string("Gray-code encoder input driver failed to start - halting"))
        Stop
    _watch_cog := cognew(WatchSwitch, @_swstack)

PUB Stop

    time.MSleep (5)
    encoder.Stop
    ser.Stop
    cogstop(_watch_cog)
    FlashLED (LED, 500)

PUB WatchSwitch
' Watch for I/O pin connected to switch to go low
'   and light LED if so
    io.Low (SW_LED_PIN)
    io.Output(SW_LED_PIN)

    io.Input(SWITCH_PIN)
    repeat
        ifnot io.Input (SWITCH_PIN)
            io.High(SW_LED_PIN)
        else
            io.Low(SW_LED_PIN)

#include "lib.utility.spin"
