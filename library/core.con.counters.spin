CON
' CTRA/CTRB register setup
' OR these constants together to set up your desired
'   counter mode. No need to shift bits into position -
'   already performed below:

'PLL settings
    PLLDIV                  = 23
    VCO_DIV_128             = %000 << PLLDIV
    VCO_DIV_64              = %001 << PLLDIV
    VCO_DIV_32              = %010 << PLLDIV
    VCO_DIV_16              = %011 << PLLDIV
    VCO_DIV_8               = %100 << PLLDIV
    VCO_DIV_4               = %101 << PLLDIV
    VCO_DIV_2               = %110 << PLLDIV
    VCO_DIV_1               = %111 << PLLDIV

'Counter modes
    MODE                    = 26
    DISABLE                 = %00000 << MODE

    PLL_INTERNAL            = %00001 << MODE
    PLL_SINGLEEND           = %00010 << MODE
    PLL_DIFFERENTIAL        = %00011 << MODE

    NCO_SINGLEEND           = %00100 << MODE
    NCO_DIFFERENTIAL        = %00101 << MODE

    DUTY_SINGLEEND          = %00110 << MODE
    DUTY_DIFFERENTIAL       = %00111 << MODE

    POS_DETECT              = %01000 << MODE
    POS_DETECT_FB           = %01001 << MODE
    POSEDGE_DETECT          = %01010 << MODE
    POSEDGE_DETECT_FB       = %01011 << MODE

    NEG_DETECT              = %01100 << MODE
    NEG_DETECT_FB           = %01101 << MODE
    NEGEDGE_DETECT          = %01110 << MODE
    NEGEDGE_DETECT_FB       = %01111 << MODE

    LOGIC_NEVER             = %10000 << MODE
    LOGIC_NOTA_AND_NOTB     = %10001 << MODE
    LOGIC_A_AND_NOTB        = %10010 << MODE
    LOGIC_NOTB              = %10011 << MODE
    LOGIC_NOTA_AND_B        = %10100 << MODE
    LOGIC_NOTA              = %10101 << MODE
    LOGIC_A_NE_B            = %10110 << MODE
    LOGIC_NOTA_OR_NOTB      = %10111 << MODE
    LOGIC_A_AND_B           = %11000 << MODE
    LOGIC_A_EQ_B            = %11001 << MODE
    LOGIC_A                 = %11010 << MODE
    LOGIC_A_OR_NOTB         = %11011 << MODE
    LOGIC_B                 = %11100 << MODE
    LOGIC_NOTA_OR_B         = %11101 << MODE
    LOGIC_A_OR_B            = %11110 << MODE
    LOGIC_ALWAYS            = %11111 << MODE

    FLD_APIN                = 0
    FLD_BPIN                = 9

PUB Null
'' This is not a top-level object
