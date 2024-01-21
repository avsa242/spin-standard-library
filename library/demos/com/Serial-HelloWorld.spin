CON { CONstants: symbols resolved at build-time }

    _clkmode    = xtal1+pll16x                 ' set up system clock source
    _xinfreq    = 5_000_000                    ' and speed


OBJ { child OBJects/classes }

    ser: "com.serial.terminal.ansi" | SER_BAUD=115_200
                                                ' declare serial terminal driver as an object/class
                                                '  from external file (filename extension optional)
                                                ' call the object 'ser'


PUB main()
' The _first PUBlic_ method/subroutine/function is started when the program starts,
'   regardless of its name ('main()' is just used here as a convention)

    ser.start()                                 ' start the serial terminal driver
    waitcnt(cnt+clkfreq/10)                     ' give the serial driver time to start
    ser.str(@"Hello world!")                    ' show a message on the terminal


