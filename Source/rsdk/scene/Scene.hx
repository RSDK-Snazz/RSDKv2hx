package rsdk.scene;

import rsdk.core.Reader;
import rsdk.core.RetroString;
import rsdk.core.Debug;
import rsdk.graphics.Drawing;
import rsdk.graphics.Palette;
import rsdk.graphics.Sprite;
import rsdk.audio.Audio;
import rsdk.input.Input;
import rsdk.scene.Player.PlayerManager;
import rsdk.scene.Object;
import rsdk.scene.Script;
import rsdk.scene.Collision.Collision;
import rsdk.graphics.Animation;
import rsdk.graphics.IndexedGif;
import rsdk.graphics.Video;

enum abstract StageListNames(Int) to Int {
    var STAGELIST_PRESENTATION = 0;
    var STAGELIST_REGULAR = 1;
    var STAGELIST_BONUS = 2;
    var STAGELIST_SPECIAL = 3;
    var STAGELIST_MAX = 4;
}

enum abstract TileLayerTypes(Int) to Int {
    var LAYER_NOSCROLL = 0;
    var LAYER_HSCROLL = 1;
    var LAYER_VSCROLL = 2;
    var LAYER_3DCLOUD = 3;
    var LAYER_3DSKY = 4;
}

enum abstract StageModes(Int) to Int {
    var STAGEMODE_LOAD = 0;
    var STAGEMODE_NORMAL = 1;
    var STAGEMODE_PAUSED = 2;
}

enum abstract TileInfoEnum(Int) to Int {
    var TILEINFO_INDEX = 0;
    var TILEINFO_DIRECTION = 1;
    var TILEINFO_VISUALPLANE = 2;
    var TILEINFO_SOLIDITYA = 3;
    var TILEINFO_SOLIDITYB = 4;
    var TILEINFO_FLAGSA = 5;
    var TILEINFO_ANGLEA = 6;
    var TILEINFO_FLAGSB = 7;
    var TILEINFO_ANGLEB = 8;
}

enum abstract DeformationModes(Int) to Int {
    var DEFORM_FG = 0;
    var DEFORM_FG_WATER = 1;
    var DEFORM_BG = 2;
    var DEFORM_BG_WATER = 3;
}

enum abstract CameraStyles(Int) to Int {
    var CAMERASTYLE_FOLLOW = 0;
    var CAMERASTYLE_EXTENDED = 1;
}

class SceneInfo {
    public var name:Array<Int> = [for (i in 0...0x40) 0];
    public var folder:Array<Int> = [for (i in 0...0x40) 0];
    public var id:Array<Int> = [for (i in 0...0x40) 0];
    public var highlighted:Bool = false;

    public function new() {}
}

class CollisionMasks {
    public var floorMasks:Array<Int> = [for (i in 0...Scene.TILE_COUNT * Scene.TILE_SIZE) 0];
    public var lWallMasks:Array<Int> = [for (i in 0...Scene.TILE_COUNT * Scene.TILE_SIZE) 0];
    public var rWallMasks:Array<Int> = [for (i in 0...Scene.TILE_COUNT * Scene.TILE_SIZE) 0];
    public var roofMasks:Array<Int> = [for (i in 0...Scene.TILE_COUNT * Scene.TILE_SIZE) 0];
    public var angles:Array<Int> = [for (i in 0...Scene.TILE_COUNT) 0];
    public var flags:Array<Int> = [for (i in 0...Scene.TILE_COUNT) 0];

    public function new() {}
}

class TileLayer {
    public static inline var TILELAYER_CHUNK_MAX:Int = 0x100 * 0x100;
    public static inline var TILELAYER_SCROLL_MAX:Int = 0x100 * 0x80;

    public var tiles:Array<Int> = [for (i in 0...TILELAYER_CHUNK_MAX) 0];
    public var lineScroll:Array<Int> = [for (i in 0...TILELAYER_SCROLL_MAX) 0];
    public var parallaxFactor:Int = 0;
    public var scrollSpeed:Int = 0;
    public var scrollPos:Int = 0;
    public var angle:Int = 0;
    public var xPos:Int = 0;
    public var yPos:Int = 0;
    public var zPos:Int = 0;
    public var type:Int = 0;
    public var xsize:Int = 0;
    public var ysize:Int = 0;

    public function new() {}
}

class LineScroll {
    public static inline var PARALLAX_COUNT:Int = 0x100;

    public var parallaxFactor:Array<Int> = [for (i in 0...PARALLAX_COUNT) 0];
    public var scrollSpeed:Array<Int> = [for (i in 0...PARALLAX_COUNT) 0];
    public var scrollPos:Array<Int> = [for (i in 0...PARALLAX_COUNT) 0];
    public var linePos:Array<Int> = [for (i in 0...PARALLAX_COUNT) 0];
    public var deform:Array<Int> = [for (i in 0...PARALLAX_COUNT) 0];
    public var entryCount:Int = 0;

    public function new() {}
}

class Tiles128x128 {
    public static inline var CHUNKTILE_COUNT:Int = 0x200 * 64;

    public var gfxDataPos:Array<Int> = [for (i in 0...CHUNKTILE_COUNT) 0];
    public var tileIndex:Array<Int> = [for (i in 0...CHUNKTILE_COUNT) 0];
    public var direction:Array<Int> = [for (i in 0...CHUNKTILE_COUNT) 0];
    public var visualPlane:Array<Int> = [for (i in 0...CHUNKTILE_COUNT) 0];
    public var collisionFlags:Array<Array<Int>> = [
        [for (i in 0...CHUNKTILE_COUNT) 0],
        [for (i in 0...CHUNKTILE_COUNT) 0]
    ];

    public function new() {}
}

class Scene {
    public static inline var LAYER_COUNT:Int = 9;
    public static inline var DEFORM_STORE:Int = 0x100;
    public static inline var DEFORM_SIZE:Int = 320;
    public static inline var DEFORM_COUNT:Int = DEFORM_STORE + DEFORM_SIZE;
    public static inline var TILE_COUNT:Int = 0x400;
    public static inline var TILE_SIZE:Int = 0x10;
    public static inline var CHUNK_SIZE:Int = 0x80;
    public static inline var TILE_DATASIZE:Int = TILE_SIZE * TILE_SIZE;
    public static inline var TILESET_SIZE:Int = TILE_COUNT * TILE_DATASIZE;
    public static inline var CPATH_COUNT:Int = 2;
    public static inline var PARALLAX_COUNT:Int = 0x100;
    public static inline var PLAYER_COUNT:Int = 2;
    public static inline var SPRITESHEETS_MAX:Int = 16;

    public static inline var STAGEMODE_LOAD:Int = 0;
    public static inline var STAGEMODE_NORMAL:Int = 1;
    public static inline var STAGEMODE_PAUSED:Int = 2;

    public static inline var LAYER_NOSCROLL:Int = 0;
    public static inline var LAYER_HSCROLL:Int = 1;
    public static inline var LAYER_VSCROLL:Int = 2;
    public static inline var LAYER_3DCLOUD:Int = 3;
    public static inline var LAYER_3DSKY:Int = 4;

