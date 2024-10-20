{
    --------------------------------------------
    Filename: input.gamepad.nes.spin
    Author: Jesse Burt
    Description: Driver for NES gamepads
    Copyright (c) 2023
    Started Apr 16, 2023
    Updated Apr 16, 2023
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on excerpts of NES_Game_emulator_010.spin,
    originally by Darryl Biggar.

    Usage:
        For single-shot reads (doesn't require an extra core/cog),
            1) call startx() with the appropriate I/O pins
            2) call one of read_ctrl1(), read_ctrl2(), or read_both() to read the button state(s)
                of the connected gamepad(s). The button states are returned as 8-bit masks.
            3) call ctrl#_a(), ctrl#_b(), ctrl#_select(), ctrl#_start(), ctrl#_up(), ctrl#_down(),
                ctrl#_left(), ctrl#_right() as needed, where # is 1 or 2
            The button states can also be read directly by the parent object by reading the
                _ctrl1_state and/or _ctrl2_state variables. Example:

                    ' Parent object
                    OBJ nes: "input.gamepad.nes"

                    PUB do_something() | p1, p2

                        p1 := nes._ctrl1_state
                        p2 := nes._ctrl2_state

        For continuous background reads (requires an extra core/cog),
            1) call startx_cog() with the appropriate I/O pins
            2) call ctrl#_a(), ctrl#_b(), ctrl#_select(), ctrl#_start(), ctrl#_up(), ctrl#_down(),
                ctrl#_left(), ctrl#_right() as needed, where # is 1 or 2
            The button states can also be read directly by the parent object by reading the
                _ctrl1_state and/or _ctrl2_state variables. Example:

                    ' Parent object
                    OBJ nes: "input.gamepad.nes"

                    PUB do_something() | p1, p2

                        p1 := nes._ctrl1_state
                        p2 := nes._ctrl2_state

        NOTE: Gamepad #2 is optional. If it isn't used, data returned by ctrl2_*() methods
            is undefined
}
CON

    { gamepad button masks }
    CTRL_A    = 1 << 7
    CTRL_B    = 1 << 6
    CTRL_SEL  = 1 << 5
    CTRL_ST   = 1 << 4
    CTRL_UP   = 1 << 3
    CTRL_DN   = 1 << 2
    CTRL_LT   = 1 << 1
    CTRL_RT   = 1 << 0


VAR

    { I/O and low-level }
    long _LATCH, _CLK, _DATA1, _DATA2
    long _ctrl_stack[11], _cog

    { controller button states (directly readable by parent) }
    byte _ctrl1_state, _ctrl2_state

PUB startx(LATCH_PIN, CLK_PIN, DATA1_PIN, DATA2_PIN): status
' Start one-shot NES controller driver
'   LATCH_PIN: gamepad LATCH pin
'   CLK_PIN: gamepad CLOCK pin
'   DATA1_PIN: gamepad 1 DATA pin
'   DATA2_PIN: gamepad 2 DATA pin (optional; specify outside of range 0..31 to ignore)
'   Returns:
'       cog ID + 1 of current (parent of this object) cog ID
    longmove(@_LATCH, @LATCH_PIN, 4)
    dira[LATCH_PIN] := 1
    dira[CLK_PIN] := 1
    dira[DATA1_PIN] := 0
    if ( lookdown(DATA2_PIN: 0..31) )           ' don't touch gamepad #2 pin unless it's valid
        dira[DATA2_PIN] := 0

    outa[CLK_PIN] := 0
    outa[LATCH_PIN] := 0
    outa[LATCH_PIN] := 1 ' JOY_SH/LDn = 1
    outa[LATCH_PIN] := 0 ' JOY_SH/LDn = 0
    return cogid+1

PUB startx_cog(LATCH_PIN, CLK_PIN, DATA1_PIN, DATA2_PIN): status
' Start a continuous (asynchronous/background) NES controller driver
'   LATCH_PIN: gamepad LATCH pin
'   CLK_PIN: gamepad CLOCK pin
'   DATA1_PIN: gamepad 1 DATA pin
'   DATA2_PIN: gamepad 2 DATA pin
'   Returns:
'       cog ID + 1 of secondary cog ID
'       0 if no more cogs available
    stop()
    longmove(@_LATCH, @LATCH_PIN, 4)
    if ( status := (cognew(cog_read_controllers(), @_ctrl_stack) + 1) )
        _cog := status

PUB stop{}
' Stop the driver
    if ( _cog )
        cogstop(_cog-1)
    longfill(@_LATCH, 0, 16)
    bytefill(@_ctrl1_state, 0, 2)

PUB ctrl1_connected{}: c
' Flag indicating controller 1 is connected
'   Returns:
'       0: not connected
'       -1: connected
    return (_ctrl1_state <> $ff)

PUB ctrl2_connected{}: c
' Flag indicating controller 2 is connected
'   Returns:
'       0: not connected
'       -1: connected
    return (_ctrl2_state <> $ff)

