{
---------------------------------------------------------------------------------------------------
    Filename:       boardcfg.activity.spin
    Description:    Board configuration file for the Propeller Activity (WX) board
                    (Parallax PN's 32910, 32912)
    Author:         Jesse Burt
    Started:        Oct 15, 2022
    Updated:        Mar 11, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

CON
    { --- clock settings --- }
    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

    { --- pin definitions --- }
    { 6x 3-pin servo headers }
    SERVO1      = 12
    SERVO2      = 13
    SERVO3      = 14
    SERVO4      = 15
    SERVO5      = 16
    SERVO6      = 17


    { ADC - ADC124S021 }
    ADC_DI      = 18
    ADC_DO      = 19
    ADC_SCL     = 20
    ADC_CS      = 21


    { microSD socket - SPI }
    SD_BASEPIN  = 22
    SD_DO       = 22
    SD_CLK      = 23
    SD_DI       = 24
    SD_CS       = 25

    { microSD pin aliases }
    SD_SCK      = SD_CLK
    SD_MISO     = SD_DO
    SD_MOSI     = SD_DI
    SD_CD       = SD_CS
    SD_DAT3     = SD_CS
    SD_CMD      = SD_DI
    SD_DAT0     = SD_DO


    { sound }
    AUDIO       = 26
    AUDIO_L     = 26
    AUDIO_R     = 27
    SOUND       = AUDIO
    SOUND_L     = AUDIO_L
    SOUND_R     = AUDIO_R


    { two amber LEDs }
    LED1        = 26
    LED2        = 27


    { two DAC outputs }
    DA0         = 26
    DA1         = 27


    { I2C }
    SCL         = 28                            ' 10.5k pull-up
    SDA         = 29                            ' 10.5k pull-up


    { async serial }
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200


PUB null()
' This is not a top-level object

DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

