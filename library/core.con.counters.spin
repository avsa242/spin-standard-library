CON
' CTRA/CTRB register setup
' OR these constants together to set up your desired
'   counter mode. No need to shift bits into position -
'   already performed below:

'PLL settings
    PLLDIV_VCO_DIV_128      = %000 << 23
    PLLDIV_VCO_DIV_64       = %001 << 23
    PLLDIV_VCO_DIV_32       = %010 << 23
    PLLDIV_VCO_DIV_16       = %011 << 23
    PLLDIV_VCO_DIV_8        = %100 << 23
    PLLDIV_VCO_DIV_4        = %101 << 23
    PLLDIV_VCO_DIV_2        = %110 << 23
    PLLDIV_VCO_DIV_1        = %111 << 23

'Counter modes
    MODE_DISABLE            = %00000 << 26

    MODE_PLL_INTERNAL       = %00001 << 26
    MODE_PLL_SINGLEEND      = %00010 << 26
    MODE_PLL_DIFFERENTIAL   = %00011 << 26

    MODE_NCO_SINGLEEND      = %00100 << 26
    MODE_NCO_DIFFERENTIAL   = %00101 << 26

    MODE_DUTY_SINGLEEND     = %00110 << 26
    MODE_DUTY_DIFFERENTIAL  = %00111 << 26

    MODE_POS_DETECT         = %01000 << 26
    MODE_POS_DETECT_FB      = %01001 << 26
    MODE_POSEDGE_DETECT     = %01010 << 26
    MODE_POSEDGE_DETECT_FB  = %01011 << 26

    MODE_NEG_DETECT         = %01100 << 26
    MODE_NEG_DETECT_FB      = %01101 << 26
    MODE_NEGEDGE_DETECT     = %01110 << 26
    MODE_NEGEDGE_DETECT_FB  = %01111 << 26

    MODE_LOGIC_NEVER        = %10000 << 26
    MODE_LOGIC_NOTA_AND_NOTB= %10001 << 26
    MODE_LOGIC_A_AND_NOTB   = %10010 << 26
    MODE_LOGIC_NOTB         = %10011 << 26
    MODE_LOGIC_NOTA_AND_B   = %10100 << 26
    MODE_LOGIC_NOTA         = %10101 << 26
    MODE_LOGIC_A_NE_B       = %10110 << 26
    MODE_LOGIC_NOTA_OR_NOTB = %10111 << 26
    MODE_LOGIC_A_AND_B      = %11000 << 26
    MODE_LOGIC_A_EQ_B       = %11001 << 26
    MODE_LOGIC_A            = %11010 << 26
    MODE_LOGIC_A_OR_NOTB    = %11011 << 26
    MODE_LOGIC_B            = %11100 << 26
    MODE_LOGIC_NOTA_OR_B    = %11101 << 26
    MODE_LOGIC_A_OR_B       = %11110 << 26
    MODE_LOGIC_ALWAYS       = %11111 << 26

    FLD_APIN                = 0
    FLD_BPIN                = 9

PUB Null
'' This is not a top-level object
