''  WIZnet W5200 Driver Ver. 1.3
''
''  Original source: W5100_SPI_Driver.spin - Timothy D. Swieter (code.google.com/p/spinneret-web-server/source/browse/trunk/W5100_SPI_Driver.spin) 
''  W5200 changes/adaptations: Benjamin Yaroch (BY)
''  Additional revisions: Jim St. John (JS)
''
CON
  
  ' Command Definitions for ASM W5200 SPI Routine
    _reserved     = 0             'This is the default state - means ASM is waiting for command
    _readSPI      = 1 << 16       'High level access to reading from the W5200 via SPI
    _writeSPI     = 2 << 16       'High level access to writing to the W5200 via SPI
    _lastCmd      = 17 << 16      'Place holder for last command
    
    ' Driver Flag Definitions
    _Flag_ASMstarted = |< 1       'Flag to indicated asm routine is started succesfully

VAR

  long  cog                     'cog flag/id
  
DAT              

  'Command setup
        command         long    0               'stores command and arguments for the ASM driver
        lock            byte    255             'Mutex semaphore

PUB start(_scs, _sclk, _mosi, _miso) : okay
''  params:  the five pins required for SPI
''  return:  value of cog if started or zero if not started

  'Keeps from two cogs running
  stop

  'Initialize the I/O for writing the mask data to the memory area that will be copied into a COG.
  'This routine assumes SPI connection, SPI_EN should be tied high on W5200 and isn't controlled by this driver.
  SCSmask   := |< _scs
  SCLKmask  := |< _sclk
  MOSImask  := |< _mosi
  MISOmask  := |< _miso

  'Counter values setup before calling the ASM cog that will use them.
  'CounterX     mode  PLL         BPIN        APIN
  ctramode :=  %00100_000 << 23 +  0   << 9 +  _sclk
  ctrbmode :=  %00100_000 << 23 +  0   << 9 +  _mosi

  'Clear the command buffer - be sure no commands were set before initializing
  command := 0

  'Start a cog to execute the ASM routine
  okay := cog := cognew(@Entry, @command) + 1

PUB stop    

'' Stop the W5200 SPI Driver cog if one is running.
'' Only a single cog can be running at a time.

  if cog                                                'Is cog non-zero?
    cogstop(cog~ - 1)                                   'Yes, stop the cog and then make value zero
    longfill(@SCSmask, 0, 5)                            'Clear all masks
  
PUB mutexInit

'' Initialize mutex lock semaphore. Called once at driver initialization if application level locking is needed.
''
'' Returns -1 if no more locks available.

  lock := locknew
  return lock

PUB mutexLock

'' Waits until exclusive access to driver guaranteed.

  repeat until not lockset(lock)


PUB mutexRelease

'' Release mutex lock.

  lockclr(lock)

PUB mutexReturn

'' Returns mutex lock to semaphore pool.

  lockret(lock)

PUB readSPI(_register, _dataPtr, _Numbytes)

'' High level access to SPI routine for reading from the W5200.
'' Note for faster execution of functions code them in assembly routine like the examples of setting the MAC/IP addresses.
''
''  params:  _register is the 2 byte register address.  See the constant block with register definitions
''           _dataPtr is the place to return the byte(s) of data read from the W5200 (use the @ in front of the byte variable)
''           _Numbytes is the number of bytes to read

  'Send the command
  command := _readSPI + @_register
   
  'wait for the command to complete
  repeat while command
   
PUB writeSPI(_block, _dataPtr, _Numbytes)

'' High level access to SPI routine for writing to the W5200.
'' Note for faster execution of functions code them in assembly routine like the examples of setting the MAC/IP addresses.
''
''  params:  _block if true will wait for ASM routine to send before continuing
''           _register is the 2 byte register address. See the constant block with register definitions
''           _dataPtr is a pointer to the byte(s) of data to be written (use the @ in front of the byte variable)
''           _Numbytes is the number of bytes to write

  'Send the command
  command := _writeSPI + @_dataPtr
   
  'wait for the command to complete or just move on
    if _block
        repeat while command

   
DAT

''  Assembly language driver for W5200
 
        org
'-----------------------------------------------------------------------------------------------------
'Start of assembly routine
'-----------------------------------------------------------------------------------------------------
Entry
              'Upon starting the ASM cog the first thing to do is set the I/O states and directions.  SPIN already
              'setup the masks for each pin in the defined data section of the routine before starting the COG.

              'Set the initial state of the I/O, unless listed here, the output is initialized as off/low
              mov       outa,   SCSmask         'W5200 SPI slave select is initialized as high

                                                'Remaining outputs initialized as low including reset
                                                'NOTE: the W5200 is held in reset because the pin is low

              'Next set up the I/O with the masks in the direction register...
              '...all outputs pins are set up here because input is the default state
              mov       dira,   SCSmask         'Set to an output and clears cog dira register
              or        dira,   SCLKmask        'Set to an output
              or        dira,   MOSImask        'Set to an output
                                                'NOTE: MISOpin isn't here because it is an input
              'While the W5200 is coming out of reset initialize any COG counter values
              mov       frqb,   #0              'Counter B is used as a special register. Frq is set to 0 so there isn't accumulation.
              mov       ctrb,   ctrbmode        'This turns Counter B on. The main purpose is to have phsb[31] bit appear on the MOSI line.

