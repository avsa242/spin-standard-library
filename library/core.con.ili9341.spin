{
    --------------------------------------------
    Filename: core.con.ili9341.spin
    Author: Jesse Burt
    Description: ILI9341-specific constants
    Copyright (c) 2021
    Started Oct 13, 2021
    Updated Oct 13, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Register definitions
    NOOP        = $00
    SWRESET     = $01
    RDDID       = $D3
    RDDST       = $09

    SLPIN       = $10
    SLPOUT      = $11
    PTLON       = $12
    NORON       = $13

    RDMODE      = $0A
    RDMADCTL    = $0B
    RDPIXFMT    = $0C
    RDIMGFMT    = $0D
    RDSELFDIAG  = $0F

    INVOFF      = $20
    INVON       = $21
    GAMMASET    = $26
    DISPOFF     = $28
    DISPON      = $29

    CASET       = $2A
    PASET       = $2B
    RAMWR       = $2C
    RAMRD       = $2E

    PTLAR       = $30
    MADCTL      = $36
    PIXFMT      = $3A

' Access to below requires EXTC pin to be pulled high
    FRMCTR1     = $B1
    FRMCTR2     = $B2
    FRMCTR3     = $B3
    INVCTR      = $B4
    DFUNCTR     = $B6

    ENTRYMODE   = $B7

    PWCTR1      = $C0
    PWCTR2      = $C1
    PWCTR3      = $C2
    PWCTR4      = $C3
    PWCTR5      = $C4
    VMCTR1      = $C5
    VMCTR2      = $C7

    RDID1       = $DA
    RDID2       = $DB
    RDID3       = $DC
    RDID4       = $DD

    GMCTRP1     = $E0
    GMCTRN1     = $E1

PUB Null{}
' This is not a top-level object
    result := (0)
