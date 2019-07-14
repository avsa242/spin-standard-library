{
    --------------------------------------------
    Filename:
    Author:
    Copyright (c) 20__
    See end of file for terms of use.
    --------------------------------------------
}

CON

  _clkmode = cfg#_clkmode
  _xinfreq = cfg#_xinfreq

OBJ

  cfg   : "core.con.boardcfg.flip"
  ser   : "com.serial.terminal"
  int   : "string.integer"
  time  : "time"
  lux   : "sensor.lux.tsl2591"
  debug : "debug"

VAR

  long _lux_cog
  byte _passfail_col

PUB Main

  _passfail_col := 37
  Setup
  waitkey

  Test_DeviceID
  Test_PackageID
  Test_EnableInts
  Test_EnablePersist
  Test_Enabled
  Test_SetGain
  Test_SetIntThresh
  Test_SetPersistThresh
  Test_SetPersistence
  Test_SetIntegrationTime
  Test_IntTriggered
  Test_IsPowered
  Test_MeasurementComplete
  Test_SleepAfterInt
  Test_Luminosity
  debug.here (cfg#LED1)
  
PUB Test_DeviceID | tmp

  tmp := lux.DeviceID
  ser.Str (string("DeviceID:"))
  ser.PositionX (_passfail_col)
  if tmp == $50
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

PUB Test_EnableInts | tmp

  lux.EnableInts (FALSE)
  tmp := lux.IntsEnabled
  ser.Str (string("EnableInts(FALSE):"))
  ser.PositionX (_passfail_col)
  if tmp == FALSE
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED"))
    ser.Hex (tmp, 8)
    ser.NewLine

  lux.EnableInts (TRUE)
  tmp := lux.IntsEnabled
  ser.Str (string("EnableInts(TRUE):"))
  ser.PositionX (_passfail_col)
  if tmp == TRUE
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED: "))
    ser.Hex (tmp, 8)
    ser.NewLine

PUB Test_EnablePersist | tmp

  lux.EnablePersist (FALSE)
  tmp := lux.PersistEnabled
  ser.Str (string("EnablePersist(FALSE):"))
  ser.PositionX (_passfail_col)
  if tmp == FALSE
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED"))
    ser.Hex (tmp, 8)
    ser.NewLine

  lux.EnablePersist (TRUE)
  tmp := lux.PersistEnabled
  ser.Str (string("EnablePersist(TRUE):"))
  ser.PositionX (_passfail_col)
  if tmp == TRUE
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED: "))
    ser.Hex (tmp, 8)
    ser.NewLine

PUB Test_Enabled | tmp

  lux.EnableSensor (FALSE)
  tmp := lux.SensorEnabled
  ser.Str (string("EnableSensor(FALSE):"))
  ser.PositionX (_passfail_col)
  if tmp == FALSE
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED"))
    ser.Hex (tmp, 8)
    ser.NewLine

  lux.EnableSensor (TRUE)
  tmp := lux.SensorEnabled
  ser.Str (string("EnableSensor(TRUE):"))
  ser.PositionX (_passfail_col)
  if tmp == TRUE
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED: "))
    ser.Hex (tmp, 8)
    ser.NewLine

PUB Test_IntTriggered | i, r 'XXX - More comprehensive?

  lux.EnableInts (FALSE)
  lux.ClearAllInts

  ser.Str (string("ClearAllInts:"))

  ser.PositionX (_passfail_col)
  if lux.IntTriggered
    ser.Str (string("FAILED", ser#NL))
  else
    ser.Str (string("PASSED", ser#NL))

  lux.ForceInt
  ser.Str (string("ForceInt:"))

  ser.PositionX (_passfail_col)
  if lux.IntTriggered
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

PUB Test_IsPowered

  lux.PowerOn (TRUE)
  ser.Str (string("PowerOn(TRUE):"))
  ser.PositionX (_passfail_col)
  if lux.IsPowered
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

  lux.PowerOn (FALSE)
  ser.Str (string("PowerOn(FALSE):"))
  ser.PositionX (_passfail_col)
  if lux.IsPowered
    ser.Str (string("FAILED", ser#NL))
  else
    ser.Str (string("PASSED", ser#NL))

PUB Test_Luminosity | tmp

  lux.Reset
  lux.PowerOn (TRUE)
  repeat until lux.IsPowered
  lux.EnableSensor (TRUE)
  repeat until lux.SensorEnabled
  lux.SetIntegrationTime (200)
  lux.SetGain (1)
  ser.Str (string("Luminosity(0):"))
  tmp := 0
  repeat 50
    ser.PositionX (_passfail_col)
    repeat until lux.MeasurementComplete
    tmp := lux.Luminosity (0)
    ser.Hex (tmp, 8)
    time.MSleep (100)
  ser.NewLine
  
  ser.Str (string("Luminosity(1):"))
  repeat 50
    ser.PositionX (_passfail_col)
    repeat until lux.MeasurementComplete
    tmp := lux.Luminosity (1)
    ser.Hex (tmp, 8)
    time.MSleep (100)
  ser.NewLine

  ser.Str (string("Luminosity(2):"))
  repeat 50
    ser.PositionX (_passfail_col)
    repeat until lux.MeasurementComplete
    tmp := lux.Luminosity (2)
    ser.Hex (tmp, 8)
    time.MSleep (100)
  ser.NewLine
      
PUB Test_MeasurementComplete

  lux.Reset
  lux.PowerOn (FALSE)
  lux.EnableSensor (FALSE)
  time.Sleep (1)
  ser.Str (string("MeasurementComplete (sensor off):"))
  ser.PositionX (_passfail_col)
  if lux.MeasurementComplete
    ser.Str (string("FAILED", ser#NL))
  else
    ser.Str (string("PASSED", ser#NL))

  lux.Reset
  lux.PowerOn (TRUE)
  lux.EnableSensor (TRUE)
  ser.Str (string("MeasurementComplete (sensor on):"))
  time.Sleep (1)
  ser.PositionX (_passfail_col)
  if lux.MeasurementComplete
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

PUB Test_PackageID | tmp

  tmp := lux.PackageID
  ser.Str (string("PackageID:"))
  ser.PositionX (_passfail_col)
  if tmp == $00
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

PUB Test_SetGain | i, glut, r, retval 'XXX Test invalid value also?

  repeat i from 0 to 3
    ser.Str (string("SetGain("))
    glut := lookupz(i: 1, 25, 428, 9876)
    ser.Dec (glut)
    ser.Str (string("): ["))
    ser.Hex (lux.SetGain (glut), 8)
    ser.Str (string("]: "))
    r := lux.Gain
    ser.PositionX (_passfail_col)
    if r == glut
      ser.Str (string("PASSED", ser#NL))
    else
      ser.Str (string("FAILED"))
      ser.Str (string(", read back "))
      ser.Dec (r)
      ser.NewLine

PUB Test_SetIntThresh | lt, ht, thr

  ser.Str (string("SetIntThresh(0, 0):"))
  lux.SetInterruptThresh (0, 0)
  thr := lux.GetIntThresh
  lt := thr & $FFFF
  ht := (thr >> 16) & $FFFF
  ser.PositionX (_passfail_col)
  if lt == 0 and ht == 0
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

  ser.Str (string("SetIntThresh(1234, 5678):"))
  lux.SetInterruptThresh ($1234, $5678)
  thr := lux.GetIntThresh
  lt := thr & $FFFF
  ht := (thr >> 16) & $FFFF
  ser.PositionX (_passfail_col)
  if lt == $1234 and ht == $5678
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

PUB Test_SetIntegrationTime | i, r

  repeat i from 100 to 600 step 100
    ser.Str (string("SetIntegrationTime("))
    ser.Dec (i)
    ser.Str (string("): ["))
    ser.hex ( lux.SetIntegrationTime (i), 8 )
    ser.Str (string("]: "))
    time.MSleep (1)
    r := lux.IntegrationTime
    ser.PositionX (_passfail_col)
    if r == i
      ser.Str (string("PASSED", ser#NL))
    else
      ser.Str (string("FAILED: "))
      ser.Dec (r)
      ser.NewLine

PUB Test_SetPersistThresh | lt, ht, thr

  ser.Str (string("SetPersistThresh(0, 0):"))
  lux.SetPersistThresh (0, 0)
  thr := lux.PersistThresh
  lt := thr & $FFFF
  ht := (thr >> 16) & $FFFF
  ser.PositionX (_passfail_col)
  if lt == 0 and ht == 0
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

  ser.Str (string("SetPersistThresh(1234, 5678):"))
  lux.SetPersistThresh ($1234, $5678)
  thr := lux.PersistThresh
  lt := thr & $FFFF
  ht := (thr >> 16) & $FFFF
  ser.PositionX (_passfail_col)
  if lt == $1234 and ht == $5678
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

PUB Test_SetPersistence | i, pcy, r

  repeat i from 0 to 15
    pcy := lookupz(i: 0, 1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60)
    ser.Str (string("SetPersistence("))
    ser.Dec (pcy)
    ser.Str (string("): "))
    lux.SetPersistence (pcy)
    time.MSleep (1)
    r := lux.PersistCycles
    ser.PositionX (_passfail_col)
    if r == pcy
      ser.Str (string("PASSED", ser#NL))
    else
      ser.Str (string("FAILED", ser#NL))

PUB Test_SleepAfterInt | tmp

  lux.SleepAfterInt (FALSE)
  tmp := lux.SleepingAfterInt
  ser.Str (string("SleepAfterInt(FALSE):"))
  ser.PositionX (_passfail_col)
  if tmp == FALSE
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

  lux.SleepAfterInt (TRUE)
  tmp := lux.SleepingAfterInt
  ser.Str (string("SleepAfterInt(TRUE):"))
  ser.PositionX (_passfail_col)
  if tmp == TRUE
    ser.Str (string("PASSED", ser#NL))
  else
    ser.Str (string("FAILED", ser#NL))

PUB Setup

  repeat until ser.Start (115_200)
  ser.Clear
  ser.Str (string("Serial console started", ser#NL))
  ser.Str (string("TSL2591 test harness", ser#NL))

  if _lux_cog := lux.Start-1
    ser.Str (string("tsl2591 object started", ser#NL))
  else
    ser.Str (string("unable to start tsl2591 object", ser#NL))
    time.MSleep (500)
    lux.Stop
    ser.Stop
    debug.LEDFast (cfg#LED1)

PUB waitkey

  ser.Str (string("Press any key", ser#NL))
  ser.CharIn

PUB waitmsg(msg_string)

  ser.Str (msg_string)
  ser.CharIn

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