    public static var stageListCount:Array<Int> = [0, 0, 0, 0];
    public static var stageListNames:Array<String> = ["Presentation Stages", "Regular Stages", "Bonus Stages", "Special Stages"];
    public static var stageList:Array<Array<SceneInfo>> = [
        for (i in 0...STAGELIST_MAX) [for (j in 0...0x100) new SceneInfo()]
    ];

    public static var stageMode:Int = STAGEMODE_LOAD;
    public static var cameraStyle:Int = CAMERASTYLE_FOLLOW;
    public static var cameraEnabled:Int = 0;
    public static var cameraAdjustY:Int = 0;
    public static var xScrollOffset:Int = 0;
    public static var yScrollOffset:Int = 0;
    public static var yScrollA:Int = 0;
    public static var yScrollB:Int = Drawing.SCREEN_YSIZE;
    public static var xScrollA:Int = 0;
    public static var xScrollB:Int = Drawing.SCREEN_XSIZE;
    public static var yScrollMove:Int = 0;
    public static var earthquakeX:Int = 0;
    public static var earthquakeY:Int = 0;
    public static var xScrollMove:Int = 0;

    public static var xBoundary1:Int = 0;
    public static var newXBoundary1:Int = 0;
    public static var yBoundary1:Int = 0;
    public static var newYBoundary1:Int = 0;
    public static var xBoundary2:Int = 0;
    public static var yBoundary2:Int = 0;
    public static var waterLevel:Int = 0x7FFFFFF;
    public static var waterDrawPos:Int = Drawing.SCREEN_YSIZE;
    public static var newXBoundary2:Int = 0;
    public static var newYBoundary2:Int = 0;

    public static var screenScrollLeft:Int = Std.int(Drawing.SCREEN_XSIZE / 2) - 8;
    public static var screenScrollRight:Int = Std.int(Drawing.SCREEN_XSIZE / 2) + 8;
    public static inline var SCREEN_SCROLL_UP:Int = (Drawing.SCREEN_YSIZE >> 1) - 16;
    public static inline var SCREEN_SCROLL_DOWN:Int = (Drawing.SCREEN_YSIZE >> 1) + 16;

    public static var lastXSize:Int = -1;
    public static var lastYSize:Int = -1;

    public static var pauseEnabled:Bool = true;
    public static var timeEnabled:Bool = true;
    public static var debugMode:Bool = false;
    public static var frameCounter:Int = 0;
    public static var milliSeconds:Int = 0;
    public static var seconds:Int = 0;
    public static var minutes:Int = 0;

    public static var activeStageList:Int = 0;
    public static var stageListPosition:Int = 0;
    public static var currentStageFolder:Array<Int> = [for (i in 0...0x100) 0];
    public static var actNumber:Int = 0;

    public static var titleCardText:Array<Int> = [for (i in 0...0x100) 0];
    public static var titleCardWord2:Int = 0;

    public static var activeTileLayers:Array<Int> = [0, 0, 0, 0];
    public static var tLayerMidPoint:Int = 0;
    public static var stageLayouts:Array<TileLayer> = [for (i in 0...LAYER_COUNT) new TileLayer()];

    public static var bgDeformationData1:Array<Int> = [for (i in 0...DEFORM_COUNT) 0];
    public static var bgDeformationData2:Array<Int> = [for (i in 0...DEFORM_COUNT) 0];
    public static var bgDeformationData3:Array<Int> = [for (i in 0...DEFORM_COUNT) 0];
    public static var bgDeformationData4:Array<Int> = [for (i in 0...DEFORM_COUNT) 0];

    public static var deformationPos1:Int = 0;
    public static var deformationPos2:Int = 0;
    public static var deformationPos3:Int = 0;
    public static var deformationPos4:Int = 0;

    public static var hParallax:LineScroll = new LineScroll();
    public static var vParallax:LineScroll = new LineScroll();

    public static var stageTiles:Tiles128x128 = new Tiles128x128();
    public static var tileCollisions:Array<CollisionMasks> = [new CollisionMasks(), new CollisionMasks()];

    public static var tileGfx:Array<Int> = [for (i in 0...TILESET_SIZE) 0];

    static var lastLoggedMode:Int = -1;
    public static function processStage():Void {
        if (stageMode != lastLoggedMode) {
            Debug.printLog("processStage: mode changed to " + stageMode);
            lastLoggedMode = stageMode;
        }
        switch (stageMode) {
            case STAGEMODE_LOAD:
                Video.stopVideoPlayback();
                cameraEnabled = 1;
                xScrollOffset = 0;
                yScrollOffset = 0;
                pauseEnabled = false;
                timeEnabled = false;
                milliSeconds = 0;
                seconds = 0;
                minutes = 0;
                loadStageFiles();
                for (i in 0...PLAYER_COUNT) {
                    PlayerManager.playerList[i].visible = 1;
                    PlayerManager.playerList[i].state = 0;
                    PlayerManager.playerList[i].collisionPlane = 0;
                    PlayerManager.playerList[i].collisionMode = 0;
                    PlayerManager.playerList[i].gravity = 1;
                    PlayerManager.playerList[i].yVelocity = 0;
                    PlayerManager.playerList[i].xVelocity = 0;
                    PlayerManager.playerList[i].speed = 0;
                    PlayerManager.playerList[i].direction = 0;
                    PlayerManager.playerList[i].tileCollisions = 1;
                    PlayerManager.playerList[i].objectInteraction = 1;
                }
                stageMode = STAGEMODE_NORMAL;
            case STAGEMODE_NORMAL:
                if (Palette.paletteMode > 0)
                    Palette.paletteMode--;
                lastXSize = -1;
                lastYSize = -1;
                Input.checkKeyDown(Input.gKeyDown, 0xFF);
                Input.checkKeyPress(Input.gKeyPress, 0xFF);
                if (pauseEnabled && Input.gKeyPress.start != 0) {
                    stageMode = STAGEMODE_PAUSED;
                    Audio.pauseSound();
                }
                if (timeEnabled) {
                    if (++frameCounter == 60) {
                        frameCounter = 0;
                        if (++seconds > 59) {
                            seconds = 0;
                            if (++minutes > 59)
                                minutes = 0;
                        }
                    }
                    milliSeconds = Std.int(100 * frameCounter / 60);
                }
                processObjects();
                if (Object.objectEntityList[0].type == 1) {
                    if (cameraEnabled != 0) {
                        switch (cameraStyle) {
                            case CAMERASTYLE_FOLLOW: setPlayerScreenPosition(PlayerManager.playerList[0]);
                            case CAMERASTYLE_EXTENDED: setPlayerScreenPositionCDStyle(PlayerManager.playerList[0]);
                            default:
                        }
                    } else {
                        setPlayerLockedScreenPosition(PlayerManager.playerList[0]);
                    }
                }
                drawStageGfx();
                Drawing.flipScreen();
            case STAGEMODE_PAUSED:
                if (Palette.paletteMode > 0)
                    Palette.paletteMode--;
                lastXSize = -1;
                lastYSize = -1;
                Input.checkKeyDown(Input.gKeyDown, 0xFF);
                Input.checkKeyPress(Input.gKeyPress, 0xFF);
                if (Input.gKeyPress.C != 0) {
                    Input.gKeyPress.C = 0;
                    if (timeEnabled) {
                        if (++frameCounter == 60) {
                            frameCounter = 0;
                            if (++seconds > 59) {
                                seconds = 0;
                                if (++minutes > 59)
                                    minutes = 0;
                            }
                        }
                        milliSeconds = Std.int(100 * frameCounter / 60);
                    }
                    processObjects();
                    if (Object.objectEntityList[0].type == 1) {
                        if (cameraEnabled != 0) {
                            switch (cameraStyle) {
                                case CAMERASTYLE_FOLLOW: setPlayerScreenPosition(PlayerManager.playerList[0]);
                                case CAMERASTYLE_EXTENDED: setPlayerScreenPositionCDStyle(PlayerManager.playerList[0]);
                                default:
                            }
                        } else {
                            setPlayerLockedScreenPosition(PlayerManager.playerList[0]);
                        }
                    }
                    drawStageGfx();
                }
                if (Input.gKeyPress.start != 0) {
                    stageMode = STAGEMODE_NORMAL;
                    Audio.resumeSound();
                }
            default:
        }
    }

