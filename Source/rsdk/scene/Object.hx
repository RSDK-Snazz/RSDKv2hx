package rsdk.scene;

import rsdk.scene.Player;
import rsdk.scene.Collision.Collision;
import rsdk.graphics.Animation;
import rsdk.graphics.Drawing;
import rsdk.input.Input;

class Entity {
    public var xPos:Int = 0;
    public var yPos:Int = 0;
    public var values:Array<Int> = [for (i in 0...8) 0];
    public var scale:Int = 512;
    public var rotation:Int = 0;
    public var type:Int = 0;
    public var propertyValue:Int = 0;
    public var state:Int = 0;
    public var priority:Int = 0;
    public var drawOrder:Int = 3;
    public var direction:Int = 0;
    public var inkEffect:Int = 0;
    public var frame:Int = 0;

    public function new() {}
}

class DrawListEntry {
    public var entityRefs:Array<Int> = [for (i in 0...Object.ENTITY_COUNT) 0];
    public var listSize:Int = 0;

    public function new() {}
}

enum abstract ObjectTypes(Int) to Int {
    var OBJ_TYPE_BLANKOBJECT = 0;
    var OBJ_TYPE_PLAYER = 1;
}

enum abstract ObjectPriority(Int) to Int {
    var PRIORITY_BOUNDS = 0;
    var PRIORITY_ALWAYS = 1;
}

enum abstract FlipFlags(Int) to Int {
    var FLIP_NONE = 0;
    var FLIP_X = 1;
    var FLIP_Y = 2;
    var FLIP_XY = 3;
}

enum abstract InkEffects(Int) to Int {
    var INK_NONE = 0;
    var INK_BLEND = 1;
    var INK_TINT = 2;
}

enum abstract DrawFX(Int) to Int {
    var FX_SCALE = 0;
    var FX_ROTATE = 1;
    var FX_INK = 2;
    var FX_TINT = 3;
}

enum abstract CollisionTypes(Int) to Int {
    var C_TOUCH = 0;
    var C_BOX = 1;
    var C_PLATFORM = 2;
}

class Object {
    public static inline var ENTITY_COUNT:Int = 0x4A0;
    public static inline var TEMPENTITY_START:Int = ENTITY_COUNT - 0x80;
    public static inline var OBJECT_COUNT:Int = 0x100;
    public static inline var DRAWLAYER_COUNT:Int = 8;

    public static inline var OBJ_TYPE_BLANKOBJECT:Int = 0;
    public static inline var OBJ_TYPE_PLAYER:Int = 1;

    public static var objectLoop:Int = 0;
    public static var curObjectType:Int = 0;
    public static var objectEntityList:Array<Entity> = [for (i in 0...ENTITY_COUNT) new Entity()];
    public static var objectDrawOrderList:Array<DrawListEntry> = [for (i in 0...DRAWLAYER_COUNT) new DrawListEntry()];

    public static var OBJECT_BORDER_X1:Int = 0x80;
    public static var OBJECT_BORDER_X2:Int = Drawing.SCREEN_XSIZE + 0x80;
    public static inline var OBJECT_BORDER_Y1:Int = 0x100;
    public static var OBJECT_BORDER_Y2:Int = Drawing.SCREEN_YSIZE + 0x100;

    public static function processStartupScripts():Void {
        Animation.scriptFramesNo = 0;
        Animation.clearAnimationData();
        PlayerManager.playerNo = 0;
        Script.scriptEng.arrayPosition[2] = TEMPENTITY_START;
        var entity = objectEntityList[TEMPENTITY_START];
        for (i in 0...OBJECT_COUNT) {
            var scriptInfo = Script.objectScriptList[i];
            objectLoop = TEMPENTITY_START;
            curObjectType = i;
            var frameStart = Animation.scriptFramesNo;
            scriptInfo.frameStartPtr = Animation.scriptFramesNo;
            scriptInfo.spriteSheetID = 0;
            entity.type = i;
            if (Script.scriptData[scriptInfo.subStartup.scriptCodePtr] > 0)
                Script.processScript(scriptInfo.subStartup.scriptCodePtr, scriptInfo.subStartup.jumpTablePtr, Script.SUB_SETUP);
            scriptInfo.frameCount = Animation.scriptFramesNo - frameStart;
        }
        entity.type = 0;
        curObjectType = 0;
        Animation.scriptFramesNo = 0;
    }

