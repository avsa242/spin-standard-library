CON
'' Propeller Board of Education (PropBOE)
'' Parallax #32900
'' Clock Settings
  _CLKMODE    = XTAL1 + PLL16X
  _XINFREQ    = 5_000_000

'' Pin definitions
  SERVO1      = 14        '' 6 3-pin servo headers
  SERVO2      = 15
  SERVO3      = 16
  SERVO4      = 17
  SERVO5      = 18
  SERVO6      = 19

  MIC_FB      = 20        '' Onboard mic
  MIC_IN      = 21

  SD_DO       = 22        '' uSD socket
  SD_CLK      = 23
  SD_DI       = 24
  SD_CS       = 25

  SD_MISO     = 22        '' uSD socket (alternate names)
{ SD_CLK      = 23 }	  '' (this line included just for illustrative purposes)
  SD_MOSI     = 24
  SD_CD       = 25

  SOUND       = 26        '' Sound
  SOUND_L     = 26
  SOUND_R     = 27

  LED1        = 26        '' Two amber LEDs D1 and D2
  LED2        = 27

  DA0         = 26        '' Two DAC outputs
  DA1         = 27

  SCL         = 28        '' I2C
  SDA         = 29

  ADC_ADDR    = $46 << 1  '' Slave address of ADC

PUB Null
'' This is not a top-level object
