CON { CONstants: symbols resolved at build-time }

    _clkmode    = xtal1 + pll16x                ' set up system clock source
    _xinfreq    = 5_000_000                     ' and speed

    { create a symbol that the compiler on the PC will replace any instance of in the program
        with the value on the right side of the equals (=) sign }
    SER_BAUD    = 115_200

OBJ { child OBJects/classes }

    ser : "com.serial.terminal.ansi"            ' declare serial terminal driver as an object/class
                                                '  from external file (filename extension optional)
                                                ' call the object 'ser'

PUB main
' The _first PUBlic_ method/subroutine/function is started when the program starts,
'   regardless of its name ('main()' is just used here as a convention)

    ser.start(SER_BAUD)                         ' start the serial terminal driver
    waitcnt(cnt + (clkfreq / 100))              ' wait briefly for the serial driver to start
    ser.str(string("Hello world!"))             ' show a message on the terminal


