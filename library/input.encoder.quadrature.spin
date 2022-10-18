{
    --------------------------------------------
    Filename: input.encoder.quadrature.spin
    Author: Jeff Martin
    Modified by: Jesse Burt
    Description: Quadrature/grey code encoder
        driver, 1..16
    Copyright (c) 2005
    Started 2005
    Updated Oct 18, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Quadrature Encoder.spin,
        originally by Jeff Martin.
}

VAR

    long _ptr_posbuff                           ' pointer to pos buffer
    byte _cog                                   ' cog ID of encoder engine
    byte _nr_delta                              ' # enc. requiring delta vals

PUB start = startx
PUB startx(ENC_BASEPIN, nr_enc, nr_delta, ptr_posbuff): status
' Start using custom I/O basepin and parameters
'   ENC_BASEPIN: 0..31
'       1st pin of encoder 1 (2nd pin of encoder 1 is ENC_BASEPIN+1)
'       Additional pins for other encoders are contiguous starting with
'           ENC_BASEPIN+2
'   nr_enc: Number of encoders (1..16) to monitor.
'   nr_delta: Number of encoders (0..16) needing delta value support
'       (can be less than nr_enc).
'   ptr_posbuff: pointer to buffer of longs where each encoder's position
'       (and deta position, if any) is to be stored.
'   Returns: cog ID+1 if started, FALSE otherwise
    _pin := ENC_BASEPIN
    _nr_enc := nr_enc
    _nr_delta := nr_delta
    _ptr_posbuff := ptr_posbuff
    stop{}
    longfill(_ptr_posbuff, 0, _nr_enc+_nr_delta)
    status := (_cog := cognew(@entry, _ptr_posbuff) + 1)

PUB stop{}
' Stop the encoder-reading cog, if there is one.
    if (_cog > 0)
        cogstop(_cog-1)

PUB readdelta = pos_delta
PUB pos_delta(enc_id): deltapos
' Read delta position (relative position value since last time read) of enc_id.
    deltapos := 0 + -(enc_id < _nr_delta) * -long[_ptr_posbuff][_nr_enc+enc_id] {
}   + (long[_ptr_posbuff][_nr_enc+enc_id] := long[_ptr_posbuff][enc_id])

CON

    SELFMOD = 0-0                               ' symbol used where code will  |
                                                '   be modified at runtime
DAT
' Read all encoders and update encoder positions in main memory.
' See "Theory of Operation," below, for operational explanation.
                org     0

entry           mov     ptr_ipos,   #intpos     ' Clear encoder position values
                movd    :iclear,    ptr_ipos    '  set starting internal pointer
                mov     idx,        _nr_enc     '  for all encoders...
:iclear         mov     SELFMOD,    #0          '  clear internal memory
                add     ptr_ipos,   #1          '  increment pointer
                movd    :iclear,    ptr_ipos
                djnz    idx,        #:iclear    '  loop for each encoder

                mov     st2,        ina         ' sample encoder pins (initial)
                shr     st2,        _pin
:sample         mov     ptr_ipos,   #intpos     ' Reset encoder pos. pointer
                movd    :ipos+0,    ptr_ipos
                movd    :ipos+1,    ptr_ipos
                mov     mposaddr,   par
                mov     st1,        st2         ' Calc 2-bit signed offsets (st1 = B1:A1)
                mov     t1,         st2         '                           t1  = B1:A1
                shl     t1,         #1          '                           t1  = A1:x
:pinsrc         mov     st2,        ina         ' Sample encoders         (st2 = B2:A2 left shifted by first encoder offset)
                shr     st2,        _pin        ' Adj for first encoder   (st2 = B2:A2)
                xor     st1,        st2         '          st1  =              B1^B2:A1^A2
                xor     t1,         st2         '          t1   =              A1^B2:x
                and     t1,         bmask       '          t1   =              A1^B2:0
                or      t1,         amask       '          t1   =              A1^B2:1
                mov     t2,         st1         '          t2   =              B1^B2:A1^A2
                and     t2,         amask       '          t2   =                  0:A1^A2
                and     st1,        bmask       '          st1  =              B1^B2:0
                shr     st1,        #1          '          st1  =                  0:B1^B2
                xor     t2,         st1         '          t2   =                  0:A1^A2^B1^B2
                mov     st1,        t2          '          st1  =                  0:A1^B2^B1^A2
                shl     st1,        #1          '          st1  =        A1^B2^B1^A2:0
                or      st1,        t2          '          st1  =        A1^B2^B1^A2:A1^B2^B1^A2
                and     st1,        t1          '          st1  =  A1^B2^B1^A2&A1^B2:A1^B2^B1^A2
                mov     idx,        _nr_enc     ' For all encoders...
