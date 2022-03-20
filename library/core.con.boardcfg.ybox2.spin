CON
' YBox2

    { Clock Settings }
    _clkmode        = xtal1 + pll16x
    _xinfreq        = 5_000_000

    { Pin definitions }
    RESET_PIN       = 0                         ' O: ENC28J60
    CS_PIN          = 1                         ' O
    SCK_PIN         = 2                         ' O
    MOSI_PIN        = 3                         ' O
    MISO_PIN        = 4                         ' I
    WOL_PIN         = 5                         ' I: Wake-on-LAN
    INT_PIN         = 6                         ' I: Interrupt
    ENC_OSCPIN      = 7                         ' O: Clock input *required: 25MHz

    BUZZER          = 8                         ' O: piezo buzzer
    AUDIO           = 8
    AUDIO_L         = 8
    AUDIO_R         = 8
    SOUND           = 8

    LED1            = 9                         ' O: RGB LED
    LED2            = 10                        ' O
    LED3            = 11                        ' O

    COMPVIDEO       = 12                        ' O: composite video

    IR_RX           = 15                        ' I: PNA640XM

    SWITCH1         = 16                        ' I
    BUTTON1         = 16

    SCL             = 28                        ' O: I2C
    SDA             = 29                        ' I/O

    SER_RX_DEF      = 31                        ' I: Serial
    SER_TX_DEF      = 30                        ' O
    SER_BAUD_DEF    = 115_200

PUB Null
' This is not a top-level object
