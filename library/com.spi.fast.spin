{
    --------------------------------------------
    Filename: com.spi.fast.spin
    Author: Timothy D. Swieter
    Modified by: Jesse Burt
    Description: Fast PASM SPI driver (20MHz W, 10MHz R)
    Started Oct 13, 2012
    Updated May 9, 2020
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is an excerpt of Timothy D. Swieter's Wiznet W5200 driver
        adapted for use as a general-purpose SPI engine.
        The original header is preserved below.

''  WIZnet W5200 Driver Ver. 1.3
''
''  Original source: W5100_SPI_Driver.spin - Timothy D. Swieter (code.google.com/p/spinneret-web-server/source/browse/trunk/W5100_SPI_Driver.spin)
''  W5200 changes/adaptations: Benjamin Yaroch (BY)
''  Additional revisions: Jim St. John (JS)
''
}

CON

    CMD_RESERVED    = 0                                     ' Default state - means ASM is waiting for command
    CMD_READ        = 1 << 16
    CMD_WRITE       = 2 << 16
    CMD_LAST        = 17 << 16                              ' Placeholder for last command

VAR

    long _cog

OBJ

    counters    : "core.con.counters"

DAT

' Command setup
    command         long    0                               ' Stores command and arguments for the ASM driver
    lock            byte    255                             ' Mutex semaphore

PUB Start(CS, SCLK, MOSI, MISO) : okay

    Stop

    SCSmask := |< CS
    SCLKmask := |< SCLK
    MOSImask := |< MOSI
    MISOmask := |< MISO

'Counter values setup before calling the ASM cog that will use them.
    ctramode := counters#NCO_SINGLEEND | counters#VCO_DIV_128 + SCLK
    ctrbmode := counters#NCO_SINGLEEND | counters#VCO_DIV_128 + MOSI

'Clear the command buffer - be sure no commands were set before initializing
    command := 0

'Start a cog to execute the ASM routine
    okay := _cog := cognew(@entry, @command) + 1

PUB Stop

    if _cog
        cogstop(_cog - 1)
        longfill(@SCSmask, 0, 5)                            ' Clear all masks
        _cog := 0

PUB MutexInit
' Initialize mutex lock semaphore. Called once at driver initialization if application level locking is needed.
'   Returns: Lock number, or -1 if no more locks available.
    lock := locknew
    return lock

PUB MutexLock
' Waits until exclusive access to driver guaranteed.
    repeat until not lockset(lock)

PUB MutexRelease
' Release mutex lock.
    lockclr(lock)

PUB MutexReturn
' Returns mutex lock to semaphore pool.
    lockret(lock)

PUB Read(buff_addr, nr_bytes)
' Read nr_bytes from slave device into buff_addr
    command := CMD_READ + @buff_addr

    repeat while command

PUB Write(block, buff_addr, nr_bytes, deselect_after)
' Write nr_bytes from buff_addr into slave device
'   Valid values:
'       block:
'           Non-zero: Wait for ASM routine to finish before returning
'           0: Return immediately after writing
'       buff_addr: Pointer to byte(s) of data to be written
'       nr_bytes: Number of bytes to write
'       deselect_after:
'           TRUE (-1 or 1): Deselect slave/Raise CS after writing
'           FALSE (0): Leave slave selected/Keep CS low after writing; most commonly used for writing a register address that data will subsequently be read from with Read()
    deselect_after := (||deselect_after) <# 1
    command := CMD_WRITE + @buff_addr

    if block
        repeat while command

DAT
        org
entry
              'Set the initial state of the I/O, unless listed here, the output is initialized as off/low
              mov       outa,   SCSmask         'SPI slave select is initialized as high

              'Next set up the I/O with the masks in the direction register...
              '...all outputs pins are set up here because input is the default state
              mov       dira,   SCSmask         'Set to an output and clears cog dira register
              or        dira,   SCLKmask        'Set to an output
              or        dira,   MOSImask        'Set to an output
                                                'NOTE: MISOpin isn't here because it is an input
              mov       frqb,   #0              'Counter B is used as a special register. Frq is set to 0 so there isn't accumulation.
              mov       ctrb,   ctrbmode        'This turns Counter B on. The main purpose is to have phsb[31] bit appear on the MOSI line.

