CON
'' Hybrid Boards
'' Clock Settings
  _CLKMODE  = XTAL1 + PLL16X
  _XINFREQ  = 6_000_000

'' Pin definitions
  SOUND     = 10 '' Sound

  KEYBOARD  = 13 '' PS/2 Keyboard

  VIDEO     = 24 '' Composite video

PUB Null
'' This is not a top-level object
