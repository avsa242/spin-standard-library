{
    --------------------------------------------
    Filename: core.con.boardcfg.ybox2.spin
    Author: Jesse Burt
    Description: Board configuration file for YBox2
    Started Mar 19, 2022
    Updated Mar 20, 2022
    Copyright 2022
    See end of file for terms of use.
    --------------------------------------------
}
#define YBOX2

CON
' YBox2
' https://www.adafruit.com/product/95
    { Clock Settings }
    _clkmode        = xtal1 + pll16x
    _xinfreq        = 5_000_000

    { Pin definitions }

    { ENC28J60 Ethernet controller }
    RESET_PIN       = 0                         ' O
    CS_PIN          = 1                         ' O
    SCK_PIN         = 2                         ' O
    MOSI_PIN        = 3                         ' O
    MISO_PIN        = 4                         ' I
    WOL_PIN         = 5                         ' I (Wake-on-LAN)
    INT_PIN         = 6                         ' I (Interrupt)

    { NOTE: The YBox2 provides no crystal for the ENC28J60,
        so the clock (25MHz) must be generated using one of the Propeller's
        counters, output to I/O pin 7 }
    ENC_OSCPIN      = 7                         ' O

    { Piezo buzzer }
    BUZZER          = 8                         ' O
    AUDIO           = 8
    AUDIO_L         = 8
    AUDIO_R         = 8
    SOUND           = 8

    { RGB LED (not smart-LED), color order can differ from LED to LED }
    LED1            = 9                         ' O
    LED2            = 10                        ' O
    LED3            = 11                        ' O

    { Composite video; spans 3 pins }
    COMPVIDEO       = 12                        ' O

    { PNA640XM IR receiver, 38kHz }
    IR_RX           = 15                        ' I

    { S1: Tactile button }
    SWITCH1         = 16                        ' I
    BUTTON1         = 16

    { I2C bus }
    SCL             = 28                        ' O
    SDA             = 29                        ' I/O

    { Async serial }
    SER_RX_DEF      = 31                        ' I
    SER_TX_DEF      = 30                        ' O
    SER_BAUD_DEF    = 115_200

PUB Null
' This is not a top-level object