    static var processObjectsLogged:Bool = false;
    public static function processObjects():Void {
        for (i in 0...DRAWLAYER_COUNT)
            objectDrawOrderList[i].listSize = 0;

        var activeCount = 0;
        for (ol in 0...ENTITY_COUNT) {
            objectLoop = ol;
            var active = false;
            var x = 0;
            var y = 0;
            var entity = objectEntityList[objectLoop];

            if (entity.priority <= 0) {
                x = entity.xPos >> 16;
                y = entity.yPos >> 16;
                active = x > Scene.xScrollOffset - OBJECT_BORDER_X1 && x < OBJECT_BORDER_X2 + Scene.xScrollOffset
                    && y > Scene.yScrollOffset - OBJECT_BORDER_Y1 && y < Scene.yScrollOffset + OBJECT_BORDER_Y2;
            } else {
                active = true;
            }

            if (active && entity.type > OBJ_TYPE_BLANKOBJECT) {
                activeCount++;
                if (entity.type == OBJ_TYPE_PLAYER) {
                    if (objectLoop >= 2) {
                        entity.type = OBJ_TYPE_BLANKOBJECT;
                    } else {
                        var player = PlayerManager.playerList[objectLoop];
                        var script = PlayerManager.playerScriptList[objectLoop];
                        switch (entity.propertyValue) {
                            case 0:
                                PlayerManager.playerNo = objectLoop;
                                PlayerManager.processPlayerControl(player);
                                player.animationSpeed = 0;
                                if (Script.scriptData[script.scriptCodePtr_PlayerMain] > 0)
                                    Script.processScript(script.scriptCodePtr_PlayerMain, script.jumpTablePtr_PlayerMain, Script.SUB_PLAYERMAIN);
                                var stateBeforeScript = player.state;
                                var codePtr = script.scriptCodePtr_PlayerState[player.state];
                                if (Script.scriptData[codePtr] > 0) {
                                    Script.processScript(codePtr, script.jumpTablePtr_PlayerState[player.state], Script.SUB_PLAYERSTATE);
                                }
                                PlayerManager.processPlayerAnimation(player);
                                if (player.tileCollisions != 0)
                                    Collision.processPlayerTileCollisions(player);
                            case 1:
                                PlayerManager.processPlayerControl(player);
                                PlayerManager.processPlayerAnimation(player);
                                if (Script.scriptData[script.scriptCodePtr_PlayerMain] > 0)
                                    Script.processScript(script.scriptCodePtr_PlayerMain, script.jumpTablePtr_PlayerMain, Script.SUB_PLAYERMAIN);
                                if (player.tileCollisions != 0)
                                    Collision.processPlayerTileCollisions(player);
                            case 2:
                                PlayerManager.processPlayerControl(player);
                                PlayerManager.processDebugMode(player);
                                if (objectLoop == 0) {
                                    Scene.cameraEnabled = 1;
                                    if (Input.gKeyPress.B != 0) {
                                        player.tileCollisions = 1;
                                        player.objectInteraction = 1;
                                        player.controlMode = 0;
                                        objectEntityList[objectLoop].propertyValue = 0;
                                    }
                                }
                            default:
                        }
                        if (entity.drawOrder < DRAWLAYER_COUNT)
                            objectDrawOrderList[entity.drawOrder].entityRefs[objectDrawOrderList[entity.drawOrder].listSize++] = objectLoop;
                    }
                } else {
                    var scriptInfo = Script.objectScriptList[entity.type];
                    PlayerManager.playerNo = 0;
                    if (Script.scriptData[scriptInfo.subMain.scriptCodePtr] > 0)
                        Script.processScript(scriptInfo.subMain.scriptCodePtr, scriptInfo.subMain.jumpTablePtr, Script.SUB_MAIN);
                    if (Script.scriptData[scriptInfo.subPlayerInteraction.scriptCodePtr] > 0) {
                        while (PlayerManager.playerNo < PlayerManager.activePlayerCount) {
                            if (PlayerManager.playerList[PlayerManager.playerNo].objectInteraction != 0)
                                Script.processScript(scriptInfo.subPlayerInteraction.scriptCodePtr, scriptInfo.subPlayerInteraction.jumpTablePtr, Script.SUB_PLAYERINTERACTION);
                            ++PlayerManager.playerNo;
                        }
                    }
                    if (entity.drawOrder < DRAWLAYER_COUNT)
                        objectDrawOrderList[entity.drawOrder].entityRefs[objectDrawOrderList[entity.drawOrder].listSize++] = objectLoop;
                }
            }
        }
        if (!processObjectsLogged) {
            processObjectsLogged = true;
            var totalDraw = 0;
            for (i in 0...DRAWLAYER_COUNT) totalDraw += objectDrawOrderList[i].listSize;
            rsdk.core.Debug.printLog("processObjects: " + activeCount + " active entities, " + totalDraw + " in draw lists");
        }
    }
}
