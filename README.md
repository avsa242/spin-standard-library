# The Spin Standard Library

The Spin Standard Library is designed to be a general-purpose library with a wide scope of functionality, covering low-level I/O, text processing, device drivers and more for the Parallax Propeller (P8X32A) MCU. It contains a curated collection of Spin objects that have been organized and formatted with a focus on consistency and code reusability.

## API

An ongoing effort is being made to standardize the API for the various device drivers and other objects contained in the library. Manufacturers may not all utilize the same design methodologies and the interface they expose to developers may differ, but this library aims to distill all of it to a common programming interface. Essentially, once you've learned how to operate a particular device driver, all others of the same category would require minimal or no extra effort to learn.

Decriptions of the programming interface for the various classes of library can be found in the [API](api) subdirectory.
At the time of this writing, they are:
* [display](api/display.md): Displays, e.g., OLED, LCD, VGA
* [driver-basic-structure](api/driver-basic-structure.md): Describes common conventions used throughout device driver object files
* [lib.gfx.bitmap](api/lib.gfx.bitmap.md): Generic bitmap graphics routines common to dot-matrix type displays
* [memory](api/memory.md): Various memory technologies, e.g.: EEPROM, FRAM, SRAM, Flash
* [sensor.imu](api/sensor.imu.md): IMUs and other motion-related sensors, e.g., accelerometers, gyroscopes, magnetometers
* [sensor.power](api/sensor.power.md): Sensors for measuring the flow of electricity, power usage
* [sensor.temp_rh](api/sensor.temp_rh.md): Temperature and humidity sensors
* [signal.adc](api/signal.adc.md): Analog to Digital Converters
* [time](api/time.md): Timekeeping device drivers (hardware and emulated), e.g.: RTC
* [wireless.transceiver](api/wireless.transceiver.md): RF Packet radios for sending and receiving data wirelessly


## Intended audience

I don't recommend the use of this library if you're new to programming, in general. It makes assumptions about some things that an inexperienced programmer may simply not understand, and I don't have the time to maintain the library and support that level of inexperience simultaneously. I'd also hesitate to recommend it if you're looking for code of the utmost efficiency and speed. Consistency and reusability is my primary objective.

## Compiler compatibility

| Compiler         | Version | Supported? | Platforms | Comments                                                                                      |
|------------------|---------|------------|-----------|-----------------------------------------------------------------------------------------------|
| FlexProp/FlexSpin| Current | YES        | All       | Use this one; it can build bytecode or native code, and is also used for the Propeller 2 MCU  |
| OpenSpin         | 1.00.81 | DEPRECATED | All       | Not recommended; it's no longer maintained, but may still work 		                      |
| Brad's Spin Tool | Any     | NO         | All       | Not supported; no longer maintained; limited preprocessor features (no #include)              |
| Propeller Tool   | Any     | NO         | Windows   | Not supported; no preprocessor, no code optimization features (such as dead code removal)     |
| PNut   	   | Any     | NO         | Windows   | Not supported; no preprocessor, no code optimization features (such as dead code removal)     |

The library is developed using [FlexSpin](https://github.com/totalspectrum/spin2cpp). Some objects use preprocessor directives so will not be compatible out-of-the-box with the Propeller Tool, or Brad's Spin Tool (bstc). OpenSpin will _usually_ work fine as well, although it is no longer maintained.

All sources target FlexSpin as the build system. Upon specific request, I may be able to translate to Propeller Tool-compatible source if absolutely necessary.
Please understand though: nearly every project in this library is also maintained as SPIN2 in the p2-spin-standard-library for the Propeller 2, which requires twice the time and effort, so please use FlexSpin before asking for support translating to source compatible with other tools. Thanks for understanding!

## Testing

You can compile every file in the project with the following script.

    ./test.sh

Note that some individual drivers may (expectedly) fail to build, if they utilize preprocessor features. This will be reworked in the future.

## License

This project is licensed under the [MIT license](LICENSE).

__*Please note this library isn't officialy sanctioned by Parallax, Inc - it is a fork of the original spin-standard-library.*__
