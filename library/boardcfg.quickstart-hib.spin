CON
' Quickstart Human Interface Board (HIB)
' Parallax #40003
' NOTE: This is just an optional daughterboard for
'   the Parallax QuickStart #40000.
'   It doesn't contain a Propeller MCU.

' Clock Settings
  _CLKMODE      = XTAL1 + PLL16X
  _XINFREQ      = 5_000_000

' Pin definitions
    SD_MISO     = 0                                         ' uSD Socket
    SD_CLK      = 1
    SD_MOSI     = 2
    SD_CS       = 3

    IR_RX       = 8                                         ' IR Receiver
    IR_TX       = 9                                         ' IR Transmitter

    SOUND       = 10                                        ' Sound
    SOUND_R     = 10
    SOUND_L     = 11

    VIDEO       = 12                                        ' Composite video

    LED1        = 16                                        ' Blue LEDs
    LED2        = 17
    LED3        = 18
    LED4        = 19
    LED5        = 20
    LED6        = 21
    LED7        = 22
    LED8        = 23

    VGA         = 16                                        ' VGA

    MOUSE_DATA  = 24                                        ' PS/2 Mouse
    MOUSE_CLK   = 25

    KEYB_DATA   = 26                                        ' PS/2 Keyboard
    KEYB_CLK    = 27

    SER_RX_DEF  = 31                                        ' Serial
    SER_TX_DEF  = 30
    SER_BAUD_DEF= 115_200

' TV output modes and channels

    COMPOSITE   = %0101
    BROADCAST   = %0100 '' Default on HIB

    CH2         = 55_250_000
    CH3         = 61_250_000
    CH4         = 67_250_000

PUB Null
' This is not a top-level object
