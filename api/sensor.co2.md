# sensor.co2
----------------

API for Carbon Dioxide sensing device drivers

Object filename description:

`sensor.co2.model.spin`

_model_ indicates the manufacturer's model number of the sensor

## Base Methods

These are methods that are common to _all_ of the above types of drivers

| Method          | Description                                      | Param     | Returns        |
| --------------- | ------------------------------------------------ | --------- | -------------- |
| `startx()`      | Start driver using explicitly defined settings   | Notes 1-3 | cog id+1       |
| `stop()`        | Stop the driver                                  | n/a       | n/a            |
| `defaults()`    | Set sensor factory default settings              | n/a       | n/a            |

Notes:

1. For I2C-connected sensors:
	* `startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS): status`
	* If no particular interface preprocessor symbol is defined when building, the driver will
default to the PASM-based I2C engine.
	* For some devices, a `MODEL_I2C_BC` variant exists, which directs the driver to use a
bytecode-based engine that while much slower, doesn't use another cog.
	* Not all devices support alternate I2C addresses.

2. For all variants: `startx()` returns the launched cog number+1 of com engine used on success.

3. For all variants: There may be a `RST_PIN` parameter, for specifying an optional reset pin
(device-dependent). The pin is only validated in the `reset()` method, and is ignored if set
outside the allowable range.

4. `startx()` returns `FALSE` (0) if the driver fails to start, for these possible reasons:
	* No more cogs available
	* One or more specified I/O pins are outside allowed range
	* Bus frequency is outside allowed range
	* If supported by the device, `dev_id()` didn't return the expected value

5. `defaults()` may simply call `reset()`, if sensible, as opposed to calling several other driver
methods, in order to reduce memory usage.

6. Drivers may have one or more `preset_()` methods, that establish a set of pre-set settings.

7. `stop()` performs the following tasks:
	* Stop any extra cogs that were started (if applicable)
	* Clear all global variable space used to 0

## Methods

| Method          | Description                                      |
| --------------- | ------------------------------------------------ |
| `adc2co2()`     | Convert ADC word to CO2 data                     |
| `co2_data()`    | CO2 data ADC word                                |
| `co2_ppm()`     | CO2 concentration                                |


`adc2co2(co2_wd)`
-----------------
__Convert ADC word to CO2 data__
* Parameters:
	* `co2_wd`: ADC word representing CO2 measurement
* Returns:
	* CO2 concentration in 0.1 parts per million (e.g., `12004` is 1200.4ppm)


`co2_data()`
------------
__CO2 data ADC word__
* Parameters: none
* Returns:
	* ADC word representing CO2 measurement


`co2_ppm()`
-----------
__CO2 concentration__
* Parameters: none
* Returns:
	* CO2 concentration in 0.1 parts per million (e.g., `12004` is 1200.4ppm)


Notes:

1. Some devices also contain temperature and/or relative humidity sensors. These follow the [sensor.temp_rh API](https://github.com/avsa242/spin-standard-library/blob/testing/api/sensor.temp_rh.md)


## Build examples

Notes:

1. Some devices require build-time features to be enabled in order to function properly. e.g., the SCD30 requires a behavioral quirk be enabled in the I2C engine, with `-DQUIRK_SCD30`

Build the SCD30 demo for P1, bytecode output, using the PASM-based I2C engine:
`flexspin --interp=rom -L$HOME/spin-standard-library/library -DQUIRK_SCD30 -DSCD30_I2C SCD30-Demo.spin`

or `flexspin --interp=rom -L$HOME/spin-standard-library/library -DQUIRK_SCD30 SCD30-Demo.spin`

The same, but using the bytecode-based I2C engine:
`flexspin --interp=rom -L$HOME/spin-standard-library/library -DQUIRK_SCD30 -DSCD30_I2C_BC SCD30-Demo.spin`

The same, but build using P1 native code output:

`flexspin -L$HOME/spin-standard-library/library -DQUIRK_SCD30 SCD30-Demo.spin`

(NOTE: An application may build successfully when using native code output and a bytecode-based
engine, but may not function properly, as bus timings aren't accounted for in bytecode-based
engines, so may run too fast)

