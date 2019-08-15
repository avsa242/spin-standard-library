{
    --------------------------------------------
    Filename: display.oled.4dgl.uart.spin
    Author: Beau Schwabe
    Modified by: Jesse Burt
    Description: Driver for 4D Systems Goldelox series OLED displays
    Copyright (c) 2019
    Started Jun 1, 2019
    Updated Jun 2, 2019
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This file is a derivative of the 4DGL OLED driver object
        originally written by Beau Schwabe, oled-128-g2_v2.1.spin
}
CON

    LF      = 10
    NL      = 13

OBJ

    core    : "core.con.4dgl-oled"
    ser     : "com.serial.terminal"
    time    : "time"

VAR

    long strAddress
    word color, GaugeValue[4], BarValue[4], C0L0RPalette[256]
    byte _Ack

PUB Null
' This is not a top-level object

PUB Start(OLED_RX, OLED_TX, OLED_RESET, OLED_BAUD): okay

    outa[OLED_RESET] := 0                                       ' Reset uOLED
    dira[OLED_RESET] := 1
    time.MSleep(62)
    outa[OLED_RESET] := 1
    dira[OLED_RESET] := 0

    time.Sleep(2)                                               ' Give time for system to settle down
    ser.StartRxTx (OLED_RX, OLED_TX, 0, 9600)                   ' Start Communications with default Baud
    time.Sleep(1)                                               ' Give time for system to settle down
    SetBaud(BaudIndex(OLED_BAUD))                               ' Set New Baud speed
    time.MSleep(5)                                              ' Give time for system to settle down
    ser.Stop                                                    ' Change Communication Baud
    okay := ser.startrxtx(OLED_RX, OLED_TX, 0, OLED_BAUD)       ' Start Communications with new Baud
    time.MSleep(500)                                            ' Give time for system to settle down
    ClearScreen                                                 ' Erase OLED display ; at new baud speed

PUB Stop

    ser.Stop

