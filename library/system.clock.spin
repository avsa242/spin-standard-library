{
    --------------------------------------------
    Filename: system.clock.spin
    Author: Jesse Burt
    Description: Runtime clock mode and frequency setting
    Copyright (c) 2022
    Started 2006 (estimated)
    Updated Oct 15, 2022
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This is based on Clock.spin,
        originally by Jeff Martin (further modified by Brett Weir)
}

CON

    WMIN = 381                                  ' WAITCNT-expression overhead minimum

    RCFAST_         = %0_0_0_00_000             ' Clock mode constants used for the
    RCSLOW_         = %0_0_0_00_001             ' set_mode() method.  Each constant name
    XINPUT_         = %0_0_1_00_010             ' represents the expression built of
    XTAL1_          = %0_0_1_01_010             ' similar names from clock setting
    XTAL2_          = %0_0_1_10_010             ' constants (without trailing "_" and
    XTAL3_          = %0_0_1_11_010             ' with "+" instead of middle "_").
    XINPUT_PLL1X    = %0_1_1_00_011             '
    XINPUT_PLL2X    = %0_1_1_00_100             ' For example, calling the method
    XINPUT_PLL4X    = %0_1_1_00_101             ' set_mode(XTAL1_PLL16X) changes the
    XINPUT_PLL8X    = %0_1_1_00_110             ' clock mode to the same state at
    XINPUT_PLL16X   = %0_1_1_00_111             ' run-time as the CON block statement
    XTAL1_PLL1X     = %0_1_1_01_011             ' _clkmode = xtal1 + pll16x does at
    XTAL1_PLL2X     = %0_1_1_01_100             ' compile-time.
    XTAL1_PLL4X     = %0_1_1_01_101             '
    XTAL1_PLL8X     = %0_1_1_01_110             ' Calling set_mode() with one of these
    XTAL1_PLL16X    = %0_1_1_01_111             ' constants is much faster than using
    XTAL2_PLL1X     = %0_1_1_10_011             ' the legacy SetClock method from
    XTAL2_PLL2X     = %0_1_1_10_100             ' previous versions of this Clock
    XTAL2_PLL4X     = %0_1_1_10_101             ' object.
    XTAL2_PLL8X     = %0_1_1_10_110             '
    XTAL2_PLL16X    = %0_1_1_10_111             ' The values of each are the actual
    XTAL3_PLL1X     = %0_1_1_11_011             ' CLK Register values that determine
    XTAL3_PLL2X     = %0_1_1_11_100             ' the System Clock mode and frequency
    XTAL3_PLL4X     = %0_1_1_11_101
    XTAL3_PLL8X     = %0_1_1_11_110
    XTAL3_PLL16X    = %0_1_1_11_111

PUB setclock = set_clk
PUB clk_set(xin_freq)
' Set the system clock input frequency, in Hz
'   xin_freq: frequency that external crystal/clock is driving into XIN pin
'       (Use 0 if no external clock source is connected.)
'    NOTE: The clk_mode() method automatically converts the given clock setting constant
'    expression to the corresponding CLK Register value (shown in the table), calculates
'    and updates the System Clock Frequency value (CLKFREQ) and performs the proper
'    stabilization procedure (10 ms delay), as needed, to ensure a stable clock when
'    switching from a non-feedback clock source to a feedback-based clock source (like
'    crystals and resonators). In addition to the required stabilization procedure noted above
'    an additional delay of approximately 75 µs occurs while the hardware switches the source.
    _xin_freq := xin_freq                       ' update _xin_freq
    _osc_delay[2] := _xin_freq / 100 #> WMIN    ' update _osc_delay for XINPUT 10 ms delay

PUB setmode = clk_mode
PUB clk_mode(mode): new
' Set system clock mode
'   Returns: new clock frequency
    if not (clkmode & $18) and (mode & $18)
        { If switching from a non-feedback to a feedback-based clock source,
            first rev up oscillator and possibly PLL circuits (using current clock source RCSLOW,
            RCFAST, XINPUT, or XINPUT + PLLxxx) and wait 10 ms to stabilize, accounting for
            worst-case IRC speed (or XIN + PLL speed) }
        clkset(clkmode & $07 | mode & $78, clkfreq)
        waitcnt(_osc_delay[clkmode & $7 <# 2] * |<(clkmode & $7 - 3 #> 0) + cnt)

    { Switch to new clock mode, indicate new frequency (ideal RCFAST, ideal RCSLOW, or }
    { XINFreq * PLL multiplier) and update return value (new frequency) }
    clkset(mode, newFreq := _ideal_rcf_freq[mode <# 2] * |<(mode & $7 - 3 #> 0))
DAT

    { ideal RCFAST frequency }
    _ideal_rcf_freq long    12_000_000

    { ideal RCSLOW frequency }
                    long    20_000

    { external source (XIN) frequency (updated by clk_set()); MUST be declared _here_ }
    _xin_freq       long    0

    { sys counter offset for 10 ms oscillator startup delay based on worst-case RCFAST frequency }
    _osc_delay      long    20_000_000 / 100

    { <same as above> for worst-case RCSLOW frequency; limited to WMIN to prevent freeze }
                    long    33_000 / 100 #> WMIN

    { <same as above> but based on external source (XIN) frequency; updated by init() }
                    long    0 {_xin_freq / 100 #> WMIN}

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