    public static function loadStageFiles():Void {
        Audio.stopAllSfx();
        var infoStore = new FileInfo();
        var info = new FileInfo();
        var fileBuffer:Int = 0;
        var fileBuffer2:Int = 0;
        var scriptID:Int = 2;
        var strBuffer:Array<Int> = [for (i in 0...0x100) 0];

        if (!checkCurrentStageFolder(stageListPosition)) {
            Debug.printLog("Loading Scene " + stageListNames[activeStageList] + " - " + RetroString.arrayToString(stageList[activeStageList][stageListPosition].name));
            Audio.releaseStageSfx();
            Palette.loadPalette("Data/Palettes/MasterPalette.act", 0, 256);
            if (activeStageList >= 1) {
                PlayerManager.loadPlayerFromList(0, 0);
            }
            Script.clearScriptData();
            for (i in 0...SPRITESHEETS_MAX) Sprite.removeGraphicsFile("", SPRITESHEETS_MAX - 1 - i);

            var loadGlobals = false;
            if (loadStageFile("StageConfig.bin", stageListPosition, info)) {
                loadGlobals = Reader.fileReadByte() != 0;
                Reader.closeFile();
            }
            if (loadGlobals && Reader.loadFile("Data/Game/GameConfig.bin", info)) {
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();

                var globalScriptCount = Reader.fileReadByte();
                for (i in 0...globalScriptCount) {
                    fileBuffer2 = Reader.fileReadByte();
                    for (j in 0...fileBuffer2) strBuffer[j] = Reader.fileReadByte();
                    strBuffer[fileBuffer2] = 0;
                    Reader.getFileInfo(infoStore);
                    Reader.closeFile();
                    Script.parseScriptFile(RetroString.arrayToString(strBuffer), scriptID++);
                    Reader.setFileInfo(infoStore);
                }
                Reader.closeFile();
            }

            if (loadStageFile("StageConfig.bin", stageListPosition, info)) {
                Reader.fileReadByte();
                for (i in 96...128) {
                    var r = Reader.fileReadByte();
                    var g = Reader.fileReadByte();
                    var b = Reader.fileReadByte();
                    Palette.setPaletteEntry(i, r, g, b);
                }

                var stageScriptCount = Reader.fileReadByte();
                for (i in 0...stageScriptCount) {
                    fileBuffer2 = Reader.fileReadByte();
                    for (j in 0...fileBuffer2) strBuffer[j] = Reader.fileReadByte();
                    strBuffer[fileBuffer2] = 0;
                    Reader.getFileInfo(infoStore);
                    Reader.closeFile();
                    Script.parseScriptFile(RetroString.arrayToString(strBuffer), scriptID + i);
                    Reader.setFileInfo(infoStore);
                }

                fileBuffer2 = Reader.fileReadByte();
                Audio.noStageSFX = fileBuffer2;
                for (i in 0...Audio.noStageSFX) {
                    fileBuffer2 = Reader.fileReadByte();
                    for (j in 0...fileBuffer2) strBuffer[j] = Reader.fileReadByte();
                    strBuffer[fileBuffer2] = 0;
                    Reader.getFileInfo(infoStore);
                    Reader.closeFile();
                    Audio.loadSfx(RetroString.arrayToString(strBuffer), Audio.noGlobalSFX + i);
                    Reader.setFileInfo(infoStore);
                }
                Reader.closeFile();
            }

            for (p in 0...PLAYER_COUNT) {
                if (PlayerManager.playerScriptList[p].scriptPath[0] != 0)
                    Script.parseScriptFile(RetroString.arrayToString(PlayerManager.playerScriptList[p].scriptPath), p);
            }

            loadStageGIFFile(stageListPosition);
            load128x128Mappings();
            loadStageCollisions();
            loadStageBackground();
        } else {
            Debug.printLog("Reloading Scene " + stageListNames[activeStageList] + " - " + RetroString.arrayToString(stageList[activeStageList][stageListPosition].name));
        }

        for (i in 0...Audio.TRACK_COUNT) Audio.setMusicTrack("", i, false);
        for (i in 0...Object.ENTITY_COUNT) {
            var ent = Object.objectEntityList[i];
            ent.type = 0; ent.propertyValue = 0; ent.xPos = 0; ent.yPos = 0;
            ent.direction = 0; ent.frame = 0; ent.priority = 0; ent.rotation = 0;
            ent.state = 0; ent.drawOrder = 3; ent.scale = 512; ent.inkEffect = 0;
            for (v in 0...8) ent.values[v] = 0;
        }
        loadActLayout();
        processStartupScripts();

        var screenCenterX = Std.int(Drawing.SCREEN_XSIZE / 2);
        xScrollA = (PlayerManager.playerList[0].xPos >> 16) - screenCenterX;
        xScrollB = (PlayerManager.playerList[0].xPos >> 16) - (screenCenterX + Drawing.SCREEN_XSIZE);
        yScrollA = (PlayerManager.playerList[0].yPos >> 16) - SCREEN_SCROLL_UP;
        yScrollB = (PlayerManager.playerList[0].yPos >> 16) - (SCREEN_SCROLL_UP + Drawing.SCREEN_YSIZE);
    }

    public static function loadActFile(ext:String, stageID:Int, info:FileInfo):Bool {
        var dest:Array<Int> = [for (i in 0...0x40) 0];
        RetroString.strCopy(dest, "Data/Stages/");
        RetroString.strAddArr(dest, stageList[activeStageList][stageID].folder);
        RetroString.strAdd(dest, "/Act");
        RetroString.strAddArr(dest, stageList[activeStageList][stageID].id);
        RetroString.strAdd(dest, ext);
        var result = Script.convertStringToInteger(stageList[activeStageList][stageID].id);
        if (result.success) actNumber = result.value;
        return Reader.loadFile(RetroString.arrayToString(dest), info);
    }

