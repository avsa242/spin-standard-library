{{
    Basic object for setting Propeller pins.
}}
CON

    IO_OUT      = 1
    IO_IN       = 0
    IO_HIGH     = 1
    IO_LOW      = 0

PUB Output(pin)

    dira[pin] := IO_OUT

PUB Input(pin)

    dira[pin] := IO_IN
    result := ina[pin]

PUB High(pin)

    dira[pin] := IO_OUT
    outa[pin] := IO_HIGH

PUB Low(pin)

    dira[pin] := IO_OUT
    outa[pin] := IO_LOW

PUB Toggle(pin)

    ~outa[pin]

PUB Set(pin, enabled)

    outa[pin] := enabled

