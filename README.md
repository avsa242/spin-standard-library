# The Spin Standard Library

The Spin Standard Library is designed to be a definitive starting point for Spin programming on the Parallax Propeller (P8X32A). It contains a
curated collection of Spin objects that have been organized and formatted for consistency, covering a wide array of functionality.

## API

In order to reduce the burden of having to learn a new programming interface with each individual object, an ongoing effort is being made to standardize the API for the various device drivers and other objects contained in the library. For example - there may be many different manufacturers of packet radio transceiver chips. They all have their own way of doing things internally, but when it comes down to it, they all send and receive data wirelessly. Why should using each driver be so uniquely different?

Decriptions of the programming interface for the various classes of library can be found in the [API](api) subdirectory.
At the time of this writing, they are:
* [display](api/display.md): Displays, e.g., OLED, LCD, VGA
* [memory](api/memory.md): Various memory technologies, e.g.: EEPROM, FRAM, SRAM, Flash
* [signal.adc](api/signal.adc.md): Analog to Digital Converters
* [sensor.imu](api/sensor.imu.md): IMUs and other motion-related sensors, e.g., accelerometers, gyroscopes, magnetometers
* [sensor.power](api/sensor.power.md): Sensors for measuring the flow of electricity, power usage
* [sensor.temp_rh](api/sensor.temp_rh.md): Temperature and humidity sensors
* [wireless.transceiver](api/wireless.transceiver.md): RF Packet radios for sending and receiving data wirelessly


## Intended audience

Who this library is aimed at:
* The programmer with _some_ prior experience: knowledge of basic programming concepts (though not necessarily the SPIN programming language) who doesn't want to spend the bulk of their time searching for and cobbling together possibly incompatible objects and libraries

Who this library is _not_ aimed at:
* Someone who has little or no programming experience - you may find yourself with as many questions as answers
* Veteran/advanced (especially SPIN) programmers - you're looking to squeeze every cycle or byte out of the MCU. Some of the objects herein may be relatively efficient, but it isn't the primary scope. You will probably find something faster or smaller elsewhere. You're probably already writing your own libraries!

As with anything though, your mileage may vary!

## Compiler compatibility

- OpenSpin (1.00.81) (Supported: lateast release; mature; available on any platform)
- FastSpin (current) (Partial support, with the major caveat that because the code produced will generally be much larger, many programs may simply not fit in RAM; available on any platform)
- ~~Brad's Spin Tool~~ (Not supported: No preprocessor support; LONG-since abandoned; please do not follow others' advice to use this - it offers little to no advantage over OpenSpin)
- ~~Propeller Tool~~ (Not supported: No preprocessor support; Windows platform only)

The library is written with [OpenSpin](https://github.com/parallaxinc/OpenSpin) in mind. Some objects use preprocessor directives so will not be compatible out-of-the-box with the Propeller Tool, or Brad's Spin Tool (bstc). FastSpin will generally work fine as well, though because it produces native code instead of SPIN bytecode, the resulting programs will be *much* larger. Some demos in this library may simply not fit in RAM as a result.

All sources target OpenSpin as the build system. Upon request, I may be able to translate to Propeller Tool-compatible source, but please make an attempt to build using OpenSpin.

Nearly every project in this library is also duplicated as FastSpin-compatible source in the p2-spin-standard-library for the Propeller 2, which doubles the effort put forth, so please give OpenSpin a try before asking for support translating to source compatible with other tools. Thanks for understanding!

## Contributing

Please read the [guidelines](CONTRIBUTING.md) before submitting a pull request.

## Testing

You can compile every file in the project with the following script.

    ./test.sh

## License

This project is licensed under the [MIT license](LICENSE).

*Please note this library isn't officialy sanctioned by Parallax, Inc - it is a fork of the original spin-standard-library and has been ported to the P2X8C4M64P/Propeller 2.*