'-----------------------------------------------------------------------------------------------------
'Main loop
'wait for a command to come in and then process it.
'-----------------------------------------------------------------------------------------------------
CmdWait
              rdlong    cmdAdrLen, par      wz  'Check for a command being present
        if_z  jmp       #CmdWait                'If there is no command, check again

              mov       t1, cmdAdrLen           'Take a copy of the command/address combo to work on
              rdlong    paramA, t1              'Get parameter A value
              add       t1, #4                  'Increment the address pointer by four bytes
              rdlong    paramB, t1              'Get parameter B value
              add       t1, #4                  'Increment the address pointer by four bytes
              rdlong    paramC, t1              'Get parameter C value
              add       t1, #4                  'Increment the address pointer by four bytes
              rdlong    paramD, t1              'Get parameter D value
              add       t1, #4                  'Increment the address pointer by four bytes
              rdlong    paramE, t1              'Get parameter E value

              mov       t0, cmdAdrLen           'Take a copy of the command/address combo to work on
              shr       t0, #16            wz   'Get the command
              cmp       t0, #(_lastCmd>>16)+1 wc 'Check for valid command
  if_z_or_nc  jmp       #:CmdExit               'Command is invalid so exit loop
              shl       t0, #1                  'Shift left, multiply by two
              add       t0, #:CmdTable-2        'add in the "call" address"
              jmp       t0                      'Jump to the command

              'The table of commands that can be called
:CmdTable     call      #rSPIcmd                'Read a byte from the W5200 - high level call
              jmp       #:CmdExit
              call      #wSPIcmd                'Write a byte to the W5200 - high level call
              jmp       #:CmdExit
              call      #LastCMD                'PlaceHolder for last command
              jmp       #:CmdExit
:CmdTableEnd

              'End of processing a command
:CmdExit      wrlong    _zero,  par             'Clear the command status
              jmp       #CmdWait                'Go back to waiting for a new command

'-----------------------------------------------------------------------------------------------------
'Command sub-routine to read a register from the W5200 - a high level call
'-----------------------------------------------------------------------------------------------------
rSPIcmd
              mov       reg,    paramA          'Move the register address into a variable for processing
              mov       ram,    ParamB          'Move the address of the returned byte into a variable for processing
              mov       ctr,    ParamC          'Set up a counter for number of bytes to process

              call      #ReadMulti              'Read the byte from the W5200

rSPIcmd_ret ret                                 'Command execution complete

'-----------------------------------------------------------------------------------------------------
'Command sub-routine to write a register in the W5200 - a high level call
'-----------------------------------------------------------------------------------------------------
wSPIcmd
              mov       ram,    paramA          'Move the data byte into a variable for processing
              mov       ctr,    ParamB          'Set up a counter for number of bytes to process

              call      #writeMulti             'Write the byte to the W5200

wSPIcmd_ret ret                                 'Command execution complete

'-----------------------------------------------------------------------------------------------------
'Command sub-routine holding place
'-----------------------------------------------------------------------------------------------------
LastCMD

LastCMD_ret ret                                 'Command execution complete

'=====================================================================================================

'-----------------------------------------------------------------------------------------------------
'Sub-routine to map write to SPI and to loop through bytes
' NOTE: RAM, Reg, and CTR setup must be done before calling this routine
'-----------------------------------------------------------------------------------------------------
WriteMulti
                 
:bytes        
              rdbyte    data,   ram             'Read the byte/octet from hubram           
              call      #wSPI_Data              'write one byte to W5200
              
              add       reg,    #1              'Increment the register address by one byte
              add       ram,    #1              'Increment the hubram address by one byte
              djnz      ctr,    #:bytes         'Check if there is another byte, if so, process it
              or        outa,scsmask            'De-assert CS  
WriteMulti_ret ret                              'Return to the calling code

'-----------------------------------------------------------------------------------------------------
'Sub-routine to map read to SPI and to loop through bytes
' NOTE: Reg, and CTR setup must be done before calling this routine
'-----------------------------------------------------------------------------------------------------

ReadMulti     mov       dataLen, ctr            '# of bytes to read in one burst
              call      #rSPI                   'send the burst read command to the W5200
:bytes         
              call      #rSPI_Data              'read one data byte from the W5200   1.15us
              and       data,   _bytemask       'Ensure there is only a byte   +20 clocks in this loop = 1.4us/byte
              wrbyte    data,   ram             'Write the byte to hubram
              add       reg,    #1              'Increment the register address by one byte
              add       ram,    #1              'Increment the hubram address by one byte
              djnz      ctr,    #:bytes         'Check if there is another if so, process it
              or        outa,scsmask            'finally de-assert CS 

ReadMulti_ret ret                               'Return to the calling code

