CON
  '' I/O SETTINGS
  '' Hackable badge
  '' Parallax #20000, 20100, 20200
  _CLKMODE    = XTAL1 + PLL16X
  _XINFREQ    = 5_000_000

  '' I/O Pin definitions

  RCT_V       = 0
  RGBA        = 1
  RGBB        = 2
  RGBC        = 3
  XYZI        = 4
  PAD_OSH     = 5
  LEDA        = 6
  LEDB        = 7
  LEDC        = 8
  SOUND       = 9   '' Sound
  SOUND_L     = 9
  SOUND_R     = 10
  VIDEO       = 12  '' Composite video connection

  PADL_1      = 15
  PADL_2      = 16
  PADL_3      = 17

  OLED_CS     = 18  '' OLED (4-wire SPI)
  OLED_RST    = 19
  OLED_DC     = 20
  OLED_CLK    = 21
  OLED_DAT    = 22

  IR_IN       = 23  '' IR comms
  IR_OUT      = 24
  PADR_1      = 25
  PADR_2      = 26
  PADR_3      = 27

  SCL         = 28  '' I2C
  SDA         = 29

  '' TV output modes and channels

  COMPOSITE   = %0101 
  BROADCAST   = %0100

  CH2         = 55_250_000
  CH3         = 61_250_000
  CH4         = 67_250_000

PUB Null
'' This is not a top-level object