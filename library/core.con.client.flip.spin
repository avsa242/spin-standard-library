CON
'' FLiP Propeller Module
'' Parallax #32123
'' Clock Settings
  _CLKMODE      = XTAL1 + PLL16X
  _XINFREQ      = 5_000_000
  
'' Pin definitions
  LED1          = 26
  LED2          = 27  ''Onboard green LEDs

  SCL           = 28  ''I2C
  SDA           = 29
  
  
PUB Null
' This is not a top-level object
