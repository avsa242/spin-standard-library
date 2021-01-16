{
    --------------------------------------------
    Filename: sensor.iaq.sgp30.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Sensirion SGP30
        Indoor Air Quality sensor
    Copyright (c) 2020
    Started Nov 20, 2020
    Updated Nov 20, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR


OBJ

    i2c : "com.i2c"
    core: "core.con.sgp30.spin"
    time: "time"

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins and 100kHz
    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
                time.usleep(core#T_POR)
                if i2c.present(SLAVE_WR)        ' test device bus presence
                    return

    return FALSE                                ' something above failed

PUB Stop{}
' Put any other housekeeping code here required/recommended by your device before shutting down
    i2c.terminate{}

PUB Defaults{}
' Set factory defaults

PUB CO2Eq{}: ppm
' CO2/Carbon Dioxide equivalent concentration
'   Returns: parts-per-million (400..60_000)
    readreg(core#MEAS_IAQ, 4, @ppm)
    return (ppm & $FFFF)

PUB DeviceID{}: id
' Read device identification
    readreg(core#GET_FEATURES, 2, @id)

PUB IAQData{}: adc
' Indoor air-quality data ADC words
'   Returns: TVOC word | CO2 word (MSW|LSW)
    readreg(core#MEAS_RAW, 4, @adc)

PUB Reset{}
' Reset the device
'   NOTE: There is a delay of approximately 15 seconds after calling
'   this method, during which the sensor will return 400ppm CO2Eq and
'   0ppb TVOC
    writereg(core#IAQ_INIT, 0, 0)

PUB SerialNum(ptr_buff)
' Read device Serial Number
'   NOTE: ptr_buff must be at least 6 bytes in length
    readreg(core#GET_SN, 6, ptr_buff)

PUB TVOC{}: ppb
' Total Volatile Organic Compounds concentration
'   Returns: parts-per-billion (0..60_000)
    readreg(core#MEAS_IAQ, 4, @ppb)
    return (ppb >> 16) & $FFFF

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, rd_data[3], tmp
' Read nr_bytes from the device into ptr_buff
    cmd_pkt.byte[0] := SLAVE_WR                 ' form command packet
    cmd_pkt.byte[1] := reg_nr.byte[1]
    cmd_pkt.byte[2] := reg_nr.byte[0]

    case reg_nr                                 ' validate command
        core#MEAS_IAQ, core#GET_IAQ_BASE, core#MEAS_RAW:
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)
            i2c.wait(SLAVE_RD)                  ' poll the sensor for readiness
            repeat tmp from 0 to 5              ' read all bytes, incl. CRC's
                rd_data.byte[tmp] := i2c.read(tmp == 5)
            i2c.stop{}

            byte[ptr_buff][0] := rd_data.byte[1]' copy the sensor data to
            byte[ptr_buff][1] := rd_data.byte[0]'   ptr_buff, but skip over
            byte[ptr_buff][2] := rd_data.byte[4]'   the CRC bytes, for now
            byte[ptr_buff][3] := rd_data.byte[3]'
            return
        core#MEAS_TEST, core#GET_FEATURES, core#GET_TVOC_INCBASE:
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)
            i2c.wait(SLAVE_RD)
            repeat tmp from 0 to 2
                rd_data.byte[tmp] := i2c.read(tmp == 2)
            i2c.stop{}

            byte[ptr_buff][0] := rd_data.byte[1]
            byte[ptr_buff][1] := rd_data.byte[0]
        core#GET_SN:
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)
            i2c.wait(SLAVE_RD)
            repeat tmp from 0 to 8
                rd_data.byte[tmp] := i2c.read(tmp == 8)
            i2c.stop{}

            byte[ptr_buff][0] := rd_data.byte[1]
            byte[ptr_buff][1] := rd_data.byte[0]
            byte[ptr_buff][2] := rd_data.byte[4]
            byte[ptr_buff][3] := rd_data.byte[3]
            byte[ptr_buff][4] := rd_data.byte[7]
            byte[ptr_buff][5] := rd_data.byte[6]
            return
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt[2], tmp
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        core#IAQ_INIT:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)
            i2c.stop{}
        core#SET_IAQ_BASE, core#SET_ABS_HUM, core#SET_TVOC_BASE:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}
        other:
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
