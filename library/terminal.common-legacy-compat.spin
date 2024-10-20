{
---------------------------------------------------------------------------------------------------
    Filename:       terminal.common-legacy-compat.spin
    Description:    Terminal I/O common code functions and aliases for compatibility with
                        old/obsolete APIs
    Author:         Jesse Burt
    Started:        Oct 19, 2024
    Updated:        Oct 19, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}
PUB bin = putbin
PUB dec = putdec
PUB decuns = putudec
PUB udec = putudec
PUB hex = puthex
PUB hexs = puthexs

PUB printf1(fmt, arg1)
' 1-arg variant of printf()
    printf(fmt, arg1)


PUB printf2(fmt, arg1, arg2)
' 2-arg variant of printf()
    printf(fmt, arg1, arg2)


PUB printf3(fmt, arg1, arg2, arg3)
' 3-arg variant of printf()
    printf(fmt, arg1, arg2, arg3)


PUB printf4(fmt, arg1, arg2, arg3, arg4)
' 4-arg variant of printf()
    printf(fmt, arg1, arg2, arg3, arg4)


PUB printf5(fmt, arg1, arg2, arg3, arg4, arg5)
' 5-arg variant of printf()
    printf(fmt, arg1, arg2, arg3, arg4, arg5)


PUB printf6(fmt, arg1, arg2, arg3, arg4, arg5, arg6)
' 6-arg variant of printf()
    printf(fmt, arg1, arg2, arg3, arg4, arg5, arg6)


PUB printf7(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
' 7-arg variant of printf()
    printf(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7)


PUB printf8(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
' 8-arg variant of printf()
    printf(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)


PUB printf9(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
' 9-arg variant of printf()
    printf(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)


PUB printf10(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
' 10-arg variant of printf()
    printf(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)

PUB str = puts