CmdWait
              rdlong    cmdAdrLen, par      wz  'Check for a command being present
        if_z  jmp       #CmdWait                'If there is no command, check again

              mov       t1, cmdAdrLen           'Take a copy of the command/address combo to work on
              rdlong    paramA, t1              'Get parameter A value
              add       t1, #4                  'Increment the address pointer by four bytes
              rdlong    paramB, t1              'Get parameter B value
              add       t1, #4                  'Increment the address pointer by four bytes
              rdlong    paramC, t1              'Get parameter C value

              add       t1, #4                  'Increment the address pointer by four bytesi
              mov       t0, cmdAdrLen           'Take a copy of the command/address combo to work on
              shr       t0, #16            wz   'Get the command
              cmp       t0, #(CMD_LAST>>16)+1 wc'Check for valid command
  if_z_or_nc  jmp       #:CmdExit               'Command is invalid so exit loop
              shl       t0, #1                  'Shift left, multiply by two
              add       t0, #:CmdTable-2        'add in the "call" address"
              jmp       t0                      'Jump to the command

              'The table of commands that can be called
:CmdTable     call      #rSPIcmd                'Read a byte
              jmp       #:CmdExit
              call      #wSPIcmd                'Write a byte
              jmp       #:CmdExit
              call      #LastCMD                'PlaceHolder for last command
              jmp       #:CmdExit
:CmdTableEnd

              'End of processing a command
:CmdExit      wrlong    _zero,  par             'Clear the command status
              jmp       #CmdWait                'Go back to waiting for a new command

rSPIcmd
              mov       ram,    ParamA          'Move the address of the returned byte into a variable for processing
              mov       ctr,    ParamB          'Set up a counter for number of bytes to process

              call      #ReadMulti              'Read the byte

rSPIcmd_ret ret                                 'Command execution complete

wSPIcmd
              mov       ram,    paramA          'Move the data byte into a variable for processing
              mov       ctr,    ParamB          'Set up a counter for number of bytes to process
              mov       deselect, ParamC        'Flag indicating if slave should be deselected after writing
              call      #writeMulti             'Write the byte

wSPIcmd_ret ret                                 'Command execution complete

LastCMD

LastCMD_ret ret                                 'Command execution complete

'-----------------------------------------------------------------------------------------------------
'Sub-routine to map write to SPI and to loop through bytes
' NOTE: RAM, Reg, and CTR setup must be done before calling this routine
'-----------------------------------------------------------------------------------------------------
WriteMulti

:bytes
              rdbyte    data,   ram             'Read the byte from hubram
              call      #wSPI_Data              'Write one byte

              add       ram, #1                 'Increment the hubram address by one byte
              djnz      ctr, #:bytes            'Check if there is another byte, if so, process it
              test      deselect, #1    wc      'Should we deselect the slave after writing?
        if_c  or        outa, scsmask           'If yes, de-assert CS
WriteMulti_ret ret                              'Return to the calling code

'-----------------------------------------------------------------------------------------------------
'Sub-routine to map read to SPI and to loop through bytes
' NOTE: Reg, and CTR setup must be done before calling this routine
'-----------------------------------------------------------------------------------------------------

ReadMulti     mov       dataLen, ctr            '# of bytes to read in one burst
:bytes
              call      #rSPI_Data              'Read one data byte 1.15us
              and       data, _bytemask         'Ensure there is only a byte    +20 clocks in this loop = 1.4us/byte
              wrbyte    data, ram               'Write the byte to hubram
              add       ram, #1                 'Increment the hubram address by one byte
              djnz      ctr, #:bytes            'Check if there is another if so, process it
              or        outa, scsmask           'Finally de-assert CS

ReadMulti_ret ret                               'Return to the calling code

wSPI
'High speed serial driver utilizing the counter modules. Counter A is the clock while Counter B is used as a special register
'to get the data on the output line in one clock cycle. This code is meant to run on 80MHz. processor and the code clocks data
'at 20MHz. Populate reg and data before calling this routine.

