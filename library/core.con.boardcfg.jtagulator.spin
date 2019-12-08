CON
'' JTAGULATOR
'' Parallax #32115
'' Clock Settings
    _CLKMODE    = XTAL1 + PLL16X
    _XINFREQ    = 5_000_000

'' Pin definitions
    DACOUT      = 25
    LED1        = 26
    LED2        = 27
    LEDGREEN    = 26
    LEDRED      = 27

PUB Null
'' This is not a top-level object
