CON
'' QuickStart
'' Parallax #40000
'' Clock Settings
  _CLKMODE    = XTAL1 + PLL16X
  _XINFREQ    = 5_000_000

'' Pin definitions
  BUTTON1     = 0   '' Touch buttons
  BUTTON2     = 1
  BUTTON3     = 2
  BUTTON4     = 3
  BUTTON5     = 4
  BUTTON6     = 5
  BUTTON7     = 6
  BUTTON8     = 7

  ADC_FB      = 8   '' Optional Sigma-Delta ADC
  ADC_SIG     = 9   '' NOTE: Parts unpopulated from factory.

  LED1        = 16  '' Blue LEDs
  LED2        = 17
  LED3        = 18
  LED4        = 19
  LED5        = 20
  LED6        = 21
  LED7        = 22
  LED8        = 23

  SCL         = 28    '' I2C
  SDA         = 29

PUB Null
'' This is not a top-level object
