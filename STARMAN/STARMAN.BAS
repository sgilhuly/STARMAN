DEFINT A-Z  'declare all variables starting with a through z as integers
SCREEN 13   'set screen mode 13, 320x200x256
VIEW PRINT 17 TO 25
CLS

' http://www.petesqbsite.com/sections/tutorials/zines/qbtm/5-scripting.html

' Load the Dawnbringer 16 palette
PALETTE 0, 459525
PALETTE 1, 854289
PALETTE 2, 1772812
PALETTE 3, 1249811
PALETTE 4, 791329
PALETTE 5, 596237
PALETTE 6, 1184052
PALETTE 7, 1580061
PALETTE 8, 3350294
PALETTE 9, 728884
PALETTE 10, 2630945
PALETTE 11, 731675
PALETTE 12, 2501172
PALETTE 13, 3289115
PALETTE 14, 1520950
PALETTE 15, 3488567

CONST CAMWIDTH = 15
CONST CAMHEIGHT = 7
CONST SIZE = 16
CONST IMGSIZE = 130  ' Each image takes 130 bytes, (16*16 + 4) / 2
CONST XOFFSET = 40
CONST YOFFSET = 8
CONST MASKWALK = 1
CONST MASKWATER = 2
CONST PLAYERTILE = 83

' Data about the player
TYPE playertype
  x AS INTEGER
  y AS INTEGER
END TYPE

' Data about the camera
TYPE cameratype
  x AS INTEGER
  y AS INTEGER
END TYPE

' Data about each tile
TYPE tiletype
  back AS INTEGER   ' Background tile index
  solid AS INTEGER  ' Does this tile block movement?
END TYPE

' Data about each script
TYPE scripttype
  x1 AS INTEGER
  y1 AS INTEGER
  x2 AS INTEGER
  y2 AS INTEGER
END TYPE

' Data about the map, contains tiles and scripts
' Not allowed to use arrays or variable length strings in user data types
' Fortunately only one map is loaded at once
DIM SHARED mapwidth, mapheight, numscripts AS INTEGER
' $DYNAMIC
DIM SHARED tiles(0, 0) AS tiletype
DIM SHARED scriptinfo(0) AS scripttype
DIM SHARED scripttext(0) AS STRING

' $DYNAMIC
DIM SHARED tileimg(0)

DIM SHARED player AS playertype
DIM SHARED camera AS cameratype

' Load tile image data from the file TILES.DAT
DEF FNLoadTiles
  file = FREEFILE
  OPEN "TILES.DAT" FOR BINARY ACCESS READ AS file
  GET file,,numtiles
  REDIM tileimg(numtiles * IMGSIZE - 1)
  FOR i = 0 TO numtiles * IMGSIZE - 1
    GET file,,tileimg(i)
  NEXT i
  CLOSE file
END DEF

' Load map data from a file
' The map switch trigger should set the player's location
DEF FNLoadMap (mapfile$)
  file = FREEFILE
  OPEN mapfile$ FOR BINARY ACCESS READ AS file
  GET file,,mapwidth
  GET file,,mapheight
  REDIM tiles(mapwidth - 1, mapheight - 1)
  FOR y = 0 TO mapheight - 1
    FOR x = 0 TO mapwidth - 1
      GET file,,tiles(x, y).back
      GET file,,tiles(x, y).solid
    NEXT x
  NEXT y
  GET file,,numscripts
  REDIM scriptinfo(numscripts - 1)
  REDIM scripttext(numscripts - 1)
  FOR i = 0 TO numscripts - 1
    GET file,,scriptinfo(i).x1
    GET file,,scriptinfo(i).y1
    GET file,,scriptinfo(i).x2
    GET file,,scriptinfo(i).y2
    GET file,,scriptlength
    ' Set the length of the string, which determines the number of bytes read
    scripttext(i) = STRING$(scriptlength, " ")
    GET file,,scripttext(i)
  NEXT i
  CLOSE file
END DEF

DEF FNParseLine (line$)
  IF MID$(line$, 1, 1) <> "#" THEN
    PRINT "(Running "; CHR$(34); line$; CHR$(34); ")"
    spacebreak = INSTR(line$, " ")
    IF spacebreak > 0 THEN
      keyword$ = MID$(line$, 1, spacebreak - 1)
      parameter$ = MID$(line$, spacebreak + 1)

      SELECT CASE keyword$
        CASE "print"
          PRINT parameter$
      END SELECT
    END IF
  END IF
