{
    --------------------------------------------
    Filename: wireless.transceiver.cc1101.spi.spin
    Author: Jesse Burt
    Description: Driver for TI's CC1101 ISM-band transceiver
    Copyright (c) 2019
    Started Mar 25, 2019
    Updated Apr 2, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    F_XOSC                  = 26_000_000        ' CC1101 XTAL Oscillator freq, in Hz
    SIXT                    = 1 << 16           ' 2^16
    UM_FACT                 = 1_000_000_000     ' Scale to use in unsigned math object
    UM_FREQ_RES             = 396_728515        '(F_XOSC / SIXT) * 1_000_000

' Auto-calibration state
    NEVER                   = 0
    IDLE_RXTX               = 1
    RXTX_IDLE               = 2
    RXTX_IDLE4              = 3

' RXOff states
    RXOFF_IDLE              = 0
    RXOFF_FSTXON            = 1
    RXOFF_TX                = 2
    RXOFF_RX                = 3

' TXOff states
    TXOFF_IDLE              = 0
    TXOFF_FSTXON            = 1
    TXOFF_TX                = 2
    TXOFF_RX                = 3

' Modulation formats
    FSK2                    = %000
    GFSK                    = %001
    ASKOOK                  = %011
    FSK4                    = %100
    MSK                     = %111

' CC1101 I/O pin output signals
    TRIG_RXTHRESH_END_PKT   = $01
    TRIG_RXOVERFLOW         = $04
    TRIG_TXUNDERFLOW        = $05
    TRIG_SYNCWORD_TXRX      = $06
    TRIG_CARRIER            = $0E
    IO_CHIP_RDYn            = $29
    IO_XOSC_STABLE          = $2B
    IO_HI_Z                 = $2E
    IO_CLK_XODIV1           = $30
    IO_CLK_XODIV192         = $3F

' Packet Length configuration modes
    PKTLEN_FIXED            = 0
    PKTLEN_VAR              = 1
    PKTLEN_INF              = 2

' Syncword qualifier modes
    SYNCMODE_NONE           = 0
    SYNCMODE_1516           = 1
    SYNCMODE_1616           = 2
    SYNCMODE_3032           = 3
    SYNCMODE_CS_ONLY        = 4
    SYNCMODE_1516_CS        = 5
    SYNCMODE_1616_CS        = 6
    SYNCMODE_3032_CS        = 7

' Address check modes
    ADRCHK_NONE             = 0
    ADRCHK_CHK_NO_BCAST     = 1
    ADRCHK_CHK_00_BCAST     = 2
    ADRCHK_CHK_00_FF_BCAST  = 3

VAR

    byte _CS, _MOSI, _MISO, _SCK
    byte _status_byte

OBJ

    spi     : "SPI_Asm"                                             'PASM SPI Driver
    core    : "core.con.cc1101"
    time    : "time"                                                'Basic timing functions
    umath   : "umath"

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): okay

    okay := Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, core#CLK_DELAY, core#CPOL)

PUB Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, SCK_DELAY, SCK_CPOL): okay
    if SCK_DELAY => 1 and lookdown(SCK_CPOL: 0, 1)
        if okay := spi.start (SCK_DELAY, SCK_CPOL)              'SPI Object Started?
            time.MSleep (5)
            _CS := CS_PIN
            _MOSI := MOSI_PIN
            _MISO := MISO_PIN
            _SCK := SCK_PIN

            outa[_CS] := 1
            dira[_CS] := 1
            if Version => $14                                   'Poll chip for version
                return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.stop