    public static function loadStageFile(filePath:String, stageID:Int, info:FileInfo):Bool {
        var dest:Array<Int> = [for (i in 0...0x40) 0];
        RetroString.strCopy(dest, "Data/Stages/");
        RetroString.strAddArr(dest, stageList[activeStageList][stageID].folder);
        RetroString.strAdd(dest, "/");
        RetroString.strAdd(dest, filePath);
        return Reader.loadFile(RetroString.arrayToString(dest), info);
    }

    public static function loadActLayout():Void {
        var info = new FileInfo();
        if (loadActFile(".bin", stageListPosition, info)) {
            var length = Reader.fileReadByte();
            titleCardWord2 = length;
            for (i in 0...length) {
                titleCardText[i] = Reader.fileReadByte();
                if (titleCardText[i] == "-".code)
                    titleCardWord2 = i + 1;
            }
            titleCardText[length] = 0;

            for (i in 0...4) activeTileLayers[i] = Reader.fileReadByte();
            tLayerMidPoint = Reader.fileReadByte();

            stageLayouts[0].xsize = Reader.fileReadByte();
            stageLayouts[0].ysize = Reader.fileReadByte();
            xBoundary1 = 0;
            newXBoundary1 = 0;
            yBoundary1 = 0;
            newYBoundary1 = 0;
            xBoundary2 = stageLayouts[0].xsize << 7;
            yBoundary2 = stageLayouts[0].ysize << 7;
            waterLevel = yBoundary2 + 128;
            newXBoundary2 = stageLayouts[0].xsize << 7;
            newYBoundary2 = stageLayouts[0].ysize << 7;

            for (i in 0...0x10000) stageLayouts[0].tiles[i] = 0;

            for (y in 0...stageLayouts[0].ysize) {
                for (x in 0...stageLayouts[0].xsize) {
                    var fileBuffer = Reader.fileReadByte();
                    stageLayouts[0].tiles[y * 0x100 + x] = fileBuffer << 8;
                    fileBuffer = Reader.fileReadByte();
                    stageLayouts[0].tiles[y * 0x100 + x] += fileBuffer;
                }
            }

            var typenameCnt = Reader.fileReadByte();
            if (typenameCnt != 0) {
                for (i in 0...typenameCnt) {
                    var nameLen = Reader.fileReadByte();
                    for (l in 0...nameLen) Reader.fileReadByte();
                }
            }

            var objectCount = Reader.fileReadByte();
            objectCount = (objectCount << 8) + Reader.fileReadByte();
            var objectSlot = 32;
            for (i in 0...objectCount) {
                var obj = Object.objectEntityList[objectSlot];
                obj.type = Reader.fileReadByte();
                obj.propertyValue = Reader.fileReadByte();
                obj.xPos = Reader.fileReadByte() << 8;
                obj.xPos += Reader.fileReadByte();
                obj.xPos <<= 16;
                obj.yPos = Reader.fileReadByte() << 8;
                obj.yPos += Reader.fileReadByte();
                obj.yPos <<= 16;

                if (obj.type == 1 && PlayerManager.playerList[0].type == obj.propertyValue) {
                    var player = Object.objectEntityList[0];
                    player.type = 1;
                    player.drawOrder = 4;
                    player.priority = 1;
                    PlayerManager.playerList[0].xPos = obj.xPos;
                    PlayerManager.playerList[0].yPos = obj.yPos;
                    PlayerManager.setMovementStats(PlayerManager.playerList[0].stats);
                    PlayerManager.playerList[0].walkingSpeed = PlayerManager.playerScriptList[PlayerManager.playerList[0].type].startWalkSpeed;
                    PlayerManager.playerList[0].runningSpeed = PlayerManager.playerScriptList[PlayerManager.playerList[0].type].startRunSpeed;
                    PlayerManager.playerList[0].jumpingSpeed = PlayerManager.playerScriptList[PlayerManager.playerList[0].type].startJumpSpeed;
                    obj.type = 0;
                }
                objectSlot++;
            }
            stageLayouts[0].type = LAYER_HSCROLL;
            Reader.closeFile();
        }
    }

    public static function loadStageBackground():Void {
        for (i in 0...LAYER_COUNT) {
            stageLayouts[i].type = LAYER_NOSCROLL;
        }
        for (i in 0...PARALLAX_COUNT) {
            hParallax.scrollPos[i] = 0;
            vParallax.scrollPos[i] = 0;
        }

        var info = new FileInfo();
        if (loadStageFile("Backgrounds.bin", stageListPosition, info)) {
            var layerCount = Reader.fileReadByte();
            hParallax.entryCount = Reader.fileReadByte();
            for (i in 0...hParallax.entryCount) {
                hParallax.parallaxFactor[i] = Reader.fileReadByte();
                hParallax.scrollSpeed[i] = Reader.fileReadByte() << 10;
                hParallax.scrollPos[i] = 0;
                hParallax.deform[i] = Reader.fileReadByte();
            }

            vParallax.entryCount = Reader.fileReadByte();
            for (i in 0...vParallax.entryCount) {
                vParallax.parallaxFactor[i] = Reader.fileReadByte();
                vParallax.scrollSpeed[i] = Reader.fileReadByte() << 10;
                vParallax.scrollPos[i] = 0;
                vParallax.deform[i] = Reader.fileReadByte();
            }

            for (i in 1...layerCount + 1) {
                stageLayouts[i].xsize = Reader.fileReadByte();
                stageLayouts[i].ysize = Reader.fileReadByte();
                stageLayouts[i].type = Reader.fileReadByte();
                stageLayouts[i].parallaxFactor = Reader.fileReadByte();
                stageLayouts[i].scrollSpeed = Reader.fileReadByte() << 10;
                stageLayouts[i].scrollPos = 0;

                for (t in 0...TileLayer.TILELAYER_CHUNK_MAX) stageLayouts[i].tiles[t] = 0;
                for (t in 0...0x7FFF) stageLayouts[i].lineScroll[t] = 0;

                var lineScrollIdx = 0;
                while (true) {
                    var buf0 = Reader.fileReadByte();
                    if (buf0 == 0xFF) {
                        var buf1 = Reader.fileReadByte();
                        if (buf1 == 0xFF) {
                            break;
                        } else {
                            var buf2 = Reader.fileReadByte();
                            var cnt = buf2 - 1;
                            for (c in 0...cnt) stageLayouts[i].lineScroll[lineScrollIdx++] = buf1;
                        }
                    } else {
                        stageLayouts[i].lineScroll[lineScrollIdx++] = buf0;
                    }
                }

                for (y in 0...stageLayouts[i].ysize) {
                    for (x in 0...stageLayouts[i].xsize) {
                        stageLayouts[i].tiles[y * 0x100 + x] += Reader.fileReadByte();
                    }
                }
            }
            Reader.closeFile();
        }
    }

