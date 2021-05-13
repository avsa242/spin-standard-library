CON
' Propeller Demoboard
' Parallax #32100
    _CLKMODE    = XTAL1 + PLL16X
    _XINFREQ    = 5_000_000

' Pin definitions
    MIC_IN      = 8                             ' Electret Mic
    MIC_FB      = 9

    SOUND       = 10                            ' Sound
    AUDIO       = 10
    SOUND_L     = 10
    AUDIO_L     = 10
    SOUND_R     = 11
    AUDIO_R     = 11

    VIDEO       = 12                            ' Composite Video

    VGA         = 16                            ' VGA Video

    LED1        = 16                            ' Amber LEDs
    LED2        = 17
    LED3        = 18
    LED4        = 19
    LED5        = 20
    LED6        = 21
    LED7        = 22
    LED8        = 23

    MOUSE       = 24                            ' PS2 Mouse
    MOUSE_DATA  = 24
    MOUSE_CLK   = 25

    KEYBOARD    = 26                            ' PS2 Keyboard
    KEYB_CLK    = 26
    KEYB_DATA   = 27

    SCL         = 28                            ' I2C
    SDA         = 29

PUB Null
' This is not a top-level object

