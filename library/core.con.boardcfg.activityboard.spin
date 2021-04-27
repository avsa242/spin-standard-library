CON
' Activity Board
' Parallax WX #32912 and non-WX #32910
' Clock Settings
    _CLKMODE    = XTAL1 + PLL16X
    _XINFREQ    = 5_000_000

    ' Pin definitions
    SERVO1      = 12                            ' 6 3-pin servo headers
    SERVO2      = 13
    SERVO3      = 14
    SERVO4      = 15
    SERVO5      = 16
    SERVO6      = 17

    ADC_DI      = 18                            ' ADC
    ADC_DO      = 19
    ADC_SCL     = 20
    ADC_CS      = 21

    SD_BASEPIN  = 22
    SD_DO       = 22                            ' uSD socket
    SD_CLK      = 23
    SD_DI       = 24
    SD_CS       = 25

    AUDIO       = 26                            ' Sound
    AUDIO_L     = 26
    AUDIO_R     = 27
    SOUND       = 26
    SOUND_L     = 26
    SOUND_R     = 27

    LED1        = 26                            ' Two amber LEDs
    LED2        = 27

    DA0         = 26                            ' Two DAC outputs
    DA1         = 27

    SCL         = 28                            ' I2C
    SDA         = 29

PUB Null
' This is not a top-level object
