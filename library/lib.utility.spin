' Library of utility functions
'   Must be included using the preprocessor #include directive
'   Requires:
'       time.spin
'       io.spin

PUB FlashLED(led_pin, delay_ms)

    io.Output(led_pin)
    repeat
        io.Toggle (led_pin)
        time.MSleep (delay_ms)