    public static function load128x128Mappings():Void {
        var info = new FileInfo();
        if (loadStageFile("128x128Tiles.bin", stageListPosition, info)) {
            for (i in 0...Tiles128x128.CHUNKTILE_COUNT) {
                var entry0 = Reader.fileReadByte();
                var entry1 = Reader.fileReadByte();
                var entry2 = Reader.fileReadByte();
                entry0 -= ((entry0 >> 6) << 6);
                stageTiles.visualPlane[i] = entry0 >> 4;
                entry0 -= 16 * (entry0 >> 4);
                stageTiles.direction[i] = entry0 >> 2;
                entry0 -= 4 * (entry0 >> 2);
                stageTiles.tileIndex[i] = entry1 + (entry0 << 8);
                stageTiles.gfxDataPos[i] = stageTiles.tileIndex[i] << 8;
                stageTiles.collisionFlags[0][i] = entry2 >> 4;
                stageTiles.collisionFlags[1][i] = entry2 - ((entry2 >> 4) << 4);
            }
            Reader.closeFile();
        }
    }

    public static function loadStageCollisions():Void {
        var info = new FileInfo();
        if (loadStageFile("CollisionMasks.bin", stageListPosition, info)) {
            var tileIndex = 0;
            for (t in 0...1024) {
                for (p in 0...2) {
                    var fileBuffer = Reader.fileReadByte();
                    var isCeiling = fileBuffer >> 4;
                    tileCollisions[p].flags[t] = fileBuffer & 0xF;
                    tileCollisions[p].angles[t] = Reader.fileReadByte();
                    tileCollisions[p].angles[t] += Reader.fileReadByte() << 8;
                    tileCollisions[p].angles[t] += Reader.fileReadByte() << 16;
                    tileCollisions[p].angles[t] += Reader.fileReadByte() << 24;

                    if (isCeiling != 0) {
                        for (c in 0...Std.int(TILE_SIZE / 2)) {
                            fileBuffer = Reader.fileReadByte();
                            tileCollisions[p].roofMasks[c * 2 + tileIndex] = fileBuffer >> 4;
                            tileCollisions[p].roofMasks[c * 2 + tileIndex + 1] = fileBuffer & 0xF;
                        }
                        fileBuffer = Reader.fileReadByte();
                        var id = 1;
                        for (c in 0...Std.int(TILE_SIZE / 2)) {
                            if ((fileBuffer & id) != 0) {
                                tileCollisions[p].floorMasks[c + tileIndex + 8] = 0;
                            } else {
                                tileCollisions[p].floorMasks[c + tileIndex + 8] = 0x40;
                                tileCollisions[p].roofMasks[c + tileIndex + 8] = -0x40;
                            }
                            id <<= 1;
                        }
                        fileBuffer = Reader.fileReadByte();
                        id = 1;
                        for (c in 0...Std.int(TILE_SIZE / 2)) {
                            if ((fileBuffer & id) != 0) {
                                tileCollisions[p].floorMasks[c + tileIndex] = 0;
                            } else {
                                tileCollisions[p].floorMasks[c + tileIndex] = 0x40;
                                tileCollisions[p].roofMasks[c + tileIndex] = -0x40;
                            }
                            id <<= 1;
                        }
                        for (c in 0...TILE_SIZE) {
                            var h = 0;
                            while (h > -1) {
                                if (h >= TILE_SIZE) {
                                    tileCollisions[p].lWallMasks[c + tileIndex] = 0x40;
                                    h = -1;
                                } else if (c > tileCollisions[p].roofMasks[h + tileIndex]) {
                                    ++h;
                                } else {
                                    tileCollisions[p].lWallMasks[c + tileIndex] = h;
                                    h = -1;
                                }
                            }
                        }
                        for (c in 0...TILE_SIZE) {
                            var h = TILE_SIZE - 1;
                            while (h < TILE_SIZE) {
                                if (h <= -1) {
                                    tileCollisions[p].rWallMasks[c + tileIndex] = -0x40;
                                    h = TILE_SIZE;
                                } else if (c > tileCollisions[p].roofMasks[h + tileIndex]) {
                                    --h;
                                } else {
                                    tileCollisions[p].rWallMasks[c + tileIndex] = h;
                                    h = TILE_SIZE;
                                }
                            }
                        }
                    } else {
                        for (c in 0...Std.int(TILE_SIZE / 2)) {
                            fileBuffer = Reader.fileReadByte();
                            tileCollisions[p].floorMasks[c * 2 + tileIndex] = fileBuffer >> 4;
                            tileCollisions[p].floorMasks[c * 2 + tileIndex + 1] = fileBuffer & 0xF;
                        }
                        fileBuffer = Reader.fileReadByte();
                        var id = 1;
                        for (c in 0...Std.int(TILE_SIZE / 2)) {
                            if ((fileBuffer & id) != 0) {
                                tileCollisions[p].roofMasks[c + tileIndex + 8] = 0xF;
                            } else {
                                tileCollisions[p].floorMasks[c + tileIndex + 8] = 0x40;
                                tileCollisions[p].roofMasks[c + tileIndex + 8] = -0x40;
                            }
                            id <<= 1;
                        }
                        fileBuffer = Reader.fileReadByte();
                        id = 1;
                        for (c in 0...Std.int(TILE_SIZE / 2)) {
                            if ((fileBuffer & id) != 0) {
                                tileCollisions[p].roofMasks[c + tileIndex] = 0xF;
                            } else {
                                tileCollisions[p].floorMasks[c + tileIndex] = 0x40;
                                tileCollisions[p].roofMasks[c + tileIndex] = -0x40;
                            }
                            id <<= 1;
                        }
                        for (c in 0...TILE_SIZE) {
                            var h = 0;
                            while (h > -1) {
                                if (h >= TILE_SIZE) {
                                    tileCollisions[p].lWallMasks[c + tileIndex] = 0x40;
                                    h = -1;
                                } else if (c < tileCollisions[p].floorMasks[h + tileIndex]) {
                                    ++h;
                                } else {
                                    tileCollisions[p].lWallMasks[c + tileIndex] = h;
                                    h = -1;
                                }
                            }
                        }
                        for (c in 0...TILE_SIZE) {
                            var h = TILE_SIZE - 1;
                            while (h < TILE_SIZE) {
                                if (h <= -1) {
                                    tileCollisions[p].rWallMasks[c + tileIndex] = -0x40;
                                    h = TILE_SIZE;
                                } else if (c < tileCollisions[p].floorMasks[h + tileIndex]) {
                                    --h;
                                } else {
                                    tileCollisions[p].rWallMasks[c + tileIndex] = h;
                                    h = TILE_SIZE;
                                }
                            }
                        }
                    }
                }
                tileIndex += 16;
            }
            Reader.closeFile();
        }
    }

    public static function loadStageGIFFile(stageID:Int):Void {
        var filePath = "Data/Stages/" + RetroString.arrayToString(stageList[activeStageList][stageID].folder) + "/16x16Tiles.gif";
        var fileBytes = Reader.loadFileAsBytes(filePath);
        if (fileBytes == null) {
            Debug.printLog("loadStageGIFFile: Failed to load: " + filePath);
            return;
        }
        
        var gif = IndexedGif.parse(fileBytes);
        
        if (gif == null || gif.pixels.length == 0) {
            Debug.printLog("loadStageGIFFile: Failed to decode GIF");
            return;
        }
        
        if (gif.palette.length == 256) {
            for (c in 0x80...0x100) {
                var color = gif.palette[c];
                var r = (color >> 16) & 0xFF;
                var g = (color >> 8) & 0xFF;
                var b = color & 0xFF;
                Palette.setPaletteEntry(c, r, g, b);
            }
        }
        
        for (i in 0...gif.pixels.length) {
            tileGfx[i] = gif.pixels[i];
        }
        
        var transparent = tileGfx[0];
        for (i in 0...0x40000) {
            if (i < tileGfx.length && tileGfx[i] == transparent)
                tileGfx[i] = 0;
        }
    }