wSPI
'High speed serial driver utilizing the counter modules. Counter A is the clock while Counter B is used as a special register
'to get the data on the output line in one clock cycle. This code is meant to run on 80MHz. processor and the code clocks data
'at 20MHz. Populate reg and data before calling this routine.

wSPI_Data
              andn      outa,   SCSmask         'Begin the data transmission by enabling SPI mode - making line go low
              andn      outa,   SCLKmask        'turn the clock off, ensure it is low before placing data on the line
              mov       phsb,   #0
              mov       phsb,   data            'Add in the data, to be clocked out

              shl       phsb,   #24
              mov       frqa,   frq20           'Setup the writing frequency  08/15/2012 modified for 20mhz writes
              mov       phsa,   phs20           'Setup the writing phase of data/clock
              mov       ctra,   ctramode        'Turn on Counter A to start clocking
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              mov       ctra,   #0              '8 bits sent - Turn off the clocking

'              or        phsb,   #1              'XXX   if LSB isn't set, mosi doesn't return to high idle
'              shl       phsb,   #31

wSPI_Data_ret ret                               'Return to the calling loop

'-----------------------------------------------------------------------------------------------------
'Sub-routine to read data from W5200 via SPI (Note that it must write in order to read)
'-----------------------------------------------------------------------------------------------------
rSPI
'High speed serial driver utilizing the counter modules. Counter A is the clock while Counter B is used as a special register
'to get the data on the output line in one clock cycle. This code is meant to run on 80MHz. processor and the code clocks data
'at 10MHz. 

              andn      outa,   SCLKmask        'turn the clock off, ensure it is low before placing data on the line

              mov       phsb,   reg             'Add register address (16 bits) to the packet
              shl       phsb,   #1              'Make room (1 bit) for the write operation (OpCode)
              or        phsb,   #0              'Add in a read operation in phsb (OpCode)    
              shl       phsb,   #15             'Make room (15 bits) for the and Data Length
              or        phsb,   dataLen         'Add Data Length - 32 bits added, buffer full!   

              andn      outa,   SCSmask         'Begin the data transmission by enabling SPI mode - making line go low

              mov       frqa,   frq20           'Setup the writing frequency  for 20mhz 08/15/2012
              mov       phsa,   phs20           'Setup the writing phase of data/clock for 20mhz 08/15/2012
              
              mov       ctra,   ctramode        'Turn on Counter A to start clocking                                                                                                                                                         
              rol       phsb,   #1              'NOTE: First bit is clocked just as soon as the clock turns on
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              rol       phsb,   #1
              mov       ctra,   #0              '32 bits sent - Turn off the clocking
rSPI_ret      ret

rSPI_Data
              mov       frqa, frq10             '10MHz read frequency  read speed the same 'cause we can't shorten the 
              mov       phsa, phs10             'start phs for clock   2-instructions per bit read code 08/15/2012
              nop
              mov       ctra, ctramode          'start clocking
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
_zero         long      0       'Zero
_bytemask     long      $FF     'Byte mask

'Pin/mask definitions are initianlized in SPIN and program/memory modified here before the COG is started
SCSmask       long      0-0     'W5200 SPI slave select - active low, output
SCLKmask      long      0-0     'W5200 SPI clock - output
MOSImask      long      0-0     'W5200 Master out slave in - output
MISOmask      long      0-0     'W5200 Master in slave out - input
RESETmask     long      0-0     'W5200 Reset - active low, output

'NOTE: Data that is initialized in SPIN and program/memory modified here before COG is started
ctramode      long      0-0     'Counter A for the COG is used a serial clock line = SCLK
                                'Counter A has phsa and frqa loaded appropriately to create a clock cycle
                                'on the configured APIN

ctrbmode      long      0-0     'Counter B for the COG is used as the data output = MOSI
                                'Counter B isn't really used as a counter per se, but as a special register
                                'that can quickly output data onto an I/O pin in one instruction using the
                                'behavior of the phsb register where phsb[31] = APIN of the counter

frq20         long      $4000_0000             'Counter A & B's frqa register setting for reading data from W5200. 08/15/2012
                                               'This value is the system clock divided by 4 i.e. CLKFREQ/4 (80MHz clk = 20MHz)
phs20         long      $5000_0000             'Counter A & B's phsa register setting for reading data from W5200.   08/15/2012
                                                'This sets the relationship of the MOSI line to the clock line.  Note have not tried
                                                'other values to determine if there is a "sweet sdpot" for phase... 08/15/2012
frq10         long      $2000_0000              'need to keep 10mhz vaues also, because read is maxed at 10mhz
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
paramD        res 1     'Parameter D
paramE        res 1     'Parameter E

reg           res 1     'Register address of W5200 for processing
dataLen       res 1     'Data Length for packet
data          res 1     'Data read to/from the W5200  
ram           res 1     'Ram address of Prop Hubram for reading/writing data from
ctr           res 1     'Counter of bytes for looping

              fit 496   'Ensure the ASM program and defined/res variables fit in a single COG.

DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}