wSPI_Data
              andn      outa, SCSmask           'Begin the data transmission by enabling SPI mode - making line go low
              andn      outa, SCLKmask          'Turn the clock off, ensure it is low before placing data on the line
              mov       phsb, #0
              mov       phsb, data              'Add in the data, to be clocked out

              shl       phsb, #24
              mov       frqa, frq20             'Setup the writing frequency  08/15/2012 modified for 20MHz writes
              mov       phsa, phs20             'Setup the writing phase of data/clock
              mov       ctra, ctramode          'Turn on Counter A to start clocking
              rol       phsb, #1
              rol       phsb, #1
              rol       phsb, #1
              rol       phsb, #1
              rol       phsb, #1
              rol       phsb, #1
              rol       phsb, #1
              mov       ctra, #0                '8 bits sent - Turn off the clocking
wSPI_Data_ret ret                               'Return to the calling loop

rSPI_Data
              mov       frqa, frq10             '10MHz read frequency  | Read speed the same 'cause we can't shorten the
              mov       phsa, phs10             'start phs for clock   | 2-instructions per bit read code 08/15/2012
              nop
              mov       ctra, ctramode          'Start clocking
              test      MISOmask, ina wc        'Gather data, to be clocked in
              rcl       data, #1                'Data bit 0
              test      MISOmask, ina wc
              rcl       data, #1                'Data bit 1
              test      MISOmask, ina wc
              rcl       data, #1                'Data bit 2
              test      MISOmask, ina wc
              rcl       data, #1                'Data bit 3
              test      MISOmask, ina wc
              rcl       data, #1                'Data bit 4
              test      MISOmask, ina wc
              rcl       data, #1                'Data bit 5
              test      MISOmask, ina wc
              rcl       data, #1                'Data bit 6
              test      MISOmask, ina wc
              mov       ctra, #0                'Turn off the clocking immediately, otherwise might get odd behavior
              rcl       data, #1                'Data bit 7
rSPI_Data_ret ret                               'Return to the calling loop

'==========================================================================================================
'Defined data
_zero         long      0                       'Zero
_bytemask     long      $FF                     'Byte mask

'Pin/mask definitions are initianlized in SPIN and program/memory modified here before the COG is started
SCSmask       long      0-0                     'Chip/Slave select - active low, output
SCLKmask      long      0-0                     'SPI clock - output
MOSImask      long      0-0                     'Master out slave in - output
MISOmask      long      0-0                     'Master in slave out - input

'NOTE: Data that is initialized in SPIN and program/memory modified here before COG is started
ctramode      long      0-0                     'Counter A for the COG is used a serial clock line = SCLK
                                                'Counter A has phsa and frqa loaded appropriately to create a clock cycle
                                                'on the configured APIN

ctrbmode      long      0-0                     'Counter B for the COG is used as the data output = MOSI
                                                'Counter B isn't really used as a counter per se, but as a special register
                                                ' that can quickly output data onto an I/O pin in one instruction using the
                                                ' behavior of the phsb register where phsb[31] = APIN of the counter

frq20         long      $4000_0000              'Counter A & B's frqa register setting for reading data. 08/15/2012
                                                'This value is the system clock divided by 4 i.e. CLKFREQ/4 (80MHz clk = 20MHz)
phs20         long      $5000_0000              'Counter A & B's phsa register setting for reading data.   08/15/2012
                                                'This sets the relationship of the MOSI line to the clock line.  Note have not tried
                                                ' other values to determine if there is a "sweet spot" for phase... 08/15/2012
frq10         long      $2000_0000              'Need to keep 10MHz vaues also, because read is maxed at 10MHz
phs10         long      $6000_0000              '08/15/2012

'Data defined in constant section, but needed in the ASM for program operation


'==========================================================================================================
'Uninitialized data - temporary variables
t0            res 1     'temp0
t1            res 1     'temp1

'Parameters read from commands passed into the ASM routine
cmdAdrLen     res 1     'Combo of address, ocommand and data length into ASM
paramA        res 1     'Parameter A
paramB        res 1     'Parameter B
paramC        res 1     'Parameter C

deselect      res 1     'Flag indicating if CS should be deselected after the write
dataLen       res 1     'Data Length for packet
data          res 1     'Data read to/from
ram           res 1     'Ram address of Prop Hubram for reading/writing data from
ctr           res 1     'Counter of bytes for looping

              fit 496   'Ensure the ASM program and defined/res variables fit in a single COG.

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