PUB ctrl1_a{}: s
' State of ctrl 1 A button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
    return ( (_ctrl1_state & CTRL_A) <> 0 )

PUB ctrl1_b{}: s
' State of ctrl 1 B button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
    return ( (_ctrl1_state & CTRL_B) <> 0 )

PUB ctrl1_select{}: s
' State of ctrl 1 select button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl1_state & CTRL_SEL) <> 0 )

PUB ctrl1_start{}: s
' State of ctrl 1 start button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl1_state & CTRL_ST) <> 0 )

PUB ctrl1_up{}: s
' State of ctrl 1 D-pad up button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl1_state & CTRL_UP) <> 0 )

PUB ctrl1_down{}: s
' State of ctrl 1 D-pad down button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl1_state & CTRL_DN) <> 0 )

PUB ctrl1_left{}: s
' State of ctrl 1 D-pad left button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl1_state & CTRL_LT) <> 0 )

PUB ctrl1_right{}: s
' State of ctrl 1 D-pad right button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl1_state & CTRL_RT) <> 0 )

PUB ctrl2_a{}: s
' State of ctrl 2 A button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl2_state & CTRL_A) <> 0 )

PUB ctrl2_b{}: s
' State of ctrl 2 B button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl2_state & CTRL_B) <> 0 )

PUB ctrl2_select{}: s
' State of ctrl 2 select button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl2_state & CTRL_SEL) <> 0 )

PUB ctrl2_start{}: s
' State of ctrl 2 start button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl2_state & CTRL_ST) <> 0 )

PUB ctrl2_up{}: s
' State of ctrl 2 D-pad up button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl2_state & CTRL_UP) <> 0 )

PUB ctrl2_down{}: s
' State of ctrl 2 D-pad down button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl2_state & CTRL_DN) <> 0 )

PUB ctrl2_left{}: s
' State of ctrl 2 D-pad left button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl2_state & CTRL_LT) <> 0 )

PUB ctrl2_right{}: s
' State of ctrl 2 D-pad right button
'   Returns:
'       0: not pressed
'       -1: pressed
'   NOTE: if the driver was started in cogless mode, read_both() or read_ctrl1() must be called
'       first to update button states
   return ( (_ctrl2_state & CTRL_RT) <> 0 )

PUB read_both{}: nes_bits | i
' Read the state of both controllers 1 and 2
'   Returns:
'       MSB: 8-bit controller 2 state
'       LSB: 8-bit controller 1 state
'   NOTE: State is also cached in RAM
    outa[_LATCH] := 1                           ' latch state
    outa[_LATCH] := 0
    nes_bits := ina[_DATA1] | (ina[_DATA2] << 8)
    repeat i from 0 to 6
        outa[_CLK] := 1                         ' pulse clock
        outa[_CLK] := 0
        nes_bits := (nes_bits << 1) | ina[_DATA1] | (ina[_DATA2] << 8)

    _ctrl1_state := !nes_bits.byte[0]           ' store states in RAM
    _ctrl2_state := !nes_bits.byte[1]
    return (!nes_bits & $FFFF)

PUB read_ctrl1{}: nes_bits | i
' Read the state of controller 1
'   Returns:
'       8-bit controller 1 state
'   NOTE: State is also cached in RAM
    outa[_LATCH] := 1                           ' latch state
    outa[_LATCH] := 0
    nes_bits := ina[_DATA1]
    repeat i from 0 to 6
        outa[_CLK] := 1                         ' pulse clock
        outa[_CLK] := 0
        nes_bits := (nes_bits << 1) | ina[_DATA1]

    _ctrl1_state := !nes_bits                   ' store state in RAM
    return (!nes_bits & $FF)

PUB read_ctrl2{}: nes_bits | i
' Read the state of controller 2
'   Returns:
'       8-bit controller 2 state
'   NOTE: State is also cached in RAM
    outa[_LATCH] := 1                           ' latch state
    outa[_LATCH] := 0
    nes_bits := ina[_DATA2]
    repeat i from 0 to 6
        outa[_CLK] := 1                         ' pulse clock
        outa[_CLK] := 0
        nes_bits := (nes_bits << 1) | ina[_DATA2]

    _ctrl2_state := !nes_bits                   ' store state in RAM
    return (!nes_bits & $FF)

PRI cog_read_controllers()
' Read gamepads in async/background cog and store states in RAM
    dira[_LATCH] := 1
    dira[_CLK] := 1
    dira[_DATA1] := 0
    outa[_CLK] := 0
    outa[_LATCH] := 0
    outa[_LATCH] := 1

    if ( lookdown(_DATA2: 0..31) )
        dira[_DATA2] := 0
        repeat
            read_both{}
    else
        repeat
            read_ctrl1{}

DAT
{
Copyright 2023 Jesse Burt

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

