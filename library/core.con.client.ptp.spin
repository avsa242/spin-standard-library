CON
  '' I/O SETTINGS
  '' Propeller Touchscreen Platform (PTP) 3.5"
  '' Ray Allen (Rayman)
  _CLKMODE      = XTAL1 + PLL16X
  _XINFREQ      = 5_000_000

  SD_DO         = 0         '' uSD socket
  SD_CLK        = 1
  SD_DI         = 2
  SD_CS         = 3

  SOUND         = 10        '' Sound
  SOUND_L       = 10
  SOUND_R       = 11
  
  LCD_RESET     = 12        '' LCD Panel and Touchscreen
  LCD_LSDI      = 13
  LCD_LCLK      = 14
  LCD_LCS       = 15
  LCD_VSYNC     = 16
  LCD_HSYNC     = 17
  LCD_B0        = 18
  LCD_B1        = 19
  LCD_G0        = 20
  LCD_G1        = 21
  LCD_R0        = 22
  LCD_R1        = 23
  LCD_DE        = 24
  LCD_PCLK      = 25
  LCD_BL        = 26
  TS_IRQ        = 27
  
  SCL           = 28        '' I2C
  SDA           = 29

  TSC2003_SLAVE = $48 << 1  '' Default TSC2003 Slave Address
  TSC2003_MAX_HZ= 3_400_000
  TSC2003_FASTHZ= 1_000_000
  
PUB Null
'' This is not a top-level object
