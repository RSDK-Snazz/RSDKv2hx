package rsdk.core;

import rsdk.core.RetroMath;
import rsdk.core.RetroString;
import rsdk.core.Reader;
import rsdk.core.Debug;
import rsdk.graphics.Drawing;
import rsdk.graphics.Palette;
import rsdk.scene.Scene;
import rsdk.scene.Script;
import rsdk.audio.Audio;

enum RetroStates {
    ENGINE_SYSMENU;
    ENGINE_MAINGAME;
    ENGINE_INITSYSMENU;
    ENGINE_EXITGAME;
}

class RetroEngine {
    public static inline final ENGINE_DEVMENU:Int = 0;
    public static inline final ENGINE_MAINGAME:Int = 1;
    public static inline final ENGINE_INITDEVMENU:Int = 2;
    public static inline final ENGINE_EXITGAME:Int = 3;
    public static inline final ENGINE_SCRIPTERROR:Int = 4;
    public static inline final ENGINE_ENTER_HIRESMODE:Int = 5;
    public static inline final ENGINE_EXIT_HIRESMODE:Int = 6;
    public static inline final ENGINE_PAUSE:Int = 7;
    public static inline final ENGINE_WAIT:Int = 8;
    public static inline final SCREEN_YSIZE:Int = 240;
    public static inline final SCREEN_CENTERY:Int = 120;
    public static inline final BASE_PATH:String = "";

    public static var useBinFile:Bool = false;
    public static var usingDataFileStore:Bool = false;
    public static var forceFolder:Bool = false;

    public static var dataFile:Array<Int> = RetroString.createArray(0x80);

    public static var initialised:Bool = false;
    public static var gameRunning:Bool = false;
    public static var running:Bool = true;

    public static var gameMode:Int = 1;
    public static var colourMode:Int = 1;

    public static var frameSkipSetting:Int = 0;
    public static var frameSkipTimer:Int = 0;

    public static var startList_Game:Int = -1;
    public static var startStage_Game:Int = -1;

    public static var consoleEnabled:Bool = false;
    public static var devMenu:Bool = false;
    public static var engineDebugMode:Bool = false;
    public static var startList:Int = -1;
    public static var startStage:Int = -1;
    public static var gameSpeed:Int = 1;
    public static var fastForwardSpeed:Int = 8;
    public static var masterPaused:Bool = false;
    public static var frameStep:Bool = false;

    public static var startSceneFolder:Array<Int> = RetroString.createArray(0x10);
    public static var startSceneID:Array<Int> = RetroString.createArray(0x10);

    public static var gameWindowText:Array<Int> = RetroString.createArray(0x40);
    public static var gameDescriptionText:Array<Int> = RetroString.createArray(0x100);
    public static var gameVersion:Array<Int> = RetroString.createArray(0x40);

    public static var isFullScreen:Bool = false;
    public static var startFullScreen:Bool = false;
    public static var borderless:Bool = false;
    public static var vsync:Bool = false;
    public static var enhancedScaling:Bool = true;
    public static var windowScale:Int = 2;
    public static var refreshRate:Int = 60;
    public static var screenRefreshRate:Int = 60;
    public static var targetRefreshRate:Int = 60;

    public static var frameCount:Int = 0;
    public static var renderFrameIndex:Int = 0;
    public static var skipFrameIndex:Int = 0;

    public static var windowXSize:Int = 0;
    public static var windowYSize:Int = 0;

