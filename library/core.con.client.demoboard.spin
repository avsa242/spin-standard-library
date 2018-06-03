CON
'' I/O SETTINGS
'' Propeller Demoboard
'' Parallax #32100
  _clkmode  = xtal1 + pll16x
  _xinfreq  = 5_000_000

  MIC_IN    = 8   '' Electret Mic
  MIC_FB    = 9

  SOUND     = 10  '' Sound
  SOUND_L   = 10
  SOUND_R   = 11

  VIDEO     = 12  '' Composite Video

  VGA       = 16  '' VGA Video

  LED1      = 16  '' I/O for Amber LEDs
  LED2      = 17
  LED3      = 18
  LED4      = 19
  LED5      = 20
  LED6      = 21
  LED7      = 22
  LED8      = 23

  MOUSE     = 24  '' PS2 Mouse
  MOUSE_DATA= 24
  MOUSE_CLK = 25

  KEYBOARD  = 26  '' PS2 Keyboard
  KEYB_DATA = 26
  KEYB_CLK  = 27

  SCL       = 28  '' I2C
  SDA       = 29

PUB null
'' This is not a top-level object