    public static function loadStageGFXFile(stageID:Int):Void {
        var info = new FileInfo();
        if (loadStageFile("16x16Tiles.gfx", stageID, info)) {
            var width = Reader.fileReadByte() << 8;
            width += Reader.fileReadByte();
            var height = Reader.fileReadByte() << 8;
            height += Reader.fileReadByte();

            for (i in 0...0x80) { Reader.fileReadByte(); Reader.fileReadByte(); Reader.fileReadByte(); }
            for (c in 0x80...0x100) {
                var r = Reader.fileReadByte();
                var g = Reader.fileReadByte();
                var b = Reader.fileReadByte();
                Palette.setPaletteEntry(c, r, g, b);
            }

            var gfxIdx = 0;
            while (true) {
                var buf0 = Reader.fileReadByte();
                if (buf0 == 0xFF) {
                    var buf1 = Reader.fileReadByte();
                    if (buf1 == 0xFF) {
                        break;
                    } else {
                        var buf2 = Reader.fileReadByte();
                        for (i in 0...buf2) tileGfx[gfxIdx++] = buf1;
                    }
                } else {
                    tileGfx[gfxIdx++] = buf0;
                }
            }

            var transparent = tileGfx[0];
            for (i in 0...0x40000) {
                if (tileGfx[i] == transparent)
                    tileGfx[i] = 0;
            }
            Reader.closeFile();
        }
    }

    public static function resetBackgroundSettings():Void {
        for (i in 0...LAYER_COUNT) {
            stageLayouts[i].scrollPos = 0;
        }
        for (i in 0...PARALLAX_COUNT) {
            hParallax.scrollPos[i] = 0;
            vParallax.scrollPos[i] = 0;
        }
    }

    public static function resetCurrentStageFolder():Void {
        currentStageFolder[0] = 0;
    }

    public static function checkCurrentStageFolder(stage:Int):Bool {
        if (RetroString.strComp(currentStageFolder, stageList[activeStageList][stage].folder)) {
            return true;
        } else {
            RetroString.strCopyArray(currentStageFolder, stageList[activeStageList][stage].folder);
            return false;
        }
    }

    public static function setPlayerScreenPosition(player:Player):Void {
        var script = PlayerManager.playerScriptList[player.type];
        var playerXPos = player.xPos >> 16;
        var playerYPos = player.yPos >> 16;
        var screenCenterX = Std.int(Drawing.SCREEN_XSIZE / 2);

        if (newYBoundary1 > yBoundary1) {
            if (yScrollOffset <= newYBoundary1) yBoundary1 = yScrollOffset;
            else yBoundary1 = newYBoundary1;
        }
        if (newYBoundary1 < yBoundary1) {
            if (yScrollOffset <= yBoundary1) --yBoundary1;
            else yBoundary1 = newYBoundary1;
        }
        if (newYBoundary2 < yBoundary2) {
            if (yScrollOffset + Drawing.SCREEN_YSIZE >= yBoundary2 || yScrollOffset + Drawing.SCREEN_YSIZE <= newYBoundary2) --yBoundary2;
            else yBoundary2 = yScrollOffset + Drawing.SCREEN_YSIZE;
        }
        if (newYBoundary2 > yBoundary2) {
            if (yScrollOffset + Drawing.SCREEN_YSIZE >= yBoundary2) ++yBoundary2;
            else yBoundary2 = newYBoundary2;
        }
        if (newXBoundary1 > xBoundary1) {
            if (xScrollOffset <= newXBoundary1) xBoundary1 = xScrollOffset;
            else xBoundary1 = newXBoundary1;
        }
        if (newXBoundary1 < xBoundary1) {
            if (xScrollOffset <= xBoundary1) --xBoundary1;
            else xBoundary1 = newXBoundary1;
        }
        if (newXBoundary2 < xBoundary2) {
            if (xScrollOffset + Drawing.SCREEN_XSIZE >= xBoundary2) xBoundary2 = xScrollOffset + Drawing.SCREEN_XSIZE;
            else xBoundary2 = newXBoundary2;
        }
        if (newXBoundary2 > xBoundary2) {
            if (xScrollOffset + Drawing.SCREEN_XSIZE >= xBoundary2) ++xBoundary2;
            else xBoundary2 = newXBoundary2;
        }

        var lxScrollA = xScrollA;
        var lxScrollB = xScrollB;
        var scrollAmount = playerXPos - (xScrollA + screenCenterX);
        if (intAbs(scrollAmount) >= 25) {
            if (scrollAmount <= 0) lxScrollA -= 16;
            else lxScrollA += 16;
            lxScrollB = lxScrollA + Drawing.SCREEN_XSIZE;
        } else {
            if (playerXPos > lxScrollA + screenScrollRight) {
                lxScrollA = playerXPos - screenScrollRight;
                lxScrollB = playerXPos - screenScrollRight + Drawing.SCREEN_XSIZE;
            }
            if (playerXPos < lxScrollA + screenScrollLeft) {
                lxScrollA = playerXPos - screenScrollLeft;
                lxScrollB = playerXPos - screenScrollLeft + Drawing.SCREEN_XSIZE;
            }
        }
        if (lxScrollA < xBoundary1) {
            lxScrollA = xBoundary1;
            lxScrollB = xBoundary1 + Drawing.SCREEN_XSIZE;
        }
        if (lxScrollB > xBoundary2) {
            lxScrollB = xBoundary2;
            lxScrollA = xBoundary2 - Drawing.SCREEN_XSIZE;
        }
        xScrollA = lxScrollA;
        xScrollB = lxScrollB;

        if (playerXPos <= lxScrollA + screenCenterX) {
            player.screenXPos = earthquakeX + playerXPos - lxScrollA;
            xScrollOffset = lxScrollA - earthquakeX;
        } else {
            xScrollOffset = playerXPos + earthquakeX - screenCenterX;
            player.screenXPos = screenCenterX - earthquakeX;
            if (playerXPos > lxScrollB - screenCenterX) {
                player.screenXPos = playerXPos - (lxScrollB - screenCenterX) + earthquakeX + screenCenterX;
                xScrollOffset = lxScrollB - Drawing.SCREEN_XSIZE - earthquakeX;
            }
        }

        var lyscrollA = yScrollA;
        var lyscrollB = yScrollB;
        var hitboxDiff = Animation.playerCBoxes[0].bottom[0] - Collision.getPlayerCBoxInstance(player, script).bottom[0];
        var adjustYPos = playerYPos - hitboxDiff;
        var adjustAmount = player.lookPos + adjustYPos - (yScrollA + SCREEN_SCROLL_UP);

        if (player.trackScroll != 0) {
            yScrollMove = 32;
        } else {
            if (yScrollMove == 32) {
                yScrollMove = 2 * ((hitboxDiff + SCREEN_SCROLL_UP - player.screenYPos - player.lookPos) >> 1);
                if (yScrollMove > 32) yScrollMove = 32;
                if (yScrollMove < -32) yScrollMove = -32;
            }
            if (yScrollMove > 0) yScrollMove -= 6;
            yScrollMove += yScrollMove < 0 ? 6 : 0;
        }

        var absAdjust = intAbs(adjustAmount);
        if (absAdjust >= intAbs(yScrollMove) + 17) {
            if (adjustAmount <= 0) lyscrollA -= 16;
            else lyscrollA += 16;
            lyscrollB = lyscrollA + Drawing.SCREEN_YSIZE;
        } else if (yScrollMove == 32) {
            if (player.lookPos + adjustYPos > lyscrollA + yScrollMove + SCREEN_SCROLL_UP) {
                lyscrollA = player.lookPos + adjustYPos - (yScrollMove + SCREEN_SCROLL_UP);
                lyscrollB = lyscrollA + Drawing.SCREEN_YSIZE;
            }
            if (player.lookPos + adjustYPos < lyscrollA + SCREEN_SCROLL_UP - yScrollMove) {
                lyscrollA = player.lookPos + adjustYPos - (SCREEN_SCROLL_UP - yScrollMove);
                lyscrollB = lyscrollA + Drawing.SCREEN_YSIZE;
            }
        } else {
            lyscrollA = player.lookPos + adjustYPos + yScrollMove - SCREEN_SCROLL_UP;
            lyscrollB = lyscrollA + Drawing.SCREEN_YSIZE;
        }

        if (lyscrollA < yBoundary1) {
            lyscrollA = yBoundary1;
            lyscrollB = yBoundary1 + Drawing.SCREEN_YSIZE;
        }
        if (lyscrollB > yBoundary2) {
            lyscrollB = yBoundary2;
            lyscrollA = yBoundary2 - Drawing.SCREEN_YSIZE;
        }
        yScrollA = lyscrollA;
        yScrollB = lyscrollB;

        if (earthquakeY != 0) {
            if (earthquakeY <= 0) earthquakeY = ~earthquakeY;
            else earthquakeY = -earthquakeY;
        }

        if (player.lookPos + adjustYPos <= lyscrollA + SCREEN_SCROLL_UP) {
            player.screenYPos = adjustYPos - lyscrollA - earthquakeY;
            yScrollOffset = earthquakeY + lyscrollA;
        } else {
            yScrollOffset = earthquakeY + adjustYPos + player.lookPos - SCREEN_SCROLL_UP;
            player.screenYPos = SCREEN_SCROLL_UP - player.lookPos - earthquakeY;
            if (player.lookPos + adjustYPos > lyscrollB - SCREEN_SCROLL_DOWN) {
                player.screenYPos = adjustYPos - (lyscrollB - SCREEN_SCROLL_DOWN) + earthquakeY + SCREEN_SCROLL_UP;
                yScrollOffset = lyscrollB - Drawing.SCREEN_YSIZE - earthquakeY;
            }
        }
        player.screenYPos += hitboxDiff;
    }