:updatepos      ror     st1,        #2          ' Rotate current bit pair into 31:30
                mov     diff,       st1         ' Convert 2-bit signed to 32-bit signed diff
                sar     diff,       #30
:ipos           add     SELFMOD,    diff        ' Add to encoder position value
                wrlong  SELFMOD,    mposaddr    ' Write new pos. to memory
                add     ptr_ipos,   #1          ' Increment encoder pos. ptr
                movd    :ipos+0,    ptr_ipos
                movd    :ipos+1,    ptr_ipos
                add     mposaddr,   #4
:next_enc       djnz    idx,        #:updatepos ' Loop for each encoder
                jmp     #:sample                ' Loop forever

'Define Encoder Reading Cog's constants/variables

amask           long    $55555555               ' A bit mask
bmask           long    $AAAAAAAA               ' B bit mask

_pin            long    0                       ' First pin connected to first encoder
_nr_enc         long    0                       ' Total number of encoders

idx             res     1                       ' Encoder index
st1             res     1                       ' Previous state
st2             res     1                       ' Current state
t1              res     1                       ' Temp 1
t2              res     1                       ' Temp 2
diff            res     1                       ' difference, ie: -1, 0 or +1
ptr_ipos        res     1                       ' ptr to encoder pos. ctr (cog)
mposaddr        res     1                       ' ptr to encoder pos. ctr (hub)
intpos          res     16                      ' encoder pos. ctr buffer (cog)


' Cycle Calculation Equation:
'   Terms:
'       SU = :sample to :update
'       UTI = :update_ptr_posbuff through :ipos
'       MMW = Main Memory Write
'       AMMN = After MMW to :next_enc
'       NU = :next to :update_ptr_posbuff
'       SH = Resync to Hub
'       NS = :next to :sample
'
'   Equation:
'       SU + UTI + MMW + (AMMN + NU + UTI + SH + MMW) * (_nr_enc-1) + AMMN + NS
'           = 92 + 16  +  8  + ( 16  + 4  + 16  + 6  +  8 ) * (_nr_enc-1) +  16  + 12
'           = 144 + 50 * (_nr_enc-1)

{

# FUNCTIONAL DESCRIPTION
------------------------

Reads 1 to 16 two-bit gray-code quadrature encoders and provides 32-bit absolute position values for each and optionally provides delta position support
(value since last read) for up to 16 encoders.  See "Required Cycles and Maximum RPM" below for speed boundary calculations.

Connect each encoder to two contiguous I/O pins (multiple encoders must be connected to a contiguous block of pins).  If delta position support is
required, those encoders must be at the start of the group, followed by any encoders not requiring delta position support.

To use this object:
  1) Create a position buffer (array of longs).  The position buffer MUST contain nr_enc + nr_delta longs.  The first nr_enc longs of the position buffer will always contain read-only, absolute positions for the respective encoders.  The remaining nr_delta longs of the position buffer will be "last absolute read" storage for providing delta position support (if used) and should be ignored (use ReadDelta() method instead).
  2) Call Start() passing in the starting pin number, number of encoders, number needing delta support and the address of the position buffer.  Start() will configure and start an encoder reader in a separate cog; which runs continuously until Stop is called.
  3) Read position buffer (first nr_enc values) to obtain an absolute 32-bit position value for each encoder.  Each long (32-bit position counter) within the position buffer is updated automatically by the encoder reader cog.
  4) For any encoders requiring delta position support, call ReadDelta(); you must have first sized the position buffer and configured Start() appropriately for this feature.