PUB BackgroundColor(col)
' Set the screen background color based on NEW color
    _Ack := Fxn(1, core#CMD_GFX_BGCOLOR, @col)

PUB ChangeColor(OldColor, NewColor)
' Changes ALL Old Color pixels to NewColor pixels
    _Ack := Fxn(2, core#CMD_GFX_CHANGECOLOR, @OldColor)         ' Note: Image writes mess with the graphics area
                                                                '      that color changes would normall affect.
                                                                '      There is a way around this, but it needs
                                                                '      further testing

PUB DrawCircle(X, Y, R, Co)
' Draws a circle with center at X,Y with radius R using the specified color
    _Ack := Fxn(4, core#CMD_GFX_CIRCLE, @X)

PUB Circle(X, Y, R)                                             ' draws a circle with center at X,Y with radius R

    DrawCircle(X, Y, R, color)                                  ' using the current color

PUB DrawFilledCircle(X, Y, R, C0L0R)
' Draws a solid circle with center at X,Y with radius R using the specified color
    _Ack := Fxn(4, core#CMD_GFX_CIRCLEFILLED, @X)

PUB Gfx_DrawFilledCircle(X, Y, R, C0L0R)

    DrawFilledCircle(X, Y, R, C0L0R)

PUB Clipping(mode)
' Enables or Disables the ability for Clipping to be used
    _Ack := Fxn(1, core#CMD_GFX_CLIPPING, @mode)                ' 0=Clipping Disabled ; 1=Clipping Enabled

PUB SetClipWindow(x1,y1,x2,y2)|varstore,index
' specifies a clipping window region on the screen that any objects and text placed onto the screen will be clipped and displayed only within that region
    _Ack := Fxn(4, core#CMD_GFX_CLIPWINDOW, @x1)                ' Note: Need to enable first with the Clipping function

PUB ClearScreen
' This will just erase the OLED...
    _Ack := Fxn(0, core#CMD_GFX_CLS, 0)
    time.MSleep(250)                                            ' Give time for display to clear

PUB Erase

    ClearScreen

PUB Contrast(level)
' Sets the contrast of the display, or turns it On/Off depending on the display model
    _Ack := Fxn(1, core#CMD_GFX_CONTRAST, @level)               ' 0 = Display OFF ; 1-15 = Contrast

PUB DisplayControl(mode, value)
' This command will access the display control functions.  There are two different commands that can be given.
' Display on or off...Mode = 1, value = 1(on) or 0(off)
' OLED contrast....Mode = 2, value = 0 - 15(15 being highest setting and 0 being lowest setting)
    case mode
        0     : value := 0
        1     : value := 15
        2     : value := value
        other : value := 0
    Contrast(value)

PUB PowerDown
' It is recommended by the company(4D systems) to power down the OLED after use, instead of turning off the power. Damage may occur to the display with an improper power down
    Contrast(0)

PUB FrameDelay(delay)                                           'UNTESTED FUNCTION
' Sets the inter frame delay for the "Media Video" command
    _Ack := Fxn(1, core#CMD_GFX_FRAMEDELAY, @delay)             ' 0-255 milliseconds

PUB ReadPixel(x, y)
' Reads the color value of the pixel at position x,y
    _Ack := Fxn(2, core#CMD_GFX_GETPIXEL, @x)
    result := Get_WORD_Response

PUB Pixelread(x, y)

    result := ReadPixel(x,y)

PUB DrawLine(X1, Y1, X2, Y2, C0L0R)
' Draws a line from X1,Y1 to X2,Y2 using the specified color
    _Ack := Fxn(5, core#CMD_GFX_LINE, @X1)

PUB Line(x1, y1, x2, y2)                                        ' draws a line from X1,Y1 to X2,Y2 using the current color

    DrawLine(x1, y1, x2, y2, color)

PUB LinePattern(pattern)
' Sets the line draw pattern for drawing.  If set to zero, lines are solid, else each '1' bit represents a pixel that is turned off
    _Ack := Fxn(1, core#CMD_GFX_LINEPATTERN, @pattern)

PUB DrawLineMoveOrigin(x, y)
' Draws line from the current origin to a new x,y position.
    _Ack := Fxn(2, core#CMD_GFX_LINETO, @x)                     ' The origin is then set to the new position

PUB MoveOrigin(x, y)
' Moves the origin to a new x,y position
    _Ack := Fxn(2, core#CMD_GFX_MOVETO, @x)

PUB Gfx_MoveTo(x, y)

    MoveOrigin(x, y)

PUB CalculateOrbit(angle, distance)
' Calculates the x,y coordinates of a distant point relative to the current origin
' Returns:
'       Xdist returned in upper WORD ; Ydist returned in lower WORD
    _Ack := Fxn(2, core#CMD_GFX_ORBIT, @Angle)
    result := (Get_WORD_Response << 16) + Get_WORD_Response

PUB Gfx_Orbit(Angle, Distance)

    result := CalculateOrbit(angle, distance)

PUB Orbit(Angle, Distance)

    result := CalculateOrbit(Angle, Distance)

PUB EllipseOrbit(x, y, Xrad, Yrad, _Angle) | XY, distance, deviation
' Calculates the x, y coordinates of a distant point relative to the current origin of an Ellipse
'       from a series of two stacked Orbits with opposite degrees and different radius, where the only known
'       parameters are the angle and the distance from the current origin
' Returns:
'       Xdist returned in upper WORD ; Ydist returned in lower WORD
    deviation := (Xrad - Yrad) >> 1
    distance := (Xrad + Yrad) >> 1
    gfx_MoveTo(x, y)
    XY := gfx_Orbit(_Angle, distance)
    gfx_MoveTo(XY >> 16, XY & $FFFF)
    result := gfx_Orbit(360 - _Angle, deviation)

PUB OutlineColor(Co)
' Sets the outline color for rectangles and circles
    _Ack := Fxn(1, core#CMD_GFX_OUTLINECOLOR, @Co)

PUB DrawPolygon(N, xArray, yArray, Co)
' Plots lines between points specified by a pair of arrays using the specified color within each array element
    SendData(core#CMD_GFX_POLYGON)                              ' The last point is drawn back to the first point
    DrawPoly(N, xArray, yArray, Co)

PUB DrawPolyLine(N, xArray, yArray, C0L0R)
' Plots lines between points specified by a pair of arrays using the specified color within each array element
    SendData(core#CMD_GFX_POLYLINE)
    DrawPoly(N, xArray, yArray, C0L0R)

PRI DrawPoly(N, xArray, yArray, C0L0R)|idx
{{
DAT
' Example Array Setup
    xArray
    byte 10, 50, 20
    yArray
    byte 10, 40, 120
}}
    SendData(N)
    idx := 0
    repeat N
        ser.char(0)
        ser.char(byte[xArray][idx++])
    idx := 0
    repeat N
        ser.char(0)
        ser.char(byte[yArray][idx++])
    SendData(C0L0R)
    _Ack := ser.CharIn

PUB PutPixel(x, y, C0L0R)
' Draws a pixel at position x, y using the specified color.
    _Ack := Fxn(3, core#CMD_GFX_PUTPIXEL, @x)

PUB Gfx_PutPixel(x, y, C0L0R)

    PutPixel(x, y, C0L0R)

PUB Pixel(x, y)                                                 ' draws a pixel at position x,y using the current color.

    PutPixel(x, y, color)

PUB DrawRectangle(X1, Y1, X2, Y2, C0L0R)
' Draws a rectangle from X1,Y1 to X2,Y2 using the specified color
    _Ack := Fxn(5, core#CMD_GFX_RECTANGLE, @X1)

PUB Rectangle(X1, Y1, X2, Y2)                                   ' draws a rectangle from X1,Y1 to X2,Y2 using the current

    DrawRectangle(X1, Y1, X2, Y2, color)                        ' color

PUB DrawFilledRectangle(X1, Y1, X2, Y2, C0L0R)
' Draws a filled rectangle from X1,Y1 to X2,Y2 using the specified color
    _Ack := Fxn(5, core#CMD_GFX_RECTANGLEFILLED, @X1)

PUB ScreenMode(mode)
' Alters the graphics orientation
    _Ack := Fxn(1, core#CMD_GFX_SCREENMODE, @mode)              ' 0=Landscape ; 1=Landscape reverse ; 2=Portrait ; 3=Portrait reverse

PUB SetGraphicsParameters(Function, Value)
' Sets various parameters for the Graphics Commands.
    _Ack := Fxn(2, core#CMD_GFX_SET, @Function)

PUB PenSize(mode)
' This will set the OLED to use either a wire frame or solid filling
    SetGraphicsParameters(0, mode)

PUB ObjectColor(Co)
' Generic color for Cmd_gfx_LineTo(...)
    SetGraphicsParameters(2, Co)

PUB ExtendClipRegion
' Forces the clip region to the extent of the last text that was printed, or the last image that was shown
    _Ack := Fxn(0, core#CMD_GFX_SETCLIPREGION, 0)               ' Note: Need to enable first with the Clipping function

PUB Transparency(Mode)
' Turn the transparency ON or OFF.                              ' 1=ON ; 0=OFF
    _Ack := Fxn(1, core#CMD_GFX_TRANSPARENCY, @Mode)

PUB Transparentcolor(Co)
' Color that needs to be made transparent.                      ' color, 0-65535
    _Ack := Fxn(1, core#CMD_GFX_TRANSPARENCYCOLOR, @Co)

PUB DrawTriangle(x1, y1, x2, y2, x3, y3, C0L0R) | varstore, index
' Draws a triangle outline between x1,y1,x2,y2,x3,y3 using a specified color
    _Ack := Fxn(7, core#CMD_GFX_TRIANGLE, @x1)

PUB Triangle(x1, y1, x2, y2, x3, y3)                            ' draws a triangle outline between x1,y1,x2,y2,x3,y3 using

    DrawTriangle(x1, y1, x2, y2, x3, y3, color)                 ' current color

PUB TextAttributes(Mode)
' Sets the text to underline
    _Ack := Fxn(1, core#CMD_TXT_ATTRIBUTES, @mode)              ' attribute cleared once the text (character or string)
                                                                ' is displayed
'                                                               BIT 5 = Bold
'                                                               BIT 6 = Italic
'                                                               BIT 7 = Inverse
'                                                               BIT 8 = Underlined

PUB TextBackgroundColor(Co)
' Sets the text background color
    _Ack := Fxn(1, core#CMD_TXT_BGCOLOR, @Co)

PUB TextBold(mode)
' Sets the BOLD attribute for text
    _Ack := Fxn(1, core#CMD_TXT_BOLD, @mode)                    ' attribute cleared once the text (character or string)
                                                                ' is displayed
                                                                '                1=ON ; 0=OFF
PUB TextForegroundColor(Co)
' Sets the text foreground color
    _Ack := Fxn(1, core#CMD_TXT_FGCOLOR, @Co)

PUB SetFont(id)
' Set the required font using it's ID. 0 for System font (default Fonts) ; 7 for Media fonts
    _Ack := Fxn(1, core#CMD_TXT_FONTID, @id)                    ' * Needs further testing

PUB TextHeight(height)
' Sets the text height multiplier

    _Ack := Fxn(1, core#CMD_TXT_HEIGHT, @height)                ' 1-16 Default = 1

PUB TextInverse(mode)
' Inverts the Foreground and Background color
    _Ack := Fxn(1, core#CMD_TXT_INVERSE, @mode)                 ' attribute cleared once the text (character or string)
                                                                ' is displayed
                                                                '                1=ON ; 0=OFF
PUB TextItalic(mode)
' Sets the text to italic
    _Ack := Fxn(1, core#CMD_TXT_ITALIC, @mode)                  ' attribute cleared once the text (character or string)
                                                                ' is displayed
                                                                '                1=ON ; 0=OFF
PUB MoveCursor(row, column)
' Move text cursor tp a screen position
    _Ack := Fxn(2, core#CMD_TXT_MOVECURSOR, @row)

PUB TextOpacity(mode)
' Determines if background pixels are drawn
    _Ack := Fxn(1, core#CMD_TXT_OPACITY, @mode)                 ' attribute cleared once the text (character or string)
                                                                ' is displayed
                                                                '                1=ON(Opaque) ; 0=OFF(Transparent)
PUB Opaquetext(data)

    TextOpacity(data)

PUB SetTextParameters(Function, Value)
' Sets various parameters for the Text commands
    _Ack := Fxn(2, core#CMD_TXT_SET, @Function)

PUB TextPrintDelay(delay)
' Sets the Delay between the characters being printed through Put Character or Put String functions
    SetTextParameters(7, delay)                                 ' 0 - 255 msec ; Default = 0

PUB TextUnderline(mode)
' Sets the text to underline
    _Ack := Fxn(1, core#CMD_TXT_UNDERLINE, @mode)               ' attribute cleared once the text (character or string)
                                                                ' is displayed
                                                                '                1=ON ; 0=OFF

PUB TextWidth(multiplier)
' Sets the text width multiplier
    _Ack := Fxn(1, core#CMD_TXT_WIDTH, @multiplier)             ' 1-16 Default = 1

PUB TextXgap(pixels)
' Sets the pixel gap between characters (x-axis)
    _Ack := Fxn(1, core#CMD_TXT_XGAP, @pixels)                  ' 0-32 Default = 0

PUB TextYgap(pixels)
' Sets the pixel gap between characters (y-axis)
    _Ack := Fxn(1, core#CMD_TXT_YGAP, @pixels)                  ' 0-32 Default = 0

PUB FlushMedia                                                  ' UNTESTED FUNCTION
' After writing any data to a sector, the Flush Media command should be called to ensure data is written correctly
    _Ack := Fxn(0, core#CMD_MEDIA_FLUSH, 0)
    result := Get_WORD_Response

PUB DisplayImage(X, Y)                                          ' UNTESTED FUNCTION
' Displays an image from the media storage at the specified co-ordinates.  The image is previously specified with the
'   "Set Byte Address" or the "Set Sector Address".
    _Ack := Fxn(2, core#CMD_MEDIA_IMAGE, @X)

PUB MediaInit
' Initializes a uSD/SD/SDHC memory card for further operations
'   Returns:
'       returned word represents memory type
    _Ack := Fxn(0, core#CMD_MEDIA_INIT, 0)
    result := Get_WORD_Response                                 ' 0  = No Memory Card

PUB ReadByte
' Returns byte value from current media address
    _Ack := Fxn(0, core#CMD_MEDIA_READBYTE, 0)
    result := Get_WORD_Response

PUB ReadWord
' Returns word value from current media address
    _Ack := Fxn(0, core#CMD_MEDIA_READWORD, 0)
    result := Get_WORD_Response

PUB SetByteAddress(HIword, LOword)
' Sets the media memory internal address pointer for access at non-sector aligned byte address
    _Ack := Fxn(2, core#CMD_MEDIA_SETADD, @HIword)

PUB SetSectorAddress(HIword, LOword)
' Sets the media memory internal address pointer for sector access
    _Ack := Fxn(2, core#CMD_MEDIA_SETSECTOR, @HIword)

PUB DisplayVideo(X, Y)                                            ' UNTESTED FUNCTION
' Displays a video clip from the media storage at the specified co-ordinates.  The image is previously specified with
'   the "Set Byte Address" or the "Set Sector Address".
    _Ack := Fxn(2, core#CMD_MEDIA_VIDEO, @X)

PUB DisplayVideoFrame(x, y, Frame)                                ' UNTESTED FUNCTION
'   Displays a video frame from the media storage at the specified co-ordinates.  The image is previously specified with
'    the "Set Byte Address" or the "Set Sector Address".
    _Ack := Fxn(3, core#CMD_MEDIA_VIDEOFRAME, @X)

PUB WriteByte(value)
' Writes a byte value from current media address
'   Returns:
'       result Non Zero for successful media response ; 0 for attempt failed
    _Ack := Fxn(1, core#CMD_MEDIA_WRITEBYTE, @value)
    result := Get_WORD_Response

PUB WriteWord(value)
' Writes a word value from current media address
'   Returns:
'       result Non Zero for successful media response ; 0 for attempt failed
    _Ack := Fxn(1, core#CMD_MEDIA_WRITEWORD, @value)
    result := Get_WORD_Response

PUB Beep(Note, Duration)
' Produce a single musical note for the required duration through IO2
'   Note     - specifying frequency of note ranging from 0 to 64        Note: Using a Servo Extender cable and
'   Duration - time in milliseconds that the note will play for               aligning it on the uOLED so that
'                                                                          the Black wire is connected to GND
'                                                                          then IO1 is RED and IO2 is WHITE
'                                                                          you can bring the I/O functionality
'                                                                          of your uOLED to your project.
'                                                                    Note: Beep is a single threaded process
'                                                                          Beep is not a background task
    _Ack := Fxn(2, core#_BEEP, @Note)

PUB BlitCom2Display(x, y, width, height, data) | idx
' BLIT(BLock Image Transfer) 16 Bit pixel data from the COM port to the screen
    SendData(core#_BLITCOMTODISPLAY)
    SendData(x)
    SendData(y)
    SendData(width)
    SendData(height)
    idx := 0
    repeat width * height
        SendData(word[data][idx++])
    _Ack := ser.CharIn

PUB Image(x, y, h, w, mode, data) | index, BMPdataTable, temp, R, G, B, Co
' Display image based on the string of data input in the "data" parameter. starting at location x,y with height "h"
'   and width "W"... 'mode' is legacy compatibility and is not used the same as before. It was used for defining an 8-bit
'   color reference or 16-Bit color reference to save program space.  Which sacrificed color depth for resolution.  The
'   function implemented here uses the full 16-bit color reference and instead to save space sacrifices resolution. When
'   mode is equal to 0 you get the full color and full resolution.  When mode is equal to 1 you get the full color and half
'   the resolution.  In other words, the image is displayed twice as big in both the X and the Y.
'   MODE = 0  16 bit 5-6-5 color 128x128 pixel images
'   MODE = 1  16 bit 5-6-5 color 64x64 pixel images (saves space)
'   Returns:
'       Ack = 255
    mode &= 1
'       find BMP data table
    index := $0D
    BMPdataTable := byte[data][index--]
    repeat 3
        BMPdataTable := BMPdataTable<<8 + byte[data][index--]

'       Go to beginning of BMP color table
    index := $36

    repeat temp from 1 to 256
        B := byte[data][index++]>>3                             '<-- Convert colors from 8-8-8 to 5-6-5
        G := byte[data][index++]>>2
        R := byte[data][index++]>>3
                      index++                                   '<-- Place holder for Alpha ; not used
        C0L0RPalette[temp] := R<<11+G<<5+B                      '<-- pack 5-6-5 colors into WORD

' Go to beginning of BMP data table
    index := BMPdataTable
' The remaining BYTES define the data.  Each BYTE represents one pixel where the value
'   points to one of the 256 colors in the color palette defined above.

    SendData(core#_BLITCOMTODISPLAY)
    SendData(x)
    SendData(y)
    SendData(w<<mode)
    SendData(h<<mode)

    time.MSleep (2)

    index += (w * (h-1) )
    repeat h
        repeat 1<<mode
            repeat w
                temp := index++
                repeat 1<<mode
                    Co := C0L0RPalette[byte[data][temp]+1]
                    SendData(Co)

            index -= w
        index -= w

    _Ack := ser.CharIn

PUB CharacterHeight(height)
' Used to calculate the height in pixel units for a character based on the currently selected font.
'   Returns: calculated character height
    SendData(core#_CHARHEIGHT)
    ser.char(height)
    _Ack := ser.CharIn
    result := Get_WORD_Response

PUB CharacterWidth(width)
' Used to calculate the width in pixel units for a character based on the currently selected font.
' Returns: calculated character width
    SendData(core#_CHARWIDTH)
    ser.char(width)
    _Ack := ser.CharIn
    result := Get_WORD_Response

PUB Joystick
' Returns the value of the Joystick position from 0-5
    _Ack := Fxn(0, core#_JOYSTICK, 0)
    result := Get_WORD_Response                                 ' 0=Released
                                                                ' 1=Up          Note: Using a Servo Extender cable and
                                                                ' 2=Left              aligning it on the uOLED so that
                                                                ' 3=Down              the Black wire is connected to GND
                                                                ' 4=Right             then IO1 is RED and IO2 is WHITE
                                                                ' 5=Press             you can bring the I/O functionality
                                                                '                    of your uOLED to your project.
PUB BytePeek(value)
' Return the EVE system Byte Register value
    _Ack := Fxn(1, core#_PEEKB, @value)
    result := Get_WORD_Response

PUB WordPeek(value)
' Return the EVE system Word Register value
    _Ack := Fxn(1, core#_PEEKW, @value)
    result := Get_WORD_Response

PUB BytePoke(Register, value)
' Sets the EVE system Byte Register value
    if ByteRegisterCheck(Register) == 1
        _Ack := Fxn(2, core#_POKEB, @Register)
    else
        _Ack := 0

PUB WordPoke(Register, value)
' Sets the EVE system Word Register value

    if WordRegisterCheck(Register) == 1
        _Ack := Fxn(2, core#_POKEW, @Register)
    else
        _Ack := 0

PUB PutCharacter(chr)
' Prints a single character to display
    _Ack := Fxn(1, core#_PUTCH, @chr)

PUB PutString(data, size)
' Prints a Null terminated string string to the display
' NOTE: If size is set to a number less than the actual string
'      length, then only that number of characters in the string
'      are printed.  If size is set to 0 or a number larger than
'      the string length, then the entire string is printed.
    if size == 0 or size > strsize(data)
        size := strsize(data)
    SendData( core#_PUTSTR)
    repeat until size == 0
        ser.char(byte[data++])
        size--
    ser.char(0)
    _Ack := ser.CharIn

PUB ScreenSaverMode(mode)
' Set Screen Saver Scroll Direction
'   uLCD-144-G2  n/a
'   uOLED-96-G2  n/a
'   uOLED-128-G2 n/a
'   uOLED-160-G2 0-Up, 1-Down, 2-Left, 3-Right
'   uTOLED-20-G2 0-Left, 1-Right, 3-Down, 7-Up
'                4-Left/Down, 5-Down/Right
'                8-Top/Left, 9-Top/Right
    _Ack := Fxn(1, core#_SSMODE, @mode)

PUB ScreenSaverTimeout(timeout)
' Set the Screen Saver Timeout
'   0 disables the screen saver
'   1-65535 specifies the timeout in milliseconds
    _Ack := Fxn(1, core#_SSTIMEOUT, @timeout)

PUB ScreenSaverSpeed(speed)
' Set the Screen Saver speed
    _Ack := Fxn(1, core#_SSSPEED, @speed)                       ' uLCD-144-G2  n/a
                                                                ' uOLED-96-G2  0-3   (Fastest-Slowest)
                                                                ' uOLED-128-G2 0-3   (Fastest-Slowest)
                                                                ' uOLED-160-G2 0-255 (Fastest-Slowest)
                                                                ' uTOLED-20-G2 1-16  (Fastest-Slowest)

PUB GetDisplayModel|index
' Returns the Display Model in the form of a string address
    _Ack := Fxn(0, core#CMD_SYS_GETMODEL, 0)
    ClearStr
    index := 0
    repeat Get_WORD_Response
        byte[strAddress][index++] := ser.CharIn
    result := strAddress

PUB RequestInfo                                                 ' Returns the Display Model in the form of a string address

    result := GetDisplayModel

PUB GetPmmCVersion
' Returns the PmmC Version installed on the module in Hex
    _Ack := Fxn(0, core#CMD_SYS_GETPMMC, 0)
    result := Get_WORD_Response

PUB GetSPEVersion
' Returns the SPE Version installed on the module in Hex
    _Ack := Fxn(0, core#CMD_SYS_GETVERSION, 0)
    result := Get_WORD_Response

PUB SetBaud(baud)
' Specifies the baud rate index value
    _Ack := Fxn(1, core#_SETBAUD, @baud)

PUB WritePalette(C0L0R, value)
' Sets one of 256 colors in the scratch pad color palette
'   NOTE: The image function uses this palette
    C0L0RPalette[(C0L0R & $FF)+1] := value & $FFFF

PUB ReadPalette(C0L0R)
'Reads one of 256 colors in the scratch pad color palette
    result := C0L0RPalette[(C0L0R & $FF)+1]

PUB RunScreenSaver(runtime)
' Run Screen Saver for N milliseconds, and then disable Screen Saver
    ScreenSaverTimeout(1)
    time.MSleep (runtime)
    ScreenSaverTimeout(0)

PUB SystemTimer
' Get 32-Bit uOLED System Timer value
    result := WordPeek(113)<<16 + WordPeek(112)

PUB XScreenResolution
' X Screen Resolution
    result := BytePeek(132)

PUB YScreenResolution
' Y Screen Resolution
    result := BytePeek(133)

PUB RGB(Red, Green, Blue)
' Creates composite LONG value from RGB values
'   Input Format: 8-Bit Red / 8-Bit Green / 8-Bit Blue   24 Bit color
'   Returns: 5-Bit Red / 6-Bit Green / 5-Bit Blue   16 Bit color
   color := ((Red >> 3) << 11) | ((Green >> 2) << 5) | (Blue >> 3)
   result := color

PUB CustomColor(colordata)
' This is for choosing your own colors. The input must be a (5-6-5) 16 bit representation of the color
    color := colordata                                          ' See also the ... RGB command

PUB BaudIndex(Baud)
' Calculate Baud Index
    result :=  (3000000 / Baud)-1

PUB PlaceString(column, row, data, size)
' Place a string of text on the display. It will start at the column and row specified in the first two
'   parameters... specified in the first two parameters..."data" is the parameter used for passing along the array of
'   characters. "size" is the number of bytes of data that are to be sent
' NOTE: 'color' is a global variable set with choosecolor, customcolor, or RGB
    MoveCursor(row, column)          'Move Cursor first
    TextForegroundColor(color)      'Set Color
    PutString(data, size)            'Display String

PUB EraseChar(c, r)
' Erase a single character(located by c and r) by converting it back to it's background color.
    PlaceString(c, r, string(" "), 0)

PUB Char(Chardata, c, r)
' Place an ASCII character onto the display at the appropriate column and row
    strAddress := string(" ")
    byte[strAddress] := Chardata
    placestring(c, r, strAddress, 0)

PUB BMPChar(x, y, charID, Data)|index,bitdata
' Uses BLIT(BLock Image Transfer) to send a custom 8x8 bitmap character image to the screen
    SendData(core#_BLITCOMTODISPLAY)
    SendData(x)
    SendData(y)
    SendData(8)                                                 ' Data = Address of an 8x8 bit array
    SendData(8)
    index := charID * 8                                         ' charID is the character index
    repeat 8
        bitdata := byte[data][index++]
        repeat 8
            if (bitdata & 128)== 128
                SendData(color)
            else
                SendData(0)
            bitdata := bitdata << 1
    _Ack := ser.CharIn

PUB ChooseColor(colorpointer)
' Set a common variable(Color) to represent one of the pre-defined colors. You can also make your
'   own using the "customcolor" or "RGB" method. This function accepts a single ASCII character. Use the following chart
'   to determine color
    case ColorPointer
        "B": color := %00000_000000_00011 'DarkBlue
        "b": color := %00000_000000_11111 'LightBlue
        "G": color := %00000_000011_00000 'DarkGreen
        "g": color := %00000_011111_00000 'LightGreen
        "R": color := %00010_000000_00000 'DarkRed
        "r": color := %11111_000000_00000 'LightRed
        "Y": color := %00010_000100_00000 'DarkYellow
        "y": color := %11111_111110_00000 'LightYellow
        "P": color := %00010_000000_00010 'DarkPurple
        "p": color := %00111_000000_00111 'LightPurple
        "O": color := %10011_001111_00000 'Orange
        "W": color := %11111_111111_11111 'BrightWhite
        "H": color := %11111_000111_01011 'HotPink
        "D": color := %00000_000000_00000 'dark(black)

PUB Gauge(x, y, r, mode, C0L0R, level, GaugeNumber) | data1, data2, index
' Displays a circular 180 Deg indicator Gauge located at x,y .. r sets the gauge radius Mode adjusts the screen orientation, see
' the 'ScreenMode' for more information 'color' sets the color you want the Gauge to be drawn. 'level' is the position of
' the gauge 0-255. GaugeNumber 1-4 references the active gauge.  It is used to prevent unnecessary redraw when the value of
' the gauge doesn't need to be changed.
    GaugeNumber := (GaugeNumber -1) & %11
    level := (((level & $FF) * 179) / 255)
    ScreenMode(mode)
    MoveOrigin(x, y)
    if GaugeValue[GaugeNumber] & $100 <> $100
        repeat index from 360 to 180 step 18
            data1 := CalculateOrbit(index, r)
            data2 := CalculateOrbit(index, r+5)
            DrawLine(data1.word[1], data1.word[0], data2.word[1], data2.word[0], C0L0R)
    if GaugeValue[GaugeNumber] & $FF <> level
        data1 := CalculateOrbit(360-GaugeValue[GaugeNumber] & $FF, r-1)
        DrawLine(x, y, data1.word[1], data1.word[0], 0)
        GaugeValue[GaugeNumber] := 1<<8 + level
    data1 := CalculateOrbit(360-level, r-1)
    DrawLine(x, y, data1.word[1], data1.word[0], C0L0R)
    MoveOrigin(0, 0)
    ScreenMode(0)

PUB BARgraph(x, y, mode, size, segments, ColorON, ColorOFF, level, BARnumber) | index, offset, C0L0R, thresh
' Displays a linear BAR graph meter with the top left corner being at location x,y Mode adjusts the screen orientation,
' see the 'ScreenMode' for more information 'size' sets the pixel width of each LED segment. The height of each segment is
' scaled to 1/4th of the width. 'segments' determine the total number of segments in the graph. ColorON - the "ON" color
' likewise for ColorOFF. 'level' is the position of the gauge 0-255. BARnumber 1-4 references the active graph. It is used
' to prevent unnecessary redraw when the value of the graph doesn't need to be changed.
    BARnumber := (BARnumber - 1) & %11
    level := level & $FF
    thresh := (segments * (255-level)) / 255
    offset := 0
    ScreenMode(mode)
    if BarValue[BARnumber] <> thresh
        BarValue[BARnumber] := thresh
        repeat index from 1 to segments
            if thresh => index
                C0L0R := ColorOFF
            else
                C0L0R := ColorON
             DrawFilledRectangle(x, y+offset, x+size, size >> 2 + offset, C0L0R)
             offset += size >> 1 - 1
    ScreenMode(0)

PRI ByteRegisterCheck(location) | flag
' Memory protection to avoid accidental writes into system memory

    flag := 0
    case location                                               ' Note: Memory that is ok to write to, the flag is set to a "1"
        138     :  flag := 1
        140..147:  flag := 1
        153..154:  flag := 1
        156..156:  flag := 1
    result := flag

PRI WordRegisterCheck(location) | flag
' Memory protection to avoid accidental writes into system memory
    flag := 0
    case location                                               ' Note: Memory that is ok to write to, the flag is set to a "1"
        83      :  flag:=1
        86..91  :  flag:=1
        104..105:  flag:=1
        112..118:  flag:=1
        121     :  flag:=1
        129..383:  flag:=1
    result := flag

PUB Char5x7(x, y, address) | index ' XXX VERIFY NAME VS DESCRIPTION
' Display 5x7 Null terminated String at location specified by x,y
    index := 0
    repeat strsize(address)
        displaybmpchar(byte[address][index], x + index++ * 6, y)

PUB Displaybmpchar(_char, x, y)
' Display 5x7 Character at location specified by x,y
    if _char > 64 and _char < 92
        bmpchar(x, y, _char-65, @bitmap)
    if _char > 96 and _char < 123
        bmpchar(x, y, _char-97, @bitmap)
    if _char > 47 and _char < 59
        bmpchar(x, y, (_char-48) + 26, @bitmap)

PUB Ack                                                         ' Request latest Ack result

    result := _Ack

PUB NextAck                                                     ' Adapted mainly for Debugging

    _Ack := ser.CharIn
    result := _Ack

PUB Dec(data, r, c)
' Displays a byte, word or long as a series of ASCII characters representing their number in decimal "r" and "c"
' are the starting column and row
    PlaceString(c, r, decstr(data), 0)

PUB Binary(data, digits, r, c)
' Display binary data onto the screen. "Digits" is the number of digits in the sequence "r" and
' "c" are the starting column and row
    PlaceString(c, r, binstr(data, digits), 0)

PUB Hex(data, digits, r, c)
' Displays a Hex number on to the screen, "Digits" is the number of digits in the sequence "r" and "c" are the
' starting column and row
    PlaceString(c, r, hexstr(data, digits), 0)

PRI Fxn(argCount, Command, ArgAddress)|index

    SendData(Command)
    index := 0
    repeat argCount
        SendData(long[ArgAddress][index++])                     ' Main Function to communicate with various methods
    result := ser.CharIn                                        ' associated with the uOLED display

PRI SendData(Data)                                              ' Send Word variable to the uOLED display
    ser.char(Data.byte[1])
    ser.char(Data.byte[0])
    'waitcnt(clkfreq/3500 + cnt)

PRI Get_WORD_Response                                           ' Read Word variable response from the uOLED display

    result := ser.CharIn << 8 + ser.CharIn                      ' return WORD result

PUB DecStr(value) | div, z_pad, idx
' Converts value to signed-decimal string equivalent
' -- characters written to current position of idx
' -- returns pointer to strAddress
    ClearStr
    idx := 0

    if (value < 0)                                              ' negative value?
        -value                                                  '   yes, make positive
        byte[strAddress][idx++] := "-"                          '   and print sign indicator

    div := 1_000_000_000                                        ' initialize divisor
    z_pad~                                                      ' clear zero-pad flag

    repeat 10
        if (value => div)                                       ' printable character?
            byte[strAddress][idx++] := (value / div + "0")      '   yes, print ASCII digit
            value //= div                                       '   update value
            z_pad~~                                             '   set zflag
        elseif z_pad or (div == 1)                              ' printing or last column?
            byte[strAddress][idx++] := "0"
        div /= 10

    return strAddress

PUB BinStr(value, digits) | idx
' Converts value to digits-wide binary string equivalent
' -- characters written to current position of idx
' -- returns pointer to strAddress
    ClearStr
    idx := 0

    digits := 1 #> digits <# 32                                 ' qualify digits
    value <<= 32 - digits                                       ' prep MSB
    repeat digits
        byte[strAddress][idx++] := (value <-= 1) & 1 + "0"      ' move digits (ASCII) to string

    return strAddress

PUB HexStr(value, digits) | idx
' Converts value to digits-wide hexadecimal string equivalent
' -- characters written to current position of idx
' -- returns pointer to strAddress
    ClearStr
    idx := 0

    digits := 1 #> digits <# 8                                  ' qualify digits
    value <<= (8 - digits) << 2                                 ' prep most significant digit
    repeat digits
        byte[strAddress][idx++] := lookupz((value <-= 4) & $F: "0".."9", "A".."F")

    return strAddress

PRI ClearStr

    strAddress := string("                    ")
    bytefill(strAddress, 0, strsize(strAddress))

DAT
'----------------------------------------------------------
'                bitmap for 5x7 Character set
'----------------------------------------------------------
bitmap  byte  $70, $88, $88, $F8, $88, $88, $88, $00    ' A
        byte  $F0, $88, $88, $F0, $88, $88, $F0, $00    ' B
        byte  $70, $88, $80, $80, $80, $88, $70, $00    ' C
        byte  $F0, $88, $88, $88, $88, $88, $F0, $00    ' D
        byte  $F8, $80, $80, $F0, $80, $80, $F8, $00    ' E
        byte  $F8, $80, $80, $F0, $80, $80, $80, $00    ' F
        byte  $70, $88, $80, $80, $98, $88, $68, $00    ' G
        byte  $88, $88, $88, $F8, $88, $88, $88, $00    ' H
        byte  $F8, $20, $20, $20, $20, $20, $F8, $00    ' I
        byte  $70, $20, $20, $20, $20, $20, $C0, $00    ' J
        byte  $88, $90, $A0, $C0, $A0, $90, $88, $00    ' K
        byte  $80, $80, $80, $80, $80, $80, $F8, $00    ' L
        byte  $88, $D8, $A8, $88, $88, $88, $88, $00    ' M
        byte  $88, $88, $C8, $A8, $98, $88, $88, $00    ' N
        byte  $70, $88, $88, $88, $88, $88, $70, $00    ' O
        byte  $F0, $88, $88, $F0, $80, $80, $80, $00    ' P
        byte  $70, $88, $88, $88, $A8, $90, $68, $00    ' Q
        byte  $F0, $88, $88, $F0, $90, $88, $88, $00    ' R
        byte  $70, $88, $80, $70, $08, $88, $70, $00    ' S
        byte  $F8, $20, $20, $20, $20, $20, $20, $00    ' T
        byte  $88, $88, $88, $88, $88, $88, $70, $00    ' U
        byte  $88, $88, $88, $88, $88, $50, $20, $00    ' V
        byte  $88, $88, $88, $88, $A8, $D8, $88, $00    ' W
        byte  $88, $88, $50, $20, $50, $88, $88, $00    ' X
        byte  $88, $88, $50, $20, $20, $20, $20, $00    ' Y
        byte  $F8, $08, $10, $20, $40, $80, $F8, $00    ' Z
        byte  $70, $88, $98, $A8, $C8, $88, $70, $00    ' 0
        byte  $20, $60, $20, $20, $20, $20, $70, $00    ' 1
        byte  $70, $88, $10, $20, $40, $80, $F8, $00    ' 2
        byte  $F8, $10, $20, $70, $08, $88, $70, $00    ' 3
        byte  $30, $50, $90, $F8, $10, $10, $10, $00    ' 4
        byte  $F8, $80, $80, $F0, $08, $88, $70, $00    ' 5
        byte  $70, $80, $80, $70, $88, $88, $70, $00    ' 6
        byte  $F8, $08, $10, $20, $40, $40, $40, $00    ' 7
        byte  $70, $88, $88, $70, $88, $80, $70, $00    ' 8
        byte  $70, $88, $88, $70, $08, $00, $70, $00    ' 9

DAT
{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, PUBlish, distribute, sub license, and/or sell copies of the Software, and to permit persons to whom the       │
│Software is furnished to do so, subject to the following conditions:                                                         │
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}


