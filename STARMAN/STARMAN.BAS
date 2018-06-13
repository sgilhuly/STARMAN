DEFINT A-Z  'declare all variables starting with a through z as integers
SCREEN 13   'set screen mode 13, 320x200x256
CLS

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

CONST CAMWIDTH = 11
CONST CAMHEIGHT = 11
CONST SIZE = 16
CONST XOFFSET = 12
CONST YOFFSET = 12
CONST MASKWALK = 1
CONST MASKWATER = 2

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
  fore AS INTEGER   ' Foreground
  solid AS INTEGER  ' Does this tile block movement?
END TYPE

' Each image takes 130 bytes, (16*16 + 4) / 2
' $DYNAMIC
DIM tileimg(0)

DIM player AS playertype
DIM camera AS cameratype
DIM tile(0, 0) AS tiletype
DIM mapwidth, mapheight AS INTEGER

' Load tile image data from the file TILES.DAT
DEF FNLoadTiles
  file = FREEFILE
  OPEN "TILES.DAT" FOR BINARY ACCESS READ AS file
  GET file,,numtiles
  REDIM tileimg(numtiles * 130 - 1)
  FOR i = 0 TO numtiles * 130 - 1
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
  REDIM tile(mapwidth, mapheight)
  FOR d = 0 TO mapheight - 1
    FOR a = 0 TO mapwidth - 1
      GET file,,tile(a, d).back
      GET file,,tile(a, d).solid
    NEXT a
  NEXT d
  CLOSE file
END DEF

' Follow the player with the camera, constrain to edges of the world
DEF FNCameraFollow
  camera.x = player.x - 5
  camera.y = player.y - 5
  IF camera.x < 0 THEN camera.x = 0
  IF camera.x > mapwidth - CAMWIDTH THEN camera.x = mapwidth - CAMWIDTH
  IF camera.y < 0 THEN camera.y = 0
  IF camera.y > mapheight - CAMHEIGHT THEN camera.y = mapheight - CAMHEIGHT
END DEF

'this next routine draws the tile on the screen
'the tx and ty variables are the tile numbers out of all the tiles
'the cx and cy variables are locations of the tile spaces where the tiles
'will be displayed on the screen
DEF FNDrawTile (tile, cx, cy)
  PUT (cx, cy), tileimg(tile * 130), PSET
END DEF

' Draw all of the tiles visible to the camera
DEF FNDrawScreen
  FOR relx = 0 TO CAMWIDTH - 1
    FOR rely = 0 TO CAMHEIGHT - 1
      tx = camera.x + relx
      ty = camera.y + rely
      cx = relx * SIZE + XOFFSET
      cy = rely * SIZE + YOFFSET
      dummy = FNDrawTile(tile(tx, ty).back, cx, cy)
    NEXT rely
  NEXT relx
END DEF

' Draw the player on screen, offset by camera location
DEF FNDrawPlayer
  cx = (player.x - camera.x) * SIZE + XOFFSET
  cy = (player.y - camera.y) * SIZE + YOFFSET
  dummy = FNDrawTile(83, cx, cy)
END DEF

DEF FNMovePlayer (relx, rely)
  IF (tile(player.x + relx, player.y + rely).solid AND MASKWALK) > 0 THEN
    player.x = player.x + relx
    player.y = player.y + rely
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
