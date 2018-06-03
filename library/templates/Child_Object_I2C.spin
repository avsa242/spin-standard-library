{
    --------------------------------------------
    Filename:
    Author:
    Copyright (c) 20__
    See end of file for terms of use.
    --------------------------------------------
}

CON

  SLAVE_ADDR        = YOUR_7BIT_DEVICE_SLAVE_ADDR << 1  'Replace with 7bit address, or 8bit and remove the left shift
  SLAVE_ADDR_W      = SLAVE_ADDR
  SLAVE_ADDR_R      = SLAVE_ADDR|1
  
  SCL               = 28
  SDA               = 29
  HZ                = 400_000
  I2C_MAX_BUS_FREQ  = 1_000_000

VAR


OBJ

  i2c : "jm_i2c_fast"

PUB null
''This is not a top-level object

PUB Start: okay                                         'Default to "standard" Propeller I2C pins and 400kHz

  okay := Startx (SCL, SDA, HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ)

  if lookdown(SCL_PIN: 0..31)                           'Validate pins
    if lookdown(SDA_PIN: 0..31)
      if SCL_PIN <> SDA_PIN
        if I2C_HZ =< I2C_MAX_BUS_FREQ
          return i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)
        else
          return FALSE
      else
        return FALSE
    else
      return FALSE
  else
    return FALSE

PUB readOne: readbyte

  readX (@readbyte, 1)

PUB readX(ptr_buff, num_bytes)

  i2c.start
  i2c.write (SLAVE_ADDR_R)
  i2c.pread (ptr_buff, num_bytes, TRUE)
  i2c.stop

PUB writeOne(data)

  WriteX (data, 1)

PUB WriteX(ptr_buff, num_bytes)

  i2c.start
  i2c.write (SLAVE_ADDR_W)
  i2c.pwrite (ptr_buff, num_bytes)
  i2c.stop

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
