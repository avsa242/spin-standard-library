CON
'' P8XBlade2
'' Cluso99 (cluso@clusos.com)
'' Clock Settings
  _CLKMODE    = xtal1 + pll8x
  _XINFREQ    = 12_000_000

'' Pin definitions
  SD_DO       = 12  '' uSD Card Socket
  SD_CLK      = 13
  SD_MISO     = 14
  SD_CS       = 15

  SCL         = 28
  SDA         = 29

PUB Null
'' This is not a top-level object
