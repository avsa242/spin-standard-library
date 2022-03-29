# sensor.temp_rh

----------------

API for temperature and/or humidity device drivers

Object filename description:

`sensor.type.model.spin`

_type_ is one of: humidity, temp_rh, temperature, thermal-array, thermocouple

_model_ indicates the manufacturer's model number of the sensor





## Methods (standard)

| Method             | Description                                          | Param    | Returns                                        |
| ------------------ | ---------------------------------------------------- | -------- | ---------------------------------------------- |
| `LastRH()`         | Previous Relative Humidity measurement               | n/a      | integer: RH in hundredths of a percent         |
| `LastTemp()`       | Previous Temperature measurement                     | n/a      | integer: temperature in hundredths of a degree |
| `RH()`             | Current relative humidity                            | n/a      | integer: RH in hundredths of a percent         |
| `Temperature()`    | Current temperature                                  | n/a      | integer: temperature in hundredths of a degree |
| `TempScale(scale)` | Set temperature scale used by `Temperature()` method | constant | Current setting                                |



Other methods vary by specific sensor type and model.



## Built-in symbols

```spin
CON

    { Temperature scales }
    C               = 0
    F               = 1
    K               = 2

    { I2C-specific }
    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

```



## Global variables

```spin
VAR

    long _last_temp    ' Last temperature measurement
    long _last_rh      ' Last relative humidity measurement

    byte _temp_scale   ' Current temperature scale

```



## Structure

```spin
sensor.type.model.spin - driver object
|-- #include: sensor.temp_rh.common.spinh - provides standard API
|-- OBJ: HW-specific constants (core.con.model.spin)
|-- OBJ: Low-level communications engine (I2C, SPI, OneWire, etc)
|-- OBJ: Time delay methods (time.spin)


```
