{                                                                                                                
    --------------------------------------------
    Filename: signal.dac.duty.spin
    Author: Jesse Burt
    Description: 2-channel DAC object using the duty mode of the counters as output
    Started Feb 16, 2020
    Updated Feb 17, 2020
    See end of file for terms of use.
    --------------------------------------------
    NOTE: This object is based on the Parallax Simple-Library functionality
}

OBJ

    io      : "io"
    counters: "core.con.counters"

VAR

    long _dac_stack[6]
    long _ctra, _ctrb, _frqa, _frqb
    byte _dac_res
    byte _ch0, _ch1
    byte _cog

PUB Start(ch0_pin, ch1_pin, dac_res_bits)

    if lookup(ch0_pin: 0..31)                               ' Validate ch0 pin
        _ch0 := ch0_pin
        io.Output(ch0_pin)
        if ch1_pin <> ch0_pin AND lookup(ch1_pin: 0..31)    ' ch1 is optional - ignore if outside of 0..31 range
            io.Output(ch1_pin)
            _ch1 := ch1_pin
        if _cog := cognew(dacLoop, @_dac_stack) + 1         ' Is a cog available?
            Resolution(dac_res_bits)                        ' Set resolution (default to 8 if invalid)
            return _cog
    return FALSE                                            ' If we got here, something went wrong

PUB Stop
' Stop the DAC cog
    cogstop(_cog-1)

PUB Output(channel, value)
' Output value to DAC
'   Valid values:
'       channel: 0, 1
'       value: 0..(1 << Resolution)-1
'   Voltage output will be approx: value * (3.3V / 2^Resolution)
'   Example:
'   OBJ
'
'       dac : "signal.audio.duty"
'
'   PUB ExampleDemoMethod
'
'       dac.Start(26, 27, 8)' Use I/O pins 26 and 27 for ch0 and ch1, resp. Set resolution to 8 bits
'       dac.Output(0, 0)    ' Output 0V on channel 0
'       dac.Output(1, 127)  ' Output 1.65V on channel 1
'       dac.Output(0, 255)  ' Output 3.3V on channel 0
    ifnot channel                                           ' Channel 0
        _frqa := (value << _dac_res)
    else                                                    ' Channel 1
        _frqb := (value << _dac_res)

PUB Resolution(bits)
' Set DAC resolution, in bits
'   Valid values: 1..32
'   Any other value sets a default resolution of 8 bits
    case bits
        1..32:
        OTHER:
            bits := 8

    _dac_res := 32-bits

PRI dacLoop | pin
' Digital to Analog Converter
    _ctra := (counters#MODE_DUTY_SINGLEEND + _ch0)       ' Set counters to single-ended duty-cycle mode
    _ctrb := (counters#MODE_DUTY_SINGLEEND + _ch1)
    repeat
        if _ctra <> CTRA
            if CTRA <> 0
                pin := CTRA & %111111
                DIRA &= (1 << pin) ^ $FFFFFFFF
            CTRA := _ctra

            if _ctra <> 0
                pin := CTRA & %111111
                DIRA |= (1 << pin)

        if _ctrb <> CTRB
            if CTRB <> 0
                pin := CTRB & %111111
                DIRA &= (1 << pin) ^ $FFFFFFFF
            CTRB := _ctrb

            if ctrb <> 0
                pin := CTRB & %111111
                DIRA |= (1 << pin)
        FRQA := _frqa
        FRQB := _frqb