    public static function init():Void {
        RetroMath.calculateTrigAngles();
        rsdk.storage.Userdata.initUserdata();

        if (RetroString.arrayToString(dataFile) == "")
            RetroString.strCopy(dataFile, "Data.bin");

        var dest = BASE_PATH + RetroString.arrayToString(dataFile);
        Reader.checkBinFile(dest);

        gameMode = 3;
        gameRunning = false;

        if (loadGameConfig("Data/Game/GameConfig.bin")) {
            if (Drawing.initRenderDevice()) {
                if (Audio.initSoundDevice() != 0) {
                    initialised = true;
                    gameRunning = true;
                    gameMode = ENGINE_MAINGAME;
                    Scene.activeStageList = (startList_Game == 0xFF) ? 0 : startList_Game;
                    Scene.stageListPosition = (startStage_Game == 0xFF) ? 0 : startStage_Game;
                }
            }
        }

        var lower = getLowerRate(targetRefreshRate, refreshRate);
        renderFrameIndex = Std.int(targetRefreshRate / lower);
        skipFrameIndex = Std.int(refreshRate / lower);
    }

    public static function run():Void {
        Debug.printLog("Engine Run started");
    }

    public static function loadGameConfig(filePath:String):Bool {
        var info = new FileInfo();
        var fileBuffer:Int = 0;
        var fileBuffer2:Int = 0;

        if (Reader.loadFile(filePath, info)) {
            fileBuffer = Reader.fileReadByte();
            for (i in 0...fileBuffer) {
                gameWindowText[i] = Reader.fileReadByte();
            }
            gameWindowText[fileBuffer] = 0;

            fileBuffer = Reader.fileReadByte();
            for (i in 0...fileBuffer) {
                gameVersion[i] = Reader.fileReadByte();
            }
            gameVersion[fileBuffer] = 0;

            fileBuffer = Reader.fileReadByte();
            for (i in 0...fileBuffer) {
                gameDescriptionText[i] = Reader.fileReadByte();
            }
            gameDescriptionText[fileBuffer] = 0;

            var scriptCount = Reader.fileReadByte();
            for (s in 0...scriptCount) {
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();
            }

            var varCount = Reader.fileReadByte();
            Script.noGlobalVariables = varCount;
            for (v in 0...varCount) {
                fileBuffer = Reader.fileReadByte();
                var varName = "";
                for (i in 0...fileBuffer) {
                    varName += String.fromCharCode(Reader.fileReadByte());
                }
                Script.globalVariableNames[v] = varName;
                
                var value = Reader.fileReadByte() << 24;
                value += Reader.fileReadByte() << 16;
                value += Reader.fileReadByte() << 8;
                value += Reader.fileReadByte();
                Script.globalVariables[v] = value;
            }

            var sfxCount = Reader.fileReadByte();
            for (s in 0...sfxCount) {
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();
            }

            var playerCount = Reader.fileReadByte();
            for (p in 0...playerCount) {
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();
            }

            for (c in 0...4) {
                var cat = c;
                if (c == 2) cat = 3;
                else if (c == 3) cat = 2;
                fileBuffer = Reader.fileReadByte();
                Scene.stageListCount[cat] = fileBuffer;
                for (s in 0...fileBuffer) {
                    var len = Reader.fileReadByte();
                    for (i in 0...len) Scene.stageList[cat][s].folder[i] = Reader.fileReadByte();
                    Scene.stageList[cat][s].folder[len] = 0;
                    len = Reader.fileReadByte();
                    for (i in 0...len) Scene.stageList[cat][s].id[i] = Reader.fileReadByte();
                    Scene.stageList[cat][s].id[len] = 0;
                    len = Reader.fileReadByte();
                    for (i in 0...len) Scene.stageList[cat][s].name[i] = Reader.fileReadByte();
                    Scene.stageList[cat][s].name[len] = 0;
                    Scene.stageList[cat][s].highlighted = Reader.fileReadByte() != 0;
                }
            }

            Reader.closeFile();

            Debug.printLog("Loaded GameConfig: " + RetroString.arrayToString(gameWindowText));
            return true;
        }

        return false;
    }

    private static function getLowerRate(intendRate:Int, targetRate:Int):Int {
        var result = targetRate;
        var valStore = 0;
        if (intendRate != 0) {
            while (true) {
                valStore = result % intendRate;
                result = intendRate;
                intendRate = valStore;
                if (valStore == 0) break;
            }
        }
        return result;
    }
}