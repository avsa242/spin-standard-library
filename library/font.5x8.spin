{
    --------------------------------------------
    Filename: font.5x8.spin
    Description: 5x8 bitmap font
    Author: Jesse Burt
    Bitmap font author unknown, reference Thomas P. Sullivan's
        SSD1331 OLED driver
    Created: Apr 26, 2018
    Updated: Oct 3, 2021
    See end of file for terms of use.
    --------------------------------------------
}


CON
' Font definition: width, height in pixels, ASCII code of lowest and highest characters
    WIDTH       = 5
    HEIGHT      = 8
    FIRSTCHAR   = 0
    LASTCHAR    = 127

PUB Null
' This is not a top-level object

PUB BaseAddr{}: ptr
' Return base address of font table
    return @table

DAT

    table   byte %11111111   '$00
            byte %11111111   '$00
            byte %11111111   '$00
            byte %11111111   '$00
            byte %11111111   '$00
            byte %00000000   '$00
            byte %00000000   '$00
            byte %00000000   '$00

            byte %11111111   '$01
            byte %11111100   '$01
            byte %11111000   '$01
            byte %11100000   '$01
            byte %11000000   '$01
            byte %10000000   '$01
            byte %00000000   '$01
            byte %00000000   '$01

            byte %11111111   '$02
            byte %10100101   '$02
            byte %10011001   '$02
            byte %10100101   '$02
            byte %11111111   '$02
            byte %00000000   '$02
            byte %00000000   '$02
            byte %00000000   '$02

            byte %00000001   '$03
            byte %00000111   '$03
            byte %00001111   '$03
            byte %00111111   '$03
            byte %11111111   '$03
            byte %00000000   '$03
            byte %00000000   '$03
            byte %00000000   '$03

            byte %10000001   '$04
            byte %01000010   '$04
            byte %00100100   '$04
            byte %00011000   '$04
            byte %00011000   '$04
            byte %00000000   '$04
            byte %00000000   '$04
            byte %00000000   '$04

            byte %00011000   '$05
            byte %00011000   '$05
            byte %00011000   '$05
            byte %00011000   '$05
            byte %00011000   '$05
            byte %00000000   '$05
            byte %00000000   '$05
            byte %00000000   '$05

            byte %00000000   '$06
            byte %00000000   '$06
            byte %11111111   '$06
            byte %00000000   '$06
            byte %00000000   '$06
            byte %00000000   '$06
            byte %00000000   '$06
            byte %00000000   '$06

            byte %11111111   '$07
            byte %10000001   '$07
            byte %10000001   '$07
            byte %10000001   '$07
            byte %11111111   '$07
            byte %00000000   '$07
            byte %00000000   '$07
            byte %00000000   '$07

            byte %10101010   '$08
            byte %01010101   '$08
            byte %10101010   '$08
            byte %01010101   '$08
            byte %10101010   '$08
            byte %00000000   '$08
            byte %00000000   '$08
            byte %00000000   '$08

            byte %10101010   '$09
            byte %01010101   '$09
            byte %10101010   '$09
            byte %01010101   '$09
            byte %10101010   '$09
            byte %00000000   '$09
            byte %00000000   '$09
            byte %00000000   '$09

            byte %10101010   '$0A
            byte %01010101   '$0A
            byte %10101010   '$0A
            byte %01010101   '$0A
            byte %10101010   '$0A
            byte %00000000   '$0A
            byte %00000000   '$0A
            byte %00000000   '$0A

            byte %10101010   '$0B
            byte %01010101   '$0B
            byte %10101010   '$0B
            byte %01010101   '$0B
            byte %10101010   '$0B
            byte %00000000   '$0B
            byte %00000000   '$0B
            byte %00000000   '$0B

            byte %10101010   '$0C
            byte %01010101   '$0C
            byte %10101010   '$0C
            byte %01010101   '$0C
            byte %10101010   '$0C
            byte %00000000   '$0C
            byte %00000000   '$0C
            byte %00000000   '$0C

            byte %10101010   '$0D
            byte %01010101   '$0D
            byte %10101010   '$0D
            byte %01010101   '$0D
            byte %10101010   '$0D
            byte %00000000   '$0D
            byte %00000000   '$0D
            byte %00000000   '$0D

            byte %10101010   '$0E
            byte %01010101   '$0E
            byte %10101010   '$0E
            byte %01010101   '$0E
            byte %10101010   '$0E
            byte %00000000   '$0E
            byte %00000000   '$0E
            byte %00000000   '$0E

            byte %10101010   '$0F
            byte %01010101   '$0F
            byte %10101010   '$0F
            byte %01010101   '$0F
            byte %10101010   '$0F
            byte %00000000   '$0F
            byte %00000000   '$0F
            byte %00000000   '$0F

            byte %11111111   '$10
            byte %11111111   '$10
            byte %11111111   '$10
            byte %11111111   '$10
            byte %11111111   '$10
            byte %00000000   '$10
            byte %00000000   '$10
            byte %00000000   '$10

            byte %01111110   '$11
            byte %10111101   '$11
            byte %11011011   '$11
            byte %11100111   '$11
            byte %11100111   '$11
            byte %00000000   '$11
            byte %00000000   '$11
            byte %00000000   '$11

            byte %11000011   '$12
            byte %11000011   '$12
            byte %11000011   '$12
            byte %11000011   '$12
            byte %11000011   '$12
            byte %00000000   '$12
            byte %00000000   '$12
            byte %00000000   '$12

            byte %11111111   '$13
            byte %00000000   '$13
            byte %00000000   '$13
            byte %00000000   '$13
            byte %11111111   '$13
            byte %00000000   '$13
            byte %00000000   '$13
            byte %00000000   '$13

            byte %11111111   '$14
            byte %11100111   '$14
            byte %10011001   '$14
            byte %11100111   '$14
            byte %11111111   '$14
            byte %00000000   '$14
            byte %00000000   '$14
            byte %00000000   '$14

            byte %11111111   '$15
            byte %11111111   '$15
            byte %10000001   '$15
            byte %10000001   '$15
            byte %11111111   '$15
            byte %00000000   '$15
            byte %00000000   '$15
            byte %00000000   '$15

            byte %11111111   '$16
            byte %10000001   '$16
            byte %10000001   '$16
            byte %11111111   '$16
            byte %11111111   '$16
            byte %00000000   '$16
            byte %00000000   '$16
            byte %00000000   '$16

            byte %11111111   '$17
            byte %10000001   '$17
            byte %10000001   '$17
            byte %10000001   '$17
            byte %11111111   '$17
            byte %00000000   '$17
            byte %00000000   '$17
            byte %00000000   '$17

            byte %11111111   '$18
            byte %10000001   '$18
            byte %10000001   '$18
            byte %10000001   '$18
            byte %11111111   '$18
            byte %00000000   '$18
            byte %00000000   '$18
            byte %00000000   '$18

            byte %11111111   '$19
            byte %10000001   '$19
            byte %10000001   '$19
            byte %10000001   '$19
            byte %11111111   '$19
            byte %00000000   '$19
            byte %00000000   '$19
            byte %00000000   '$19

            byte %11111111   '$1A
            byte %10000001   '$1A
            byte %10000001   '$1A
            byte %10000001   '$1A
            byte %11111111   '$1A
            byte %00000000   '$1A
            byte %00000000   '$1A
            byte %00000000   '$1A

            byte %11111111   '$1B
            byte %10000001   '$1B
            byte %10000001   '$1B
            byte %10000001   '$1B
            byte %11111111   '$1B
            byte %00000000   '$1B
            byte %00000000   '$1B
            byte %00000000   '$1B

            byte %11111111   '$1C
            byte %10000001   '$1C
            byte %10000001   '$1C
            byte %10000001   '$1C
            byte %11111111   '$1C
            byte %00000000   '$1C
            byte %00000000   '$1C
            byte %00000000   '$1C

            byte %11111111   '$1D
            byte %10000001   '$1D
            byte %10000001   '$1D
            byte %10000001   '$1D
            byte %11111111   '$1D
            byte %00000000   '$1D
            byte %00000000   '$1D
            byte %00000000   '$1D

            byte %11111111   '$1E
            byte %10000001   '$1E
            byte %10000001   '$1E
            byte %10000001   '$1E
            byte %11111111   '$1E
            byte %00000000   '$1E
            byte %00000000   '$1E
            byte %00000000   '$1E

            byte %11111111   '$1F
            byte %10000001   '$1F
            byte %10000001   '$1F
            byte %10000001   '$1F
            byte %11111111   '$1F
            byte %00000000   '$1F
            byte %00000000   '$1F
            byte %00000000   '$1F

            byte %00000000   '$20
            byte %00000000   '$20
            byte %00000000   '$20
            byte %00000000   '$20
            byte %00000000   '$20
            byte %00000000   '$20
            byte %00000000   '$20
            byte %00000000   '$20

            byte %01011111   '$21
            byte %00000000   '$21
            byte %00000000   '$21
            byte %00000000   '$21
            byte %00000000   '$21
            byte %00000000   '$21
            byte %00000000   '$21
            byte %00000000   '$21

            byte %00000011   '$22
            byte %00000101   '$22
            byte %00000000   '$22
            byte %00000011   '$22
            byte %00000101   '$22
            byte %00000000   '$22
            byte %00000000   '$22
            byte %00000000   '$22

            byte %00010100   '$23
            byte %00111110   '$23
            byte %00010100   '$23
            byte %00111110   '$23
            byte %00010100   '$23
            byte %00000000   '$23
            byte %00000000   '$23
            byte %00000000   '$23

            byte %00100100   '$24
            byte %00101010   '$24
            byte %01111111   '$24
            byte %00101010   '$24
            byte %00010010   '$24
            byte %00000000   '$24
            byte %00000000   '$24
            byte %00000000   '$24

            byte %01100011   '$25
            byte %00010000   '$25
            byte %00001000   '$25
            byte %00000100   '$25
            byte %01100011   '$25
            byte %00000000   '$25
            byte %00000000   '$25
            byte %00000000   '$25

            byte %00110110   '$26
            byte %01001001   '$26
            byte %01010110   '$26
            byte %00100000   '$26
            byte %01010000   '$26
            byte %00000000   '$26
            byte %00000000   '$26
            byte %00000000   '$26

            byte %00000000   '$27
            byte %00000000   '$27
            byte %00000101   '$27
            byte %00000011   '$27
            byte %00000000   '$27
            byte %00000000   '$27
            byte %00000000   '$27
            byte %00000000   '$27

            byte %00000000   '$28
            byte %00000000   '$28
            byte %00011100   '$28
            byte %00100010   '$28
            byte %01000001   '$28
            byte %00000000   '$28
            byte %00000000   '$28
            byte %00000000   '$28

            byte %01000001   '$29
            byte %00100010   '$29
            byte %00011100   '$29
            byte %00000000   '$29
            byte %00000000   '$29
            byte %00000000   '$29
            byte %00000000   '$29
            byte %00000000   '$29

            byte %00100100   '$2A
            byte %00011000   '$2A
            byte %01111110   '$2A
            byte %00011000   '$2A
            byte %00100100   '$2A
            byte %00000000   '$2A
            byte %00000000   '$2A
            byte %00000000   '$2A

            byte %00001000   '$2B
            byte %00001000   '$2B
            byte %00111110   '$2B
            byte %00001000   '$2B
            byte %00001000   '$2B
            byte %00000000   '$2B
            byte %00000000   '$2B
            byte %00000000   '$2B

            byte %10100000   '$2C
            byte %01100000   '$2C
            byte %00000000   '$2C
            byte %00000000   '$2C
            byte %00000000   '$2C
            byte %00000000   '$2C
            byte %00000000   '$2C
            byte %00000000   '$2C

            byte %00001000   '$2D
            byte %00001000   '$2D
            byte %00001000   '$2D
            byte %00001000   '$2D
            byte %00001000   '$2D
            byte %00000000   '$2D
            byte %00000000   '$2D
            byte %00000000   '$2D

            byte %01100000   '$2E
            byte %01100000   '$2E
            byte %00000000   '$2E
            byte %00000000   '$2E
            byte %00000000   '$2E
            byte %00000000   '$2E
            byte %00000000   '$2E
            byte %00000000   '$2E

            byte %01100000   '$2F
            byte %00010000   '$2F
            byte %00001000   '$2F
            byte %00000100   '$2F
            byte %00000011   '$2F
            byte %00000000   '$2F
            byte %00000000   '$2F
            byte %00000000   '$2F

            byte %00111110   '$30
            byte %01010001   '$30
            byte %01001001   '$30
            byte %01000101   '$30
            byte %00111110   '$30
            byte %00000000   '$30
            byte %00000000   '$30
            byte %00000000   '$30

            byte %00000000   '$31
            byte %01000010   '$31
            byte %01111111   '$31
            byte %01000000   '$31
            byte %00000000   '$31
            byte %00000000   '$31
            byte %00000000   '$31
            byte %00000000   '$31

            byte %01100010   '$32
            byte %01010001   '$32
            byte %01010001   '$32
            byte %01001001   '$32
            byte %01000110   '$32
            byte %00000000   '$32
            byte %00000000   '$32
            byte %00000000   '$32

            byte %00100010   '$33
            byte %01001001   '$33
            byte %01001001   '$33
            byte %01001001   '$33
            byte %00110110   '$33
            byte %00000000   '$33
            byte %00000000   '$33
            byte %00000000   '$33

            byte %00011000   '$34
            byte %00010100   '$34
            byte %00010010   '$34
            byte %01111111   '$34
            byte %00010000   '$34
            byte %00000000   '$34
            byte %00000000   '$34
            byte %00000000   '$34

            byte %00100111   '$35
            byte %01000101   '$35
            byte %01000101   '$35
            byte %01000101   '$35
            byte %00111001   '$35
            byte %00000000   '$35
            byte %00000000   '$35
            byte %00000000   '$35

            byte %00111100   '$36
            byte %01001010   '$36
            byte %01001001   '$36
            byte %01001001   '$36
            byte %00110000   '$36
            byte %00000000   '$36
            byte %00000000   '$36
            byte %00000000   '$36

            byte %00000001   '$37
            byte %01110001   '$37
            byte %00001001   '$37
            byte %00000101   '$37
            byte %00000011   '$37
            byte %00000000   '$37
            byte %00000000   '$37
            byte %00000000   '$37

            byte %00110110   '$38
            byte %01001001   '$38
            byte %01001001   '$38
            byte %01001001   '$38
            byte %00110110   '$38
            byte %00000000   '$38
            byte %00000000   '$38
            byte %00000000   '$38

            byte %00000110   '$39
            byte %01001001   '$39
            byte %01001001   '$39
            byte %00101001   '$39
            byte %00011110   '$39
            byte %00000000   '$39
            byte %00000000   '$39
            byte %00000000   '$39

            byte %00110110   '$3A
            byte %00110110   '$3A
            byte %00000000   '$3A
            byte %00000000   '$3A
            byte %00000000   '$3A
            byte %00000000   '$3A
            byte %00000000   '$3A
            byte %00000000   '$3A

            byte %10110110   '$3B
            byte %01110110   '$3B
            byte %00000000   '$3B
            byte %00000000   '$3B
            byte %00000000   '$3B
            byte %00000000   '$3B
            byte %00000000   '$3B
            byte %00000000   '$3B

            byte %00000000   '$3C
            byte %00001000   '$3C
            byte %00010100   '$3C
            byte %00100010   '$3C
            byte %01000001   '$3C
            byte %00000000   '$3C
            byte %00000000   '$3C
            byte %00000000   '$3C

            byte %00010100   '$3D
            byte %00010100   '$3D
            byte %00010100   '$3D
            byte %00010100   '$3D
            byte %00010100   '$3D
            byte %00000000   '$3D
            byte %00000000   '$3D
            byte %00000000   '$3D

            byte %01000001   '$3E
            byte %00100010   '$3E
            byte %00010100   '$3E
            byte %00001000   '$3E
            byte %00000000   '$3E
            byte %00000000   '$3E
            byte %00000000   '$3E
            byte %00000000   '$3E

            byte %00000010   '$3F
            byte %00000001   '$3F
            byte %01010001   '$3F
            byte %00001001   '$3F
            byte %00000110   '$3F
            byte %00000000   '$3F
            byte %00000000   '$3F
            byte %00000000   '$3F

            byte %00111110   '$40
            byte %01000001   '$40
            byte %01011101   '$40
            byte %01010001   '$40
            byte %01001110   '$40
            byte %00000000   '$40
            byte %00000000   '$40
            byte %00000000   '$40

            byte %01111100   '$41
            byte %00010010   '$41
            byte %00010001   '$41
            byte %00010010   '$41
            byte %01111100   '$41
            byte %00000000   '$41
            byte %00000000   '$41
            byte %00000000   '$41

            byte %01111111   '$42
            byte %01001001   '$42
            byte %01001001   '$42
            byte %01001001   '$42
            byte %00110110   '$42
            byte %00000000   '$42
            byte %00000000   '$42
            byte %00000000   '$42

            byte %00011100   '$43
            byte %00100010   '$43
            byte %01000001   '$43
            byte %01000001   '$43
            byte %00100010   '$43
            byte %00000000   '$43
            byte %00000000   '$43
            byte %00000000   '$43

            byte %01111111   '$44
            byte %01000001   '$44
            byte %01000001   '$44
            byte %00100010   '$44
            byte %00011100   '$44
            byte %00000000   '$44
            byte %00000000   '$44
            byte %00000000   '$44

            byte %01111111   '$45
            byte %01001001   '$45
            byte %01001001   '$45
            byte %01001001   '$45
            byte %01000001   '$45
            byte %00000000   '$45
            byte %00000000   '$45
            byte %00000000   '$45

            byte %01111111   '$46
            byte %00001001   '$46
            byte %00001001   '$46
            byte %00001001   '$46
            byte %00000001   '$46
            byte %00000000   '$46
            byte %00000000   '$46
            byte %00000000   '$46

            byte %00111110   '$47
            byte %01000001   '$47
            byte %01000001   '$47
            byte %01010001   '$47
            byte %00110010   '$47
            byte %00000000   '$47
            byte %00000000   '$47
            byte %00000000   '$47

            byte %01111111   '$48
            byte %00001000   '$48
            byte %00001000   '$48
            byte %00001000   '$48
            byte %01111111   '$48
            byte %00000000   '$48
            byte %00000000   '$48
            byte %00000000   '$48

            byte %01000001   '$49
            byte %01000001   '$49
            byte %01111111   '$49
            byte %01000001   '$49
            byte %01000001   '$49
            byte %00000000   '$49
            byte %00000000   '$49
            byte %00000000   '$49

            byte %00100000   '$4A
            byte %01000000   '$4A
            byte %01000000   '$4A
            byte %01000000   '$4A
            byte %00111111   '$4A
            byte %00000000   '$4A
            byte %00000000   '$4A
            byte %00000000   '$4A

            byte %01111111   '$4B
            byte %00001000   '$4B
            byte %00010100   '$4B
            byte %00100010   '$4B
            byte %01000001   '$4B
            byte %00000000   '$4B
            byte %00000000   '$4B
            byte %00000000   '$4B

            byte %01111111   '$4C
            byte %01000000   '$4C
            byte %01000000   '$4C
            byte %01000000   '$4C
            byte %01000000   '$4C
            byte %00000000   '$4C
            byte %00000000   '$4C
            byte %00000000   '$4C

            byte %01111111   '$4D
            byte %00000010   '$4D
            byte %00001100   '$4D
            byte %00000010   '$4D
            byte %01111111   '$4D
            byte %00000000   '$4D
            byte %00000000   '$4D
            byte %00000000   '$4D

            byte %01111111   '$4E
            byte %00000100   '$4E
            byte %00001000   '$4E
            byte %00010000   '$4E
            byte %01111111   '$4E
            byte %00000000   '$4E
            byte %00000000   '$4E
            byte %00000000   '$4E

            byte %00111110   '$4F
            byte %01000001   '$4F
            byte %01000001   '$4F
            byte %01000001   '$4F
            byte %00111110   '$4F
            byte %00000000   '$4F
            byte %00000000   '$4F
            byte %00000000   '$4F

            byte %01111111   '$50
            byte %00001001   '$50
            byte %00001001   '$50
            byte %00001001   '$50
            byte %00000110   '$50
            byte %00000000   '$50
            byte %00000000   '$50
            byte %00000000   '$50

            byte %00111110   '$51
            byte %01000001   '$51
            byte %01010001   '$51
            byte %00100001   '$51
            byte %01011110   '$51
            byte %00000000   '$51
            byte %00000000   '$51
            byte %00000000   '$51

            byte %01111111   '$52
            byte %00001001   '$52
            byte %00011001   '$52
            byte %00101001   '$52
            byte %01000110   '$52
            byte %00000000   '$52
            byte %00000000   '$52
            byte %00000000   '$52

            byte %00100110   '$53
            byte %01001001   '$53
            byte %01001001   '$53
            byte %01001001   '$53
            byte %00110010   '$53
            byte %00000000   '$53
            byte %00000000   '$53
            byte %00000000   '$53

            byte %00000001   '$54
            byte %00000001   '$54
            byte %01111111   '$54
            byte %00000001   '$54
            byte %00000001   '$54
            byte %00000000   '$54
            byte %00000000   '$54
            byte %00000000   '$54

            byte %00111111   '$55
            byte %01000000   '$55
            byte %01000000   '$55
            byte %01000000   '$55
            byte %00111111   '$55
            byte %00000000   '$55
            byte %00000000   '$55
            byte %00000000   '$55

            byte %00000111   '$56
            byte %00011000   '$56
            byte %01100000   '$56
            byte %00011000   '$56
            byte %00000111   '$56
            byte %00000000   '$56
            byte %00000000   '$56
            byte %00000000   '$56

            byte %00111111   '$57
            byte %01000000   '$57
            byte %00111000   '$57
            byte %01000000   '$57
            byte %00111111   '$57
            byte %00000000   '$57
            byte %00000000   '$57
            byte %00000000   '$57

            byte %01100011   '$58
            byte %00010100   '$58
            byte %00001000   '$58
            byte %00010100   '$58
            byte %01100011   '$58
            byte %00000000   '$58
            byte %00000000   '$58
            byte %00000000   '$58

            byte %00000011   '$59
            byte %00000100   '$59
            byte %01111000   '$59
            byte %00000100   '$59
            byte %00000011   '$59
            byte %00000000   '$59
            byte %00000000   '$59
            byte %00000000   '$59

            byte %01100001   '$5A
            byte %01010001   '$5A
            byte %01001001   '$5A
            byte %01000101   '$5A
            byte %01000011   '$5A
            byte %00000000   '$5A
            byte %00000000   '$5A
            byte %00000000   '$5A

            byte %01111111   '$5B
            byte %01111111   '$5B
            byte %01000001   '$5B
            byte %01000001   '$5B
            byte %01000001   '$5B
            byte %00000000   '$5B
            byte %00000000   '$5B
            byte %00000000   '$5B

            byte %00000011   '$5C
            byte %00000100   '$5C
            byte %00001000   '$5C
            byte %00010000   '$5C
            byte %01100000   '$5C
            byte %00000000   '$5C
            byte %00000000   '$5C
            byte %00000000   '$5C

            byte %01000001   '$5D
            byte %01000001   '$5D
            byte %01000001   '$5D
            byte %01111111   '$5D
            byte %01111111   '$5D
            byte %00000000   '$5D
            byte %00000000   '$5D
            byte %00000000   '$5D

            byte %00010000   '$5E
            byte %00001000   '$5E
            byte %00000100   '$5E
            byte %00001000   '$5E
            byte %00010000   '$5E
            byte %00000000   '$5E
            byte %00000000   '$5E
            byte %00000000   '$5E

            byte %10000000   '$5F
            byte %10000000   '$5F
            byte %10000000   '$5F
            byte %10000000   '$5F
            byte %10000000   '$5F
            byte %00000000   '$5F
            byte %00000000   '$5F
            byte %00000000   '$5F

            byte %00000000   '$60
            byte %00000000   '$60
            byte %00000110   '$60
            byte %00000101   '$60
            byte %00000000   '$60
            byte %00000000   '$60
            byte %00000000   '$60
            byte %00000000   '$60

            byte %00100000   '$61
            byte %01010100   '$61
            byte %01010100   '$61
            byte %01010100   '$61
            byte %01111000   '$61
            byte %00000000   '$61
            byte %00000000   '$61
            byte %00000000   '$61

            byte %01111111   '$62
            byte %01000100   '$62
            byte %01000100   '$62
            byte %01000100   '$62
            byte %00111000   '$62
            byte %00000000   '$62
            byte %00000000   '$62
            byte %00000000   '$62

            byte %00111000   '$63
            byte %01000100   '$63
            byte %01000100   '$63
            byte %01000100   '$63
            byte %01000100   '$63
            byte %00000000   '$63
            byte %00000000   '$63
            byte %00000000   '$63

            byte %00111000   '$64
            byte %01000100   '$64
            byte %01000100   '$64
            byte %01000100   '$64
            byte %01111111   '$64
            byte %00000000   '$64
            byte %00000000   '$64
            byte %00000000   '$64

            byte %00111000   '$65
            byte %01010100   '$65
            byte %01010100   '$65
            byte %01010100   '$65
            byte %01011000   '$65
            byte %00000000   '$65
            byte %00000000   '$65
            byte %00000000   '$65

            byte %00001000   '$66
            byte %01111110   '$66
            byte %00001001   '$66
            byte %00001001   '$66
            byte %00000010   '$66
            byte %00000000   '$66
            byte %00000000   '$66
            byte %00000000   '$66

            byte %00011000   '$67
            byte %10100100   '$67
            byte %10100100   '$67
            byte %10100100   '$67
            byte %01111000   '$67
            byte %00000000   '$67
            byte %00000000   '$67
            byte %00000000   '$67

            byte %01111111   '$68
            byte %00000100   '$68
            byte %00000100   '$68
            byte %00000100   '$68
            byte %01111000   '$68
            byte %00000000   '$68
            byte %00000000   '$68
            byte %00000000   '$68

            byte %00000000   '$69
            byte %01000100   '$69
            byte %01111101   '$69
            byte %01000000   '$69
            byte %00000000   '$69
            byte %00000000   '$69
            byte %00000000   '$69
            byte %00000000   '$69

            byte %01000000   '$6A
            byte %10000000   '$6A
            byte %10000100   '$6A
            byte %01111101   '$6A
            byte %00000000   '$6A
            byte %00000000   '$6A
            byte %00000000   '$6A
            byte %00000000   '$6A

            byte %01101111   '$6B
            byte %00010000   '$6B
            byte %00010000   '$6B
            byte %00101000   '$6B
            byte %01000100   '$6B
            byte %00000000   '$6B
            byte %00000000   '$6B
            byte %00000000   '$6B

            byte %00000000   '$6C
            byte %01000001   '$6C
            byte %01111111   '$6C
            byte %01000000   '$6C
            byte %00000000   '$6C
            byte %00000000   '$6C
            byte %00000000   '$6C
            byte %00000000   '$6C

            byte %01111100   '$6D
            byte %00000100   '$6D
            byte %00111000   '$6D
            byte %00000100   '$6D
            byte %01111100   '$6D
            byte %00000000   '$6D
            byte %00000000   '$6D
            byte %00000000   '$6D

            byte %01111100   '$6E
            byte %00000100   '$6E
            byte %00000100   '$6E
            byte %00000100   '$6E
            byte %01111000   '$6E
            byte %00000000   '$6E
            byte %00000000   '$6E
            byte %00000000   '$6E

            byte %00111000   '$6F
            byte %01000100   '$6F
            byte %01000100   '$6F
            byte %01000100   '$6F
            byte %00111000   '$6F
            byte %00000000   '$6F
            byte %00000000   '$6F
            byte %00000000   '$6F

            byte %11111100   '$70
            byte %00100100   '$70
            byte %00100100   '$70
            byte %00100100   '$70
            byte %00011000   '$70
            byte %00000000   '$70
            byte %00000000   '$70
            byte %00000000   '$70

            byte %00011000   '$71
            byte %00100100   '$71
            byte %00100100   '$71
            byte %00100100   '$71
            byte %11111100   '$71
            byte %00000000   '$71
            byte %00000000   '$71
            byte %00000000   '$71

            byte %01111100   '$72
            byte %00001000   '$72
            byte %00000100   '$72
            byte %00000100   '$72
            byte %00000100   '$72
            byte %00000000   '$72
            byte %00000000   '$72
            byte %00000000   '$72

            byte %01001000   '$73
            byte %01010100   '$73
            byte %01010100   '$73
            byte %01010100   '$73
            byte %00100100   '$73
            byte %00000000   '$73
            byte %00000000   '$73
            byte %00000000   '$73

            byte %00000100   '$74
            byte %00111111   '$74
            byte %01000100   '$74
            byte %01000100   '$74
            byte %00100000   '$74
            byte %00000000   '$74
            byte %00000000   '$74
            byte %00000000   '$74

            byte %00111100   '$75
            byte %01000000   '$75
            byte %01000000   '$75
            byte %00100000   '$75
            byte %01111100   '$75
            byte %00000000   '$75
            byte %00000000   '$75
            byte %00000000   '$75

            byte %00011100   '$76
            byte %00100000   '$76
            byte %01000000   '$76
            byte %00100000   '$76
            byte %00011100   '$76
            byte %00000000   '$76
            byte %00000000   '$76
            byte %00000000   '$76

            byte %01111100   '$77
            byte %01000000   '$77
            byte %00110000   '$77
            byte %01000000   '$77
            byte %01111100   '$77
            byte %00000000   '$77
            byte %00000000   '$77
            byte %00000000   '$77

            byte %01000100   '$78
            byte %00101000   '$78
            byte %00010000   '$78
            byte %00101000   '$78
            byte %01000100   '$78
            byte %00000000   '$78
            byte %00000000   '$78
            byte %00000000   '$78

            byte %00011100   '$79
            byte %10100000   '$79
            byte %10100000   '$79
            byte %10100000   '$79
            byte %01111100   '$79
            byte %00000000   '$79
            byte %00000000   '$79
            byte %00000000   '$79

            byte %01000100   '$7A
            byte %01100100   '$7A
            byte %01010100   '$7A
            byte %01001100   '$7A
            byte %01000100   '$7A
            byte %00000000   '$7A
            byte %00000000   '$7A
            byte %00000000   '$7A

            byte %00001000   '$7B
            byte %00111110   '$7B
            byte %01110111   '$7B
            byte %01000001   '$7B
            byte %01000001   '$7B
            byte %00000000   '$7B
            byte %00000000   '$7B
            byte %00000000   '$7B

            byte %00000000   '$7C
            byte %00000000   '$7C
            byte %11111111   '$7C
            byte %00000000   '$7C
            byte %00000000   '$7C
            byte %00000000   '$7C
            byte %00000000   '$7C
            byte %00000000   '$7C

            byte %01000001   '$7D
            byte %01000001   '$7D
            byte %01110111   '$7D
            byte %00111110   '$7D
            byte %00001000   '$7D
            byte %00000000   '$7D
            byte %00000000   '$7D
            byte %00000000   '$7D

            byte %00000100   '$7E
            byte %00000010   '$7E
            byte %00000110   '$7E
            byte %00000100   '$7E
            byte %00000010   '$7E
            byte %00000000   '$7E
            byte %00000000   '$7E
            byte %00000000   '$7E

            byte %11111111   '$7F
            byte %11111111   '$7F
            byte %11111111   '$7F
            byte %11111111   '$7F
            byte %11111111   '$7F
            byte %00000000   '$7F
            byte %00000000   '$7F
            byte %00000000   '$7F