Example Code:

OBJ
  Encoder : "input.encoder.quadrature"

VAR
  long _ptr_posbuff[3]                            'Create buffer for two encoders (plus room for delta position support of 1st encoder)

PUB Init
  Encoder.Start(8, 2, 1, @_ptr_posbuff)           'Start continuous two-encoder reader (encoders connected to pins 8 - 11)

PUB Main
  repeat
    <read _ptr_posbuff[0] or Pos[1] here>         'Read each encoder's absolute position
    <variable> := Encoder.ReadDelta(0)   'Read 1st encoder's delta position (value since last read)

# REQUIRED CYCLES AND MAXIMUM RPM:
----------------------------------

Encoder Reading Cog requires 144 + 50*(_nr_enc-1) cycles per sample.  That is: 144 for 1 encoder, 194 for 2 encoders, 894 for 16 encoders.

Conservative Maximum RPM of Highest Resolution Encoder = XINFreq * PLLMultiplier / EncReaderCogCycles / 2 / MaxEncPulsesPerRevolution * 60

Example 1: Using a 4 MHz crystal, 8x internal multiplier, 16 encoders where the highest resolution encoders is 1024 pulses per revolution:
           Max RPM = 4,000,000 * 8 / 894 / 2 / 1024 * 60 = 1,048 RPM

Example 2: Using same example above, but with only 2 encoders of 128 pulses per revolution:
           Max RPM = 4,000,000 * 8 / 194 / 2 / 128 * 60 = 38,659 RPM

# THEORY OF OPERATION:
----------------------

Column 1 of the following truth table illustrates 2-bit, gray code quadrature encoder output (encoder pins A and B) and their possible transitions (assuming we're sampling fast enough).  A1 is the previous value of pin A, A2 is the current value of pin A, etc.  '->' means 'transition to'.  The four double-step  transition possibilities are not shown here because we won't ever see them if we're sampling fast enough and, secondly, it is impossible to tell direction if a transition is missed anyway.

Column 2 shows each of the 2-bit results of cross XOR'ing the bits in the previous and current values.  Because of the encoder's gray code output, when there is an actual transition, A1^B2 (msb of column 2) yields the direction (0 = clockwise, 1 = counter-clockwise).  When A1^B2 is paired with B1^A2, the resulting 2-bit value gives more transition detail (00 or 11 if no transition, 01 if clockwise, 10 if counter-clockwise).

Columns 3 and 4 show the results of further XORs and one AND operation.  The result is a convenient set of 2-bit signed values: 0 if no transition, +1 if clockwise, and -1 and if counter-clockwise.

This object's Update routine performs the sampling (column 1) and logical operations (colum 3) of up to 16 2-bit pairs in one operation, then adds the resulting offset (-1, 0 or +1) to each position counter, iteratively.

      1      |      2      |          3           |       4        |     5
-------------|-------------|----------------------|----------------|-----------
             |             | A1^B2^B1^A2&(A1^B2): |   2-bit sign   |
B1A1 -> B2A2 | A1^B2:B1^A2 |     A1^B2^B1^A2      | extended value | Diagnosis
-------------|-------------|----------------------|----------------|-----------
 00  ->  00  |     00      |          00          |      +0        |    No
 01  ->  01  |     11      |          00          |      +0        | Movement
 11  ->  11  |     00      |          00          |      +0        |
 10  ->  10  |     11      |          00          |      +0        |
-------------|-------------|----------------------|----------------|-----------
 00  ->  01  |     01      |          01          |      +1        | Clockwise
 01  ->  11  |     01      |          01          |      +1        |
 11  ->  10  |     01      |          01          |      +1        |
 10  ->  00  |     01      |          01          |      +1        |
-------------|-------------|----------------------|----------------|-----------
 00  ->  10  |     10      |          11          |      -1        | Counter-
 10  ->  11  |     10      |          11          |      -1        | Clockwise
 11  ->  01  |     10      |          11          |      -1        |
 01  ->  00  |     10      |          11          |      -1        |
}

DAT
{
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