END DEF

' Run a script defined in the map
DEF FNParseScript (n)
  ' Wouldn't be basic without these dollar signs...
  script$ = scripttext(n)
  line$ = ""
  ' Split the script and run line by line
  WHILE LEN(script$) > 0
    linebreak = INSTR(script$, CHR$(10))
    IF linebreak > 0 THEN
      line$ = MID$(script$, 1, linebreak - 1)
      script$ = MID$(script$, linebreak + 1)
    ELSE
      line$ = script$
      script$ = ""
    END IF
    dummy = FNParseLine(line$)
  WEND
END DEF

' Follow the player with the camera, constrain to edges of the world
DEF FNCameraFollow
  camera.x = player.x - (CAMWIDTH - 1) / 2
  camera.y = player.y - (CAMHEIGHT - 1) / 2
  IF camera.x < 0 THEN camera.x = 0
  IF camera.x > mapwidth - CAMWIDTH THEN camera.x = mapwidth - CAMWIDTH
  IF camera.y < 0 THEN camera.y = 0
  IF camera.y > mapheight - CAMHEIGHT THEN camera.y = mapheight - CAMHEIGHT
END DEF

'Draw a tile at pixel coordinates
DEF FNDrawTile (tile, cx, cy)
  PUT (cx, cy), tileimg(tile * IMGSIZE), PSET
END DEF

' Draw all of the tiles visible to the camera
DEF FNDrawScreen
  FOR relx = 0 TO CAMWIDTH - 1
    FOR rely = 0 TO CAMHEIGHT - 1
      tx = camera.x + relx
      ty = camera.y + rely
      cx = relx * SIZE + XOFFSET
      cy = rely * SIZE + YOFFSET
      dummy = FNDrawTile(tiles(tx, ty).back, cx, cy)
    NEXT rely
  NEXT relx
END DEF

' Draw the player on screen, offset by camera location
DEF FNDrawPlayer
  cx = (player.x - camera.x) * SIZE + XOFFSET
  cy = (player.y - camera.y) * SIZE + YOFFSET
  dummy = FNDrawTile(PLAYERTILE, cx, cy)
END DEF

DEF FNMovePlayer (relx, rely)
  IF (tiles(player.x + relx, player.y + rely).solid AND MASKWALK) > 0 THEN
    player.x = player.x + relx
    player.y = player.y + rely

    FOR i = 0 TO numscripts - 1
      IF player.x >= scriptinfo[i].x1 AND player.x <= scriptinfo[i].x2 AND _
          player.y >= scriptinfo[i].y1 AND player.y <= scriptinfo[i].y2 THEN
        dummy = FNParseScript(i)
      END IF
    NEXT i
  END IF
END DEF

' Functions need FN at the start of their name
' Can't call the function on a line by itself, so dummy is used to call the
' function, and ignore the return value
' Could use SUB, but that still requires CALL, etc...

dummy = FNLoadTiles
dummy = FNLoadMap("TESTMAP.MAP")
player.x = 21
player.y = 14

DO
  ' Draw the player, and the screen around the player
  dummy = FNCameraFollow
  dummy = FNDrawScreen
  dummy = FNDrawPlayer

getinput:
  kbd$ = INKEY$            'get a "transparent" input
  IF kbd$ <> "" THEN
    kbd$ = RIGHT$(kbd$, 1) 'get the first byte of the input
    SELECT CASE kbd$
      CASE CHR$(27) 'user pressed escape key
        END
      CASE CHR$(72) 'user pressed up arrow
        dummy = FNMovePlayer(0, -1)
      CASE CHR$(80) 'user pressed down arrow
        dummy = FNMovePlayer(0, 1)
      CASE CHR$(75) 'user pressed left arrow
        dummy = FNMovePlayer(-1, 0)
      CASE CHR$(77) 'user pressed right arrow
        dummy = FNMovePlayer(1, 0)
      CASE ELSE     'don't redraw screen
        GOTO getinput
    END SELECT
  ELSE
    GOTO getinput
  END IF
LOOP