    public static function setPlayerScreenPositionCDStyle(player:Player):Void {
        var script = PlayerManager.playerScriptList[player.type];
        var playerXPos = player.xPos >> 16;
        var playerYPos = player.yPos >> 16;
        var screenCenterX = Std.int(Drawing.SCREEN_XSIZE / 2);

        if (newYBoundary1 > yBoundary1) {
            if (yScrollOffset <= newYBoundary1) yBoundary1 = yScrollOffset;
            else yBoundary1 = newYBoundary1;
        }
        if (newYBoundary1 < yBoundary1) {
            if (yScrollOffset <= yBoundary1) --yBoundary1;
            else yBoundary1 = newYBoundary1;
        }
        if (newYBoundary2 < yBoundary2) {
            if (yScrollOffset + Drawing.SCREEN_YSIZE >= yBoundary2 || yScrollOffset + Drawing.SCREEN_YSIZE <= newYBoundary2) --yBoundary2;
            else yBoundary2 = yScrollOffset + Drawing.SCREEN_YSIZE;
        }
        if (newYBoundary2 > yBoundary2) {
            if (yScrollOffset + Drawing.SCREEN_YSIZE >= yBoundary2) ++yBoundary2;
            else yBoundary2 = newYBoundary2;
        }
        if (newXBoundary1 > xBoundary1) {
            if (xScrollOffset <= newXBoundary1) xBoundary1 = xScrollOffset;
            else xBoundary1 = newXBoundary1;
        }
        if (newXBoundary1 < xBoundary1) {
            if (xScrollOffset <= xBoundary1) --xBoundary1;
            else xBoundary1 = newXBoundary1;
        }
        if (newXBoundary2 < xBoundary2) {
            if (xScrollOffset + Drawing.SCREEN_XSIZE >= xBoundary2) xBoundary2 = xScrollOffset + Drawing.SCREEN_XSIZE;
            else xBoundary2 = newXBoundary2;
        }
        if (newXBoundary2 > xBoundary2) {
            if (xScrollOffset + Drawing.SCREEN_XSIZE >= xBoundary2) ++xBoundary2;
            else xBoundary2 = newXBoundary2;
        }

        if (player.gravity == 0) {
            if (player.direction != 0) {
                if (player.animation == 8 || player.animation == 9 || player.speed < -0x5F5C2) {
                    if (xScrollMove < 64) xScrollMove += 2;
                } else {
                    xScrollMove += xScrollMove < 0 ? 2 : 0;
                    if (xScrollMove > 0) xScrollMove -= 2;
                }
            } else if (player.animation == 8 || player.animation == 9 || player.speed > 0x5F5C2) {
                if (xScrollMove > -64) xScrollMove -= 2;
            } else {
                xScrollMove += xScrollMove < 0 ? 2 : 0;
                if (xScrollMove > 0) xScrollMove -= 2;
            }
        }

        if (playerXPos <= xBoundary1 + xScrollMove + screenCenterX) {
            player.screenXPos = earthquakeX + playerXPos - xBoundary1;
            xScrollOffset = xBoundary1 - earthquakeX;
        } else {
            xScrollOffset = playerXPos + earthquakeX - xScrollMove - screenCenterX;
            player.screenXPos = xScrollMove - earthquakeX + screenCenterX;
            if (playerXPos - xScrollMove > xBoundary2 - screenCenterX) {
                player.screenXPos = earthquakeX + playerXPos - xBoundary2 + Drawing.SCREEN_XSIZE;
                xScrollOffset = xBoundary2 - Drawing.SCREEN_XSIZE - earthquakeX;
            }
        }

        xScrollA = xScrollOffset;
        xScrollB = xScrollA + Drawing.SCREEN_XSIZE;

        var lyscrollA = yScrollA;
        var lyscrollB = yScrollB;
        var hitboxDiff = Animation.playerCBoxes[0].bottom[0] - Collision.getPlayerCBoxInstance(player, script).bottom[0];
        var adjustY = playerYPos - hitboxDiff;
        var adjustOffset = player.lookPos + adjustY - (yScrollA + SCREEN_SCROLL_UP);

        if (player.trackScroll != 0) {
            yScrollMove = 32;
        } else {
            if (yScrollMove == 32) {
                yScrollMove = ((hitboxDiff + SCREEN_SCROLL_UP - player.screenYPos - player.lookPos) >> 1) << 1;
                if (yScrollMove > 32) yScrollMove = 32;
                if (yScrollMove < -32) yScrollMove = -32;
            }
            if (yScrollMove > 0) yScrollMove -= 6;
            yScrollMove += yScrollMove < 0 ? 6 : 0;
        }

        var absAdjust = intAbs(adjustOffset);
        if (absAdjust >= intAbs(yScrollMove) + 17) {
            if (adjustOffset <= 0) lyscrollA -= 16;
            else lyscrollA += 16;
            lyscrollB = lyscrollA + Drawing.SCREEN_YSIZE;
        } else if (yScrollMove == 32) {
            if (player.lookPos + adjustY > lyscrollA + yScrollMove + SCREEN_SCROLL_UP) {
                lyscrollA = player.lookPos + adjustY - (yScrollMove + SCREEN_SCROLL_UP);
                lyscrollB = lyscrollA + Drawing.SCREEN_YSIZE;
            }
            if (player.lookPos + adjustY < lyscrollA + SCREEN_SCROLL_UP - yScrollMove) {
                lyscrollA = player.lookPos + adjustY - (SCREEN_SCROLL_UP - yScrollMove);
                lyscrollB = lyscrollA + Drawing.SCREEN_YSIZE;
            }
        } else {
            lyscrollA = player.lookPos + adjustY + yScrollMove - SCREEN_SCROLL_UP;
            lyscrollB = lyscrollA + Drawing.SCREEN_YSIZE;
        }

        if (lyscrollA < yBoundary1) {
            lyscrollA = yBoundary1;
            lyscrollB = yBoundary1 + Drawing.SCREEN_YSIZE;
        }
        if (lyscrollB > yBoundary2) {
            lyscrollB = yBoundary2;
            lyscrollA = yBoundary2 - Drawing.SCREEN_YSIZE;
        }
        yScrollA = lyscrollA;
        yScrollB = lyscrollB;

        if (earthquakeY != 0) {
            if (earthquakeY <= 0) earthquakeY = ~earthquakeY;
            else earthquakeY = -earthquakeY;
        }

        if (player.lookPos + adjustY <= lyscrollA + SCREEN_SCROLL_UP) {
            player.screenYPos = adjustY - lyscrollA - earthquakeY;
            yScrollOffset = earthquakeY + lyscrollA;
        } else {
            yScrollOffset = earthquakeY + adjustY + player.lookPos - SCREEN_SCROLL_UP;
            player.screenYPos = SCREEN_SCROLL_UP - player.lookPos - earthquakeY;
            if (player.lookPos + adjustY > lyscrollB - SCREEN_SCROLL_DOWN) {
                player.screenYPos = adjustY - (lyscrollB - SCREEN_SCROLL_DOWN) + earthquakeY + SCREEN_SCROLL_UP;
                yScrollOffset = lyscrollB - Drawing.SCREEN_YSIZE - earthquakeY;
            }
        }
        player.screenYPos += hitboxDiff;
    }

