CON
  '' I/O SETTINGS
  '' Spinneret Web Server
  '' Parallax #32203
  _CLKMODE    = XTAL1 + PLL16X
  _XINFREQ    = 5_000_000

  '' I/O Pin definitions

  DATA0       = 0   '' Wiznet W5100
  DATA1       = 1
  DATA2       = 2
  DATA3       = 3
  DATA4       = 4
  DATA5       = 5
  DATA6       = 6
  DATA7       = 7
  ADDR0       = 8
  ADDR1       = 9
  _WR         = 10
  _RD         = 11
  _CS         = 12
  _INT        = 13
  E_RST       = 14
  SEN         = 15
  DAT0        = 16
  DAT1        = 17
  DAT2        = 18
  DAT3        = 19
  CMD         = 20
  SIO         = 22
  LED         = 23
  AUX0        = 24
  AUX1        = 25
  AUX2        = 26
  AUX3        = 27

  SD_MISO     = 16  '' uSD Socket
  SD_DAT1     = 17
  SD_DAT2     = 18
  SD_CS       = 19
  SD_MOSI     = 20
  SD_CLK      = 21

  SCL         = 28    '' I2C
  SDA         = 29

PUB Null
'' This is not a top-level object