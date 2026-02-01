package rsdk.graphics;

import rsdk.core.Reader;
import rsdk.core.Reader.FileInfo;
import rsdk.core.Debug;
import rsdk.core.RetroString;
import rsdk.scene.Player.PlayerManager;

class SpriteFrame {
    public var sprX:Int = 0;
    public var sprY:Int = 0;
    public var width:Int = 0;
    public var height:Int = 0;
    public var pivotX:Int = 0;
    public var pivotY:Int = 0;
    public var sheetID:Int = 0;
    public var hitboxID:Int = 0;

    public function new() {}
}

class SpriteAnimation {
    public var frameCount:Int = 0;
    public var speed:Int = 0;
    public var loopPoint:Int = 0;
    public var frames:Array<SpriteFrame> = [];

    public function new() {}
}

class Hitbox {
    public var left:Array<Int> = [for (i in 0...8) 0];
    public var top:Array<Int> = [for (i in 0...8) 0];
    public var right:Array<Int> = [for (i in 0...8) 0];
    public var bottom:Array<Int> = [for (i in 0...8) 0];

    public function new() {}
}

class AnimFile {
    public var animCount:Int = 0;
    public var aniListOffset:Int = 0;

    public function new() {}
}

class Animation {
    public static inline var ANIFILE_COUNT:Int = 0x100;
    public static inline var ANIMATION_COUNT:Int = 0x400;
    public static inline var SPRITEFRAME_COUNT:Int = 0x1000;
    public static inline var HITBOX_COUNT:Int = 0x20;
    public static inline var HITBOX_DIR_COUNT:Int = 0x8;

    public static var scriptFrames:Array<SpriteFrame> = [for (i in 0...SPRITEFRAME_COUNT) new SpriteFrame()];
    public static var scriptFramesNo:Int = 0;

    public static var animFrames:Array<SpriteFrame> = [for (i in 0...SPRITEFRAME_COUNT) new SpriteFrame()];
    public static var playerCBoxes:Array<Hitbox> = [for (i in 0...HITBOX_COUNT) new Hitbox()];

    public static function loadPlayerAnimation(filePath:String, playerID:Int):Void {
        var buffer:Array<Int> = [for (i in 0...0x80) 0];
        RetroString.strCopy(buffer, "Data/Animations/");
        RetroString.strAdd(buffer, filePath);

        var info = new FileInfo();
        if (Reader.loadFile(RetroString.arrayToString(buffer), info)) {
            var sheetIDs:Array<Int> = [0, 0, 0, 0];

            Reader.fileReadByte();
            Reader.fileReadByte();
            Reader.fileReadByte();
            Reader.fileReadByte();
            Reader.fileReadByte();

            for (s in 0...4) {
                var strLen = Reader.fileReadByte();
                if (strLen > 0) {
                    var strBuf:Array<Int> = [for (i in 0...0x21) 0];
                    for (i in 0...strLen) strBuf[i] = Reader.fileReadByte();
                    strBuf[strLen] = 0;

                    Reader.getFileInfo(info);
                    Reader.closeFile();

                    Sprite.removeGraphicsFile("", s + 4 * playerID + 16);

                    RetroString.strCopy(buffer, "Data/Sprites/");
                    RetroString.strAdd(buffer, RetroString.arrayToString(strBuf));

                    var lastChar = strBuf[strLen - 1];
                    switch (lastChar) {
                        case 102: Sprite.loadGIFFile(RetroString.arrayToString(buffer), s + 4 * playerID + 16);  // 'f'
                        case 112: Sprite.loadBMPFile(RetroString.arrayToString(buffer), s + 4 * playerID + 16); // 'p'
                        case 120: Sprite.loadGFXFile(RetroString.arrayToString(buffer), s + 4 * playerID + 16); // 'x'
                    }
                    sheetIDs[s] = (4 * playerID + 16) + s;

                    Reader.setFileInfo(info);
                }
            }

            var animCount = Reader.fileReadByte();
            var frameID = playerID << 10;

            for (a in 0...animCount) {
                var anim = PlayerManager.playerScriptList[playerID].animations[a];
                if (anim == null) {
                    anim = new SpriteAnimation();
                    PlayerManager.playerScriptList[playerID].animations[a] = anim;
                }
                anim.frameCount = Reader.fileReadByte();
                anim.speed = Reader.fileReadByte();
                anim.loopPoint = Reader.fileReadByte();
                anim.frames = [];

                for (f in 0...anim.frameCount) {
                    var frame = animFrames[frameID++];
                    frame.sheetID = Reader.fileReadByte();
                    frame.sheetID = sheetIDs[frame.sheetID];
                    frame.hitboxID = Reader.fileReadByte();
                    frame.sprX = Reader.fileReadByte();
                    frame.sprY = Reader.fileReadByte();
                    frame.width = Reader.fileReadByte();
                    frame.height = Reader.fileReadByte();
                    var pivX = Reader.fileReadByte();
                    if (pivX > 127) pivX -= 256;
                    frame.pivotX = pivX;
                    var pivY = Reader.fileReadByte();
                    if (pivY > 127) pivY -= 256;
                    frame.pivotY = pivY;
                    anim.frames.push(frame);
                }
            }

            var hitboxCount = Reader.fileReadByte();
            var hitboxID = playerID << 3;
            for (i in 0...hitboxCount) {
                var hitbox = playerCBoxes[hitboxID++];
                for (d in 0...HITBOX_DIR_COUNT) {
                    hitbox.left[d] = toSigned(Reader.fileReadByte());
                    hitbox.top[d] = toSigned(Reader.fileReadByte());
                    hitbox.right[d] = toSigned(Reader.fileReadByte());
                    hitbox.bottom[d] = toSigned(Reader.fileReadByte());
                }
            }

            PlayerManager.playerScriptList[playerID].startWalkSpeed = PlayerManager.playerScriptList[playerID].animations[PlayerManager.ANI_WALKING].speed - 20;
            PlayerManager.playerScriptList[playerID].startRunSpeed = PlayerManager.playerScriptList[playerID].animations[PlayerManager.ANI_RUNNING].speed;
            PlayerManager.playerScriptList[playerID].startJumpSpeed = PlayerManager.playerScriptList[playerID].animations[PlayerManager.ANI_JUMPING].speed - 48;

            Reader.closeFile();
        }
    }
    public static function clearAnimationData():Void {
        for (i in 0...SPRITEFRAME_COUNT) {
            scriptFrames[i].pivotX = 0;
            scriptFrames[i].pivotY = 0;
            scriptFrames[i].width = 0;
            scriptFrames[i].height = 0;
            scriptFrames[i].sprX = 0;
            scriptFrames[i].sprY = 0;
            scriptFrames[i].sheetID = 0;
            scriptFrames[i].hitboxID = 0;
        }
        scriptFramesNo = 0;
    }

    public static function getPlayerCBox(playerScript:Dynamic):Hitbox {
        return playerCBoxes[0];
    }

    static inline function toSigned(val:Int):Int {
        return val > 127 ? val - 256 : val;
    }
}