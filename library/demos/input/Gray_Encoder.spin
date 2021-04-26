{
    --------------------------------------------
    Filename: Gray_Encoder.spin
    Modified by: Jesse Burt
    Description: Simple demo/test of the
        input.encoder.graycode.spin Gray-code encoder driver
    Started May 18, 2019
    Updated Apr 26, 2021
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

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    encoder : "input.encoder.graycode"
    time    : "time"
    io      : "io"

VAR

    long _swstack[50]

PUB Main{} | newlevel, oldlevel

    setup{}
    newlevel := encoder.read                    ' Read initial value
    repeat
        ser.position(0, 3)                      ' Display it
        ser.printf1(string("Encoder: %d"), newlevel)
        ser.clearline{}
        oldlevel := newlevel                    ' Setup to detect change
        repeat
            newlevel := encoder.read{}          ' Poll encoder
        until (newlevel <> oldlevel)            '   until it changes

PUB cog_WatchSwitch{}
' Watch for I/O pin connected to switch to go low
'   and light LED if so
    io.low(SW_LED_PIN)
    io.output(SW_LED_PIN)
    io.input(SWITCH_PIN)

    repeat
        waitpne(|< SWITCH_PIN, |< SWITCH_PIN, 0)' wait for pin to go low
        io.high(SW_LED_PIN)                     ' turn on the LED
        waitpeq(|< SWITCH_PIN, |< SWITCH_PIN, 0)' wait for pin to go high
        io.low(SW_LED_PIN)                      ' turn off the LED

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    encoder.start(ENC_BASEPIN, ENC_DETENT, ENC_LOW, ENC_HIGH, ENC_PRESET)
    ser.strln(string("Gray-code encoder input driver started"))

    cognew(cog_watchswitch{}, @_swstack)
