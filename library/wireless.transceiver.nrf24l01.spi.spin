{
    --------------------------------------------
    Filename: wireless.transceiver.nrf24l01.spi.spin
    Author: Jesse Burt
    Description: Driver for Nordic Semi. nRF24L01+
    Copyright (c) 2019
    Started Jan 6, 2019
    Updated Jul 19, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    TRXSETTLE   = 130 'us
    TTXSETTLE   = 130 'us
    THCE        = 10  'us

    RF_PWR_0    = %11           ' 0dBm
    RF_PWR__6   = %10           ' -6dBm
    RF_PWR__12  = %01           ' -12dBm
    RF_PWR__18  = %00           ' -18dBm

    ROLE_TX     = 0
    ROLE_RX     = 1

' Recommended states:
' Power down:
'   PWR_UP = 1: XO Start (wait Tpd2stby) transition to Standby I
'   Tpd2stby:
'       150uS Ext clock
'       1.5ms Ext xtal, Ls < 30mH
'       3.0ms Ext xtal, Ls < 60mH
'       4.5ms Ext xtal, Ls < 90mH

' Standby-I:
'   TX_FIFO not empty, PRIM_RX = 0, CE = 1 for >= 10uS: -> TX Settling 130uS -> TX Mode
'   TX finished with one packet, CE = 0: -> Standby-I

'   PRIM_RX = 1, CE = 1: -> RX Settling 130uS -> RX Mode
'   CE = 0 to return to Standby-I

'   PWR-UP = 0 to return to Power Down

VAR

    byte    _CE, _CSN, _SCK, _MOSI, _MISO
    word    _status

OBJ

    spi:    "com.spi.4w"
    core:   "core.con.nrf24l01"
    time:   "time"

PUB Null
''This is not a top-level object

PUB Startx(CE_PIN, CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): okay

    if lookdown(CE_PIN: 0..31) and lookdown(CSN_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if okay := spi.start (core#CLK_DELAY, core#CPOL)
            _CE := CE_PIN
            _CSN := CSN_PIN
            _SCK := SCK_PIN
            _MOSI := MOSI_PIN
            _MISO := MISO_PIN
            time.MSleep(core#TPOR)
            time.MSleep(core#TPD2STBY)

            outa[_CE] := 0
            dira[_CE] := 1
            outa[_CSN] := 1
            dira[_CSN] := 1

            return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    outa[_CSN] := 0
    outa[_CE] := 0
    dira[_CSN] := 0
    dira[_CE] := 0
    spi.stop

PUB CE(state)
' Set state of Chip-Enable pin
    outa[_CE] := state
    time.USleep (THCE)

PUB AddressWidth(bytes) | tmp
' Set width, in bytes, of RX/TX address field
'   Valid values: 3, 4, 5
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_SETUP_AW, 1, @tmp)
    case bytes
        3, 4, 5:
            bytes := bytes-2
        OTHER:
            return (tmp & core#BITS_AW) + 2

    tmp &= core#MASK_AW
    tmp := (tmp | bytes) & core#NRF24_SETUP_AW_MASK
    writeRegX (core#NRF24_SETUP_AW, 1, @tmp)

PUB AutoRetransmitDelay(delay_us) | tmp
' Setup of automatic retransmission - Auto Retransmit Delay, in microseconds
' Delay defined from end of transmission to start of next transmission
'   Valid values: 250..4000
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_SETUP_RETR, 1, @tmp)
    case delay_us := lookdown(delay_us: 250, 500, 750, 1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000, 3250, 3500, 3750, 4000)
        1..16:
            delay_us := (delay_us - 1) << core#FLD_ARD
        OTHER:
            tmp := ((tmp >> core#FLD_ARD) & core#BITS_ARD) + 1
            return lookup(tmp: 250, 500, 750, 1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000, 3250, 3500, 3750, 4000)

    tmp &= core#MASK_ARD
    tmp := (tmp | delay_us) & core#NRF24_SETUP_RETR_MASK
    writeRegX (core#NRF24_SETUP_RETR, 1, @tmp)

PUB AutoRetransmitCount(tries) | tmp
' Setup of automatic retransmission - Auto Retransmit Count
' Defines number of attempts to re-transmit on fail of Auto-Acknowledge
'   Valid values: 0..15 (0 disables re-transmit)
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_SETUP_RETR, 1, @tmp)
    case tries
        0..15:
        OTHER:
            return (tmp & core#BITS_ARC)

    tmp &= core#MASK_ARC
    tmp := (tmp | tries) & core#NRF24_SETUP_RETR_MASK
    writeRegX (core#NRF24_SETUP_RETR, 1, @tmp)

PUB Channel(ch)
' Set/Get RF Channel
'   Resulting frequency of set channel = 2400MHz + ch
'       e.g., if ch is 35, Frequency is 2435MHz
'   Valid values: 0..127 sets channel
'   Any other value polls the chip and returns the current setting
    case ch
        0..127:
            writeRegX (core#NRF24_RF_CH, 1, @ch)
        OTHER:
            readRegX (core#NRF24_RF_CH, 1, @result)

PUB CRCEncoding(bytes) | tmp
' Choose CRC Encoding scheme, in bytes
'   Valid values: 1, 2
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_CONFIG, 1, @tmp)
    case bytes
        1, 2:
            bytes := (bytes-1) << core#FLD_CRCO
        OTHER:
            return ((tmp >> core#FLD_CRCO) & %1) + 1

    tmp &= core#MASK_CRCO
    tmp := (tmp | bytes) & core#NRF24_CONFIG_MASK
    writeRegX (core#NRF24_CONFIG, 1, @tmp)

PUB CW(enabled) | tmp
' Enable continuous wave carrier transmit (intended for testing only)
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_RF_SETUP, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_CONT_WAVE
        OTHER:
            return ((tmp >> core#FLD_CONT_WAVE) & %1) * TRUE

    tmp &= core#MASK_CONT_WAVE
    tmp := (tmp | enabled) & core#NRF24_RF_SETUP_MASK
    writeRegX (core#NRF24_RF_SETUP, 1, @tmp)

PUB DataReady(clear_intr) | tmp
' Query or clear Data Ready (received) interrupt
'   Valid values: TRUE (-1 or 1): Clear interrupt flag
'   Any other value queries the chip and returns TRUE if new data in FIFO, FALSE otherwise
    readRegX (core#NRF24_STATUS, 1, @tmp)
    case ||clear_intr
        1:
            clear_intr := ||clear_intr << core#FLD_RX_DR
        OTHER:
            tmp := ((tmp >> core#FLD_RX_DR) & core#BITS_RX_DR) * TRUE

    tmp &= core#MASK_RX_DR
    tmp := (tmp | clear_intr) & core#NRF24_STATUS_MASK
    writeRegX (core#NRF24_STATUS, 1, @tmp)

PUB DataSent(clear_intr) | tmp
' Query or clear Data Sent interrupt
'   Valid values: TRUE (-1 or 1): Clear interrupt flag
'   Any other value polls the chip and returns TRUE if packet transmitted, FALSE otherwise
    readRegX (core#NRF24_STATUS, 1, @tmp)
    case ||clear_intr
        1:
            clear_intr := ||clear_intr << core#FLD_TX_DS
        OTHER:
            tmp := ((tmp >> core#FLD_TX_DS) & core#BITS_TX_DS) * TRUE

    tmp &= core#MASK_TX_DS
    tmp := (tmp | clear_intr) & core#NRF24_STATUS_MASK
    writeRegX (core#NRF24_STATUS, 1, @tmp)

PUB EnableACK(enabled) | tmp
' Enable payload with ACK
' XXX Add timing notes/code from datasheet, p.63, note d
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_FEATURE, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_EN_ACK_PAY
        OTHER:
            return ((tmp >> core#FLD_EN_ACK_PAY) & core#BITS_EN_ACK_PAY) * TRUE

    tmp &= core#MASK_EN_ACK_PAY
    tmp := (tmp | enabled) & core#NRF24_FEATURE_MASK
    writeRegX (core#NRF24_FEATURE, 1, @tmp)

PUB EnableCRC(enabled) | tmp
' Enable CRC
' NOTE: Forced on if any data pipe has AutoAck enabled
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_CONFIG, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_EN_CRC
        OTHER:
            return ((tmp >> core#FLD_EN_CRC) & %1) * TRUE

    tmp &= core#MASK_EN_CRC
    tmp := (tmp | enabled) & core#NRF24_CONFIG_MASK
    writeRegX (core#NRF24_CONFIG, 1, @tmp)

PUB EnableDynPayload(enabled) | tmp
' Enable Dynamic Payload Length
' NOTE: Must be enabled to use the DynamicPayload method.
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_FEATURE, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_EN_DPL
        OTHER:
            return ((tmp >> core#FLD_EN_DPL) & core#BITS_EN_DPL) * TRUE

    tmp &= core#MASK_EN_DPL
    tmp := (tmp | enabled) & core#NRF24_FEATURE_MASK
    writeRegX (core#NRF24_FEATURE, 1, @tmp)

PUB EnablePipe(mask) | tmp
' Control which data pipes (0 through 5) are enabled, using a 6-bit mask
'   Data pipe:     5    0   5     0
'                  |....|   |.....|
'   Valid values: %000000..%1111111
    readRegX (core#NRF24_EN_RXADDR, 1, @tmp)
    case mask
        %000000..%111111:
'           Don't actually do anything if the values are in this range,
'            since they're already actually valid. Commented line below
'            shows what *would* be done:
'            mask := (mask << core#FLD_ERX_P0)
        OTHER:
            return tmp & core#NRF24_EN_RXADDR_MASK

    tmp &= core#MASK_EN_RXADDR
    tmp := (tmp | mask) & core#NRF24_EN_RXADDR_MASK
    writeRegX (core#NRF24_EN_RXADDR, 1, @tmp)

PUB FlushRX
' Flush receive FIFO
    writeRegX(core#NRF24_FLUSH_RX, 0, 0)

PUB FlushTX
' Flush transmit FIFO
    writeRegX(core#NRF24_FLUSH_TX, 0, 0)

PUB DynamicACK(enabled) | tmp
' Enable selective auto-acknowledge feature
' When enabled, the receive will not auto-acknowledge packets sent to it.
' XXX expand
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_FEATURE, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_EN_DYN_ACK
        OTHER:
            return ((tmp >> core#FLD_EN_DYN_ACK) & core#BITS_EN_DYN_ACK) * TRUE

    tmp &= core#MASK_EN_DYN_ACK
    tmp := (tmp | enabled) & core#NRF24_FEATURE_MASK
    writeRegX (core#NRF24_FEATURE, 1, @tmp)

PUB DynamicPayload(mask) | tmp
' Control which data pipes (0 through 5) have dynamic payload length enabled, using a 6-bit mask
'   Data pipe:     5    0   5     0
'                  |....|   |.....|
'   Valid values: %000000..%1111111
    readRegX (core#NRF24_DYNPD, 1, @tmp)
    case mask
        %000000..%111111:
'           Don't actually do anything if the values are in this range,
'            since they're already actually valid. Commented line below
'            shows what *would* be done:
'            mask := (mask << core#FLD_ERX_P0)
        OTHER:
            return tmp & core#NRF24_DYNPD_MASK

    tmp &= core#MASK_DPL
    tmp := (tmp | mask) & core#NRF24_DYNPD_MASK
    writeRegX (core#NRF24_DYNPD, 1, @tmp)

PUB IntMask(mask) | tmp
' Control which events will trigger an interrupt on the IRQ pin, using a 3-bit mask
'           Bits:  210   210
'                  |||   |||
'   Valid values: %000..%111
'       Bit:    Interrupt will be asserted on IRQ pin if:
'       2       new data is ready in RX FIFO
'       1       data is transmitted
'       0       TX retransmits reach maximum
'   Set a bit to 0 to disable the specific interrupt, 1 to enable
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_CONFIG, 1, @tmp)
    case mask
        %000..%111:
            mask := !(mask << core#FLD_MASK_MAX_RT) 'Invert because the chip's internal logic is reversed, i.e.,
        OTHER:                                      ' 1 disables the interrupt, 0 enables an active-low interrupt
            return !(tmp >> core#FLD_MASK_MAX_RT) & core#BITS_INTS

    tmp &= core#MASK_INTS
    tmp := (tmp | mask) & core#NRF24_CONFIG_MASK
    writeRegX (core#NRF24_CONFIG, 1, @tmp)

PUB LostPackets
' Count lost packets, to a maximum of 15
'   Returns: Number of lost packets since channel was set
'   NOTE: To clear the count, the channel must be re-set
    readRegX (core#NRF24_OBSERVE_TX, 1, @result)
    result := (result >> core#FLD_PLOS_CNT) & core#BITS_PLOS_CNT

PUB MaxRetrans(clear_intr) | tmp
' Query or clear Maximum number of TX retransmits interrupt
' NOTE: If this flag is set, it must be cleared to enable further communication.
'   Valid values: 1 or TRUE: Clear interrupt flag
'   Any other value returns TRUE when max number of retransmits reached, FALSE otherwise
    readRegX (core#NRF24_STATUS, 1, @tmp)
    case ||clear_intr
        1:
            clear_intr := %1 << core#FLD_MAX_RT
        OTHER:
            return ((tmp >> core#FLD_MAX_RT) & core#BITS_MAX_RT) * TRUE

    tmp &= core#MASK_MAX_RT
    tmp := (tmp | clear_intr) & core#NRF24_STATUS_MASK
    writeRegX (core#NRF24_STATUS, 1, @tmp)

PUB PLL_Lock(enabled) | tmp
' Force PLL Lock signal (intended for testing only)
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_RF_SETUP, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_PLL_LOCK
        OTHER:
            return ((tmp >> core#FLD_PLL_LOCK) & %1) * TRUE

    tmp &= core#MASK_PLL_LOCK
    tmp := (tmp | enabled) & core#NRF24_RF_SETUP_MASK
    writeRegX (core#NRF24_RF_SETUP, 1, @tmp)

PUB PowerUp(enabled) | tmp
' Power on or off
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_CONFIG, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_PWR_UP
        OTHER:
            return ((tmp >> core#FLD_PWR_UP) & %1) * TRUE

    tmp &= core#MASK_PWR_UP
    tmp := (tmp | enabled) & core#NRF24_CONFIG_MASK
    writeRegX (core#NRF24_CONFIG, 1, @tmp)

PUB Rate(kbps) | tmp, lo, hi, tmp2, tmp3
' Set RF data rate in kbps
'   Valid values: 250, 1000, 2000
'   Any other value polls the chip and returns the current setting
'   NOTE: Auto-acknowledgment/ShockBurst is only available at 1000 and 2000kbps
    readRegX (core#NRF24_RF_SETUP, 1, @tmp)
    case kbps
        1000:
            tmp &= core#MASK_RF_DR_HIGH
            tmp &= core#MASK_RF_DR_LOW
        2000:
            tmp |= (1 << core#FLD_RF_DR_HIGH)
            tmp &= core#MASK_RF_DR_LOW
        250:
            tmp &= core#MASK_RF_DR_HIGH
            tmp |= (1 << core#FLD_RF_DR_LOW)
        OTHER:
            tmp := (tmp >> core#FLD_RF_DR_HIGH) & %101          'Only care about the RF_DR_x bits
            result := lookupz(tmp: 1000, 2000, 0, 0, 250)
            return result

    writeRegX (core#NRF24_RF_SETUP, 1, @tmp)

PUB RetrPackets
' Count retransmitted packets
'   Returns: Number of packets retransmitted since the start of transmission of a new packet
    readRegX (core#NRF24_OBSERVE_TX, 1, @result)
    result &= core#BITS_ARC_CNT

PUB RFPower(power) | tmp
' Set RF output power in TX mode, in dBm
'   Valid values: -18, -12, -6, 0
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_RF_SETUP, 1, @tmp)
    case power
        -18, -12, -6, 0:
            power := lookdownz(power: -18, -12, -6, 0)
            power := power << core#FLD_RF_PWR
        OTHER:
            tmp := (tmp >> core#FLD_RF_PWR) & core#BITS_RF_PWR
            return lookupz(tmp: -18, -12, -6, 0)

    tmp &= core#MASK_RF_PWR
    tmp := (tmp | power) & core#NRF24_RF_SETUP_MASK
    writeRegX (core#NRF24_RF_SETUP, 1, @tmp)

PUB RPD
' Received Power Detector
'   Returns:
'      FALSE/0: No Carrier
'      TRUE/-1: Carrier Detected
    readRegX (core#NRF24_RPD, 1, @result)
    return (result & %1) * TRUE

PUB RXAddr(pipe, buff_addr) | tmp[2], i, addr_test
' Set receive address of pipe number 'pipe' from buffer at address buff_addr
'   Valid values:
'       pipe: 0..5
'           Any other value is ignored
'       buff_addr:
'           For pipes 0 and 1, must be a buffer at least 5 bytes long, $00..$FF
'           For pipes 2..5, must be a buffer at least 1 byte long, $01..$FF
'   Setting buff_addr to all 0's polls the chip and returns the current address for the given pipe number
    tmp := 0
    addr_test := 0
    case pipe
        0, 1:
            readRegX (core#NRF24_RX_ADDR_P0 + pipe, 5, @tmp)
            repeat i from 0 to 4
                addr_test := addr_test + byte[buff_addr][i]
            if addr_test == 0
                bytemove(buff_addr, @tmp, 5)
                return
            else
                writeRegX (core#NRF24_RX_ADDR_P0 + pipe, 5, buff_addr)
        2..5:
            readRegX (core#NRF24_RX_ADDR_P0 + pipe, 1, @tmp)
            if byte[buff_addr][0] == 0
                bytemove(buff_addr, @tmp, 1)
            else
                writeRegX (core#NRF24_RX_ADDR_P0 + pipe, 1, buff_addr)
        OTHER:
            return

PUB RXData(nr_bytes, buff_addr) | tmp
' Read data from the receive FIFO
'   NOTE: Buffer at address buff_addr must be at least nr_bytes bytes in length
    bytefill(buff_addr, 0, 32)      'Ensure the buffer is clear before reading in new data
    readRegX (core#NRF24_R_RX_PAYLOAD, nr_bytes, buff_addr)

PUB RXFIFO_Empty
' Queries the chip to check if the receive FIFO is empty
'   Returns TRUE if empty, FALSE if there's data in RX FIFO
    readRegX (core#NRF24_FIFO_STATUS, 1, @result)
    return (result & %1) * TRUE

PUB RXFIFO_Full
' Queries the chip to check if the receive FIFO is full
'   Returns TRUE if full, FALSE if not
    readRegX (core#NRF24_FIFO_STATUS, 1, @result)
    result >>= core#FLD_RXFIFO_FULL  
    result &= %1

PUB RXPayload(pipe, width) | tmp
' Set length of static payload, in bytes
'   Returns number of bytes in RX payload in data pipe, or 0 if pipe unused
'   Valid values:
'       pipe: 0..5
'       width: 0..32
'   Any other value for pipe is ignored
'   Any other value for width polls the chip and returns the current setting
'   NOTE: Setting a width of 0 effectively disables the pipe
    tmp := 0
    case pipe
        0..5:
            readRegX (core#NRF24_RX_PW_P0 + pipe, 1, @tmp)
            case width
                0..32:
                    writeRegX(core#NRF24_RX_PW_P0 + pipe, 1, @width)
                    return width
                OTHER:
                    result := tmp & core#BITS_RX_PW_P0
                    return result

        OTHER:
            return FALSE

PUB RXPipePending
' Returns pipe number of pending data available in FIFO
'   Returns: Pipe number 0..5, or 7 if FIFO is empty
    result := (Status & core#FLD_RX_P_NO)

PUB RXTX(role) | tmp
' Set to Primary RX or TX
'   Valid values: 0: TX, 1: RX
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_CONFIG, 1, @tmp)
    case role
        0, 1:
            role := role << core#FLD_PRIM_RX
        OTHER:
            return ((tmp >> core#FLD_PRIM_RX) & %1)

    tmp &= core#MASK_PRIM_RX
    tmp := (tmp | role) & core#NRF24_CONFIG_MASK
    writeRegX (core#NRF24_CONFIG, 1, @tmp)

PUB EnableAuto_Ack(pipe_mask) | tmp
' Control which data pipes (0 through 5) the Auto Acknowledgement function (aka Enhanced ShockBurst - (TM) NORDIC Semi.)
'  should be enabled on, using a 6-bit mask.
'   Data Pipe:     5    0   5    0
'                  |....|   |....|
'   Valid values: %000000..%111111
'   0 disables AA for the given pipe, 1 enables
'   Example:
'       EnableAuto_Ack(%001010)
'           would enable AA for data pipes 1 and 3, and disable for all others
    readRegX (core#NRF24_EN_AA, 1, @tmp)
    case pipe_mask
        %000000..%111111:
'           Don't actually do anything if the values are in this range,
'            since they're already actually valid. Commented line below
'            shows what *would* be done:
'            pipe_mask := (pipe_mask << core#FLD_ENAA_P0)
        OTHER:
            return tmp & core#NRF24_EN_AA_MASK

    writeRegX (core#NRF24_EN_AA, 1, @pipe_mask)

PUB TXAddr(buff_addr) | tmp[2], i, addr_test
' Set transmit address
'   Valid values: Bytes $00..$FF
'   Setting buff_addr to all 0's polls the chip and returns the current address
' NOTE: Buffer at buff_addr must be a minimum of 5 bytes
    tmp := 0
    addr_test := 0
    readRegX (core#NRF24_TX_ADDR, 5, @tmp)

    repeat i from 0 to 4
        addr_test := addr_test + byte[buff_addr][i]
    if addr_test == 0
        bytemove(buff_addr, @tmp, 5)
        return
    else
        writeRegX (core#NRF24_TX_ADDR, 5, buff_addr)

PUB TXData(nr_bytes, buff_addr) | cmd_packet, tmp
' Adds data to the transmit FIFO
'   Valid values:
'       nr_bytes: 1..32
'   Any other value is ignored
    case nr_bytes
        1..32:
            writeRegX(core#NRF24_W_TX_PAYLOAD, nr_bytes, buff_addr)
        OTHER:
            return FALSE

PUB TXFIFO_Empty
' Queries the chip to check if the transmit FIFO is empty
'   Returns: TRUE if empty, FALSE if there's data in TX FIFO
    readRegX (core#NRF24_FIFO_STATUS, 1, @result)
    return ((result >> core#FLD_TXFIFO_EMPTY) & %1) * TRUE

PUB TXFIFO_Full
' Queries the chip to check if the transmit FIFO is full
'   Returns: TRUE if full, FALSE if space still available in TX FIFO
    readRegX (core#NRF24_FIFO_STATUS, 1, @result)
    return ((result >> core#FLD_TXFIFO_FULL) & %1) * TRUE

PUB TXReuse
' Queries the chip to check if the last transmitted payload will be re-used
'   Returns: TRUE if re-using last transmitted payload, FALSE if not
    readRegX (core#NRF24_FIFO_STATUS, 1, @result)
    result &= (1 << core#FLD_TXFIFO_REUSE) * TRUE

PUB Status
' Returns status of last SPI transaction
    readRegX (core#NRF24_STATUS, 1, @result)

PUB rawread(reg)

    readRegX (reg, 1, @result)

PUB writeRegX(reg, nr_bytes, buf_addr) | tmp
' Write reg to MOSI
'    ifnot lookdown(reg: $00..$17, $1C..$1D, $A0, $E1..$E3)                             'Validate reg - there are a few the datasheet says are for testing
'        return FALSE                                                    ' only and will cause the chip to malfunction if written to.
'XXX Check flow w.r.t. CS - previously possible cases where it was never brought back high before returning
    reg |= core#NRF24_W_REG
    outa[_CSN] := 0
    spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
    repeat tmp from 0 to nr_bytes-1
        spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][tmp])
    outa[_CSN] := 1

{    case reg
        core#NRF24_W_TX_PAYLOAD:
            outa[_CSN] := 0
            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            repeat tmp from 0 to nr_bytes-1
                spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][tmp])
            outa[_CSN] := 1

        core#NRF24_FLUSH_TX:
            outa[_CSN] := 0
            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            outa[_CSN] := 1

        core#NRF24_FLUSH_RX:
            outa[_CSN] := 0
            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            outa[_CSN] := 1

        OTHER:
            case nr_bytes
                0:
                    outa[_CSN] := 0
                    spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, core#NRF24_W_REG|reg)     'Simple command
                    outa[_CSN] := 1
                1..5:
                    outa[_CSN] := 0
                    spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, core#NRF24_W_REG|reg)     'Command w/nr_bytes data bytes following
                    repeat tmp from 0 to nr_bytes-1
                        spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][tmp])
                    outa[_CSN] := 1

                OTHER:
                    result := FALSE
                    buf_addr := 0
}
PUB readRegX(reg, nr_bytes, buf_addr) | tmp
' Read reg from MISO
'    ifnot lookdown(reg: $00..$17, $1C..$1D, $61)                             'Validate reg - there are a few the datasheet says are for testing
'        return FALSE                                                    ' only and will cause the chip to malfunction if written to.

    case reg
        core#NRF24_RPD:
            outa[_CSN] := 0
            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            byte[buf_addr][0] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
            outa[_CSN] := 1

        core#NRF24_R_RX_PAYLOAD:
            outa[_CSN] := 0
            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            repeat tmp from 0 to nr_bytes-1
                byte[buf_addr][tmp] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
            outa[_CSN] := 1

        OTHER:

            case nr_bytes
                1..5:
                    outa[_CSN] := 0
                    spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, core#NRF24_R_REG | reg)              'Which register to query
                    repeat tmp from 0 to nr_bytes-1
                        byte[buf_addr][tmp] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
                    outa[_CSN] := 1
                OTHER:
                    result := FALSE
                    buf_addr := 0

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
