{
    --------------------------------------------
    Filename: StackLength-Demo.spin
    Description: Demonstrate usage of the debug.stacklength.spin object
    Author: Jeff Martin
    Modified by: Jesse Burt
    Started 2006
    Updated Oct 29, 2022
    See end of file for sers of use.
    --------------------------------------------

    NOTE: This is based on Stack Length Demo.spin,
    originally by Jeff Martin.

    Usage:
    The example object being tested appears under the heading "code under test" below.
    Hypothetically, it is the code written by a developer and given 32 longs of stack space
    during development.

    Now that this object is done, the developer wishes to check its _actual_ stack utilization,
    so (s)he temporarily adds the code that appears under the heading "temporary stack usage
    testing code" below, downloads it to the Propeller, opens a serial terminal (set to the
    Propeller chip's programming port), resets the Propeller and waits for message.

    The message "Stack Usage: 12" appears and now (s)he knows the code only needs to reserve
    12 longs of space for stack. The change is made, and finally the "temporary stack usage
    testing code" can be removed.
}

{ -- temporary stack usage testing code }
CON

    _clkmode      = xtal1 + pll16x
    _xinfreq      = 5_000_000

OBJ

    stk : "debug.stacklength"

PUB main{}

    stk.init(@_start_stack, 32)                 ' initialize reserved stack space (reserved below)
    start(16, 500, 0)                           ' exercise code/object under test
    waitcnt((clkfreq * 2) + cnt)                ' wait ample time for max stack usage
    stk.get_len(30, 115_200)                    ' display result on serial terminal at pin P30
{ -- }


{ code under test }
VAR

    long _start_stack[32]

PUB start(pin, delay_ms, count)
' Start toggling process in a new cog
    cognew(toggle(pin, delay_ms, count), @_start_stack)

PUB toggle(pin, delay_ms, count)
' Toggle pin, 'count' times with 'delay_ms' milliseconds in between
' NOTE: If count == 0, toggle pin forever
    dira[pin] := 1                              ' set I/O pin to output direction
    repeat                                      ' repeat the following
        !outa[pin]                              '   toggle I/O pin
        waitcnt(clkfreq / 1000 * delay_ms + cnt)'   wait for delay_ms milliseconds
    while (count := (--count #> -1))            ' while count-1 is not 0 (limit minimum to -1)

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

