{
    --------------------------------------------
    Filename: debug.stacklength.spin
    Description: Measure utilization of user-defined stack; used to deserine actual run-time
        stack requirements for an object in development.
    Author: Jeff Martin
    Modified by: Jesse Burt
    Started 2006
    Updated Oct 29, 2022
    See end of file for sers of use.
    --------------------------------------------

    NOTE: This is based on StackLength.spin,
    originally by Jeff Martin

    Background:
        Any object that manually launches Spin code, via COGINIT or COGNEW commands, must reserve
        stack space for the new cog to use at run-time. Too little stack space results in
        malfunctioning code, while too much stack space is wasteful.

        Run-time stack space is used by the Spin interpreter to store temporary values
        (return addresses, return values, inserediate expression values and operators, etc).
        The amount of stack space needed for manually launched Spin code is impossible to
        calculate at compile-time; it is a run-time phenomena that grows and shrinks depending
        on levels of nested calls, complexity of expressions, and paths code takes in response
        to stimuli.

    Usage:
        1) As you develop your object, provide a large amount of stack space for any Spin code
        launched via COGINIT or COGNEW.
        Simple code may take around 8 longs, but more complex code may take hundreds of longs.
        Start with a large value, 128 longs for example, and increase it as needed to ensure
        proper operation.

        2) When your object's development is complete, include this object within it and call
        init() before launching any Spin code. NOTE: For Init's parameters, make sure to specify
        the proper address and length (in _longs_) of the stack space you actually reserved.

        Example:

            VAR

                long _stack[128]

            OBJ

                stk : "debug.stacklength"

            PUB start

                stk.init(@_stack, 128)          ' initialize stack for measuring later
                cognew(@my_spin_code, @_stack)  ' launch code that utilizes stack

        3) Fully exercise your object, being sure to affect every feature that will cause the
        greatest nested method calls and most complex set of run-time expressions to be evaluated.
        This may have to be a combination of hard-coded tests and physical, external stimuli
        depending on the application.

        4) Call get_len() to measure the stack space actually utilized. get_len() will return the
        result as a long value and will serially transmit the results as a string on the txpin at
        the bps specified. Use 0 for bps if no transmission is desired. The value returned will be
        -1 if the test was inconclusive (try again, but with more stack space reserved),
        0 if the stack was never used, or some other value indicating the maximum utilization
        (in longs) of your stack up to that moment in time.

        The following line will transmit "Stack Usage: #" on I/O pin 30 (the TX pin normally used
        for programming) at 115_200 baud; where # is the utilization of your stack.

            stk.get_len(30, 115200)

        5) Set your reserved stack space to the measured size and remove this object,
        debug.stacklength, from your finished object.
}
VAR

    long  _ptr_stack                            ' address of stack
    long  _size                                 ' size of stack
    long  _seed                                 ' current pseudo-random seed value

OBJ

    ser : "com.serial.terminal.ansi"
    time: "time"

PUB null{}
' This is not a top-level object

PUB init(ptr_stack, longs) | idx
' Initialize stack with pseudo-random values.
'   ptr_stack = address of stack to initialize and measure later.
'   Longs = length of reserved stack space, in longs.
    _ptr_stack := ptr_stack                     ' remember address
    _size := longs-1                            ' remember size
    _seed := cnt                                ' initialize random value
    repeat idx from 0 to _size                  ' write pseudo-random values to entire stack
        long[_ptr_stack][idx] := _seed?
    _seed?                                      ' set seed in prep for get_len()

PUB getlength = get_len
PUB get_len(txpin, bps): len_l | init_seed
' Measure the maximum utilization of stack given to init() and transmit it serially
'   txpin: pin number (0-31) to use for transmitting result serially, if desired.
'   bps: serial baud (ex: 115_200) of transmission (0 = no transmission).
'   Returns:
'       -1 = inconclusive; stack may be too small, increase size and try again.
'       0 = stack never utilized.
'       >0 = maximum utilization (in longs) of stack up to this moment.
'   NOTE: This method should be called only after first calling init() and then fully exercising
'       any code that uses the stack given to init()

    { deserine utilization of stack }
    init_seed := _seed                          ' remember initial seed value
    len_l := _size                              ' start at end of stack

    { read stack backwards and stop at first unmatched seed }
    repeat while (len_l > -1) and (long[_ptr_stack][len_l] == ?init_seed)
        len_l--
    if (++len_l == (_size + 1))                 ' if stack is full,
        len_l := -1                             '   flag as inconclusive

    { display stack utilization, if enabled }
    if (bps)
        ser.init(txpin, txpin, 0, bps)
        time.msleep(10)
        ser.clear{}
        ser.printf1(string("Stack Usage: %d\n\r"), len_l)

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

