{
    --------------------------------------------
    Filename: TCS3x7x-Demo.spin
    Author: Jesse Burt
    Copyright (c) 2018
    Started: Jun 24, 2018
    Updated: Jun 10, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' I/O Pin connected to the (optional) on-board white LED and INT pin
    WHITE_LED_PIN   = 25
    INT_PIN         = 24
' Demo mode constants
    DISP_HELP       = 1
    TOGGLE_POWER    = 2
    TOGGLE_RGBC     = 3
    PRINT_RGBC      = 4
    TOGGLE_INTS     = 5
    TOGGLE_WAIT     = 6
    TOGGLE_LED      = 7
    TOGGLE_WAITLONG = 8
    CYCLE_GAIN      = 9
    CLEAR_INTS      = 10
    LOWINTDEC       = 11
    LOWINTINC       = 12
    HIINTDEC        = 13
    HIINTINC        = 14
    WAITING         = 15

OBJ

    cfg   : "core.con.boardcfg.flip"
    ser   : "com.serial.terminal"
    time  : "time"
    rgb   : "sensor.color.tcs3x7x.i2c"
    io    : "io"

VAR

    long _keyDaemon_stack[50], _isr_stack[50]
    byte _keyDaemon_cog, _rgb_cog, _ser_cog, _isr_cog
    byte _demo_state, _prev_state
    byte _max_cols
    byte _led_enabled
    byte _int

PUB Main

    Setup
    ser.Clear
    rgb.IntThreshold ($0F00, $A000)
    rgb.Persistence (5)
    rgb.IntegrationTime (250_000)

    repeat
        case _demo_state
            DISP_HELP:          Help
            TOGGLE_POWER:       TogglePower
            TOGGLE_RGBC:        ToggleRGBC
            PRINT_RGBC:         PrintRGBC
            TOGGLE_INTS:        ToggleInts
            TOGGLE_WAIT:        ToggleWait
            TOGGLE_LED:         ToggleLED
            TOGGLE_WAITLONG:    ToggleWaitLong
            CYCLE_GAIN:         CycleGain
            CLEAR_INTS:         ClearInts
            LOWINTINC:          ChangeThresh(0, 256)
            LOWINTDEC:          ChangeThresh(0, -256)
            HIINTINC:           ChangeThresh(1, 256)
            HIINTDEC:           ChangeThresh(1, -256)
            WAITING:            waitkey
            OTHER:
                _demo_state := DISP_HELP

PUB ISR
' Soft Interrupt Service Routine
    io.Output (cfg#LED2)
    repeat
        waitpne(|<INT_PIN, |<INT_PIN, 0)
        _int := TRUE
        io.High (cfg#LED2)

        waitpeq(|<INT_PIN, |<INT_PIN, 0)
        _int := FALSE
        io.Low (cfg#LED2)

PUB Graph(graphx, graphy, in, inmin, inmax, outrange, grads, exc_lo, exc_hi) | output, scale, inrange, bar
' Calculate
    scale := 10
    inrange := inmax-inmin
    output := ((((in << scale)-(inmin << scale)) / inrange) * outrange) >> scale

' Graduations
    if grads
        exc_lo := ((((exc_lo << scale)-(inmin << scale)) / inrange) * outrange) >> scale
        exc_hi := ((((exc_hi << scale)-(inmin << scale)) / inrange) * outrange) >> scale
        repeat bar from 0 to outrange
            case bar
                exc_lo:
                    ser.Position (graphx + bar, graphy-1)
                    ser.Char ("L")
                exc_hi:
                    ser.Position (graphx + bar, graphy-1)
                    ser.Char ("H")
                0..outrange:
                    if bar//5 == 0
                        ser.Position (graphx + bar, graphy-1)
                        ser.Char ("|")
' Graph
    repeat bar from 0 to outrange
        ser.Position (graphx + bar, graphy)
        if bar =< output
            ser.Char ("#")
        else
            ser.Char (" ")

PUB PrintRGBC | rgbc_data[2], rdata, gdata, bdata, cdata, cmax, i, int, thr, rrow, grow, brow, crow, range

    range := 256
    crow := 4
    rrow := crow + 1
    grow := crow + 2
    brow := crow + 3
    ser.Clear
    ser.Position (0, 0)
    ser.Str (string("Gain: "))

    ser.Position (6, 0)
    ser.Dec (rgb.Gain(-2))
    ser.Str (string("x "))

    ser.Position (11, 0)
    ser.Str (string("Ints: "))
    int := ||rgb.Interrupts(-2)
    ser.Position (17, 0)
    ser.Str (lookupz(int: string("Off"), string("On ")))

    ser.Position (21, 0)
    ser.Str (string("Thr: "))
    thr := rgb.IntThreshold(-2, -2)
    ser.Hex (thr & $FFFF, 4)
    ser.Char ("-")
    ser.Hex ((thr >> 16) & $FFFF, 4)

    ser.Position (0, crow)
    ser.Str (string("Clear"))
    ser.Position (0, rrow)
    ser.Str (string("Red"))
    ser.Position (0, grow)
    ser.Str (string("Green"))
    ser.Position (0, brow)
    ser.Str (string("Blue"))

    repeat until _demo_state <> PRINT_RGBC
        if _led_enabled
            io.High (WHITE_LED_PIN)

        repeat until rgb.DataValid
        rgb.GetRGBC (@rgbc_data)

        if _led_enabled
            io.Low (WHITE_LED_PIN)

        ser.Position (55, 0)
        ser.Dec (ina[INT_PIN])

        cdata := ((rgbc_data.byte[1] << 8) | rgbc_data.byte[0]) & $FFFF
        rdata := ((rgbc_data.byte[3] << 8) | rgbc_data.byte[2]) & $FFFF
        gdata := ((rgbc_data.byte[5] << 8) | rgbc_data.byte[4]) & $FFFF
        bdata := ((rgbc_data.byte[7] << 8) | rgbc_data.byte[6]) & $FFFF

        Graph (6, crow, cdata, 0, range, 70, TRUE, thr & $FFFF, (thr >> 16) & $FFFF)
        Graph (6, rrow, rdata, 0, range, 70, FALSE, 0, 0)
        Graph (6, grow, gdata, 0, range, 70, FALSE, 0, 0)
        Graph (6, brow, bdata, 0, range, 70, FALSE, 0, 0)

PUB ChangeThresh(lim, delta) | tmp
' Change interrupt thresholds
    case lim
        0:  'Change low threshold
            tmp := rgb.IntThreshold(-2, -2)
            rgb.IntThreshold (0 #> ((tmp & $FFFF) + delta) <# $FFFF, (tmp >> 16) & $FFFF)
        1:  'Change high threshold
            tmp := rgb.IntThreshold(-2, -2)
            rgb.IntThreshold (tmp & $FFFF, 0 #> ((tmp >> 16) & $FFFF) + delta <# $FFFF)
        OTHER:

    _demo_state := _prev_state

PUB ClearInts

    rgb.ClearInt
    _demo_state := _prev_state

PUB CycleGain

    case rgb.Gain(-2)
        1: rgb.Gain (4)
        4: rgb.Gain (16)
        16: rgb.Gain (60)
        60: rgb.Gain (1)

    _demo_state := _prev_state

PUB ToggleLED

    ser.NewLine
    ser.Str (string("Turning LED "))

    if _led_enabled
        _led_enabled := FALSE
        ser.Str (string("off", ser#NL))
        io.Low (WHITE_LED_PIN)  'Turn off explicitly, just to be sure
    else
        ser.Str (string("on", ser#NL))
        _led_enabled := TRUE
    waitkey

PUB ToggleInts | tmp

    tmp := rgb.Interrupts(-2)
    if tmp
        rgb.Interrupts (FALSE)
    else
        rgb.Interrupts (TRUE)
    _demo_state := _prev_state

PUB TogglePower | tmp

    ser.NewLine
    ser.Str (string("Turning Power "))
    tmp := rgb.Power (-2)
    if tmp
        ser.Str (string("off", ser#NL))
        rgb.Power (FALSE)
    else
        ser.Str (string("on", ser#NL))
        rgb.Power (TRUE)
    waitkey

PUB ToggleRGBC | tmp

    ser.NewLine
    ser.Str (string("Turning RGBC "))
    tmp := rgb.Sensor(-2)
    if tmp
        ser.Str (string("off", ser#NL))
        rgb.Sensor (FALSE)
    else
        ser.Str (string("on", ser#NL))
        rgb.Sensor (TRUE)
    waitkey

PUB ToggleWait | tmp

    ser.NewLine
    ser.Str (string("Turning Wait timer "))
    tmp := rgb.WaitTimer (-2)
    if tmp
        ser.Str (string("off", ser#NL))
        rgb.WaitTimer (FALSE)
    else
        ser.Str (string("on", ser#NL))
        rgb.WaitTimer (TRUE)
    waitkey

PUB ToggleWaitLong | tmp

    ser.NewLine
    ser.Str (string("Turning Long Waits "))
    tmp := rgb.WaitLongTimer (-2)
    if tmp
        ser.Str (string("off", ser#NL))
        rgb.WaitLongTimer (FALSE)
    else
        ser.Str (string("on", ser#NL))
        rgb.WaitLongTimer (TRUE)
    waitkey

PUB keyDaemon | key_cmd

    repeat
        repeat until key_cmd := ser.CharIn
        case key_cmd
            "h", "H":
                _prev_state := _demo_state
                _demo_state := DISP_HELP

            "a", "A":
                _prev_state := _demo_state
                _demo_state := TOGGLE_RGBC

            "c", "C":
                if _demo_state == PRINT_RGBC
                    _prev_state := _demo_state
                    _demo_state := CLEAR_INTS

            "g", "G":
                _prev_state := _demo_state
                _demo_state := CYCLE_GAIN

            "i", "I":
                _prev_state := _demo_state
                _demo_state := TOGGLE_INTS

            "l", "L":
                _prev_state := _demo_state
                _demo_state := TOGGLE_LED

            "p", "P":
                _prev_state := _demo_state
                _demo_state := TOGGLE_POWER

            "q", "Q":
                _prev_state := _demo_state
                _demo_state := TOGGLE_WAITLONG

            "s", "S":
                _prev_state := _demo_state
                _demo_state := PRINT_RGBC

            "w", "W":
                _prev_state := _demo_state
                _demo_state := TOGGLE_WAIT

            "-", "_":
                if _demo_state == PRINT_RGBC
                    _prev_state := _demo_state
                    _demo_state := LOWINTDEC

            "=", "+":
                if _demo_state == PRINT_RGBC
                    _prev_state := _demo_state
                    _demo_state := LOWINTINC

            "[", "{":
                if _demo_state == PRINT_RGBC
                    _prev_state := _demo_state
                    _demo_state := HIINTDEC

            "]", "}":
                if _demo_state == PRINT_RGBC
                    _prev_state := _demo_state
                    _demo_state := HIINTINC

            OTHER:
                if _demo_state == WAITING
                    _demo_state := _prev_state
                else
                    _prev_state := _demo_state
                    _demo_state := DISP_HELP

PUB waitkey

  _demo_state := WAITING
  ser.Str (string("Press any key", ser#NL))
  repeat until _demo_state <> WAITING

PUB Help

    ser.Clear
    ser.Str (string("Keys: ", ser#NL, ser#NL))
    ser.Str (string("a, A:  Toggle sensor data acquisition (ADCs)", ser#NL))
    ser.Str (string("c, C:  Clear interrupt", ser#NL))
    ser.Str (string("g, G:  Cycle gain setting", ser#NL))
    ser.Str (string("h, H:  This help screen", ser#NL))
    ser.Str (string("i, I:  Toggle sensor interrupt pin enable (NOTE: Doesn't affect interrupt bit in sensor's status register)", ser#NL))
    ser.Str (string("l, L:  Toggle LED Strobe", ser#NL))
    ser.Str (string("p, P:  Toggle sensor power", ser#NL))
    ser.Str (string("q, Q:  Toggle Long Waits", ser#NL))
    ser.Str (string("s, S:  Monitor sensor data", ser#NL))
    ser.Str (string("w, W:  Toggle Wait timer", ser#NL))
    ser.Str (string("-, +:  Adjust interrupt low-threshold", ser#NL))
    ser.Str (string("[, ]:  Adjust interrupt high-threshold", ser#NL))

    repeat until _demo_state <> DISP_HELP

PUB Setup

    io.Output (WHITE_LED_PIN)
    io.Low (WHITE_LED_PIN)

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#NL))
    _keyDaemon_cog := cognew(keyDaemon, @_keyDaemon_stack)
    if _rgb_cog := rgb.Start
        ser.Str (string("tcs3x7x object started", ser#NL))
    else
        ser.Str (string("tcs3x7x object failed to start - halting", ser#NL))
        time.MSleep (500)
        ser.Stop
        flash(cfg#LED1)
    _max_cols := 1
    _isr_cog := cognew(ISR, @_isr_stack)

PUB flash(led_pin)

    dira[led_pin] := 1
    repeat
        !outa[led_pin]
        time.MSleep (500)
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