PUB Address(addr) | tmp
' Set address used for packet filtration
'   Valid values: $00..$FF (000-255)
'   Any other value polls the chip and returns the current setting
'   NOTE: $00 and $FF can be used as broadcast addresses.
    readRegX (core#ADDR, 1, @tmp)
    case addr
        $00..$FF:
        OTHER:
            return tmp

    addr &= core#ADDR_MASK
    writeRegX (core#ADDR, 1, @addr)

PUB AddressCheck(check) | tmp
' Short descr
'   Valid values:
'       ADRCHK_NONE (0): No address check
'       ADRCHK_CHK_NO_BCAST (1): Check address, but ignore broadcast addresses
'       ADRCHK_CHK_00_BCAST (2): Check address, and also respond to $00 broadcast address
'       ADRCHK_CHK_00_FF_BCAST (3): Check address, and also respond to both $00 and $FF broadcast addresses
'   Any other value polls the chip and returns the current setting
    readRegX (core#PKTCTRL1, 1, @tmp)
    case check
        0..3:
            check := check & core#BITS_ADR_CHK
        OTHER:
            return tmp & core#BITS_ADR_CHK

    tmp &= core#MASK_ADR_CHK
    tmp := (tmp | check) & core#PKTCTRL1_MASK
    writeRegX (core#PKTCTRL1, 1, @tmp)

PUB AppendStatus(enabled) | tmp
' Append status bytes to packet payload (RSSI, LQI, CRC OK)
'   Valid values:
'      *TRUE (-1 or 1)
'       FALSE (0)
'   Any other value polls the chip and returns the current setting
    readRegX (core#PKTCTRL1, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_APPEND_STATUS
        OTHER:
            result := ((tmp >> core#FLD_APPEND_STATUS) & %1) * TRUE
            return result

    tmp &= core#MASK_APPEND_STATUS
    tmp := (tmp | enabled) & core#PKTCTRL1_MASK
    writeRegX (core#PKTCTRL1, 1, @tmp)

PUB AutoCal(when) | tmp
' When to perform auto-calibration
'   Valid values:
'       NEVER (0) - Never (manually calibrate)
'       IDLE_RXTX (1) - When transitioning from IDLE to RX/TX
'       RXTX_IDLE (2) - When transitioning from RX/TX to IDLE
'       RXTX_IDLE4 (3) - Every 4th time when transitioning from RX/TX to IDLE (power-saving)
    readRegX (core#MCSM0, 1, @tmp)'reg, nr_bytes, addr_buff)
    case when
        0..3:
            when := when << core#FLD_FS_AUTOCAL
        OTHER:
            result := (tmp >> core#FLD_FS_AUTOCAL) & core#BITS_FS_AUTOCAL
            return result

    tmp &= core#MASK_FS_AUTOCAL
    tmp := (tmp | when)
    writeRegX (core#MCSM0, 1, @tmp)'reg, nr_bytes, buf_addr)

PUB CalcFreqWord(Hz)

    result := umath.multdiv (F_XOSC, UM_FACT, Hz)   'Need 64bit math to hold the large scaled up numbers
    result := umath.multdiv (SIXT, UM_FACT, result)
    return

PUB CalFreqSynth
' Calibrate the frequency synthesizer
    writeRegX (core#CS_SCAL, 0, 0)

PUB CarrierFreq(Hz) | tmp
' Set carrier/center frequency, in Hz
'   Valid values:
'       300_000_000..348_000_000, 387_000_000..464_000_000, 779_000_000..928_000_000
'   Any other value polls the chip and returns the current setting
'   NOTE: The actual set frequency has a resolution of fXOSC/2^16 (i.e., approx 396Hz)
    readRegX (core#FREQ2, 3, @tmp)
    case Hz
        300_000_000..348_000_000, 387_000_000..464_000_000, 779_000_000..928_000_000:
            Hz := umath.multdiv (F_XOSC, UM_FACT, Hz)   'Need 64bit math to hold the large scaled up numbers
            Hz := umath.multdiv (SIXT, UM_FACT, Hz)
            Hz.byte[3] := Hz.byte[0]                    'Reverse the byte order - the CC1101 registers are MSB-MB-LSB
            Hz.byte[0] := Hz.byte[2]                    ' but they'd by written LSB-MB-MSB without the swap
            Hz.byte[2] := Hz.byte[3]
            Hz.byte[3] := 0
        OTHER:
            result := ((tmp.byte[0] << 16) | (tmp.byte[1] << 8) | tmp.byte[2])
            return umath.multdiv (result, UM_FREQ_RES, 1_000_000)

    writeRegX (core#FREQ2, 3, @Hz)

PUB CarrierFreqWord(freq_word) | tmp
' Set carrier/center frequency, by frequency word (use CalcFreqWord to calculate)

'   Any other value polls the chip and returns the current setting
    readRegX (core#FREQ2, 3, @tmp)
    case freq_word
        $0B_89_D9..$0D_62_76, $0E_E2_76..$11_D8_9E, $1D_F6_27..$23_B1_3B:
            freq_word.byte[3] := freq_word.byte[0]                    'Reverse the byte order - the CC1101 registers are MSB-MB-LSB
            freq_word.byte[0] := freq_word.byte[2]                    ' but they'd by written LSB-MB-MSB without the swap
            freq_word.byte[2] := freq_word.byte[3]
            freq_word.byte[3] := 0
        OTHER:
            return tmp

    writeRegX (core#FREQ2, 3, @freq_word)

PUB FreqTable(table_addr, entry_nr, freq_word) | tmp

    byte[table_addr][entry_nr*3] := freq_word.byte[0]
    byte[table_addr][(entry_nr*3)+1] := freq_word.byte[1]
    byte[table_addr][(entry_nr*3)+2] := freq_word.byte[2]

PUB CarrierSense(threshold) | tmp
' Set relative change threshold for asserting carrier sense, in dB
'   Valid values:
'       0: Disabled
'       6: 6dB increase in RSSI
'       10: 10dB increase in RSSI
'       14: 14dB increase in RSSI
'   Any other value polls the chip and returns the current setting
    readRegX (core#AGCTRL1, 1, @tmp)
    case threshold
        0, 6, 10, 14:
            threshold := lookdownz(threshold: 0, 6, 10, 14) << core#FLD_CARRIER_SENSE_REL_THR
        OTHER:
            result := (tmp >> core#FLD_CARRIER_SENSE_REL_THR) & core#BITS_CARRIER_SENSE_REL_THR
            return lookupz(result: 0, 6, 10, 14)

    tmp &= core#MASK_CARRIER_SENSE_REL_THR
    tmp := (tmp | threshold) & core#AGCTRL1_MASK
    writeRegX (core#AGCTRL1, 1, @tmp)

PUB CarrierSenseAbs(threshold) | tmp
' Set absolute change threshold for asserting carrier sense, in dB
'   Valid values:
'       %0000..%1111
'   Any other value polls the chip and returns the current setting
    readRegX (core#AGCTRL1, 1, @tmp)
    case threshold
        %0000..%1111:
            threshold := threshold & core#BITS_CARRIER_SENSE_ABS_THR
        OTHER:
            result := tmp & core#BITS_CARRIER_SENSE_ABS_THR

    tmp &= core#MASK_CARRIER_SENSE_ABS_THR
    tmp := (tmp | threshold) & core#AGCTRL1_MASK
    writeRegX (core#AGCTRL1, 1, @tmp)

PUB Channel(chan) | tmp
' Set device channel number
'   Resulting frequency is the channel number multiplied by the channel spacing setting, added to the base frequency
'   Valid values: 0..255
'   Any other value polls the chip and returns the current setting
    readRegX (core#CHANNR, 1, @tmp)
    case chan
        0..255:
        OTHER:
            return tmp

    chan &= core#CHANNR_MASK
    writeRegX (core#CHANNR, 1, @chan)

PUB CRCCheck(enabled) | tmp
' Enable CRC calc (TX) and check (RX)
'   Valid values:
'      *TRUE (-1 or 1)
'       FALSE (0)
'   Any other value polls the chip and returns the current setting
    readRegX (core#PKTCTRL0, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_CRC_EN
        OTHER:
            result := ((tmp >> core#FLD_CRC_EN) & %1) * TRUE
            return result

    tmp &= core#MASK_CRC_EN
    tmp := (tmp | enabled) & core#PKTCTRL0_MASK
    writeRegX (core#PKTCTRL0, 1, @tmp)

PUB CRCAutoFlush(enabled) | tmp
' Enable automatic flush of RX FIFO when CRC check fails
'   Valid values:
'       TRUE (-1 or 1)
'      *FALSE (0)
'   Any other value polls the chip and returns the current setting
    readRegX (core#PKTCTRL1, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_CRC_AUTOFLUSH
        OTHER:
            result := ((tmp >> core#FLD_CRC_AUTOFLUSH) & %1) * TRUE
            return result

    tmp &= core#MASK_CRC_AUTOFLUSH
    tmp := (tmp | enabled) & core#PKTCTRL1_MASK
    writeRegX (core#PKTCTRL1, 1, @tmp)

PUB CrystalOff
' Turn off crystal oscillator
    writeRegX (core#CS_SXOFF, 0, 0)

PUB DataRate(Baud) | tmp, tmp_e, tmp_m, DRATE_E, DRATE_M
' Set on-air data rate, in bps
'   Valid values: 1000, 1200, 2400, 4800, 9600, 19_600, 38_400, 76_800, 153_600, 250_000, 500_000
'   Any other value polls the chip and returns the current setting
    tmp := tmp_e := tmp_m := DRATE_E := DRATE_M := 0

    readRegX (core#MDMCFG4, 1, @tmp_e)
    readRegX (core#MDMCFG3, 1, @tmp_m)
    case Baud := lookdown(Baud: 1000, 1200, 2048, 2400, 4096, 4800, 9600, 19_600, 38_400, 76_800, 153_600, 250_000, 500_000)
        1..13:
            DRATE_E := lookup(Baud: $05, $05, $06, $06, $07, $07, $08, $09, $0A, $0B, $0C, $0D, $0E) & core#BITS_DRATE_E
            DRATE_M := lookup(Baud: $42, $83, $4A, $83, $4A, $83, $83, $8B, $83, $83, $83, $3B, $3B) & core#MDMCFG3_MASK
        OTHER:
            tmp_e &= core#BITS_DRATE_E
            tmp := (tmp_e << 8) | tmp_m
            result := lookdown(tmp: $0542, $0583, $0683, $0783, $0883, $098B, $0A83, $0B83, $0C83, $0D3B, $0E3B)
            return lookup(result: 1000, 1200, 2400, 4800, 9600, 19_600, 38_400, 76_800, 153_600, 250_000, 500_000)

    tmp_e &= core#MASK_DRATE_E
    tmp_e := (tmp_e | DRATE_E)

    writeRegX (core#MDMCFG4, 1, @tmp_e)
    writeRegX (core#MDMCFG3, 1, @DRATE_M)

PUB DCBlock(enabled) | tmp
' Enable digital DC blocking filter (before demod)
'   Valid values: TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
'   NOTE: Enable for better sensitivity (default).
'       Disable for optimizing current usage. Only for data rates 250kBaud and lower
    readRegX (core#MDMCFG2, 1, @tmp)
    case enabled := ||enabled
        0, 1:
            enabled := ((enabled ^ 1) << core#FLD_DEM_DCFILT_OFF)
        OTHER:
            result := (((tmp >> core#FLD_DEM_DCFILT_OFF) & %1) ^ 1) * TRUE
            return result

    tmp &= core#MASK_DEM_DCFILT_OFF
    tmp := (tmp | enabled)
    writeRegX (core#MDMCFG2, 1, @tmp)

PUB Deviation(freq) | tmp
' Set frequency deviation from carrier, in Hz
'   Valid values:
'       1_586..380_859
'       *47_607
'   NOTE: This setting has no effect when Modulation format is ASK/OOK.
'   NOTE: This setting applies to both TX and RX roles. When role is RX, setting must be
'           approximately correct for reliable demodulation.
'   Any other value polls the chip and returns the current setting
    readRegX (core#DEVIATN, 1, @tmp)
    case freq
        80000:
            freq := $55
        1586..380859:
'            freq := freq << core#FLD_FIELDNAME
            freq := $13
        OTHER:
            result := tmp & core#DEVIATN_MASK
            return result

    tmp := $00
    tmp := (tmp | freq)
    writeRegX (core#DEVIATN, 1, @tmp)

PUB DVGA(gain) | tmp
' Set Digital Variable Gain Amplifier gain maximum level
'   Valid values:
'       0 - Highest gain setting
'       -1 - Highest gain setting-1
'       -2 - Highest gain setting-2
'       -3 - Highest gain setting-3
'   Any other value polls the chip and returns the current setting
    readRegX (core#AGCTRL2, 1, @tmp)
    case gain
        -3..0:
            gain := ||gain << core#FLD_MAX_DVGA_GAIN
        OTHER:
            result := (tmp >> core#FLD_MAX_DVGA_GAIN) & core#BITS_MAX_DVGA_GAIN
            return result*-1

    tmp &= core#MASK_MAX_DVGA_GAIN
    tmp := (tmp | gain)
    writeRegX (core#AGCTRL2, 1, @tmp)

PUB FEC(enabled) | tmp
' Enable forward error correction with interleaving
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
'   NOTE: Only supported for fixed packet length mode
    readRegX (core#MDMCFG1, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_FEC_EN
        OTHER:
            result := ((tmp >> core#FLD_FEC_EN) & %1) * TRUE
            return result

    tmp &= core#MASK_FEC_EN
    tmp := (tmp | enabled) & core#MDMCFG1_MASK
    writeRegX (core#MDMCFG1, 1, @tmp)

PUB FIFO
' Returns number of bytes available in RX FIFO or free bytes in TX FIFO
    return Status & %1111

PUB FIFORX
' Returns number of bytes in RX FIFO
' NOTE: The MSB indicates if the RX FIFO has overflowed.
    readRegX (core#RXBYTES, 1, @result)

PUB FIFOTX
' Returns number of bytes in TX FIFO
' NOTE: The MSB indicates if the TX FIFO is underflowed.
    readRegX (core#TXBYTES, 1, @result)
    result &= $7F

PUB FilterLength(samples) | tmp
' For 2FSK, 4FSK, MSK, set averaging length for amplitude from the channel filter, in samples
' For OOK/ASK, set decision boundary for reception
'   Valid values:
'       FSK/MSK     OOK/ASK
'       Samples     decision boundary
'       8           4dB
'       16          8dB
'       32          12dB
'       64          16dB
'   Any other value polls the chip and returns the current setting
    readRegX (core#AGCTRL0, 1, @tmp)
    case samples
        8, 16, 32, 64:
            samples := lookdownz(samples: 8, 16, 32, 64) & core#BITS_FILTER_LENGTH
        OTHER:
            result := tmp & core#BITS_FILTER_LENGTH
            return lookupz(result: 8, 16, 32, 64)

    tmp &= core#MASK_FILTER_LENGTH
    tmp := (tmp | samples) & core#AGCTRL0_MASK
    writeRegX (core#AGCTRL0, 1, @tmp)

PUB FlushRX
' Flush receive FIFO/buffer
'   NOTE: Will only flush RX buffer if overflowed or if chip is idle, per datasheet recommendation
'    case Status
'        core#MARCSTATE_RXFIFO_OVERFLOW, core#MARCSTATE_IDLE:
            writeRegX (core#CS_SFRX, 0, 0)
'        OTHER:
'            return

PUB FlushTX
' Flush transmit FIFO/buffer
'   NOTE: Will only flush TX buffer if underflowed or if chip is idle, per datasheet recommendation
'    case _status_byte
'        core#MARCSTATE_TXFIFO_UNDERFLOW, core#MARCSTATE_IDLE:
            writeRegX (core#CS_SFTX, 0, 0)
'        OTHER:
'            return

PUB FSTX
' Enable frequency synthesizer and calibrate
    writeRegX (core#CS_SFSTXON, 0, 0)

PUB GDO0(config) | tmp
' Configure test signal output on GD0 pin
'   Valid values: $00..$0F, $16..$17, $1B..$1D, $24..$39, $41, $43, $46..$3F
'   Any other value polls the chip and returns the current setting
'   NOTE: The default setting is IO_CLK_XODIV192, which outputs the CC1101's XO clock, divided by 192 on the pin.
'       TI recommends the clock outputs be disabled when the radio is active, for best performance.
'       Only one IO pin at a time can be configured as a clock output.
    readRegX (core#IOCFG0, 1, @tmp)
    case config
        $00..$0F, $16..$17, $1B..$1D, $24..$27, $29, $2B, $2E..$3F:
            config &= core#BITS_GDO0_CFG
        OTHER:
            return tmp & core#BITS_GDO0_CFG

    tmp &= core#MASK_GDO0_CFG
    tmp := (tmp | config)
    writeRegX (core#IOCFG0, 1, @tmp)

PUB GDO1(config) | tmp
' Configure test signal output on GD0 pin
'   Valid values: $00..$0F, $16..$17, $1B..$1D, $24..$39, $41, $43, $46..$3F
'   Any other value polls the chip and returns the current setting
'   NOTE: This pin is shared with the SPI signal SO, and is valid only when CS is high.
'       The default setting is IO_HI_Z ($2E): Hi-Z/High-impedance/Tri-state
    readRegX (core#IOCFG1, 1, @tmp)
    case config
        $00..$0F, $16..$17, $1B..$1D, $24..$27, $29, $2B, $2E..$3F:
            config &= core#BITS_GDO1_CFG
        OTHER:
            return tmp & core#BITS_GDO1_CFG

    tmp &= core#MASK_GDO1_CFG
    tmp := (tmp | config)
    writeRegX (core#IOCFG1, 1, @tmp)

PUB GDO2(config) | tmp
' Configure test signal output on GD0 pin
'   Valid values: $00..$0F, $16..$17, $1B..$1D, $24..$39, $41, $43, $46..$3F
'   Any other value polls the chip and returns the current setting
'   NOTE: The default setting is IO_CHIP_RDYn
    readRegX (core#IOCFG2, 1, @tmp)
    case config
        $00..$0F, $16..$17, $1B..$1D, $24..$27, $29, $2B, $2E..$3F:
            config &= core#BITS_GDO2_CFG
        OTHER:
            return tmp & core#BITS_GDO2_CFG

    tmp &= core#MASK_GDO2_CFG
    tmp := (tmp | config)
    writeRegX (core#IOCFG2, 1, @tmp)

PUB Idle
' Change chip state to IDLE
    writeRegX (core#CS_SIDLE, 0, 0)

PUB IntFreq(kHz) | tmp
' Intermediate Frequency (IF), in kHz
'   Valid values: 25..787 (result will be rounded to the nearest 5-bit result)
'   Any other value polls the chip and returns the current setting
    readRegX (core#FSCTRL1, 1, @tmp)
    case kHz
        25..787:
            kHz := 1024/(F_XOSC/kHz)
        OTHER:
            return ((F_XOSC / 1024) * tmp) / 1000

    writeRegX (core#FSCTRL1, 1, @kHz)

PUB LNA(gain) | tmp
' Set maximum LNA+LNA2 gain (relative to maximum possible gain)
'   Valid values:
'       0 - Maximum possible LNA+LNA2 gain
'       -2 - ~2.6dB below maximum
'       -6 - ~6.1dB below maximum
'       -7 - ~7.4dB below maximum
'       -9 - ~9.2dB below maximum
'       -11 - ~11.5dB below maximum
'       -14 - ~14.6dB below maximum
'       -17 - ~17.1dB below maximum
'   Any other value polls the chip and returns the current setting
    readRegX (core#AGCTRL2, 1, @tmp)
    case gain
        0, -2, -6, -7, -9, -11, -14, -17:
            gain := lookdownz(gain: 0, -2, -6, -7, -9, -11, -14, -17) << core#FLD_MAX_LNA_GAIN
        OTHER:
            result := (tmp >> core#FLD_MAX_LNA_GAIN) & core#BITS_MAX_LNA_GAIN
            return lookupz(result: 0, -2, -6, -7, -9, -11, -14, -17)

    tmp &= core#MASK_MAX_LNA_GAIN
    tmp := (tmp | gain)
    writeRegX (core#AGCTRL2, 1, @tmp)

PUB MagnTarget(val) | tmp
' Set target value for averaged amplitude from digital channel filter, in dB
'   Valid values:
'       24, 27, 30, 33, 36, 38, 40, 42
'   Any other value polls the chip and returns the current setting
    readRegX (core#AGCTRL2, 1, @tmp)
    case val
        24, 27, 30, 33, 36, 38, 40, 42:
            val := lookdownz(val: 24, 27, 30, 33, 36, 38, 40, 42) & core#BITS_MAGN_TARGET
        OTHER:
            result := tmp & core#BITS_MAGN_TARGET
            return lookupz(result: 24, 27, 30, 33, 36, 38, 40, 42)

    tmp &= core#MASK_MAGN_TARGET
    tmp := (tmp | val)
    writeRegX (core#AGCTRL2, 1, @tmp)

PUB ManchesterEnc(enabled) | tmp
' Enable Manchester encoding/decoding
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    readRegX (core#MDMCFG2, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_MANCHESTER_EN
        OTHER:
            result := ((tmp >> core#FLD_MANCHESTER_EN) & %1) * TRUE
            return result

    tmp &= core#MASK_MANCHESTER_EN
    tmp := (tmp | enabled)
    writeRegX (core#MDMCFG2, 1, @tmp)

PUB Modulation(format) | tmp
' Set modulation of transmitted or expected signal
'   Valid values:
'       FSK2 (%000): 2-level or binary Frequency Shift-Keyed
'       GFSK (%001): Gaussian FSK
'       ASKOOK (%011): Amplitude Shift-Keyed or On Off-Keyed
'       FSK4 (%100): 4-level FSK
'       MSK (%111): Minimum Shift-Keyed
'   Any other value polls the chip and returns the current setting
'   NOTE: MSK supported only at baud rates greater than 26k
    readRegX (core#MDMCFG2, 1, @tmp)
    case format
        FSK2, GFSK, ASKOOK, FSK4, MSK:
            format := format << core#FLD_MOD_FORMAT
        OTHER:
            return (tmp >> core#FLD_MOD_FORMAT) & core#BITS_MOD_FORMAT

    tmp &= core#MASK_MOD_FORMAT
    tmp := (tmp | format)
    writeRegX (core#MDMCFG2, 1, @tmp)

PUB PacketLen(length) | tmp
' Set packet length, when using fixed packet length mode,
'   or maximum packet length when using variable packet length mode.
'   Valid values: 1..255
'   Any other value polls the chip and returns the current setting
    readRegX (core#PKTLEN, 1, @tmp)
    case length
        1..255:
            length &= core#PKTLEN_MASK
        OTHER:
            return tmp & core#PKTLEN_MASK

    writeRegX (core#PKTLEN, 1, @length)

PUB PacketLenCfg(mode) | tmp
' Set packet length mode
'   Valid values:
'       PKTLEN_FIXED (0): Fixed packet length mode. Set length with PacketLen
'      *PKTLEN_VAR (1): Variable packet length mode. Packet length set by first byte after sync word
'       PKTLEN_INF (2): Infinite packet length mode.
'   Any other value polls the chip and returns the current setting
    readRegX (core#PKTCTRL0, 1, @tmp)
    case mode
        0..2:
        OTHER:
            return tmp & core#BITS_LENGTH_CONFIG

    tmp &= core#MASK_LENGTH_CONFIG
    tmp := (tmp | mode) & core#PKTCTRL0_MASK
    writeRegX (core#PKTCTRL0, 1, @tmp)

PUB PartNumber
' Part number of device
'   Returns: $00
    readRegX (core#PARTNUM, 1, @result)

PUB PARead(buf_addr)
' Read 8-byte PA table into buf_addr
'   NOTE: Ensure buf_addr is at least 8 bytes
    readRegX (core#PATABLE | core#BURST, 8, buf_addr)

PUB PAWrite(buf_addr)
' Write 8-byte PA table from buf_addr
'   NOTE: Table will be written starting at index 0 from the LSB of buf_addr
    writeRegX (core#PATABLE | core#BURST, 8, buf_addr)

PUB Preamble(bytes) | tmp
' Set number of preamble bytes
'   Valid values: 2, 3, 4, 6, 8, 12, 16, 24
'   Any other value polls the chip and returns the current setting
    readRegX (core#MDMCFG1, 1, @tmp)
    case bytes
        2, 3, 4, 6, 8, 12, 16, 24:
            bytes := (lookdownz(bytes: 2, 3, 4, 6, 8, 12, 16, 24)) << core#FLD_NUM_PREAMBLE
        OTHER:
            result := (tmp >> core#FLD_NUM_PREAMBLE) & core#BITS_NUM_PREAMBLE
            return lookupz(result: 2, 3, 4, 6, 8, 12, 16, 24)

    tmp &= core#MASK_NUM_PREAMBLE
    tmp := (tmp | bytes)
    writeRegX (core#MDMCFG1, 1, @tmp)

PUB PreambleQual(threshold) | tmp
' Set Preamble quality estimator threshold
'   Valid values: 0, 4, 8, 12, 16, 20, 24, 28
'   NOTE: If 0, the sync word is always accepted.
'   Any other value polls the chip and returns the current setting
    readRegX (core#PKTCTRL1, 1, @tmp)
    case lookdown(threshold: 0, 4, 8, 12, 16, 20, 24, 28)
        1..8:
            threshold := lookdownz(threshold: 0, 4, 8, 12, 16, 20, 24, 28) << core#FLD_PQT
        OTHER:
            result := ((tmp >> core#FLD_PQT) & core#BITS_PQT)
            return lookupz(result: 0, 4, 8, 12, 16, 20, 24, 28)

    tmp &= core#MASK_PQT
    tmp := (tmp | threshold) & core#PKTCTRL1_MASK
    writeRegX (core#PKTCTRL1, 1, @tmp)

PUB Reset
' Reset the chip
    writeRegX (core#CS_SRES, 0, 0)

PUB RSSI
' Received Signal Strength Indicator
    readRegX (core#RSSI, 1, @result)
    if result => 128
        result := ((result - 256) / 2) - 74
    else
        result := (result / 2) - 74

PUB RX
' Change chip state to RX (receive)
    writeRegX (core#CS_SRX, 0, 0)

PUB RXBandwidth(kHz) | tmp
' Set receiver channel filter bandwidth, in kHz
'   Valid values: 812, 650, 541, 464, 406, 325, 270, 232, 203, 162, 135, 116, 102, 81, 68, 58
'   Any other value polls the chip and returns the current setting
    readRegX (core#MDMCFG4, 1, @tmp)
    case kHz := lookdown(kHz: 812, 650, 541, 464, 406, 325, 270, 232, 203, 162, 135, 116, 102, 81, 68, 58)
        1..16:
            kHz := (kHz-1) << core#FLD_CHANBW
        OTHER:
            result := ((tmp >> core#FLD_CHANBW) & core#BITS_CHANBW)+1
            return lookup(result: 812, 650, 541, 464, 406, 325, 270, 232, 203, 162, 135, 116, 102, 81, 68, 58)

    tmp &= core#MASK_CHANBW
    tmp := (tmp | kHz)
    writeRegX (core#MDMCFG4, 1, @tmp)

PUB RXData(nr_bytes, buf_addr) | tmp
' Read data queued in the RX FIFO
'   nr_bytes Valid values: 1..64
'   Any other value is ignored
'   NOTE: Ensure buffer at address buf_addr is at least as big as the number of bytes you're reading
    readRegX (core#FIFO, nr_bytes, buf_addr)

PUB RXFIFOThresh(threshold) | tmp
' Set receive FIFO threshold, in bytes
'   The threshold is exceeded when the number of bytes in the FIFO is greater than or equal to the threshold value.
'   Valid values: 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64
'   Any other value polls the chip and returns the current setting
'   NOTE: This affects the TX FIFO, inversely
    readRegX (core#FIFOTHR, 1, @tmp)
    case threshold := lookdown(threshold: 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64)
        1..16:
            threshold := (threshold-1) & core#BITS_FIFO_THR
        OTHER:
            result := (tmp & core#BITS_FIFO_THR) + 1
            return lookup(result: 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64)

    tmp &= core#MASK_FIFO_THR
    tmp := (tmp | threshold) & core#FIFOTHR_MASK
    writeRegX (core#FIFOTHR, 1, @tmp)

PUB RXOff(next_state) | tmp
' Defines the state the radio transitions to after a packet is successfully received
'   Valid values:
'       RXOFF_IDLE (0) - Idle state
'       RXOFF_FSTXON (1) - Turn frequency synth on and ready at TX freq. To transmit, call TX
'       RXOFF_TX (2) - Start sending preamble
'       RXOFF_RX (3) - Wait for more packets
'   Any other value polls the chip and returns the current setting
    readRegX (core#MCSM1, 1, @tmp)
    case next_state
        0..3:
            next_state := next_state << core#FLD_RXOFF_MODE
        OTHER:
            result := (tmp >> core#FLD_RXOFF_MODE) & core#BITS_RXOFF_MODE
            return result

    tmp &= core#MASK_RXOFF_MODE
    tmp := (tmp | next_state)
    writeRegX (core#MCSM1, 1, @tmp)

PUB Sleep
' Power down chip
    writeRegX (core#CS_SPWD, 0, 0)

PUB State
' Read state-machine register
    readRegX (core#MARCSTATE, 1, @result)

PUB Status
' Read the status byte
    writeRegX (core#CS_SNOP, 0, 0)
    return _status_byte

PUB SyncMode(mode) | tmp
' Set sync-word qualifier mode
'   Valid values:
'       SYNCMODE_NONE (0): No preamble or syncword
'       SYNCMODE_1516 (1): 15 of 16 syncword bits must match
'      *SYNCMODE_1616 (2): 16 of 16 syncword bits must match
'       SYNCMODE_3032 (3): 30 of 32 syncword bits must match
'       SYNCMODE_CS_ONLY (4): No preamble or syncword. Carrier-sense must be above threshold
'       SYNCMODE_1516_CS (5): 15 of 16 syncword bits must match, and carrier-sense must be above threshold
'       SYNCMODE_1616_CS (6): 16 of 16 syncword bits must match, and carrier-sense must be above threshold
'       SYNCMODE_3032_CS (7): 30 of 32 syncword bits must match, and carrier-sense must be above threshold
'   Any other value polls the chip and returns the current setting
    readRegX (core#MDMCFG2, 1, @tmp)
    case mode
        0..7:
        OTHER:
            return tmp & core#BITS_SYNC_MODE

    tmp &= core#MASK_SYNC_MODE
    tmp := (tmp | mode) & core#MDMCFG2_MASK
    writeRegX (core#MDMCFG2, 1, @tmp)

PUB SyncWord(sync_word) | tmp
' Set transmitted (TX) or expected (RX) sync word
'   Valid values: $0000..$FFFF
'   Any other value polls the chip and returns the current setting
    readRegX (core#SYNC1, 2, @tmp)
    case sync_word
        $0000..$FFFF:
        OTHER:
            return tmp

    writeRegX (core#SYNC1, 2, @sync_word)

PUB TX
' Change chip state to TX (transmit)
    writeRegX (core#CS_STX, 0, 0)

PUB TXData(nr_bytes, buf_addr)
' Queue data to transmit in the TX FIFO
'   nr_bytes Valid values: 1..64
'   Any other value is ignored
    writeRegX (core#FIFO, nr_bytes, buf_addr)

PUB TXOff(next_state) | tmp
' Defines the state the radio transitions to after a packet is successfully transmitted
'   Valid values:
'       TXOFF_IDLE (0) - Idle state
'       TXOFF_FSTXON (1) - Turn frequency synth on and ready at TX freq. To transmit, call TX
'       TXOFF_TX (2) - Start sending preamble
'       TXOFF_RX (3) - Wait for packets (RX)
'   Any other value polls the chip and returns the current setting
    readRegX (core#MCSM1, 1, @tmp)
    case next_state
        0..3:
            next_state := next_state << core#FLD_TXOFF_MODE
        OTHER:
            result := (tmp >> core#FLD_TXOFF_MODE) & core#BITS_TXOFF_MODE
            return result

    tmp &= core#MASK_TXOFF_MODE
    tmp := (tmp | next_state)
    writeRegX (core#MCSM1, 1, @tmp)

PUB Version
' Chip version number
'   Returns: $14
'   NOTE: Datasheet states this value is subject to change without notice
    readRegX (core#VERSION, 1, @result)

PUB WhiteData(enabled) | tmp
' Enable data whitening
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
'   NOTE: Applies to all data, except the preamble and sync word.
    readRegX (core#PKTCTRL0, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_WHITE_DATA
        OTHER:
            result := ((tmp >> core#FLD_WHITE_DATA) & %1) * TRUE
            return result

    tmp &= core#MASK_WHITE_DATA
    tmp := (tmp | enabled)
    writeRegX (core#PKTCTRL0, 1, @tmp)

PUB WOR
' Change chip state to WOR (Wake-on-Radio)
    writeRegX (core#CS_SWOR, 0, 0)

PUB readRegX(reg, nr_bytes, addr_buff) | i
' Read nr_bytes from register 'reg' to address 'addr_buff'
    case reg
        $00..$2E:                               ' Config regs
            case nr_bytes
                1:
                2..64:
                    reg |= core#BURST
                0:
                    return
        $30..$3D:                               ' Status regs
            reg |= core#BURST                   '   Must set BURST mode bit to read them, else they're interpreted as command strobes
        $3F:                                    ' FIFO
            case nr_bytes
                1:
                2..64:
                    reg |= core#BURST
                0:
                    return
    reg |= core#R

    outa[_CS] := 0
    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)

    repeat i from 0 to nr_bytes-1
        byte[addr_buff][i] := spi.SHIFTIN(_MISO, _SCK, core#MISO_BITORDER, 8)
    outa[_CS] := 1

PUB writeRegX(reg, nr_bytes, buf_addr) | tmp
' Write nr_bytes to register 'reg' stored in val
'HEADER BYTE:
' MSB   = R(1)/W(0) bit
' b6    = BURST ACCESS BIT (B)
' b5..0 = 6-bit ADDRESS (A5-A0)
'IF CS PULLED LOW, WAIT UNTIL SO LOW WHEN IN SLEEP OR XOFF STATES

    case reg
        $00..$2E:                               ' R/W regs
            case nr_bytes
                0:                              ' Invalid nr_bytes - ignore
                    return
                1:
                OTHER:
                    reg |= core#BURST

            outa[_CS] := 0
            spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            repeat tmp from 0 to nr_bytes-1
                spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][tmp])
'                _status_byte := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)       'Leave disbled for now - causes write issues
            outa[_CS] := 1

        $30..$3D:                               ' Command strobes
            outa[_CS] := 0
            spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            _status_byte := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
            outa[_CS] := 1

        $3F:                                    ' FIFO
            case nr_bytes
                1:
                2..64:
                    reg |= core#BURST
                0:
                    return

            outa[_CS] := 0
            spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            repeat tmp from 0 to nr_bytes-1
                spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][tmp])
'                _status_byte := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
            outa[_CS] := 1

        OTHER:                                  ' Invalid reg - ignore
            return

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
