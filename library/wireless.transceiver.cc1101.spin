{
    --------------------------------------------
    Filename: wireless.transceiver.cc1101.spin
    Author: Jesse Burt
    Description: Driver for TI's CC1101 ISM-band transceiver
    Copyright (c) 2022
    Started Mar 25, 2019
    Updated Dec 27, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    F_XOSC                  = 26_000_000        ' CC1101 XTAL Oscillator freq
    TWO13                   = 1 << 13           ' 2^13
    TWO14                   = 1 << 14           ' 2^14
    TWO16                   = 1 << 16           ' 2^16
    TWO17                   = 1 << 17           ' 2^17
    TWO18                   = 1 << 18           ' 2^18
    TWO20                   = 1 << 20           ' 2^20
    TWO28                   = 1 << 28           ' 2^28
    U64SCALE                = 1_000_000_000     ' Unsigned math scale
    U64_FREQ_RES            = 396_728515        ' (F_XOSC / TWO16) * 1_000_000
    CHANSPC_RES             = 99_182128         ' (F_XOSC / TWO18) * 1_000_000

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
    TRIG_RXTHRESH           = $00
    TRIG_RXTHRESH_END_PKT   = $01
    TRIG_RXOVERFLOW         = $04
    TRIG_TXUNDERFLOW        = $05
    TRIG_SYNCWORD_TXRX      = $06
    TRIG_PREAMBLE_QUALITY   = $08
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

' AGC modes
    AGC_NORMAL              = %00
    AGC_FREEZE_ON_SYNC      = %01
    AGC_FREEZE_A_AUTO_D     = %10
    AGC_OFF                 = %11

VAR

    byte _CS
    byte _status

OBJ

{ SPI? }
{ decide: Bytecode SPI engine, or PASM? Default is PASM if BC isn't specified }
#ifdef CC1101_SPI_BC
    spi : "com.spi.25khz.nocog"                       ' BC SPI engine
#else
    spi : "com.spi.1mhz"                          ' PASM SPI engine
#endif
    core: "core.con.cc1101"
    time: "time"
    u64 : "math.unsigned64"

PUB null{}
' This is not a top-level object

PUB startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): status

    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if (status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE))
            time.usleep(core#T_POR)
            _CS := CS_PIN

            outa[_CS] := 1
            dira[_CS] := 1
            if lookdown(dev_id{}: $04, $14..$FE) ' validate device
                reset{}
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    spi.deinit{}
    _CS := _status := 0

PUB defaults{}
' Factory default settings

' This is what _would_ be called:
{
    node_addr($00)
    addr_check(ADRCHK_NONE)
    payld_status_ena(TRUE)
    carrier_freq(800_000_000)
    channel(0)
    crc_auto_flush_ena(FALSE)
    crc_check_ena(TRUE)
    data_rate(115_200)
    dc_block_ena(TRUE)
    freq_dev(47_607)
    fec_ena(FALSE)
    gpio0(IO_CLK_XODIV192)
    gpio1(IO_HI_Z)
    gpio2(IO_CHIP_RDYn)
    interm_freq(380_859)
    manchester_enc(FALSE)
    modulation(FSK2)
    payld_len(255)
    payld_len_cfg(PKTLEN_VAR)
    preamble_len(2)
    preamble_qual(0)
    rx_bw(203)
    rx_fifo_thresh(32)
    syncwd_mode(SYNCMODE_1616)
    set_syncwd($D391)
    data_whiten_ena(TRUE)
}
' but to save code space, just call reset(), instead
    reset{}

PUB preset_fixed_pkt_len{}
' Like preset_robust1(), but sets packet length config mode to fixed-length
    preset_robust1{}
    payld_len_cfg(PKTLEN_FIXED)

PUB preset_robust1{}
' Like defaults, but with some basic improvements in robustness:
' * check/filter address field in payload (2nd byte), ignore broadcast address
' * perform oscillator auto-cal when transitioning from idle to RX or TX
' * reject packets with a bad CRC (i.e., flush from receive buffer)
' * turn off oscillator output on GPIO0 (GDO0)
    reset{}
    addr_check(ADRCHK_CHK_NO_BCAST)
    auto_cal_mode(IDLE_RXTX)
    crc_auto_flush_ena(TRUE)
    gpio0(IO_HI_Z)

PUB addr_check(mode): curr_mode
' Enable address checking/matching/filtering
'   Valid values:
'      *ADRCHK_NONE (0): No address check
'       ADRCHK_CHK_NO_BCAST (1): Check address, but ignore broadcast addresses
'       ADRCHK_CHK_00_BCAST (2): Check address, and also respond to $00 broadcast address
'       ADRCHK_CHK_00_FF_BCAST (3): Check address, and also respond to both $00 and $FF broadcast addresses
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#PKTCTRL1, 1, @curr_mode)
    case mode
        0..3:
            mode := mode & core#ADR_CHK_BITS
        other:
            return curr_mode & core#ADR_CHK_BITS

    mode := ((curr_mode & core#ADR_CHK_MASK) | mode) & core#PKTCTRL1_MASK
    writereg(core#PKTCTRL1, 1, @mode)

PUB after_rx(next_state): curr_set
' Defines the state the radio transitions to after a packet is successfully received
'   Valid values:
'      *RXOFF_IDLE (0) - Idle state
'       RXOFF_FSTXON (1) - Turn frequency synth on and ready at TX freq. To transmit, call TX
'       RXOFF_TX (2) - Start sending preamble
'       RXOFF_RX (3) - Wait for more packets
'   Any other value polls the chip and returns the current setting
    curr_set := 0
    readreg(core#MCSM1, 1, @curr_set)
    case next_state
        0..3:
            next_state := next_state << core#RXOFF_MODE
        other:
            return (curr_set >> core#RXOFF_MODE) & core#RXOFF_MODE_BITS

    next_state := ((curr_set & core#RXOFF_MODE_MASK) | next_state)
    writereg(core#MCSM1, 1, @next_state)

PUB after_tx(next_state): curr_set
' Defines the state the radio transitions to after a packet is successfully transmitted
'   Valid values:
'      *TXOFF_IDLE (0) - Idle state
'       TXOFF_FSTXON (1) - Turn frequency synth on and ready at TX freq. To transmit, call TX
'       TXOFF_TX (2) - Start sending preamble
'       TXOFF_RX (3) - Wait for packets (RX)
'   Any other value polls the chip and returns the current setting
    curr_set := 0
    readreg(core#MCSM1, 1, @curr_set)
    case next_state
        0..3:
            next_state := next_state << core#TXOFF_MODE
        other:
            return (curr_set >> core#TXOFF_MODE) & core#TXOFF_MODE_BITS

    next_state := ((curr_set & core#TXOFF_MODE_MASK) | next_state)
    writereg(core#MCSM1, 1, @next_state)

PUB agc_filt_len(len): curr_len
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
    curr_len := 0
    readreg(core#AGCCTRL0, 1, @curr_len)
    case len
        8, 16, 32, 64:
            len := lookdownz(len: 8, 16, 32, 64) & core#FILT_LEN_BITS
        other:
            curr_len := curr_len & core#FILT_LEN_BITS
            return lookupz(curr_len: 8, 16, 32, 64)

    len := ((curr_len & core#FILT_LEN_MASK) | len) & core#AGCCTRL0_MASK
    writereg(core#AGCCTRL0, 1, @len)

PUB agc_mode(mode): curr_mode
' Set AGC mode
'   Valid values:
'      *AGC_NORMAL (0): Always adjust gain when required
'       AGC_FREEZE_ON_SYNC (1): Gain setting is frozen when a sync word has been found
'       AGC_FREEZE_A_AUTO_D (2): Freeze analog gain, but autmatically adjust digital gain
'       AGC_OFF (3): Freeze both analog and digital gain settings
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#AGCCTRL0, 1, @curr_mode)
    case mode
        AGC_NORMAL, AGC_FREEZE_ON_SYNC, AGC_FREEZE_A_AUTO_D, AGC_OFF:
            mode <<= core#AGC_FREEZE
        other:
            return (curr_mode >> core#AGC_FREEZE) & core#AGC_FREEZE_BITS

    mode := ((curr_mode & core#AGC_FREEZE_MASK) | mode) & core#AGCCTRL0_MASK
    writereg(core#AGCCTRL0, 1, @mode)

PUB auto_cal_mode(mode): curr_mode
' When to perform auto-calibration
'   Valid values:
'      *NEVER (0) - Never (manually calibrate)
'       IDLE_RXTX (1) - When transitioning from IDLE to RX/TX
'       RXTX_IDLE (2) - When transitioning from RX/TX to IDLE
'       RXTX_IDLE4 (3) - Every 4th time mode transitioning from RX/TX to IDLE (power-saving)
    curr_mode := 0
    readreg(core#MCSM0, 1, @curr_mode)
    case mode
        NEVER, IDLE_RXTX, RXTX_IDLE, RXTX_IDLE4:
            mode := mode << core#FS_AUTOCAL
        other:
            return (curr_mode >> core#FS_AUTOCAL) & core#FS_AUTOCAL_BITS

    mode := ((curr_mode & core#FS_AUTOCAL_MASK) | mode)
    writereg(core#MCSM0, 1, @mode)

PUB cal_freq_synth{}
' Calibrate the frequency synthesizer
    writereg(core#CS_SCAL, 0, 0)

PUB carrier_freq(freq): curr_freq
' Set carrier/center frequency, in Hz
'   Valid values:
'       300_000_000..348_000_000, 387_000_000..464_000_000, 779_000_000..928_000_000
'   Default value: Approx 800_000_000
'   Any other value polls the chip and returns the current setting
'   NOTE: The actual set frequency has a resolution of fXOSC/2^16 (i.e., approx 397freq)
    curr_freq := 0
    readreg(core#FREQ2, 3, @curr_freq)
    case freq
        300_000_000..348_000_000, 387_000_000..464_000_000, 779_000_000..928_000_000:
            freq := u64.multdiv(F_XOSC, U64SCALE, freq)
            freq := u64.multdiv(TWO16, U64SCALE, freq)
        other:
            return u64.multdiv(curr_freq, U64_FREQ_RES, 1_000_000)

    writereg(core#FREQ2, 3, @freq)

PUB carrier_sense_thresh(thresh): curr_thr
' Set relative change threshold for asserting carrier sense, in dB
'   Valid values:
'      *0: Disabled
'       6: 6dB increase in RSSI
'       10: 10dB increase in RSSI
'       14: 14dB increase in RSSI
'   Any other value polls the chip and returns the current setting
    curr_thr := 0
    readreg(core#AGCCTRL1, 1, @curr_thr)
    case thresh
        0, 6, 10, 14:
            thresh := lookdownz(thresh: 0, 6, 10, 14) << core#CSENSE_REL_THR
        other:
            curr_thr := (curr_thr >> core#CSENSE_REL_THR) & core#CSENSE_REL_THR_BITS
            return lookupz(curr_thr: 0, 6, 10, 14)

    thresh := ((curr_thr & core#CSENSE_REL_THR_MASK) | thresh) & core#AGCCTRL1_MASK
    writereg(core#AGCCTRL1, 1, @thresh)

PUB carrier_sense_abs_thresh(thresh): curr_thr
' Set absolute change threshold for asserting carrier sense, in dB
'   Valid values:
'       %0000..%1111
'   Default value: %0000
'   Any other value polls the chip and returns the current setting
    curr_thr := 0
    readreg(core#AGCCTRL1, 1, @curr_thr)
    case thresh
        %0000..%1111:
            thresh := thresh & core#CSENSE_ABS_THR_BITS
        other:
            return curr_thr & core#CSENSE_ABS_THR_BITS

    thresh := ((curr_thr & core#CSENSE_ABS_THR_MASK) | thresh) & core#AGCCTRL1_MASK
    writereg(core#AGCCTRL1, 1, @thresh)

PUB channel(number): curr_chan
' Set channel number
'   Valid values: 0..255
'   Default value: 0
'   Any other value polls the chip and returns the current setting
'   NOTE: Resulting frequency = (channel number * channel spacing) + base freq
    curr_chan := 0
    readreg(core#CHANNR, 1, @curr_chan)
    case number
        0..255:
        other:
            return curr_chan

    number &= core#CHANNR_MASK
    writereg(core#CHANNR, 1, @number)

PUB channel_spacing(width): curr_wid | chanspc_e, chanspc_m
' Set channel spacing, in Hz
'   Valid values: 25_390..405_456 (default: 199_951)
'   Any other value polls the chip and returns the current setting
    longfill(@chanspc_e, 0, 3)
    readreg(core#MDMCFG1, 2, @curr_wid)
    case width
        25_390..405_456:
            repeat chanspc_e from 0 to 3
                chanspc_m :=  (width / (99 * (1 << chanspc_e)) - 256)
                if chanspc_m => 0 and chanspc_m < 256
                    quit
        other:
            chanspc_e := curr_wid.byte[0] & core#CHANSPC_E_BITS
            chanspc_m := curr_wid.byte[1]
            curr_wid := (256 + chanspc_m) * (1 << chanspc_e)
            return u64.multdiv(CHANSPC_RES, curr_wid, 1_000_000)

    width.byte[0] &= core#CHANSPC_E_MASK
    width.byte[0] |= chanspc_e
    width.byte[1] := chanspc_m
    writereg(core#MDMCFG1, 2, @width)

PUB crc_check_ena(mode): curr_mode
' Enable CRC calc (TX mode) and check (RX mode)
'   Valid values:
'      *TRUE (-1 or 1)
'       FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#PKTCTRL0, 1, @curr_mode)
    case ||(mode)
        0, 1:
            mode := ||(mode) << core#CRC_EN
        other:
            return ((curr_mode >> core#CRC_EN) & %1) == 1

    mode := ((curr_mode & core#CRC_EN_MASK) | mode) & core#PKTCTRL0_MASK
    writereg(core#PKTCTRL0, 1, @mode)

PUB crc_auto_flush_ena(mode): curr_mode
' Enable automatic flush of RX FIFO when CRC check fails
'   Valid values:
'       TRUE (-1 or 1)
'      *FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#PKTCTRL1, 1, @curr_mode)
    case ||(mode)
        0, 1:
            mode := ||(mode) << core#CRC_AUTOFLUSH
        other:
            return ((curr_mode >> core#CRC_AUTOFLUSH) & %1) == 1

    mode := ((curr_mode & core#CRC_AUTOFLUSH_MASK) | mode) & core#PKTCTRL1_MASK
    writereg(core#PKTCTRL1, 1, @mode)

PUB data_rate(rate): curr_rate | curr_exp, curr_mant, dr_exp, dr_mant
' Set on-air data rate, in bps
'   Valid values: 600..500_000
'   Default value: 115_051
'   Any other value polls the chip and returns the current setting
    longfill(@curr_exp, 0, 4)

    readreg(core#MDMCFG4, 1, @curr_exp)
    readreg(core#MDMCFG3, 1, @curr_mant)
    case rate
        600..500_000:
            dr_exp := >|( u64.multdiv(rate, TWO20, F_XOSC) )-1
            dr_mant := (u64.multdiv(rate, TWO28, u64.multdiv(F_XOSC, {
}                      (1 << dr_exp), 1_000) )-256_000) / 1_000
            if (dr_mant > 255)                  ' mantissa overflow?
                dr_mant := 0                    ' clear and carry it into
                dr_exp := (dr_exp + 1) <# $0E   ' the exponent
        other:
            curr_exp &= core#DRATE_E_BITS
            curr_rate := u64.multdiv( (256+curr_mant) * (1 << curr_exp), {
}                                    U64SCALE, TWO28)
            return u64.multdiv(curr_rate, F_XOSC, U64SCALE)

    curr_exp &= core#DRATE_E_MASK
    curr_exp := (curr_exp | dr_exp)

    writereg(core#MDMCFG4, 1, @curr_exp)
    writereg(core#MDMCFG3, 1, @dr_mant)

PUB data_whiten_ena(mode): curr_mode
' Enable data whitening
'   Valid values: *TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
'   NOTE: Applies to all data, except the preamble and sync word.
    curr_mode := 0
    readreg(core#PKTCTRL0, 1, @curr_mode)
    case ||(mode)
        0, 1:
            mode := ||(mode) << core#WHITE_DATA
        other:
            return ((curr_mode >> core#WHITE_DATA) & %1) == 1

    mode := ((curr_mode & core#WHITE_DATA_MASK) | mode)
    writereg(core#PKTCTRL0, 1, @mode)

PUB dc_block_ena(mode): curr_mode
' Enable digital DC blocking filter (before demod)
'   Valid values: *TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
'   NOTE: Enable for better sensitivity (default).
'       Disable for optimizing current usage. Only for data rates 250kBaud and lower
    curr_mode := 0
    readreg(core#MDMCFG2, 1, @curr_mode)
    case mode := ||(mode)
        0, 1:
            mode := ((mode ^ 1) << core#DCFILT_OFF)
        other:
            return (((curr_mode >> core#DCFILT_OFF) & %1) ^ 1) == 1

    mode := ((curr_mode & core#DCFILT_OFF_MASK) | mode)
    writereg(core#MDMCFG2, 1, @mode)

PUB dev_id{}: id
' Chip version number
'   Returns: $04 (Rev. E), $14 (Rev. I)
'   NOTE: Datasheet states this value is subject to change without notice
    id := 0
    readreg(core#VERSION, 1, @id)

PUB dvga_gain(gain): curr_gain
' Set Digital Variable Gain Amplifier gain maximum level
'   Valid values:
'       *0 - Highest gain setting
'       -1 - Highest gain setting-1
'       -2 - Highest gain setting-2
'       -3 - Highest gain setting-3
'   Any other value polls the chip and returns the current setting
    curr_gain := 0
    readreg(core#AGCCTRL2, 1, @curr_gain)
    case gain
        -3..0:
            gain := ||(gain) << core#MAX_DVGA_GAIN
        other:
            curr_gain := (curr_gain >> core#MAX_DVGA_GAIN) & core#MAX_DVGA_GAIN_BITS
            return curr_gain * -1

    gain := ((curr_gain & core#MAX_DVGA_GAIN_MASK) | gain)
    writereg(core#AGCCTRL2, 1, @gain)

PUB fec_ena(mode): curr_mode
' Enable forward error correction with interleaving
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the chip and returns the current setting
'   NOTE: Only supported when payld_len_cfg() == PKTLEN_FIXED
    curr_mode := 0
    readreg(core#MDMCFG1, 1, @curr_mode)
    case ||(mode)
        0, 1:
            mode := ||(mode) << core#FEC_EN
        other:
            return ((curr_mode >> core#FEC_EN) & %1) == 1

    mode := ((curr_mode & core#FEC_EN_MASK) | mode) & core#MDMCFG1_MASK
    writereg(core#MDMCFG1, 1, @mode)

PUB fifo_rx_bytes{}: nr_bytes
' Returns number of bytes in RX FIFO
' NOTE: The MSB indicates if the RX FIFO has overflowed.
    nr_bytes := 0
    readreg(core#RXBYTES, 1, @nr_bytes)

PUB fifo_tx_bytes{}: nr_bytes
' Returns number of bytes in TX FIFO
' NOTE: The MSB indicates if the TX FIFO is underflowed.
    nr_bytes := 0
    readreg(core#TXBYTES, 1, @nr_bytes)

PUB flush_rx{}
' Flush receive FIFO/buffer
    writereg(core#CS_SFRX, 0, 0)

PUB flush_tx{}
' Flush transmit FIFO/buffer
    writereg(core#CS_SFTX, 0, 0)

PUB freq_dev(freq): curr_freq | tmp, deviat_m, deviat_e, tmp_m
' Set frequency deviation from carrier, in Hz
'   Valid values:
'       1_586..380_859 (default: 47_607)
'   NOTE: This setting has no effect when Modulation format is ASK/OOK.
'   NOTE: This setting applies to both TX and RX roles. When role is RX, setting must be
'           approximately correct for reliable demodulation.
'   Any other value polls the chip and returns the current setting
    longfill(@tmp, 0, 4)
    readreg(core#DEVIATN, 1, @tmp)
    case freq
        1_587..380_859:
            deviat_e := u64.multdiv(freq, TWO14, F_XOSC)
            deviat_e := >|(deviat_e)
            tmp_m := F_XOSC * (1 << deviat_e)
            deviat_m := u64.multdiv(freq, TWO17, tmp_m)
            freq := (deviat_e << core#DEVIAT_E) | deviat_m
        other:
            deviat_m := tmp & core#DEVIAT_M_BITS
            deviat_e := (tmp >> core#DEVIAT_E) & core#DEVIAT_E_BITS
            return F_XOSC / TWO17 * (8 + deviat_m) * (1 << deviat_e)

    freq &= core#DEVIATN_MASK
    writereg(core#DEVIATN, 1, @freq)

PUB freq_synth_ena{}
' Enable frequency synthesizer and calibrate
    writereg(core#CS_SFSTXON, 0, 0)

PUB gpio0(mode): curr_mode 'XXX review: consolidation with other like methods? (API change)
' Configure test signal output on GDO0 pin
'   Valid values: $00..$0F, $16..$17, $1B..$1D, $24..$39, $41, $43, $46..$3F (default: $3f)
'       (see IO_* constants near top of this file)
'   Any other value polls the chip and returns the current setting
'   NOTE: The default setting is IO_CLK_XODIV192, which outputs the CC1101's XO clock,
'           divided by 192 on the pin.
'       TI recommends the clock outputs be disabled when the radio is active, for best performance.
'       Only one IO pin at a time can be configured as a clock output.
    curr_mode := 0
    readreg(core#IOCFG0, 1, @curr_mode)
    case mode
        $00..$0F, $16..$17, $1B..$1D, $24..$27, $29, $2B, $2E..$3F:
            mode &= core#GDO0_CFG_BITS
        other:
            return curr_mode & core#GDO0_CFG_BITS

    mode := ((curr_mode & core#GDO0_CFG_MASK) | mode)
    writereg(core#IOCFG0, 1, @mode)

PUB gpio1(mode): curr_mode
' Configure test signal output on GDO1 pin
'   Valid values: $00..$0F, $16..$17, $1B..$1D, $24..$39, $41, $43, $46..$3F
'   Any other value polls the chip and returns the current setting
'   NOTE: This pin is shared with the SPI signal SO, and is valid only when CS is high.
'   NOTE: The default setting is IO_HI_Z ($2E): Hi-Z/High-impedance/Tri-state
    curr_mode := 0
    readreg(core#IOCFG1, 1, @curr_mode)
    case mode
        $00..$0F, $16..$17, $1B..$1D, $24..$27, $29, $2B, $2E..$3F:
            mode &= core#GDO1_CFG_BITS
        other:
            return curr_mode & core#GDO1_CFG_BITS

    mode := ((curr_mode & core#GDO1_CFG_MASK) | mode)
    writereg(core#IOCFG1, 1, @mode)

PUB gpio2(mode): curr_mode
' Configure test signal output on GDO2 pin
'   Valid values: $00..$0F, $16..$17, $1B..$1D, $24..$39, $41, $43, $46..$3F
'   Any other value polls the chip and returns the current setting
'   NOTE: The default setting is IO_CHIP_RDYn ($29)
    curr_mode := 0
    readreg(core#IOCFG2, 1, @curr_mode)
    case mode
        $00..$0F, $16..$17, $1B..$1D, $24..$27, $29, $2B, $2E..$3F:
            mode &= core#GDO2_CFG_BITS
        other:
            return curr_mode & core#GDO2_CFG_BITS

    mode := ((curr_mode & core#GDO2_CFG_MASK) | mode)
    writereg(core#IOCFG2, 1, @mode)

PUB idle{}
' Change chip state to IDLE
    writereg(core#CS_SIDLE, 0, 0)

PUB interm_freq(freq): curr_freq
' Intermediate Frequency (IF), in Hz
'   Valid values: 25_390..787_109 (default: 380_859; rounded to the nearest value)
'   Default value: 380_859
'   Any other value polls the chip and returns the current setting
    curr_freq := 0
    readreg(core#FSCTRL1, 1, @curr_freq)
    case freq
        25_390..787_109:
            freq := 1024 / (F_XOSC/freq)
        other:
            return curr_freq * (F_XOSC / 1024)

    writereg(core#FSCTRL1, 1, @freq)

PUB last_crc_good{}: flag
' Flag indicating CRC of last reception matched
'   Returns: TRUE (-1) if comparison matched, FALSE (0) otherwise
    readreg(core#LQI, 1, @flag)
    return ((flag >> core#CRC_OK) & %1) == 1

PUB lna_gain(gain): curr_gain
' Set maximum LNA+LNA2 gain (relative to maximum possible gain)
'   Valid values:
'       *0 - Maximum possible LNA+LNA2 gain
'       -2 - ~2.6dBm below maximum
'       -6 - ~6.1dBm below maximum
'       -7 - ~7.4dBm below maximum
'       -9 - ~9.2dBm below maximum
'       -11 - ~11.5dBm below maximum
'       -14 - ~14.6dBm below maximum
'       -17 - ~17.1dBm below maximum
'   Any other value polls the chip and returns the current setting
    curr_gain := 0
    readreg(core#AGCCTRL2, 1, @curr_gain)
    case gain
        0, -2, -6, -7, -9, -11, -14, -17:
            gain := lookdownz(gain: 0, -2, -6, -7, -9, -11, -14, -17) << core#MAX_LNA_GAIN
        other:
            curr_gain := (curr_gain >> core#MAX_LNA_GAIN) & core#MAX_LNA_GAIN_BITS
            return lookupz(curr_gain: 0, -2, -6, -7, -9, -11, -14, -17)

    gain := ((curr_gain & core#MAX_LNA_GAIN_MASK) | gain)
    writereg(core#AGCCTRL2, 1, @gain)

PUB magn_target(val): curr_val
' Set target value for averaged amplitude from digital channel filter, in dB
'   Valid values:
'       24, 27, 30, *33, 36, 38, 40, 42
'   Any other value polls the chip and returns the current setting
    curr_val := 0
    readreg(core#AGCCTRL2, 1, @curr_val)
    case val
        24, 27, 30, 33, 36, 38, 40, 42:
            val := lookdownz(val: 24, 27, 30, 33, 36, 38, 40, 42) & core#MAGN_TARGET_BITS
        other:
            curr_val := curr_val & core#MAGN_TARGET_BITS
            return lookupz(curr_val: 24, 27, 30, 33, 36, 38, 40, 42)

    val := ((curr_val & core#MAGN_TARGET_MASK) | val)
    writereg(core#AGCCTRL2, 1, @val)

PUB manchest_enc_ena(mode): curr_mode
' Enable Manchester encoding/decoding
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#MDMCFG2, 1, @curr_mode)
    case ||(mode)
        0, 1:
            mode := ||(mode) << core#MANCHST_EN
        other:
            return ((curr_mode >> core#MANCHST_EN) & %1) == 1

    mode := ((curr_mode & core#MANCHST_EN_MASK) | mode)
    writereg(core#MDMCFG2, 1, @mode)

PUB modulation(mode): curr_mode
' Set modulation of transmitted (TX) or expected (RX) signal
'   Valid values:
'      *FSK2 (%000): 2-level or binary Frequency Shift-Keyed
'       GFSK (%001): Gaussian FSK
'       ASKOOK (%011): Amplitude Shift-Keyed or On Off-Keyed
'       FSK4 (%100): 4-level FSK
'       MSK (%111): Minimum Shift-Keyed
'   Any other value polls the chip and returns the current setting
'   NOTE: MSK supported only when data_rate() is greater than 26_000
    curr_mode := 0
    readreg(core#MDMCFG2, 1, @curr_mode)
    case mode
        FSK2, GFSK, ASKOOK, FSK4, MSK:
            mode := mode << core#MOD_FORMAT
        other:
            return (curr_mode >> core#MOD_FORMAT) & core#MOD_FORMAT_BITS

    mode := ((curr_mode & core#MOD_FORMAT_MASK) | mode)
    writereg(core#MDMCFG2, 1, @mode)

PUB node_addr(addr): curr_addr
' Set address used for packet filtration
'   Valid values: $00..$FF (000-255)
'   Default value: $00
'   Any other value polls the chip and returns the current setting
'   NOTE: $00 and $FF can be used as broadcast addresses.
    curr_addr := 0
    readreg(core#ADDR, 1, @curr_addr)
    case addr
        $00..$FF:
        other:
            return curr_addr

    addr &= core#ADDR_MASK
    writereg(core#ADDR, 1, @addr)

PUB pa_read(ptr_buff)
' Read PA table into ptr_buff
'   NOTE: ptr_buff must be at least 8 bytes in length
    readreg(core#PATABLE | core#BURST, 8, ptr_buff)

PUB part_num{}: pn
' Part number of device
'   Returns: $00
    readreg(core#PARTNUM, 1, @pn)

PUB pa_write(ptr_buff)
' Write 8-byte PA table from ptr_buff
'   NOTE: Table will be written starting at index 0 from the LSB of ptr_buff
    writereg(core#PATABLE | core#BURST, 8, ptr_buff)

PUB payld_len(length): curr_len
' Set payload length, when using fixed payload length mode,
'   or maximum payload length when using variable payload length mode.
'   Valid values: 1..*255
'   Any other value polls the chip and returns the current setting
    curr_len := 0
    readreg(core#PKTLEN, 1, @curr_len)
    case length
        1..255:
            length &= core#PKTLEN_MASK
        other:
            return curr_len & core#PKTLEN_MASK

    writereg(core#PKTLEN, 1, @length)

PUB payld_len_cfg(mode): curr_mode
' Set payload length mode
'   Valid values:
'       PKTLEN_FIXED (0): Fixed payload length mode. Payload length is set by payld_len()
'       PKTLEN_VAR (1): Variable payload length mode. Payload length is set by first byte of
'           payload data (default)
'       PKTLEN_INF (2): Infinite payload length mode.
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#PKTCTRL0, 1, @curr_mode)
    case mode
        0..2:
        other:
            return curr_mode & core#LEN_CFG_BITS

    mode := ((curr_mode & core#LEN_CFG_MASK) | mode) & core#PKTCTRL0_MASK
    writereg(core#PKTCTRL0, 1, @mode)

PUB payld_status_ena(mode): curr_mode
' Append status bytes to packet payload (RSSI, LQI, CRC OK)
'   Valid values:
'      *TRUE (-1 or 1)
'       FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#PKTCTRL1, 1, @curr_mode)
    case ||(mode)
        0, 1:
            mode := ||(mode) << core#APPEND_STATUS
        other:
            return ((curr_mode >> core#APPEND_STATUS) & %1) == 1

    mode := ((curr_mode & core#APPEND_STATUS_MASK) | mode) & core#PKTCTRL1_MASK
    writereg(core#PKTCTRL1, 1, @mode)

PUB pll_locked{}: flag
' Flag indicating PLL is locked
'   Returns: TRUE (-1) if locked, FALSE otherwise
    readreg(core#FSCAL1, 1, @flag)
    return (flag <> $3F)

PUB preamble_len(len): curr_len
' Set number of preamble bytes
'   Valid values: 2, 3, *4, 6, 8, 12, 16, 24
'   Any other value polls the chip and returns the current setting
    curr_len := 0
    readreg(core#MDMCFG1, 1, @curr_len)
    case len
        2, 3, 4, 6, 8, 12, 16, 24:
            len := (lookdownz(len: 2, 3, 4, 6, 8, 12, 16, 24)) << core#NUM_PREAMBLE
        other:
            curr_len := (curr_len >> core#NUM_PREAMBLE) & core#NUM_PREAMBLE_BITS
            return lookupz(curr_len: 2, 3, 4, 6, 8, 12, 16, 24)

    len := ((curr_len & core#NUM_PREAMBLE_MASK) | len)
    writereg(core#MDMCFG1, 1, @len)

PUB preamble_quality_thresh(thresh): curr_thr
' Set Preamble quality estimator threshold
'   Valid values: *0, 4, 8, 12, 16, 20, 24, 28
'   NOTE: If 0, the sync word is always accepted.
'   Any other value polls the chip and returns the current setting
    curr_thr := 0
    readreg(core#PKTCTRL1, 1, @curr_thr)
    case thresh
        0, 4, 8, 12, 16, 20, 24, 28:
            thresh := lookdownz(thresh: 0, 4, 8, 12, 16, 20, 24, 28) << core#PQT
        other:
            curr_thr := ((curr_thr >> core#PQT) & core#PQT_BITS)
            return lookupz(curr_thr: 0, 4, 8, 12, 16, 20, 24, 28)

    thresh := ((curr_thr & core#PQT_MASK) | thresh) & core#PKTCTRL1_MASK
    writereg(core#PKTCTRL1, 1, @thresh)

PUB reset{}
' Reset the chip
    writereg(core#CS_SRES, 0, 0)
    time.msleep(5)

PUB rssi{}: level
' Received Signal Strength Indicator
'   Returns: Signal strength seen by transceiver, in dBm
    level := 0
    readreg(core#RSSI, 1, @level)
    level := (~level / 2) - 74

PUB rx_bandwidth = rx_bw
PUB rx_bw(width): curr_wid
' Set receiver channel filter bandwidth, in kHz
'   Valid values: 812, 650, 541, 464, 406, 325, 270, 232, 203, 162, 135, 116, 102, 81, 68, 58
'       (default: 203)
'   Any other value polls the chip and returns the current setting
    curr_wid := 0
    readreg(core#MDMCFG4, 1, @curr_wid)
    case width
        812, 650, 541, 464, 406, 325, 270, 232, 203, 162, 135, 116, 102, 81, 68, 58:
            width := (lookdown(width: 812, 650, 541, 464, 406, 325, 270, 232,{
}                                     203, 162, 135, 116, 102, 81, 68, 58)-1) << core#CHANBW
        other:
            curr_wid := ((curr_wid >> core#CHANBW) & core#CHANBW_BITS)+1
            return lookup(curr_wid: 812, 650, 541, 464, 406, 325, 270, 232,{
}                                   203, 162, 135, 116, 102, 81, 68, 58)

    width := ((curr_wid & core#CHANBW_MASK) | width)
    writereg(core#MDMCFG4, 1, @width)

PUB rx_fifo_thresh(thresh): curr_thr
' Set receive FIFO thresh, in bytes
'   The threshold is exceeded when the number of bytes in the FIFO is greater
'       than or equal to this value.
'   Valid values: 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64 (default: 32)
'   Any other value polls the chip and returns the current setting
'   NOTE: This affects the TX FIFO, inversely
    curr_thr := 0
    readreg(core#FIFOTHR, 1, @curr_thr)
    case thresh
        4..64:
            thresh := (thresh / 4) - 1
        other:
            return ((curr_thr & core#FIFO_THR_BITS) + 1) * 4

    thresh := ((curr_thr & core#FIFO_THR_MASK) | thresh) & core#FIFOTHR_MASK
    writereg(core#FIFOTHR, 1, @thresh)

PUB rx_mode{}
' Change chip state to RX (receive)
    writereg(core#CS_SRX, 0, 0)

PUB rx_payld(nr_bytes, ptr_buff)
' Read data queued in the RX FIFO
'   nr_bytes Valid values: 1..64
'   Any other value is ignored
'   NOTE: Ensure buffer at address ptr_buff is at least as big as the number of bytes you're reading
    readreg(core#FIFO, nr_bytes, ptr_buff)

PUB sleep{}
' Power down chip
    writereg(core#CS_SPWD, 0, 0)

PUB state{}: curr_state
' Read state-machine register
    curr_state := 0
    readreg(core#MARCSTATE, 1, @curr_state)

PUB syncwd_mode(mode): curr_mode
' Set sync-word qualifier mode
'   Valid values:
'       SYNCMODE_NONE (0): Ignore preamble, syncword and carrier level
'       SYNCMODE_1516 (1): 15 of 16 syncword bits must match
'      *SYNCMODE_1616 (2): 16 of 16 syncword bits must match
'       SYNCMODE_3032 (3): 30 of 32 syncword bits must match
'       SYNCMODE_CS_ONLY (4): Ignore preamble and syncword,
'           but carrier must be above threshold
'       SYNCMODE_1516_CS (5): 15 of 16 syncword bits must match,
'           and carrier must be above threshold
'       SYNCMODE_1616_CS (6): 16 of 16 syncword bits must match,
'           and carrier must be above threshold
'       SYNCMODE_3032_CS (7): 30 of 32 syncword bits must match,
'           and carrier must be above threshold
'   Any other value polls the chip and returns the current setting
'   NOTE: A 32-bit syncword can be emulated by setting this method to
'       SYNCMODE_3032 or SYNCMODE_3032_CS. In these cases, the syncword
'       specified by syncwd() will be transmitted twice.
    curr_mode := 0
    readreg(core#MDMCFG2, 1, @curr_mode)
    case mode
        0..7:
        other:
            return curr_mode & core#SYNC_MODE_BITS

    mode := ((curr_mode & core#SYNC_MODE_MASK) | mode) & core#MDMCFG2_MASK
    writereg(core#MDMCFG2, 1, @mode)

PUB set_syncwd(ptr_syncwd)
' Set transmitted (TX) or expected (RX) syncword
'   ptr_syncwd: pointer to syncword data
'   Valid values: $0000..$FFFF (default: $D391)
    writereg(core#SYNC1, 2, ptr_syncwd)

PUB syncwd(ptr_syncwd)
' Get current syncword
'   ptr_syncwd: pointer to copy syncword data to
    readreg(core#SYNC1, 2, ptr_syncwd)

PUB tx_mode{}
' Change chip state to TX (transmit)
    writereg(core#CS_STX, 0, 0)

PUB tx_payld(nr_bytes, ptr_buff)
' Queue data to transmit in the TX FIFO
'   nr_bytes Valid values: 1..64
'   Any other value is ignored
    writereg(core#FIFO, nr_bytes, ptr_buff)

PUB tx_pwr(pwr): curr_pwr
' Set transmit power, in dBm
'   Valid values: -30, -20, -15, -10, 0, 5, 7, 10
'   Any other value polls the chip and returns the current setting
    curr_pwr := 0
    readreg(core#PATABLE, 1, @curr_pwr)
    case pwr
        -30, -20, -15, -10, 0, 5, 7, 10:
            pwr := lookdown(pwr: -30, -20, -15, -10, 0, 5, 7, 10)
            case carrier_freq(-2)                ' set power reg. value depends
                285_000_000..322_000_000:       '   on current freq. band
                    pwr := lookup(pwr: $12, $0D, $1C, $34, $51, $85, $CB, $C2)
                420_000_000..450_000_000:
                    pwr := lookup(pwr: $12, $0E, $1D, $34, $60, $84, $C8, $C0)
                854_000_000..894_000_000:
                    pwr := lookup(pwr: $03, $0F, $1E, $27, $50, $81, $CB, $C2)
                902_000_000..928_000_000:
                    pwr := lookup(pwr: $03, $0E, $1E, $27, $8E, $CD, $C7, $C0)
        other:
            case carrier_freq(-2)
                285_000_000..322_000_000:
                    curr_pwr := lookdown(curr_pwr: $12, $0D, $1C, $34, $51, $85, $CB, $C2)
                420_000_000..450_000_000:
                    curr_pwr := lookdown(curr_pwr: $12, $0E, $1D, $34, $60, $84, $C8, $C0)
                854_000_000..894_000_000:
                    curr_pwr := lookdown(curr_pwr: $03, $0F, $1E, $27, $50, $81, $CB, $C2)
                902_000_000..928_000_000:
                    curr_pwr := lookdown(curr_pwr: $03, $0E, $1E, $27, $8E, $CD, $C7, $C0)
            return lookup(curr_pwr: -30, -20, -15, -10, 0, 5, 7, 10)

    writereg(core#PATABLE, 1, @pwr)

PUB tx_pwr_idx(idx): curr_idx
' Set index within PA table to write TX power to (used for FSK power ramping, or ASK shaping)
'   Valid values: 0..7
'   Any other value polls the chip and returns the current setting
'   NOTE: For simple transmit power setting without ramping,
'       set this value to 0 and then set tx_pwr() to desired output power.
    curr_idx := 0
    readreg(core#FREND0, 1, @curr_idx)
    case idx
        0..7:
        other:
            return curr_idx & core#PA_POWER_BITS

    idx := ((curr_idx & core#PA_POWER_MASK) | idx) & core#FREND0_MASK
    writereg(core#FREND0, 1, @idx)

PUB wake_on_radio{}
' Change chip state to WOR (Wake-on-Radio)
    writereg(core#CS_SWOR, 0, 0)

PUB xtal_off{}
' Turn off crystal oscillator
    writereg(core#CS_SXOFF, 0, 0)

PRI getstatus{}: curr_status
' Read the status byte
    writereg(core#CS_SNOP, 0, 0)
    return _status

PRI readreg(reg_nr, nr_bytes, ptr_buff)
' Read nr_bytes from device into ptr_buff
    case reg_nr
        core#IOCFG2..core#TEST0, core#PATABLE:  ' Config. regs
            case nr_bytes
                1:
                2..64:
                    reg_nr |= core#BURST
                other:
                    return
        core#PARTNUM..core#RCCTRL0_STATUS:      ' Status regs
            reg_nr |= core#BURST                '   -set BURST mode bit to read
        core#FIFO:                              ' FIFO
            case nr_bytes
                1:
                2..64:
                    reg_nr |= core#BURST
                0:
                    return
            outa[_CS] := 0
            spi.wr_byte(reg_nr | core#R)
            spi.rdblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
            return

    outa[_CS] := 0
    spi.wr_byte(reg_nr | core#R)
    spi.rdblock_msbf(ptr_buff, nr_bytes)
    outa[_CS] := 1

PRI writereg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes to device from ptr_buff
    case reg_nr
        core#IOCFG2..core#TEST0, core#PATABLE:  ' Config. regs
            case nr_bytes
                0:                              ' Invalid nr_bytes - ignore
                    return
                1:
                2..64:
                    reg_nr |= core#BURST
                other:
                    return
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            spi.wrblock_msbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
            return
        core#CS_SRES..core#CS_SNOP:             ' Command strobes
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            _status := spi.rd_byte{}
            outa[_CS] := 1
            return
        core#FIFO:
            case nr_bytes
                1:
                2..64:
                    reg_nr |= core#BURST
                0:
                    return
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
            return
        other:                                  ' Invalid reg - ignore
            return

DAT
{
Copyright 2022 Jesse Burt

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

