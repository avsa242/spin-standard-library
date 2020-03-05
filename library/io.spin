{{
    Basic object for setting Propeller pins.
}}
CON
' Constants that may be used as parameters in the below methods to set pin states
    IO_OUT      = 1
    IO_IN       = 0
    IO_HIGH     = 1
    IO_LOW      = 0

PUB Direction(pin)
' Get current direction of pin
'   Returns:
'       0: Pin is set as input
'       1: Pin is set as output
    return dira[pin]

PUB Output(pin)
' Set direction of pin to output
    dira[pin] := IO_OUT

PUB Input(pin)
' Set direction of pin to input
    dira[pin] := IO_IN
    result := ina[pin]

PUB High(pin)
' Set state of pin high
    outa[pin] := IO_HIGH

PUB Low(pin)
' Set state of pin low
    outa[pin] := IO_LOW

PUB Toggle(pin)
' Toggle state of pin
    !outa[pin]

PUB Set(pin, enabled)
' Set pin to specific state
    outa[pin] := enabled

PUB State(pin)
' Get current state of pin
'   Returns:
'       0: Pin is low
'       1: Pin is high
    return outa[pin]
