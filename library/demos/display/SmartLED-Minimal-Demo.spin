{
    --------------------------------------------
    Filename: SmartLED-Minimal-Demo.spin
    Author: Jesse Burt
    Description: Demo of minimum code to light a
        single smart LED
    Started Jun 13, 2021
    Updated Oct 30, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = xtal1 + pll16x                ' _must_ be 80MHz
    _xinfreq    = 5_000_000

    SMLED_PIN   = 0
    MODEL       = led#WS2812
    ' WS2811, WS2812, WS2812B, WS2813, SK6812_24, SK6812_32 (RGBW), TM1803

OBJ

    led : "display.led.smart"

PUB main{} | pixel

    led.start(SMLED_PIN, 1, 1, MODEL, @pixel)   ' pin, width, height, model, addr
    led.plot(0, 0, $ff_00_00_00)                ' x, y, R_G_B or R_G_B_W color
    repeat