    public static function setPlayerLockedScreenPosition(player:Player):Void {
        var script = PlayerManager.playerScriptList[player.type];
        var playerXPos = player.xPos >> 16;
        var playerYPos = player.yPos >> 16;
        var screenCenterX = Std.int(Drawing.SCREEN_XSIZE / 2);

        switch (cameraStyle) {
            case CAMERASTYLE_FOLLOW:
                if (playerXPos <= xBoundary1 + xScrollMove + screenCenterX) {
                    player.screenXPos = earthquakeX + playerXPos - xBoundary1;
                    xScrollOffset = xBoundary1 - earthquakeX;
                } else {
                    xScrollOffset = playerXPos + earthquakeX - screenCenterX - xScrollMove;
                    player.screenXPos = xScrollMove + screenCenterX - earthquakeX;
                    if (playerXPos > xBoundary2 + xScrollMove - screenCenterX) {
                        player.screenXPos = xScrollMove + playerXPos - (xBoundary2 - screenCenterX) + earthquakeX + screenCenterX;
                        xScrollOffset = xBoundary2 - Drawing.SCREEN_XSIZE - earthquakeX - xScrollMove;
                    }
                }
            case CAMERASTYLE_EXTENDED:
                var lxscrollA = xScrollA;
                var lxscrollB = xScrollB;
                if (playerXPos <= xScrollA + screenCenterX) {
                    player.screenXPos = earthquakeX + playerXPos - xScrollA;
                    xScrollOffset = lxscrollA - earthquakeX;
                } else {
                    xScrollOffset = playerXPos + earthquakeX - screenCenterX;
                    player.screenXPos = screenCenterX - earthquakeX;
                    if (playerXPos > lxscrollB - screenCenterX) {
                        player.screenXPos = playerXPos - (lxscrollB - screenCenterX) + earthquakeX + screenCenterX;
                        xScrollOffset = lxscrollB - Drawing.SCREEN_XSIZE - earthquakeX;
                    }
                }
            default:
        }

        var lyscrollA = yScrollA;
        var lyscrollB = yScrollB;
        var hitboxDiff = Animation.playerCBoxes[0].bottom[0] - Collision.getPlayerCBoxInstance(player, script).bottom[0];
        var adjustY = playerYPos - hitboxDiff;

        if (earthquakeY != 0) {
            if (earthquakeY <= 0) earthquakeY = ~earthquakeY;
            else earthquakeY = -earthquakeY;
        }

        if (player.lookPos + adjustY <= yScrollA + SCREEN_SCROLL_UP) {
            player.screenYPos = adjustY - yScrollA - earthquakeY;
            yScrollOffset = earthquakeY + lyscrollA;
        } else {
            yScrollOffset = earthquakeY + adjustY + player.lookPos - SCREEN_SCROLL_UP;
            player.screenYPos = SCREEN_SCROLL_UP - player.lookPos - earthquakeY;
            if (player.lookPos + adjustY > lyscrollB - SCREEN_SCROLL_DOWN) {
                player.screenYPos = adjustY - (lyscrollB - SCREEN_SCROLL_DOWN) + earthquakeY + SCREEN_SCROLL_UP;
                yScrollOffset = lyscrollB - Drawing.SCREEN_YSIZE - earthquakeY;
            }
        }
        player.screenYPos += hitboxDiff;
    }

    public static function processObjects():Void {
        Object.processObjects();
    }

    public static function processStartupScripts():Void {
        Object.processStartupScripts();
    }

    public static function drawStageGfx():Void {
        Drawing.drawStageGfx();
    }

    static inline function intAbs(v:Int):Int { return v < 0 ? -v : v; }
}