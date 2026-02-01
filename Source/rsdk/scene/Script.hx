package rsdk.scene;

import rsdk.core.Reader;
import rsdk.core.RetroString;
import rsdk.core.RetroMath;
import rsdk.core.Debug;
import rsdk.scene.Object;
import rsdk.scene.Object.Entity;
import rsdk.scene.Scene;
import rsdk.scene.Collision.Collision;
import rsdk.scene.Player;
import rsdk.graphics.Animation;
import rsdk.graphics.Drawing;
import rsdk.graphics.Palette;
import rsdk.graphics.Sprite;
import rsdk.graphics.Video;
import rsdk.audio.Audio;
import rsdk.input.Input;
import rsdk.storage.Text;

class ScriptPtr {
    public var scriptCodePtr:Int = 0;
    public var jumpTablePtr:Int = 0;

    public function new() {}
}

class ObjectScript {
    public var frameCount:Int = 0;
    public var spriteSheetID:Int = 0;
    public var subMain:ScriptPtr = new ScriptPtr();
    public var subPlayerInteraction:ScriptPtr = new ScriptPtr();
    public var subDraw:ScriptPtr = new ScriptPtr();
    public var subStartup:ScriptPtr = new ScriptPtr();
    public var frameStartPtr:Int = 0;

    public function new() {}
}

class ScriptEngine {
    public var operands:Array<Int> = [for (i in 0...10) 0];
    public var tempValue:Array<Int> = [for (i in 0...8) 0];
    public var arrayPosition:Array<Int> = [for (i in 0...3) 0];
    public var checkResult:Int = 0;

    public function new() {}
}

class AliasInfo {
    public var name:Array<Int> = [for (i in 0...0x20) 0];
    public var value:Array<Int> = [for (i in 0...0x20) 0];

    public function new(?aliasName:String, ?aliasVal:String) {
        if (aliasName != null && aliasVal != null) {
            RetroString.strCopy(name, aliasName);
            RetroString.strCopy(value, aliasVal);
        }
    }
}

class FunctionInfo {
    public var name:Array<Int> = [for (i in 0...0x20) 0];
    public var opcodeSize:Int = 0;

    public function new(?functionName:String, ?opSize:Int) {
        if (functionName != null) {
            RetroString.strCopy(name, functionName);
            opcodeSize = opSize != null ? opSize : 0;
        }
    }
}

enum abstract ScriptSubs(Int) to Int {
    var SUB_MAIN = 0;
    var SUB_PLAYERINTERACTION = 1;
    var SUB_DRAW = 2;
    var SUB_SETUP = 3;
    var SUB_PLAYERMAIN = 4;
    var SUB_PLAYERSTATE = 5;
}

enum abstract ScriptReadModes(Int) to Int {
    var READMODE_NORMAL = 0;
    var READMODE_STRING = 1;
    var READMODE_COMMENTLINE = 2;
    var READMODE_ENDLINE = 3;
    var READMODE_EOF = 4;
}

enum abstract ScriptParseModes(Int) to Int {
    var PARSEMODE_SCOPELESS = 0;
    var PARSEMODE_PLATFORMSKIP = 1;
    var PARSEMODE_FUNCTION = 2;
    var PARSEMODE_SWITCHREAD = 3;
    var PARSEMODE_ERROR = 0xFF;
}

enum abstract ScriptVarTypes(Int) to Int {
    var SCRIPTVAR_VAR = 1;
    var SCRIPTVAR_INTCONST = 2;
    var SCRIPTVAR_STRCONST = 3;
}

enum abstract ScriptVarArrTypes(Int) to Int {
    var VARARR_NONE = 0;
    var VARARR_ARRAY = 1;
    var VARARR_ENTNOPLUS1 = 2;
    var VARARR_ENTNOMINUS1 = 3;
}

enum abstract ScrVariable(Int) to Int {
    var VAR_OBJECTTYPE = 0;
    var VAR_OBJECTPROPERTYVALUE = 1;
    var VAR_OBJECTXPOS = 2;
    var VAR_OBJECTYPOS = 3;
    var VAR_OBJECTIXPOS = 4;
    var VAR_OBJECTIYPOS = 5;
    var VAR_OBJECTSTATE = 6;
    var VAR_OBJECTROTATION = 7;
    var VAR_OBJECTSCALE = 8;
    var VAR_OBJECTPRIORITY = 9;
    var VAR_OBJECTDRAWORDER = 10;
    var VAR_OBJECTDIRECTION = 11;
    var VAR_OBJECTINKEFFECT = 12;
    var VAR_OBJECTFRAME = 13;
    var VAR_OBJECTVALUE0 = 14;
    var VAR_OBJECTVALUE1 = 15;
    var VAR_OBJECTVALUE2 = 16;
    var VAR_OBJECTVALUE3 = 17;
    var VAR_OBJECTVALUE4 = 18;
    var VAR_OBJECTVALUE5 = 19;
    var VAR_OBJECTVALUE6 = 20;
    var VAR_OBJECTVALUE7 = 21;
    var VAR_TEMPVALUE0 = 22;
    var VAR_TEMPVALUE1 = 23;
    var VAR_TEMPVALUE2 = 24;
    var VAR_TEMPVALUE3 = 25;
    var VAR_TEMPVALUE4 = 26;
    var VAR_TEMPVALUE5 = 27;
    var VAR_TEMPVALUE6 = 28;
    var VAR_TEMPVALUE7 = 29;
    var VAR_CHECKRESULT = 30;
    var VAR_ARRAYPOS0 = 31;
    var VAR_ARRAYPOS1 = 32;
    var VAR_KEYDOWNUP = 33;
    var VAR_KEYDOWNDOWN = 34;
    var VAR_KEYDOWNLEFT = 35;
    var VAR_KEYDOWNRIGHT = 36;
    var VAR_KEYDOWNBUTTONA = 37;
    var VAR_KEYDOWNBUTTONB = 38;
    var VAR_KEYDOWNBUTTONC = 39;
    var VAR_KEYDOWNSTART = 40;
    var VAR_KEYPRESSUP = 41;
    var VAR_KEYPRESSDOWN = 42;
    var VAR_KEYPRESSLEFT = 43;
    var VAR_KEYPRESSRIGHT = 44;
    var VAR_KEYPRESSBUTTONA = 45;
    var VAR_KEYPRESSBUTTONB = 46;
    var VAR_KEYPRESSBUTTONC = 47;
    var VAR_KEYPRESSSTART = 48;
    var VAR_MENU1SELECTION = 49;
    var VAR_MENU2SELECTION = 50;
    var VAR_STAGEACTIVELIST = 51;
    var VAR_STAGELISTPOS = 52;
    var VAR_XSCROLLOFFSET = 53;
    var VAR_YSCROLLOFFSET = 54;
    var VAR_GLOBAL = 55;
    var VAR_STAGETIMEENABLED = 56;
    var VAR_STAGEMILLISECONDS = 57;
    var VAR_STAGESECONDS = 58;
    var VAR_STAGEMINUTES = 59;
    var VAR_STAGEACTNO = 60;
    var VAR_OBJECTENTITYNO = 61;
    var VAR_PLAYERTYPE = 62;
    var VAR_PLAYERSTATE = 63;
    var VAR_PLAYERCONTROLMODE = 64;
    var VAR_PLAYERCOLLISIONMODE = 65;
    var VAR_PLAYERCOLLISIONPLANE = 66;
    var VAR_PLAYERXPOS = 67;
    var VAR_PLAYERYPOS = 68;
    var VAR_PLAYERSCREENXPOS = 69;
    var VAR_PLAYERSCREENYPOS = 70;
    var VAR_PLAYERSPEED = 71;
    var VAR_PLAYERXVELOCITY = 72;
    var VAR_PLAYERYVELOCITY = 73;
    var VAR_PLAYERGRAVITY = 74;
    var VAR_PLAYERANGLE = 75;
    var VAR_PLAYERROTATION = 76;
    var VAR_PLAYERDIRECTION = 77;
    var VAR_PLAYERANIMATION = 78;
    var VAR_PLAYERFRAME = 79;
    var VAR_PLAYERSKIDDING = 80;
    var VAR_PLAYERPUSHING = 81;
    var VAR_PLAYERFRICTIONLOSS = 82;
    var VAR_PLAYERWALKINGSPEED = 83;
    var VAR_PLAYERRUNNINGSPEED = 84;
    var VAR_PLAYERJUMPINGSPEED = 85;
    var VAR_PLAYERTRACKSCROLL = 86;
    var VAR_PLAYERUP = 87;
    var VAR_PLAYERDOWN = 88;
    var VAR_PLAYERLEFT = 89;
    var VAR_PLAYERRIGHT = 90;
    var VAR_PLAYERJUMPPRESS = 91;
    var VAR_PLAYERJUMPHOLD = 92;
    var VAR_PLAYERFOLLOWPLAYER1 = 93;
    var VAR_PLAYERLOOKPOS = 94;
    var VAR_PLAYERWATER = 95;
    var VAR_PLAYERTOPSPEED = 96;
    var VAR_PLAYERACCELERATION = 97;
    var VAR_PLAYERDECELERATION = 98;
    var VAR_PLAYERAIRACCELERATION = 99;
    var VAR_PLAYERAIRDECELERATION = 100;
    var VAR_PLAYERGRAVITYSTRENGTH = 101;
    var VAR_PLAYERJUMPSTRENGTH = 102;
    var VAR_PLAYERROLLINGACCELERATION = 103;
    var VAR_PLAYERROLLINGDECELERATION = 104;
    var VAR_PLAYERENTITYNO = 105;
    var VAR_PLAYERCOLLISIONLEFT = 106;
    var VAR_PLAYERCOLLISIONTOP = 107;
    var VAR_PLAYERCOLLISIONRIGHT = 108;
    var VAR_PLAYERCOLLISIONBOTTOM = 109;
    var VAR_PLAYERFLAILING = 110;
    var VAR_STAGEPAUSEENABLED = 111;
    var VAR_STAGELISTSIZE = 112;
    var VAR_PLAYERTIMER = 113;
    var VAR_PLAYERANIMATIONSPEED = 114;
    var VAR_PLAYERTILECOLLISIONS = 115;
    var VAR_PLAYEROBJECTINTERACTION = 116;
    var VAR_SCREENCAMERAENABLED = 117;
    var VAR_SCREENCAMERASTYLE = 118;
    var VAR_MUSICVOLUME = 119;
    var VAR_MUSICCURRENTTRACK = 120;
    var VAR_PLAYERVISIBLE = 121;
    var VAR_STAGENEWXBOUNDARY1 = 122;
    var VAR_STAGENEWXBOUNDARY2 = 123;
    var VAR_STAGENEWYBOUNDARY1 = 124;
    var VAR_STAGENEWYBOUNDARY2 = 125;
    var VAR_STAGEXBOUNDARY1 = 126;
    var VAR_STAGEXBOUNDARY2 = 127;
    var VAR_STAGEYBOUNDARY1 = 128;
    var VAR_STAGEYBOUNDARY2 = 129;
    var VAR_OBJECTOUTOFBOUNDS = 130;
    var VAR_MAX_CNT = 131;
}

enum abstract ScrFunction(Int) to Int {
    var FUNC_END = 0;
    var FUNC_EQUAL = 1;
    var FUNC_ADD = 2;
    var FUNC_SUB = 3;
    var FUNC_INC = 4;
    var FUNC_DEC = 5;
    var FUNC_MUL = 6;
    var FUNC_DIV = 7;
    var FUNC_SHR = 8;
    var FUNC_SHL = 9;
    var FUNC_AND = 10;
    var FUNC_OR = 11;
    var FUNC_XOR = 12;
    var FUNC_NOT = 13;
    var FUNC_FLIPSIGN = 14;
    var FUNC_CHECKEQUAL = 15;
    var FUNC_CHECKGREATER = 16;
    var FUNC_CHECKLOWER = 17;
    var FUNC_CHECKNOTEQUAL = 18;
    var FUNC_IFEQUAL = 19;
    var FUNC_IFGREATER = 20;
    var FUNC_IFGREATEROREQUAL = 21;
    var FUNC_IFLOWER = 22;
    var FUNC_IFLOWEROREQUAL = 23;
    var FUNC_IFNOTEQUAL = 24;
    var FUNC_ELSE = 25;
    var FUNC_ENDIF = 26;
    var FUNC_WEQUAL = 27;
    var FUNC_WGREATER = 28;
    var FUNC_WGREATEROREQUAL = 29;
    var FUNC_WLOWER = 30;
    var FUNC_WLOWEROREQUAL = 31;
    var FUNC_WNOTEQUAL = 32;
    var FUNC_LOOP = 33;
    var FUNC_SWITCH = 34;
    var FUNC_BREAK = 35;
    var FUNC_ENDSWITCH = 36;
    var FUNC_RAND = 37;
    var FUNC_SIN = 38;
    var FUNC_COS = 39;
    var FUNC_SIN256 = 40;
    var FUNC_COS256 = 41;
    var FUNC_SINCHANGE = 42;
    var FUNC_COSCHANGE = 43;
    var FUNC_ATAN2 = 44;
    var FUNC_INTERPOLATE = 45;
    var FUNC_INTERPOLATEXY = 46;
    var FUNC_LOADSPRITESHEET = 47;
    var FUNC_REMOVESPRITESHEET = 48;
    var FUNC_DRAWSPRITE = 49;
    var FUNC_DRAWSPRITEXY = 50;
    var FUNC_DRAWSPRITESCREENXY = 51;
    var FUNC_DRAWSPRITE3D = 52;
    var FUNC_DRAWNUMBERS = 53;
    var FUNC_DRAWACTNAME = 54;
    var FUNC_DRAWMENU = 55;
    var FUNC_SPRITEFRAME = 56;
    var FUNC_SETDEBUGICON = 57;
    var FUNC_LOADPALETTE = 58;
    var FUNC_ROTATEPALETTE = 59;
    var FUNC_SETFADE = 60;
    var FUNC_SETWATERCOLOR = 61;
    var FUNC_SETBLENDTABLE = 62;
    var FUNC_SETTINTTABLE = 63;
    var FUNC_CLEARSCREEN = 64;
    var FUNC_DRAWSPRITEFX = 65;
    var FUNC_DRAWSPRITESCREENFX = 66;
    var FUNC_DRAWLIFEICON = 67;
    var FUNC_SETUPMENU = 68;
    var FUNC_ADDMENUENTRY = 69;
    var FUNC_EDITMENUENTRY = 70;
    var FUNC_LOADSTAGE = 71;
    var FUNC_DRAWTINTRECT = 72;
    var FUNC_RESETOBJECTENTITY = 73;
    var FUNC_PLAYEROBJECTCOLLISION = 74;
    var FUNC_CREATETEMPOBJECT = 75;
    var FUNC_DEFAULTGROUNDMOVEMENT = 76;
    var FUNC_DEFAULTAIRMOVEMENT = 77;
    var FUNC_DEFAULTROLLINGMOVEMENT = 78;
    var FUNC_DEFAULTGRAVITYTRUE = 79;
    var FUNC_DEFAULTGRAVITYFALSE = 80;
    var FUNC_DEFAULTJUMPACTION = 81;
    var FUNC_SETMUSICTRACK = 82;
    var FUNC_PLAYMUSIC = 83;
    var FUNC_STOPMUSIC = 84;
    var FUNC_PLAYSFX = 85;
    var FUNC_STOPSFX = 86;
    var FUNC_SETSFXATTRIBUTES = 87;
    var FUNC_OBJECTTILECOLLISION = 88;
    var FUNC_OBJECTTILEGRIP = 89;
    var FUNC_LOADVIDEO = 90;
    var FUNC_NEXTVIDEOFRAME = 91;
    var FUNC_PLAYSTAGESFX = 92;
    var FUNC_STOPSTAGESFX = 93;
    var FUNC_MAX_CNT = 94;
}

class Script {
    public static inline var SCRIPTDATA_COUNT:Int = 0x40000;
    public static inline var JUMPTABLE_COUNT:Int = 0x4000;
    public static inline var JUMPSTACK_COUNT:Int = 0x400;
    public static inline var OBJECT_COUNT:Int = 256;
    public static inline var PLAYER_COUNT:Int = 2;
    public static inline var ALIAS_COUNT:Int = 0x80;
    public static inline var COMMONALIAS_COUNT:Int = 22;
    public static inline var GLOBALVAR_COUNT:Int = 256;

    public static inline var SUB_MAIN:Int = 0;
    public static inline var SUB_PLAYERINTERACTION:Int = 1;
    public static inline var SUB_DRAW:Int = 2;
    public static inline var SUB_SETUP:Int = 3;
    public static inline var SUB_PLAYERMAIN:Int = 4;
    public static inline var SUB_PLAYERSTATE:Int = 5;

    public static inline var READMODE_NORMAL:Int = 0;
    public static inline var READMODE_STRING:Int = 1;
    public static inline var READMODE_COMMENTLINE:Int = 2;
    public static inline var READMODE_ENDLINE:Int = 3;
    public static inline var READMODE_EOF:Int = 4;

    public static var objectScriptList:Array<ObjectScript> = [for (i in 0...OBJECT_COUNT) new ObjectScript()];
    public static var scriptData:Array<Int> = [for (i in 0...SCRIPTDATA_COUNT) 0];
    public static var jumpTableData:Array<Int> = [for (i in 0...JUMPTABLE_COUNT) 0];
    public static var jumpTableStack:Array<Int> = [for (i in 0...JUMPSTACK_COUNT) 0];

    public static var jumpTablePos:Int = 0;
    public static var jumpTableStackPos:Int = 0;

    public static var scriptEng:ScriptEngine = new ScriptEngine();
    public static var scriptText:Array<Int> = [for (i in 0...0x100) 0];

    public static var scriptDataPos:Int = 0;
    public static var scriptDataOffset:Int = 0;
    public static var jumpTableDataPos:Int = 0;
    public static var jumpTableOffset:Int = 0;

    public static var noAliases:Int = 0;
    public static var lineID:Int = 0;
    public static var currentScriptSub:Int = 0;
    public static var currentOpcode:Int = 0;
    public static var currentScriptCodePtr:Int = 0;

    public static var globalVariables:Array<Int> = [for (i in 0...GLOBALVAR_COUNT) 0];
    public static var globalVariableNames:Array<String> = [for (i in 0...GLOBALVAR_COUNT) ""];
    public static var noGlobalVariables:Int = 0;

    public static var aliases:Array<AliasInfo> = initAliases();

    static function initAliases():Array<AliasInfo> {
        var arr = new Array<AliasInfo>();
        for (i in 0...ALIAS_COUNT) {
            arr.push(new AliasInfo());
        }
        arr[0] = new AliasInfo("true", "1");
        arr[1] = new AliasInfo("false", "0");
        arr[2] = new AliasInfo("FX_SCALE", "0");
        arr[3] = new AliasInfo("FX_ROTATE", "1");
        arr[4] = new AliasInfo("FX_INK", "2");
        arr[5] = new AliasInfo("PRESENTATION_STAGE", "0");
        arr[6] = new AliasInfo("REGULAR_STAGE", "1");
        arr[7] = new AliasInfo("BONUS_STAGE", "2");
        arr[8] = new AliasInfo("SPECIAL_STAGE", "3");
        arr[9] = new AliasInfo("MENU_1", "0");
        arr[10] = new AliasInfo("MENU_2", "1");
        arr[11] = new AliasInfo("C_TOUCH", "0");
        arr[12] = new AliasInfo("C_BOX", "1");
        arr[13] = new AliasInfo("C_PLATFORM", "2");
        arr[14] = new AliasInfo("INK_NONE", "0");
        arr[15] = new AliasInfo("INK_BLEND", "1");
        arr[16] = new AliasInfo("INK_TINT", "2");
        arr[17] = new AliasInfo("FX_TINT", "3");
        arr[18] = new AliasInfo("FLIP_NONE", "0");
        arr[19] = new AliasInfo("FLIP_X", "1");
        arr[20] = new AliasInfo("FLIP_Y", "2");
        arr[21] = new AliasInfo("FLIP_XY", "3");
        return arr;
    }

    public static var variableNames:Array<String> = [
        "Object.Type", "Object.PropertyValue", "Object.XPos", "Object.YPos", "Object.iXPos", "Object.iYPos",
        "Object.State", "Object.Rotation", "Object.Scale", "Object.Priority", "Object.DrawOrder", "Object.Direction",
        "Object.InkEffect", "Object.Frame", "Object.Value0", "Object.Value1", "Object.Value2", "Object.Value3",
        "Object.Value4", "Object.Value5", "Object.Value6", "Object.Value7", "TempValue0", "TempValue1",
        "TempValue2", "TempValue3", "TempValue4", "TempValue5", "TempValue6", "TempValue7", "CheckResult",
        "ArrayPos0", "ArrayPos1", "KeyDown.Up", "KeyDown.Down", "KeyDown.Left", "KeyDown.Right", "KeyDown.ButtonA",
        "KeyDown.ButtonB", "KeyDown.ButtonC", "KeyDown.Start", "KeyPress.Up", "KeyPress.Down", "KeyPress.Left",
        "KeyPress.Right", "KeyPress.ButtonA", "KeyPress.ButtonB", "KeyPress.ButtonC", "KeyPress.Start",
        "Menu1.Selection", "Menu2.Selection", "Stage.ActiveList", "Stage.ListPos", "XScrollOffset", "YScrollOffset",
        "Global", "Stage.TimeEnabled", "Stage.MilliSeconds", "Stage.Seconds", "Stage.Minutes", "Stage.ActNo",
        "Object.EntityNo", "Player.Type", "Player.State", "Player.ControlMode", "Player.CollisionMode",
        "Player.CollisionPlane", "Player.XPos", "Player.YPos", "Player.ScreenXPos", "Player.ScreenYPos",
        "Player.Speed", "Player.XVelocity", "Player.YVelocity", "Player.Gravity", "Player.Angle", "Player.Rotation",
        "Player.Direction", "Player.Animation", "Player.Frame", "Player.Skidding", "Player.Pushing",
        "Player.FrictionLoss", "Player.WalkingSpeed", "Player.RunningSpeed", "Player.JumpingSpeed",
        "Player.TrackScroll", "Player.Up", "Player.Down", "Player.Left", "Player.Right", "Player.JumpPress",
        "Player.JumpHold", "Player.FollowPlayer1", "Player.LookPos", "Player.Water", "Player.TopSpeed",
        "Player.Acceleration", "Player.Deceleration", "Player.AirAcceleration", "Player.AirDeceleration",
        "Player.GravityStrength", "Player.JumpStrength", "Player.RollingAcceleration", "Player.RollingDeceleration",
        "Player.EntityNo", "Player.CollisionLeft", "Player.CollisionTop", "Player.CollisionRight",
        "Player.CollisionBottom", "Player.Flailing", "Stage.PauseEnabled", "Stage.ListSize", "Player.Timer",
        "Player.AnimationSpeed", "Player.TileCollisions", "Player.ObjectInteraction", "Stage.CameraEnabled",
        "Stage.CameraStyle", "Music.Volume", "Music.CurrentTrack", "Player.Visible", "Stage.NewXBoundary1",
        "Stage.NewXBoundary2", "Stage.NewYBoundary1", "Stage.NewYBoundary2", "Stage.XBoundary1", "Stage.XBoundary2",
        "Stage.YBoundary1", "Stage.YBoundary2", "Object.OutOfBounds"
    ];

    public static var functions:Array<FunctionInfo> = initFunctions();

    static function initFunctions():Array<FunctionInfo> {
        return [
            new FunctionInfo("End", 0), new FunctionInfo("Equal", 2), new FunctionInfo("Add", 2),
            new FunctionInfo("Sub", 2), new FunctionInfo("Inc", 1), new FunctionInfo("Dec", 1),
            new FunctionInfo("Mul", 2), new FunctionInfo("Div", 2), new FunctionInfo("ShR", 2),
            new FunctionInfo("ShL", 2), new FunctionInfo("And", 2), new FunctionInfo("Or", 2),
            new FunctionInfo("Xor", 2), new FunctionInfo("Not", 1), new FunctionInfo("FlipSign", 1),
            new FunctionInfo("CheckEqual", 2), new FunctionInfo("CheckGreater", 2), new FunctionInfo("CheckLower", 2),
            new FunctionInfo("CheckNotEqual", 2), new FunctionInfo("IfEqual", 3), new FunctionInfo("IfGreater", 3),
            new FunctionInfo("IfGreaterOrEqual", 3), new FunctionInfo("IfLower", 3), new FunctionInfo("IfLowerOrEqual", 3),
            new FunctionInfo("IfNotEqual", 3), new FunctionInfo("else", 0), new FunctionInfo("endif", 0),
            new FunctionInfo("WEqual", 3), new FunctionInfo("WGreater", 3), new FunctionInfo("WGreaterOrEqual", 3),
            new FunctionInfo("WLower", 3), new FunctionInfo("WLowerOrEqual", 3), new FunctionInfo("WNotEqual", 3),
            new FunctionInfo("loop", 0), new FunctionInfo("switch", 2), new FunctionInfo("break", 0),
            new FunctionInfo("endswitch", 0), new FunctionInfo("Rand", 2), new FunctionInfo("Sin", 2),
            new FunctionInfo("Cos", 2), new FunctionInfo("Sin256", 2), new FunctionInfo("Cos256", 2),
            new FunctionInfo("SinChange", 5), new FunctionInfo("CosChange", 5), new FunctionInfo("ATan2", 3),
            new FunctionInfo("Interpolate", 4), new FunctionInfo("InterpolateXY", 7), new FunctionInfo("LoadSpriteSheet", 1),
            new FunctionInfo("RemoveSpriteSheet", 1), new FunctionInfo("DrawSprite", 1), new FunctionInfo("DrawSpriteXY", 3),
            new FunctionInfo("DrawSpriteScreenXY", 3), new FunctionInfo("DrawSprite3D", 1), new FunctionInfo("DrawNumbers", 7),
            new FunctionInfo("DrawActName", 7), new FunctionInfo("DrawMenu", 3), new FunctionInfo("SpriteFrame", 6),
            new FunctionInfo("SetDebugIcon", 6), new FunctionInfo("LoadPalette", 3), new FunctionInfo("RotatePalette", 3),
            new FunctionInfo("SetFade", 6), new FunctionInfo("SetWaterColor", 4), new FunctionInfo("SetBlendTable", 4),
            new FunctionInfo("SetTintTable", 6), new FunctionInfo("ClearScreen", 1), new FunctionInfo("DrawSpriteFX", 4),
            new FunctionInfo("DrawSpriteScreenFX", 4), new FunctionInfo("DrawLifeIcon", 2), new FunctionInfo("SetupMenu", 4),
            new FunctionInfo("AddMenuEntry", 3), new FunctionInfo("EditMenuEntry", 4), new FunctionInfo("LoadStage", 0),
            new FunctionInfo("DrawTintRect", 5), new FunctionInfo("ResetObjectEntity", 5), new FunctionInfo("PlayerObjectCollision", 5),
            new FunctionInfo("CreateTempObject", 4), new FunctionInfo("DefaultGroundMovement", 0), new FunctionInfo("DefaultAirMovement", 0),
            new FunctionInfo("DefaultRollingMovement", 0), new FunctionInfo("DefaultGravityTrue", 0), new FunctionInfo("DefaultGravityFalse", 0),
            new FunctionInfo("DefaultJumpAction", 0), new FunctionInfo("SetMusicTrack", 3), new FunctionInfo("PlayMusic", 1),
            new FunctionInfo("StopMusic", 0), new FunctionInfo("PlaySfx", 2), new FunctionInfo("StopSfx", 1),
            new FunctionInfo("SetSfxAttributes", 3), new FunctionInfo("ObjectTileCollision", 4), new FunctionInfo("ObjectTileGrip", 4),
            new FunctionInfo("LoadVideo", 1), new FunctionInfo("NextVideoFrame", 0), new FunctionInfo("PlayStageSfx", 2),
            new FunctionInfo("StopStageSfx", 1)
        ];
    }

    public static var scriptEvaluationTokens:Array<String> = [
        "=", "+=", "-=", "++", "--", "*=", "/=", ">>=", "<<=", "&=", "|=", "^=", "==", ">", ">=", "<", "<=", "!="
    ];

    public static function checkAliasText(text:Array<Int>):Void {
        if (RetroString.findStringToken(text, "#alias", 1) != 0) return;
        var textPos = 6;
        var aliasStrPos = 0;
        var aliasMatch = 0;
        while (aliasMatch < 2) {
            if (aliasMatch == 1) {
                aliases[noAliases].name[aliasStrPos] = text[textPos];
                if (text[textPos] != 0) aliasStrPos++;
                else { aliasStrPos = 0; ++aliasMatch; }
            } else if (text[textPos] == ":".code) {
                aliases[noAliases].value[aliasStrPos] = 0;
                aliasStrPos = 0;
                aliasMatch = 1;
            } else {
                aliases[noAliases].value[aliasStrPos++] = text[textPos];
            }
            ++textPos;
        }
        ++noAliases;
    }

    public static function convertArithmaticSyntax(text:Array<Int>):Void {
        var token = 0;
        var offset = 0;
        var findID = 0;
        var dest:Array<Int> = [for (i in 0...260) 0];
        for (i in FUNC_EQUAL...FUNC_NOT) {
            findID = RetroString.findStringToken(text, scriptEvaluationTokens[i - 1], 1);
            if (findID > -1) { offset = findID; token = i; }
        }
        if (token > 0) {
            RetroString.strCopy(dest, RetroString.arrayToString(functions[token].name));
            RetroString.strAdd(dest, "(");
            findID = RetroString.strLength(dest);
            for (i in 0...offset) dest[findID++] = text[i];
            if (functions[token].opcodeSize > 1) {
                dest[findID] = ",".code;
                var len = scriptEvaluationTokens[token - 1].length;
                offset += len;
                ++findID;
                while (text[offset] != 0) dest[findID++] = text[offset++];
            }
            dest[findID] = 0;
            RetroString.strAdd(dest, ")");
            RetroString.strCopyArray(text, dest);
        }
    }

    public static function convertIfWhileStatement(text:Array<Int>):Void {
        var dest:Array<Int> = [for (i in 0...260) 0];
        var compareOp = -1;
        var strPos = 0;
        var destStrPos = 0;
        if (RetroString.findStringToken(text, "if", 1) != 0) {
            if (RetroString.findStringToken(text, "while", 1) == 0) {
                for (i in 0...6) {
                    destStrPos = RetroString.findStringToken(text, scriptEvaluationTokens[i + (FUNC_NOT - 1)], 1);
                    if (destStrPos > -1) { strPos = destStrPos; compareOp = i; }
                }
                if (compareOp > -1) {
                    text[strPos] = ",".code;
                    RetroString.strCopy(dest, RetroString.arrayToString(functions[compareOp + FUNC_WEQUAL].name));
                    RetroString.strAdd(dest, "(");
                    appendIntegerToString(dest, jumpTableDataPos - jumpTableOffset);
                    RetroString.strAdd(dest, ",");
                    destStrPos = RetroString.strLength(dest);
                    var i = 5;
                    while (text[i] != 0) {
                        if (text[i] != "=".code && text[i] != "(".code && text[i] != ")".code)
                            dest[destStrPos++] = text[i];
                        i++;
                    }
                    dest[destStrPos] = 0;
                    RetroString.strAdd(dest, ")");
                    RetroString.strCopyArray(text, dest);
                    jumpTableStack[++jumpTableStackPos] = jumpTableDataPos;
                    jumpTableData[jumpTableDataPos++] = scriptDataPos - scriptDataOffset;
                    jumpTableData[jumpTableDataPos++] = 0;
                }
            }
        } else {
            for (i in 0...6) {
                destStrPos = RetroString.findStringToken(text, scriptEvaluationTokens[i + (FUNC_NOT - 1)], 1);
                if (destStrPos > -1) { strPos = destStrPos; compareOp = i; }
            }
            if (compareOp > -1) {
                text[strPos] = ",".code;
                RetroString.strCopy(dest, RetroString.arrayToString(functions[compareOp + FUNC_IFEQUAL].name));
                RetroString.strAdd(dest, "(");
                appendIntegerToString(dest, jumpTableDataPos - jumpTableOffset);
                RetroString.strAdd(dest, ",");
                destStrPos = RetroString.strLength(dest);
                var i = 2;
                while (text[i] != 0) {
                    if (text[i] != "=".code && text[i] != "(".code && text[i] != ")".code)
                        dest[destStrPos++] = text[i];
                    i++;
                }
                dest[destStrPos] = 0;
                RetroString.strAdd(dest, ")");
                RetroString.strCopyArray(text, dest);
                jumpTableStack[++jumpTableStackPos] = jumpTableDataPos;
                jumpTableData[jumpTableDataPos++] = -1;
                jumpTableData[jumpTableDataPos++] = 0;
            }
        }
    }

    public static function convertSwitchStatement(text:Array<Int>):Bool {
        if (RetroString.findStringToken(text, "switch", 1) != 0) return false;
        var switchText:Array<Int> = [for (i in 0...260) 0];
        RetroString.strCopy(switchText, "switch");
        RetroString.strAdd(switchText, "(");
        appendIntegerToString(switchText, jumpTableDataPos - jumpTableOffset);
        RetroString.strAdd(switchText, ",");
        var pos = RetroString.strLength(switchText);
        var i = 6;
        while (text[i] != 0) {
            if (text[i] != "=".code && text[i] != "(".code && text[i] != ")".code)
                switchText[pos++] = text[i];
            i++;
        }
        switchText[pos] = 0;
        RetroString.strAdd(switchText, ")");
        RetroString.strCopyArray(text, switchText);
        jumpTableStack[++jumpTableStackPos] = jumpTableDataPos;
        jumpTableData[jumpTableDataPos++] = 0x10000;
        jumpTableData[jumpTableDataPos++] = -0x10000;
        jumpTableData[jumpTableDataPos++] = -1;
        jumpTableData[jumpTableDataPos++] = 0;
        return true;
    }

    public static function convertFunctionText(text:Array<Int>):Void {
        var strBuffer:Array<Int> = [for (i in 0...128) 0];
        var funcName:Array<Int> = [for (i in 0...132) 0];
        var opcode = 0;
        var opcodeSize = 0;
        var textPos = 0;
        var namePos = 0;
        while (text[namePos] != "(".code && text[namePos] != 0) {
            funcName[namePos] = text[namePos];
            namePos++;
        }
        funcName[namePos] = 0;
        for (i in 0...FUNC_MAX_CNT) {
            if (RetroString.strComp(funcName, functions[i].name)) {
                opcode = i;
                opcodeSize = functions[i].opcodeSize;
                textPos = RetroString.strLength(functions[i].name);
                break;
            }
        }
        if (opcode <= 0) return;
        scriptData[scriptDataPos++] = opcode;
        if (RetroString.strComp(funcName, RetroString.stringToArray("else")))
            jumpTableData[jumpTableStack[jumpTableStackPos]] = scriptDataPos - scriptDataOffset;
        if (RetroString.strComp(funcName, RetroString.stringToArray("endif"))) {
            var jPos = jumpTableStack[jumpTableStackPos];
            jumpTableData[jPos + 1] = scriptDataPos - scriptDataOffset;
            if (jumpTableData[jPos] == -1) jumpTableData[jPos] = (scriptDataPos - scriptDataOffset) - 1;
            --jumpTableStackPos;
        }
        if (RetroString.strComp(funcName, RetroString.stringToArray("endswitch"))) {
            var jPos = jumpTableStack[jumpTableStackPos];
            jumpTableData[jPos + 3] = scriptDataPos - scriptDataOffset;
            if (jumpTableData[jPos + 2] == -1) {
                jumpTableData[jPos + 2] = (scriptDataPos - scriptDataOffset) - 1;
                var caseCnt = intAbs(jumpTableData[jPos + 1] - jumpTableData[jPos]) + 1;
                var jOffset = jPos + 4;
                for (c in 0...caseCnt) {
                    if (jumpTableData[jOffset + c] < 0) jumpTableData[jOffset + c] = jumpTableData[jPos + 2];
                }
            }
            --jumpTableStackPos;
        }
        if (RetroString.strComp(funcName, RetroString.stringToArray("loop"))) {
            jumpTableData[jumpTableStack[jumpTableStackPos--] + 1] = scriptDataPos - scriptDataOffset;
        }
        for (i in 0...opcodeSize) {
            ++textPos;
            var funcNamePos = 0;
            var value = 0;
            var scriptTextByteID = 0;
            while (text[textPos] != ",".code && text[textPos] != ")".code && text[textPos] != 0) {
                if (value != 0) {
                    if (text[textPos] == "]".code) value = 0;
                    else strBuffer[scriptTextByteID++] = text[textPos];
                    ++textPos;
                } else {
                    if (text[textPos] == "[".code) value = 1;
                    else funcName[funcNamePos++] = text[textPos];
                    ++textPos;
                }
            }
            funcName[funcNamePos] = 0;
            strBuffer[scriptTextByteID] = 0;
            for (a in 0...noAliases) {
                if (RetroString.strComp(funcName, aliases[a].name)) {
                    copyAliasStr(funcName, aliases[a].value, false);
                    if (RetroString.findStringToken(aliases[a].value, "[", 1) > -1)
                        copyAliasStr(strBuffer, aliases[a].value, true);
                }
            }
            var funcNameStr = RetroString.arrayToString(funcName);
            for (v in 0...noGlobalVariables) {
                if (funcNameStr == globalVariableNames[v]) {
                    RetroString.strCopy(funcName, "Global");
                    strBuffer[0] = 0;
                    appendIntegerToString(strBuffer, v);
                }
            }
            var intValue:Int = 0;
            var convertResult = convertStringToInteger(funcName);
            if (convertResult.success) {
                intValue = convertResult.value;
                scriptData[scriptDataPos++] = SCRIPTVAR_INTCONST;
                scriptData[scriptDataPos++] = intValue;
            } else if (funcName[0] == "\"".code) {
                scriptData[scriptDataPos++] = SCRIPTVAR_STRCONST;
                scriptData[scriptDataPos++] = RetroString.strLength(funcName) - 2;
                var scriptTextPos = 1;
                scriptTextByteID = 0;
                while (scriptTextPos > -1) {
                    switch (scriptTextByteID) {
                        case 0: scriptData[scriptDataPos] = funcName[scriptTextPos] << 24; ++scriptTextByteID;
                        case 1: scriptData[scriptDataPos] += funcName[scriptTextPos] << 16; ++scriptTextByteID;
                        case 2: scriptData[scriptDataPos] += funcName[scriptTextPos] << 8; ++scriptTextByteID;
                        case 3: scriptData[scriptDataPos++] += funcName[scriptTextPos]; scriptTextByteID = 0;
                    }
                    if (funcName[scriptTextPos] == "\"".code) {
                        if (scriptTextByteID > 0) ++scriptDataPos;
                        scriptTextPos = -1;
                    } else { scriptTextPos++; }
                }
            } else {
                scriptData[scriptDataPos++] = SCRIPTVAR_VAR;
                if (strBuffer[0] != 0) {
                    scriptData[scriptDataPos] = VARARR_ARRAY;
                    if (strBuffer[0] == "+".code) scriptData[scriptDataPos] = VARARR_ENTNOPLUS1;
                    if (strBuffer[0] == "-".code) scriptData[scriptDataPos] = VARARR_ENTNOMINUS1;
                    ++scriptDataPos;
                    if (strBuffer[0] == "-".code || strBuffer[0] == "+".code) {
                        for (j in 0...RetroString.strLength(strBuffer)) strBuffer[j] = strBuffer[j + 1];
                    }
                    var strConvertResult = convertStringToInteger(strBuffer);
                    if (strConvertResult.success) {
                        scriptData[scriptDataPos++] = 0;
                        scriptData[scriptDataPos++] = strConvertResult.value;
                    } else {
                        var strBufferStr = RetroString.arrayToString(strBuffer);
                        if (strBufferStr == "ArrayPos0") intValue = 0;
                        if (strBufferStr == "ArrayPos1") intValue = 1;
                        if (strBufferStr == "TempObjectPos") intValue = 2;
                        scriptData[scriptDataPos++] = 1;
                        scriptData[scriptDataPos++] = intValue;
                    }
                } else {
                    scriptData[scriptDataPos++] = VARARR_NONE;
                }
                intValue = -1;
                funcNameStr = RetroString.arrayToString(funcName);
                for (v in 0...VAR_MAX_CNT) {
                    if (funcNameStr.toLowerCase() == variableNames[v].toLowerCase()) intValue = v;
                }
                if (intValue == -1) {
                    rsdk.core.Debug.printLog("WARNING: Unknown variable '" + funcNameStr + "', defaulting to Object.Type!");
                    intValue = 0;
                }
                scriptData[scriptDataPos++] = intValue;
            }
        }
    }

    public static function checkCaseNumber(text:Array<Int>):Void {
        if (RetroString.findStringToken(text, "case", 1) != 0) return;
        var caseString:Array<Int> = [for (i in 0...128) 0];
        var caseStrPos = 0;
        var caseChar = text[4];
        if (text[4] != 0) {
            var textPos = 5;
            while (caseChar != 0) {
                if (caseChar != ":".code) caseString[caseStrPos++] = caseChar;
                caseChar = text[textPos++];
            }
        } else { caseStrPos = 0; }
        caseString[caseStrPos] = 0;
        for (a in 0...noAliases) {
            if (RetroString.strComp(caseString, aliases[a].name)) {
                RetroString.strCopyArray(caseString, aliases[a].value);
                break;
            }
        }
        var caseID = 0;
        var convertResult = convertStringToInteger(caseString);
        if (convertResult.success) {
            caseID = convertResult.value;
            var stackValue = jumpTableStack[jumpTableStackPos];
            if (caseID < jumpTableData[stackValue]) jumpTableData[stackValue] = caseID;
            stackValue++;
            if (caseID > jumpTableData[stackValue]) jumpTableData[stackValue] = caseID;
        } else {
            Debug.printLog("WARNING: unable to convert case string to int, on line " + Std.string(lineID));
        }
    }

    public static function readSwitchCase(text:Array<Int>):Bool {
        var caseText:Array<Int> = [for (i in 0...0x80) 0];
        if (RetroString.findStringToken(text, "case", 1) != 0) {
            if (RetroString.findStringToken(text, "default", 1) != 0) {
                return false;
            } else {
                var jumpTablepos = jumpTableStack[jumpTableStackPos];
                jumpTableData[jumpTablepos + 2] = scriptDataPos - scriptDataOffset;
                var cnt = intAbs(jumpTableData[jumpTablepos + 1] - jumpTableData[jumpTablepos]) + 1;
                var jOffset = jumpTablepos + 4;
                for (i in 0...cnt) {
                    if (jumpTableData[jOffset + i] < 0) jumpTableData[jOffset + i] = scriptDataPos - scriptDataOffset;
                }
                return true;
            }
        } else {
            var textPos = 4;
            var caseStringPos = 0;
            while (text[textPos] != 0) {
                if (text[textPos] != ":".code) caseText[caseStringPos++] = text[textPos];
                ++textPos;
            }
            caseText[caseStringPos] = 0;
            for (a in 0...noAliases) {
                if (RetroString.strComp(caseText, aliases[a].name))
                    RetroString.strCopyArray(caseText, aliases[a].value);
            }
            var convertResult = convertStringToInteger(caseText);
            if (convertResult.success) {
                var jPos = jumpTableStack[jumpTableStackPos];
                var jOffset = jPos + 4;
                jumpTableData[convertResult.value - jumpTableData[jPos] + jOffset] = scriptDataPos - scriptDataOffset;
            }
            return true;
        }
    }

    public static function appendIntegerToString(text:Array<Int>, value:Int):Void {
        var textPos = 0;
        while (text[textPos] != 0) ++textPos;
        var cnt = 0;
        var v = value;
        if (v == 0) { cnt = 1; }
        else { while (v != 0) { v = Std.int(v / 10); cnt++; } }
        var digits:Array<Int> = [];
        v = value;
        for (i in 0...cnt) { digits.push(v % 10); v = Std.int(v / 10); }
        for (i in 0...cnt) {
            var digit = digits[cnt - 1 - i];
            text[textPos++] = digit + "0".code;
        }
        text[textPos] = 0;
    }

    public static function convertStringToInteger(text:Array<Int>):{success:Bool, value:Int} {
        var charID = 0;
        var negative = false;
        var base = 10;
        var value = 0;
        if (text[0] != "+".code && !(text[0] >= "0".code && text[0] <= "9".code) && text[0] != "-".code)
            return {success: false, value: 0};
        var strLength = RetroString.strLength(text) - 1;
        var charVal = 0;
        if (text[0] == "-".code) { negative = true; charID = 1; --strLength; }
        else if (text[0] == "+".code) { charID = 1; --strLength; }
        if (text[charID] == "0".code) {
            if (text[charID + 1] == "x".code || text[charID + 1] == "X".code) base = 16;
            else if (text[charID + 1] == "b".code || text[charID + 1] == "B".code) base = 2;
            else if (text[charID + 1] == "o".code || text[charID + 1] == "O".code) base = 8;
            if (base != 10) { charID += 2; strLength -= 2; }
        }
        while (strLength > -1) {
            var flag = text[charID] < "0".code;
            if (!flag) {
                if (base == 16 && text[charID] > "f".code) flag = true;
                if (base == 8 && text[charID] > "7".code) flag = true;
                if (base == 2 && text[charID] > "1".code) flag = true;
            }
            if (flag) return {success: false, value: 0};
            if (strLength <= 0) {
                if (text[charID] >= "0".code && text[charID] <= "9".code) {
                    value = text[charID] + value - "0".code;
                } else if (text[charID] >= "a".code && text[charID] <= "f".code) {
                    charVal = text[charID] - "a".code;
                    charVal += 10;
                    value += charVal;
                } else if (text[charID] >= "A".code && text[charID] <= "F".code) {
                    charVal = text[charID] - "A".code;
                    charVal += 10;
                    value += charVal;
                }
            } else {
                var strlen = strLength + 1;
                charVal = 0;
                if (text[charID] >= "0".code && text[charID] <= "9".code) {
                    charVal = text[charID] - "0".code;
                } else if (text[charID] >= "a".code && text[charID] <= "f".code) {
                    charVal = text[charID] - "a".code + 10;
                } else if (text[charID] >= "A".code && text[charID] <= "F".code) {
                    charVal = text[charID] - "A".code + 10;
                }
                while (--strlen > 0) charVal *= base;
                value += charVal;
            }
            --strLength;
            ++charID;
        }
        if (negative) value = -value;
        return {success: true, value: value};
    }

    public static function copyAliasStr(dest:Array<Int>, text:Array<Int>, arrayIndex:Bool):Void {
        var textPos = 0;
        var destPos = 0;
        var arrayValue = false;
        if (arrayIndex) {
            while (text[textPos] != 0) {
                if (arrayValue) {
                    if (text[textPos] == "]".code) arrayValue = false;
                    else dest[destPos++] = text[textPos];
                    ++textPos;
                } else {
                    if (text[textPos] == "[".code) arrayValue = true;
                    ++textPos;
                }
            }
        } else {
            while (text[textPos] != 0) {
                if (arrayValue) {
                    if (text[textPos] == "]".code) arrayValue = false;
                    ++textPos;
                } else {
                    if (text[textPos] == "[".code) arrayValue = true;
                    else dest[destPos++] = text[textPos];
                    ++textPos;
                }
            }
        }
        dest[destPos] = 0;
    }

    public static function parseScriptFile(scriptName:String, scriptID:Int):Void {
        var currentSub = -1;
        jumpTableStackPos = 0;
        lineID = 0;
        noAliases = COMMONALIAS_COUNT;
        for (i in COMMONALIAS_COUNT...ALIAS_COUNT) {
            RetroString.strCopy(aliases[i].name, "");
            RetroString.strCopy(aliases[i].value, "");
        }
        var scriptPath:Array<Int> = [for (i in 0...0x40) 0];
        RetroString.strCopy(scriptPath, "Data/Scripts/");
        RetroString.strAdd(scriptPath, scriptName);
        var info = new FileInfo();
        if (Reader.loadFile(RetroString.arrayToString(scriptPath), info)) {
            var readMode:Int = READMODE_NORMAL;
            var parseMode:Int = PARSEMODE_SCOPELESS;
            var prevChar = 0;
            var curChar = 0;
            var switchDeep = 0;
            while (readMode < READMODE_EOF) {
                var textPos = 0;
                readMode = READMODE_NORMAL;
                while (readMode < READMODE_ENDLINE) {
                    prevChar = curChar;
                    curChar = Reader.fileReadByte();
                    if (readMode == READMODE_STRING) {
                        if (curChar == "\t".code || curChar == "\r".code || curChar == "\n".code || curChar == ";".code || readMode >= READMODE_COMMENTLINE) {
                            if ((curChar == "\n".code && prevChar != "\r".code) || (curChar == "\n".code && prevChar == "\r".code) || curChar == ";".code) {
                                readMode = READMODE_ENDLINE;
                                scriptText[textPos] = 0;
                            }
                        } else if (curChar != "/".code || textPos <= 0) {
                            scriptText[textPos++] = curChar;
                            if (curChar == "\"".code) readMode = READMODE_NORMAL;
                        } else if (curChar == "/".code && prevChar == "/".code) {
                            readMode = READMODE_COMMENTLINE;
                            scriptText[--textPos] = 0;
                        } else {
                            scriptText[textPos++] = curChar;
                        }
                    } else if (curChar == " ".code || curChar == "\t".code || curChar == "\r".code || curChar == "\n".code || curChar == ";".code || readMode >= READMODE_COMMENTLINE) {
                        if ((curChar == "\n".code && prevChar != "\r".code) || (curChar == "\n".code && prevChar == "\r".code) || curChar == ";".code) {
                            readMode = READMODE_ENDLINE;
                            scriptText[textPos] = 0;
                        }
                    } else if (curChar != "/".code || textPos <= 0) {
                        scriptText[textPos++] = curChar;
                        if (curChar == "\"".code && readMode == READMODE_NORMAL) readMode = READMODE_STRING;
                    } else if (curChar == "/".code && prevChar == "/".code) {
                        readMode = READMODE_COMMENTLINE;
                        scriptText[--textPos] = 0;
                    } else {
                        scriptText[textPos++] = curChar;
                    }
                    if (Reader.reachedEndOfFile()) {
                        scriptText[textPos] = 0;
                        readMode = READMODE_EOF;
                    }
                }
                switch (parseMode) {
                    case PARSEMODE_SCOPELESS:
                        ++lineID;
                        checkAliasText(scriptText);
                        var scriptTextStr = RetroString.arrayToString(scriptText);
                        if (scriptTextStr == "subObjectMain") {
                            parseMode = PARSEMODE_FUNCTION;
                            objectScriptList[scriptID].subMain.scriptCodePtr = scriptDataPos;
                            objectScriptList[scriptID].subMain.jumpTablePtr = jumpTableDataPos;
                            scriptDataOffset = scriptDataPos;
                            jumpTableOffset = jumpTableDataPos;
                            currentSub = SUB_MAIN;
                        }
                        if (scriptTextStr == "subObjectPlayerInteraction") {
                            parseMode = PARSEMODE_FUNCTION;
                            objectScriptList[scriptID].subPlayerInteraction.scriptCodePtr = scriptDataPos;
                            objectScriptList[scriptID].subPlayerInteraction.jumpTablePtr = jumpTableDataPos;
                            scriptDataOffset = scriptDataPos;
                            jumpTableOffset = jumpTableDataPos;
                            currentSub = SUB_PLAYERINTERACTION;
                        }
                        if (scriptTextStr == "subObjectDraw") {
                            parseMode = PARSEMODE_FUNCTION;
                            objectScriptList[scriptID].subDraw.scriptCodePtr = scriptDataPos;
                            objectScriptList[scriptID].subDraw.jumpTablePtr = jumpTableDataPos;
                            scriptDataOffset = scriptDataPos;
                            jumpTableOffset = jumpTableDataPos;
                            currentSub = SUB_DRAW;
                        }
                        if (scriptTextStr == "subObjectStartup") {
                            parseMode = PARSEMODE_FUNCTION;
                            objectScriptList[scriptID].subStartup.scriptCodePtr = scriptDataPos;
                            objectScriptList[scriptID].subStartup.jumpTablePtr = jumpTableDataPos;
                            scriptDataOffset = scriptDataPos;
                            jumpTableOffset = jumpTableDataPos;
                            currentSub = SUB_SETUP;
                        }
                        if (scriptTextStr == "subPlayerMain") {
                            parseMode = PARSEMODE_FUNCTION;
                            PlayerManager.playerScriptList[scriptID].scriptCodePtr_PlayerMain = scriptDataPos;
                            PlayerManager.playerScriptList[scriptID].jumpTablePtr_PlayerMain = jumpTableDataPos;
                            scriptDataOffset = scriptDataPos;
                            jumpTableOffset = jumpTableDataPos;
                            currentSub = SUB_PLAYERMAIN;
                        }
                        if (RetroString.findStringToken(scriptText, "subPlayerState", 1) == 0) {
                            var stateName:Array<Int> = [for (i in 0...0x20) 0];
                            var tp = 14;
                            while (scriptText[tp] != 0) { stateName[tp - 14] = scriptText[tp]; tp++; }
                            stateName[tp - 14] = 0;
                            for (a in 0...noAliases) {
                                if (RetroString.strComp(stateName, aliases[a].name))
                                    RetroString.strCopyArray(stateName, aliases[a].value);
                            }
                            var convertResult = convertStringToInteger(stateName);
                            if (convertResult.success) {
                                PlayerManager.playerScriptList[scriptID].scriptCodePtr_PlayerState[convertResult.value] = scriptDataPos;
                                PlayerManager.playerScriptList[scriptID].jumpTablePtr_PlayerState[convertResult.value] = jumpTablePos;
                                scriptDataOffset = scriptDataPos;
                                jumpTableOffset = jumpTablePos;
                                parseMode = PARSEMODE_FUNCTION;
                                currentSub = SUB_PLAYERSTATE;
                            } else {
                                parseMode = PARSEMODE_SCOPELESS;
                            }
                        }
                    case PARSEMODE_PLATFORMSKIP:
                        ++lineID;
                        if (RetroString.findStringToken(scriptText, "{", 1) == 0) parseMode = PARSEMODE_FUNCTION;
                    case PARSEMODE_FUNCTION:
                        ++lineID;
                        if (scriptText[0] != 0) {
                            var scriptTextStr = RetroString.arrayToString(scriptText);
                            if (scriptTextStr == "endsub") {
                                scriptData[scriptDataPos++] = FUNC_END;
                                parseMode = PARSEMODE_SCOPELESS;
                            } else {
                                convertIfWhileStatement(scriptText);
                                if (convertSwitchStatement(scriptText)) {
                                    parseMode = PARSEMODE_SWITCHREAD;
                                    info.readPos = Reader.getFilePosition();
                                    switchDeep = 0;
                                }
                                convertArithmaticSyntax(scriptText);
                                if (!readSwitchCase(scriptText)) {
                                    convertFunctionText(scriptText);
                                    if (scriptText[0] == 0) {
                                        parseMode = PARSEMODE_SCOPELESS;
                                        switch (currentSub) {
                                            case SUB_MAIN: scriptData[objectScriptList[scriptID].subMain.scriptCodePtr] = FUNC_END;
                                            case SUB_PLAYERINTERACTION: scriptData[objectScriptList[scriptID].subPlayerInteraction.scriptCodePtr] = FUNC_END;
                                            case SUB_DRAW: scriptData[objectScriptList[scriptID].subDraw.scriptCodePtr] = FUNC_END;
                                            case SUB_SETUP: scriptData[objectScriptList[scriptID].subStartup.scriptCodePtr] = FUNC_END;
                                            case SUB_PLAYERMAIN: scriptData[PlayerManager.playerScriptList[scriptID].scriptCodePtr_PlayerMain] = FUNC_END;
                                            case SUB_PLAYERSTATE: for (s in 0...256) scriptData[PlayerManager.playerScriptList[scriptID].scriptCodePtr_PlayerState[s]] = FUNC_END;
                                            default:
                                        }
                                    }
                                }
                            }
                        }
                    case PARSEMODE_SWITCHREAD:
                        if (RetroString.findStringToken(scriptText, "switch", 1) == 0) ++switchDeep;
                        if (switchDeep != 0) {
                            if (RetroString.findStringToken(scriptText, "endswitch", 1) == 0) --switchDeep;
                        } else if (RetroString.findStringToken(scriptText, "endswitch", 1) != 0) {
                            checkCaseNumber(scriptText);
                        } else {
                            Reader.setFilePosition(info.readPos);
                            parseMode = PARSEMODE_FUNCTION;
                            var jPos = jumpTableStack[jumpTableStackPos];
                            switchDeep = intAbs(jumpTableData[jPos + 1] - jumpTableData[jPos]) + 1;
                            for (tp in 0...switchDeep) jumpTableData[jumpTableDataPos++] = -1;
                        }
                    default:
                }
            }
            Reader.closeFile();
        }
    }

    public static function clearScriptData():Void {
        for (i in 0...SCRIPTDATA_COUNT) scriptData[i] = 0;
        for (i in 0...JUMPTABLE_COUNT) jumpTableData[i] = 0;
        Animation.scriptFramesNo = 0;
        jumpTablePos = 0;
        jumpTableStackPos = 0;
        scriptDataPos = 0;
        scriptDataOffset = 0;
        jumpTableDataPos = 0;
        jumpTableOffset = 0;
        noAliases = COMMONALIAS_COUNT;
        lineID = 0;
        for (p in 0...PLAYER_COUNT) {
            for (s in 0...256) {
                PlayerManager.playerScriptList[p].scriptCodePtr_PlayerState[s] = SCRIPTDATA_COUNT - 1;
                PlayerManager.playerScriptList[p].jumpTablePtr_PlayerState[s] = JUMPTABLE_COUNT - 1;
            }
            PlayerManager.playerScriptList[p].scriptCodePtr_PlayerMain = SCRIPTDATA_COUNT - 1;
            PlayerManager.playerScriptList[p].jumpTablePtr_PlayerMain = JUMPTABLE_COUNT - 1;
        }
        for (o in 0...OBJECT_COUNT) {
            var scriptInfo = objectScriptList[o];
            scriptInfo.subMain.scriptCodePtr = SCRIPTDATA_COUNT - 1;
            scriptInfo.subMain.jumpTablePtr = JUMPTABLE_COUNT - 1;
            scriptInfo.subPlayerInteraction.scriptCodePtr = SCRIPTDATA_COUNT - 1;
            scriptInfo.subPlayerInteraction.jumpTablePtr = JUMPTABLE_COUNT - 1;
            scriptInfo.subDraw.scriptCodePtr = SCRIPTDATA_COUNT - 1;
            scriptInfo.subDraw.jumpTablePtr = JUMPTABLE_COUNT - 1;
            scriptInfo.subStartup.scriptCodePtr = SCRIPTDATA_COUNT - 1;
            scriptInfo.subStartup.jumpTablePtr = JUMPTABLE_COUNT - 1;
            scriptInfo.frameStartPtr = 0;
            scriptInfo.spriteSheetID = 0;
        }
    }

    public static function processScript(scriptCodePtr:Int, jumpTablePtr:Int, scriptSub:Int):Void {
        currentScriptSub = scriptSub;
        currentScriptCodePtr = scriptCodePtr;
        var running = true;
        var scriptDataPtr = scriptCodePtr;
        jumpTableStackPos = 0;
        while (running) {
            var opcode = scriptData[scriptDataPtr++];
            currentOpcode = opcode;
            var opcodeSize = functions[opcode].opcodeSize;
            var scriptCodeOffset = scriptDataPtr;
            for (i in 0...opcodeSize) {
                var opcodeType = scriptData[scriptDataPtr++];
                if (opcodeType == SCRIPTVAR_VAR) {
                    var arrayVal = 0;
                    switch (scriptData[scriptDataPtr++]) {
                        case VARARR_NONE: arrayVal = Object.objectLoop;
                        case VARARR_ARRAY:
                            if (scriptData[scriptDataPtr++] == 1) arrayVal = scriptEng.arrayPosition[scriptData[scriptDataPtr++]];
                            else arrayVal = scriptData[scriptDataPtr++];
                        case VARARR_ENTNOPLUS1:
                            if (scriptData[scriptDataPtr++] == 1) arrayVal = scriptEng.arrayPosition[scriptData[scriptDataPtr++]] + Object.objectLoop;
                            else arrayVal = scriptData[scriptDataPtr++] + Object.objectLoop;
                        case VARARR_ENTNOMINUS1:
                            if (scriptData[scriptDataPtr++] == 1) arrayVal = Object.objectLoop - scriptEng.arrayPosition[scriptData[scriptDataPtr++]];
                            else arrayVal = Object.objectLoop - scriptData[scriptDataPtr++];
                        default:
                    }
                    scriptEng.operands[i] = getVariableValue(scriptData[scriptDataPtr++], arrayVal);
                } else if (opcodeType == SCRIPTVAR_INTCONST) {
                    scriptEng.operands[i] = scriptData[scriptDataPtr++];
                } else if (opcodeType == SCRIPTVAR_STRCONST) {
                    var strLen = scriptData[scriptDataPtr++];
                    scriptText[strLen] = 0;
                    for (c in 0...strLen) {
                        switch (c % 4) {
                            case 0: scriptText[c] = scriptData[scriptDataPtr] >> 24;
                            case 1: scriptText[c] = (0x00FFFFFF & scriptData[scriptDataPtr]) >> 16;
                            case 2: scriptText[c] = (0x0000FFFF & scriptData[scriptDataPtr]) >> 8;
                            case 3: scriptText[c] = (0x000000FF & scriptData[scriptDataPtr++]) >> 0;
                        }
                    }
                    scriptDataPtr++;
                }
            }
            var entity = Object.objectEntityList[Object.objectLoop];
            var player = PlayerManager.playerList[PlayerManager.playerNo];
            if (entity.type < 0 || entity.type >= OBJECT_COUNT) { running = false; continue; }
            var scriptInfo = objectScriptList[entity.type];
            if (scriptInfo == null) { running = false; continue; }
            var result = executeOpcode(opcode, opcodeSize, scriptSub, scriptCodePtr, jumpTablePtr, entity, player, scriptInfo);
            opcodeSize = result.newOpcodeSize;
            scriptDataPtr = result.newScriptDataPtr != -1 ? result.newScriptDataPtr : scriptDataPtr;
            if (opcode == FUNC_END) running = false;
            if (opcodeSize > 0) scriptDataPtr = scriptCodeOffset;
            for (i in 0...opcodeSize) {
                var opcodeType = scriptData[scriptDataPtr++];
                if (opcodeType == SCRIPTVAR_VAR) {
                    var arrayVal = 0;
                    switch (scriptData[scriptDataPtr++]) {
                        case VARARR_NONE: arrayVal = Object.objectLoop;
                        case VARARR_ARRAY:
                            if (scriptData[scriptDataPtr++] == 1) arrayVal = scriptEng.arrayPosition[scriptData[scriptDataPtr++]];
                            else arrayVal = scriptData[scriptDataPtr++];
                        case VARARR_ENTNOPLUS1:
                            if (scriptData[scriptDataPtr++] == 1) arrayVal = scriptEng.arrayPosition[scriptData[scriptDataPtr++]] + Object.objectLoop;
                            else arrayVal = scriptData[scriptDataPtr++] + Object.objectLoop;
                        case VARARR_ENTNOMINUS1:
                            if (scriptData[scriptDataPtr++] == 1) arrayVal = Object.objectLoop - scriptEng.arrayPosition[scriptData[scriptDataPtr++]];
                            else arrayVal = Object.objectLoop - scriptData[scriptDataPtr++];
                        default:
                    }
                    setVariableValue(scriptData[scriptDataPtr++], arrayVal, scriptEng.operands[i]);
                } else if (opcodeType == SCRIPTVAR_INTCONST) {
                    scriptDataPtr++;
                } else if (opcodeType == SCRIPTVAR_STRCONST) {
                    var strLen = scriptData[scriptDataPtr++];
                    for (c in 0...strLen) { if (c % 4 == 3) ++scriptDataPtr; }
                    scriptDataPtr++;
                }
            }
        }
    }

    static function getVariableValue(varID:Int, arrayVal:Int):Int {
        var player = PlayerManager.playerList[PlayerManager.playerNo];
        var entity = Object.objectEntityList[arrayVal];
        switch (varID) {
            case VAR_OBJECTTYPE: return entity.type;
            case VAR_OBJECTPROPERTYVALUE: return entity.propertyValue;
            case VAR_OBJECTXPOS: return entity.xPos;
            case VAR_OBJECTYPOS: return entity.yPos;
            case VAR_OBJECTIXPOS: return entity.xPos >> 16;
            case VAR_OBJECTIYPOS: return entity.yPos >> 16;
            case VAR_OBJECTSTATE: return entity.state;
            case VAR_OBJECTROTATION: return entity.rotation;
            case VAR_OBJECTSCALE: return entity.scale;
            case VAR_OBJECTPRIORITY: return entity.priority;
            case VAR_OBJECTDRAWORDER: return entity.drawOrder;
            case VAR_OBJECTDIRECTION: return entity.direction;
            case VAR_OBJECTINKEFFECT: return entity.inkEffect;
            case VAR_OBJECTFRAME: return entity.frame;
            case VAR_OBJECTVALUE0: return entity.values[0];
            case VAR_OBJECTVALUE1: return entity.values[1];
            case VAR_OBJECTVALUE2: return entity.values[2];
            case VAR_OBJECTVALUE3: return entity.values[3];
            case VAR_OBJECTVALUE4: return entity.values[4];
            case VAR_OBJECTVALUE5: return entity.values[5];
            case VAR_OBJECTVALUE6: return entity.values[6];
            case VAR_OBJECTVALUE7: return entity.values[7];
            case VAR_TEMPVALUE0: return scriptEng.tempValue[0];
            case VAR_TEMPVALUE1: return scriptEng.tempValue[1];
            case VAR_TEMPVALUE2: return scriptEng.tempValue[2];
            case VAR_TEMPVALUE3: return scriptEng.tempValue[3];
            case VAR_TEMPVALUE4: return scriptEng.tempValue[4];
            case VAR_TEMPVALUE5: return scriptEng.tempValue[5];
            case VAR_TEMPVALUE6: return scriptEng.tempValue[6];
            case VAR_TEMPVALUE7: return scriptEng.tempValue[7];
            case VAR_CHECKRESULT: return scriptEng.checkResult;
            case VAR_ARRAYPOS0: return scriptEng.arrayPosition[0];
            case VAR_ARRAYPOS1: return scriptEng.arrayPosition[1];
            case VAR_KEYDOWNUP: return Input.gKeyDown.up;
            case VAR_KEYDOWNDOWN: return Input.gKeyDown.down;
            case VAR_KEYDOWNLEFT: return Input.gKeyDown.left;
            case VAR_KEYDOWNRIGHT: return Input.gKeyDown.right;
            case VAR_KEYDOWNBUTTONA: return Input.gKeyDown.A;
            case VAR_KEYDOWNBUTTONB: return Input.gKeyDown.B;
            case VAR_KEYDOWNBUTTONC: return Input.gKeyDown.C;
            case VAR_KEYDOWNSTART: return Input.gKeyDown.start;
            case VAR_KEYPRESSUP: return Input.gKeyPress.up;
            case VAR_KEYPRESSDOWN: return Input.gKeyPress.down;
            case VAR_KEYPRESSLEFT: return Input.gKeyPress.left;
            case VAR_KEYPRESSRIGHT: return Input.gKeyPress.right;
            case VAR_KEYPRESSBUTTONA: return Input.gKeyPress.A;
            case VAR_KEYPRESSBUTTONB: return Input.gKeyPress.B;
            case VAR_KEYPRESSBUTTONC: return Input.gKeyPress.C;
            case VAR_KEYPRESSSTART: return Input.gKeyPress.start;
            case VAR_MENU1SELECTION: return Text.gameMenu[0].selection1;
            case VAR_MENU2SELECTION: return Text.gameMenu[1].selection1;
            case VAR_STAGEACTIVELIST: return Scene.activeStageList;
            case VAR_STAGELISTPOS: return Scene.stageListPosition;
            case VAR_XSCROLLOFFSET: return Scene.xScrollOffset;
            case VAR_YSCROLLOFFSET: return Scene.yScrollOffset;
            case VAR_GLOBAL: return globalVariables[arrayVal];
            case VAR_STAGETIMEENABLED: return Scene.timeEnabled ? 1 : 0;
            case VAR_STAGEMILLISECONDS: return Scene.milliSeconds;
            case VAR_STAGESECONDS: return Scene.seconds;
            case VAR_STAGEMINUTES: return Scene.minutes;
            case VAR_STAGEACTNO: return Scene.actNumber;
            case VAR_OBJECTENTITYNO: return arrayVal;
            case VAR_PLAYERTYPE: return player.type;
            case VAR_PLAYERSTATE: return player.state;
            case VAR_PLAYERCONTROLMODE: return player.controlMode;
            case VAR_PLAYERCOLLISIONMODE: return player.collisionMode;
            case VAR_PLAYERCOLLISIONPLANE: return player.collisionPlane;
            case VAR_PLAYERXPOS: return player.xPos;
            case VAR_PLAYERYPOS: return player.yPos;
            case VAR_PLAYERSCREENXPOS: return player.screenXPos;
            case VAR_PLAYERSCREENYPOS: return player.screenYPos;
            case VAR_PLAYERSPEED: return player.speed;
            case VAR_PLAYERXVELOCITY: return player.xVelocity;
            case VAR_PLAYERYVELOCITY: return player.yVelocity;
            case VAR_PLAYERGRAVITY: return player.gravity;
            case VAR_PLAYERANGLE: return player.angle;
            case VAR_PLAYERROTATION: return player.rotation;
            case VAR_PLAYERDIRECTION: return player.direction;
            case VAR_PLAYERANIMATION: return player.animation;
            case VAR_PLAYERFRAME: return player.frame;
            case VAR_PLAYERSKIDDING: return player.skidding;
            case VAR_PLAYERPUSHING: return player.pushing;
            case VAR_PLAYERFRICTIONLOSS: return player.frictionLoss;
            case VAR_PLAYERWALKINGSPEED: return player.walkingSpeed;
            case VAR_PLAYERRUNNINGSPEED: return player.runningSpeed;
            case VAR_PLAYERJUMPINGSPEED: return player.jumpingSpeed;
            case VAR_PLAYERTRACKSCROLL: return player.trackScroll;
            case VAR_PLAYERUP: return player.up;
            case VAR_PLAYERDOWN: return player.down;
            case VAR_PLAYERLEFT: return player.left;
            case VAR_PLAYERRIGHT: return player.right;
            case VAR_PLAYERJUMPPRESS: return player.jumpPress;
            case VAR_PLAYERJUMPHOLD: return player.jumpHold;
            case VAR_PLAYERFOLLOWPLAYER1: return player.followPlayer1;
            case VAR_PLAYERLOOKPOS: return player.lookPos;
            case VAR_PLAYERWATER: return player.water;
            case VAR_PLAYERTOPSPEED: return player.stats.topSpeed;
            case VAR_PLAYERACCELERATION: return player.stats.acceleration;
            case VAR_PLAYERDECELERATION: return player.stats.deceleration;
            case VAR_PLAYERAIRACCELERATION: return player.stats.airAcceleration;
            case VAR_PLAYERAIRDECELERATION: return player.stats.airDeceleration;
            case VAR_PLAYERGRAVITYSTRENGTH: return player.stats.gravityStrength;
            case VAR_PLAYERJUMPSTRENGTH: return player.stats.jumpStrength;
            case VAR_PLAYERROLLINGACCELERATION: return player.stats.rollingAcceleration;
            case VAR_PLAYERROLLINGDECELERATION: return player.stats.rollingDeceleration;
            case VAR_PLAYERENTITYNO: return PlayerManager.playerNo;
            case VAR_PLAYERCOLLISIONLEFT: return Collision.getPlayerCBox(PlayerManager.playerScriptList[PlayerManager.playerNo]).left[0];
            case VAR_PLAYERCOLLISIONTOP: return Collision.getPlayerCBox(PlayerManager.playerScriptList[PlayerManager.playerNo]).top[0];
            case VAR_PLAYERCOLLISIONRIGHT: return Collision.getPlayerCBox(PlayerManager.playerScriptList[PlayerManager.playerNo]).right[0];
            case VAR_PLAYERCOLLISIONBOTTOM: return Collision.getPlayerCBox(PlayerManager.playerScriptList[PlayerManager.playerNo]).bottom[0];
            case VAR_PLAYERFLAILING: return player.flailing[arrayVal];
            case VAR_PLAYERTIMER: return player.timer;
            case VAR_PLAYERTILECOLLISIONS: return player.tileCollisions;
            case VAR_PLAYEROBJECTINTERACTION: return player.objectInteraction;
            case VAR_PLAYERANIMATIONSPEED: return player.animationSpeed;
            case VAR_STAGEPAUSEENABLED: return Scene.pauseEnabled ? 1 : 0;
            case VAR_STAGELISTSIZE: return Scene.stageListCount[Scene.activeStageList];
            case VAR_SCREENCAMERAENABLED: return Scene.cameraEnabled;
            case VAR_SCREENCAMERASTYLE: return Scene.cameraStyle;
            case VAR_MUSICVOLUME: return Audio.musicVolume;
            case VAR_MUSICCURRENTTRACK: return Audio.currentMusicTrack;
            case VAR_PLAYERVISIBLE: return player.visible;
            case VAR_STAGENEWXBOUNDARY1: return Scene.newXBoundary1;
            case VAR_STAGENEWXBOUNDARY2: return Scene.newXBoundary2;
            case VAR_STAGENEWYBOUNDARY1: return Scene.newYBoundary1;
            case VAR_STAGENEWYBOUNDARY2: return Scene.newYBoundary2;
            case VAR_STAGEXBOUNDARY1: return Scene.xBoundary1;
            case VAR_STAGEXBOUNDARY2: return Scene.xBoundary2;
            case VAR_STAGEYBOUNDARY1: return Scene.yBoundary1;
            case VAR_STAGEYBOUNDARY2: return Scene.yBoundary2;
            case VAR_OBJECTOUTOFBOUNDS:
                var pos = entity.xPos >> 16;
                if (pos <= Scene.xScrollOffset - Object.OBJECT_BORDER_X1 || pos >= Object.OBJECT_BORDER_X2 + Scene.xScrollOffset) return 1;
                pos = entity.yPos >> 16;
                return (pos <= Scene.yScrollOffset - Object.OBJECT_BORDER_Y1 || pos >= Scene.yScrollOffset + Object.OBJECT_BORDER_Y2) ? 1 : 0;
            default: return 0;
        }
    }

    static function setVariableValue(varID:Int, arrayVal:Int, value:Int):Void {
        var player = PlayerManager.playerList[PlayerManager.playerNo];
        var entity = Object.objectEntityList[arrayVal];
        switch (varID) {
            case VAR_OBJECTTYPE:
                if (arrayVal == 0 && value == 0) {
                    var sourceType = Object.objectEntityList[Object.objectLoop].type;
                    var playerState = PlayerManager.playerList[0].state;
                    var funcName = (currentOpcode >= 0 && currentOpcode < functions.length) ? rsdk.core.RetroString.arrayToString(functions[currentOpcode].name) : "UNKNOWN";
                    rsdk.core.Debug.printLog("SCRIPT SET PLAYER TYPE TO 0! objectLoop=" + Object.objectLoop + " opcode=" + currentOpcode + "(" + funcName + ") codePtr=" + currentScriptCodePtr + " playerState=" + playerState + " scriptSub=" + currentScriptSub);
                }
                entity.type = value;
            case VAR_OBJECTPROPERTYVALUE: entity.propertyValue = value;
            case VAR_OBJECTXPOS: entity.xPos = value;
            case VAR_OBJECTYPOS: entity.yPos = value;
            case VAR_OBJECTIXPOS: entity.xPos = value << 16;
            case VAR_OBJECTIYPOS: entity.yPos = value << 16;
            case VAR_OBJECTSTATE: entity.state = value;
            case VAR_OBJECTROTATION: entity.rotation = value;
            case VAR_OBJECTSCALE: entity.scale = value;
            case VAR_OBJECTPRIORITY: entity.priority = value;
            case VAR_OBJECTDRAWORDER: entity.drawOrder = value;
            case VAR_OBJECTDIRECTION: entity.direction = value;
            case VAR_OBJECTINKEFFECT: entity.inkEffect = value;
            case VAR_OBJECTFRAME: entity.frame = value;
            case VAR_OBJECTVALUE0: entity.values[0] = value;
            case VAR_OBJECTVALUE1: entity.values[1] = value;
            case VAR_OBJECTVALUE2: entity.values[2] = value;
            case VAR_OBJECTVALUE3: entity.values[3] = value;
            case VAR_OBJECTVALUE4: entity.values[4] = value;
            case VAR_OBJECTVALUE5: entity.values[5] = value;
            case VAR_OBJECTVALUE6: entity.values[6] = value;
            case VAR_OBJECTVALUE7: entity.values[7] = value;
            case VAR_TEMPVALUE0: scriptEng.tempValue[0] = value;
            case VAR_TEMPVALUE1: scriptEng.tempValue[1] = value;
            case VAR_TEMPVALUE2: scriptEng.tempValue[2] = value;
            case VAR_TEMPVALUE3: scriptEng.tempValue[3] = value;
            case VAR_TEMPVALUE4: scriptEng.tempValue[4] = value;
            case VAR_TEMPVALUE5: scriptEng.tempValue[5] = value;
            case VAR_TEMPVALUE6: scriptEng.tempValue[6] = value;
            case VAR_TEMPVALUE7: scriptEng.tempValue[7] = value;
            case VAR_CHECKRESULT: scriptEng.checkResult = value;
            case VAR_ARRAYPOS0: scriptEng.arrayPosition[0] = value;
            case VAR_ARRAYPOS1: scriptEng.arrayPosition[1] = value;
            case VAR_KEYDOWNUP: Input.gKeyDown.up = value;
            case VAR_KEYDOWNDOWN: Input.gKeyDown.down = value;
            case VAR_KEYDOWNLEFT: Input.gKeyDown.left = value;
            case VAR_KEYDOWNRIGHT: Input.gKeyDown.right = value;
            case VAR_KEYDOWNBUTTONA: Input.gKeyDown.A = value;
            case VAR_KEYDOWNBUTTONB: Input.gKeyDown.B = value;
            case VAR_KEYDOWNBUTTONC: Input.gKeyDown.C = value;
            case VAR_KEYDOWNSTART: Input.gKeyDown.start = value;
            case VAR_KEYPRESSUP: Input.gKeyPress.up = value;
            case VAR_KEYPRESSDOWN: Input.gKeyPress.down = value;
            case VAR_KEYPRESSLEFT: Input.gKeyPress.left = value;
            case VAR_KEYPRESSRIGHT: Input.gKeyPress.right = value;
            case VAR_KEYPRESSBUTTONA: Input.gKeyPress.A = value;
            case VAR_KEYPRESSBUTTONB: Input.gKeyPress.B = value;
            case VAR_KEYPRESSBUTTONC: Input.gKeyPress.C = value;
            case VAR_KEYPRESSSTART: Input.gKeyPress.start = value;
            case VAR_MENU1SELECTION: Text.gameMenu[0].selection1 = value;
            case VAR_MENU2SELECTION: Text.gameMenu[1].selection1 = value;
            case VAR_STAGEACTIVELIST: Scene.activeStageList = value;
            case VAR_STAGELISTPOS: Scene.stageListPosition = value;
            case VAR_XSCROLLOFFSET: Scene.xScrollOffset = value;
            case VAR_YSCROLLOFFSET: Scene.yScrollOffset = value;
            case VAR_GLOBAL: globalVariables[arrayVal] = value;
            case VAR_STAGETIMEENABLED: Scene.timeEnabled = value != 0;
            case VAR_STAGEMILLISECONDS: Scene.milliSeconds = value;
            case VAR_STAGESECONDS: Scene.seconds = value;
            case VAR_STAGEMINUTES: Scene.minutes = value;
            case VAR_STAGEACTNO: Scene.actNumber = value;
            case VAR_PLAYERTYPE: player.type = value;
            case VAR_PLAYERSTATE: player.state = value;
            case VAR_PLAYERCONTROLMODE: player.controlMode = value;
            case VAR_PLAYERCOLLISIONMODE: player.collisionMode = value;
            case VAR_PLAYERCOLLISIONPLANE: player.collisionPlane = value;
            case VAR_PLAYERXPOS: player.xPos = value;
            case VAR_PLAYERYPOS: player.yPos = value;
            case VAR_PLAYERSCREENXPOS: player.screenXPos = value;
            case VAR_PLAYERSCREENYPOS: player.screenYPos = value;
            case VAR_PLAYERSPEED: player.speed = value;
            case VAR_PLAYERXVELOCITY: player.xVelocity = value;
            case VAR_PLAYERYVELOCITY: player.yVelocity = value;
            case VAR_PLAYERGRAVITY: player.gravity = value;
            case VAR_PLAYERANGLE: player.angle = value;
            case VAR_PLAYERROTATION: player.rotation = value;
            case VAR_PLAYERDIRECTION: player.direction = value;
            case VAR_PLAYERANIMATION: player.animation = value;
            case VAR_PLAYERFRAME: player.frame = value;
            case VAR_PLAYERSKIDDING: player.skidding = value;
            case VAR_PLAYERPUSHING: player.pushing = value;
            case VAR_PLAYERFRICTIONLOSS: player.frictionLoss = value;
            case VAR_PLAYERWALKINGSPEED: player.walkingSpeed = value;
            case VAR_PLAYERRUNNINGSPEED: player.runningSpeed = value;
            case VAR_PLAYERJUMPINGSPEED: player.jumpingSpeed = value;
            case VAR_PLAYERTRACKSCROLL: player.trackScroll = value;
            case VAR_PLAYERUP: player.up = value;
            case VAR_PLAYERDOWN: player.down = value;
            case VAR_PLAYERLEFT: player.left = value;
            case VAR_PLAYERRIGHT: player.right = value;
            case VAR_PLAYERJUMPPRESS: player.jumpPress = value;
            case VAR_PLAYERJUMPHOLD: player.jumpHold = value;
            case VAR_PLAYERFOLLOWPLAYER1: player.followPlayer1 = value;
            case VAR_PLAYERLOOKPOS: player.lookPos = value;
            case VAR_PLAYERWATER: player.water = value;
            case VAR_PLAYERTOPSPEED: player.stats.topSpeed = value;
            case VAR_PLAYERACCELERATION: player.stats.acceleration = value;
            case VAR_PLAYERDECELERATION: player.stats.deceleration = value;
            case VAR_PLAYERAIRACCELERATION: player.stats.airAcceleration = value;
            case VAR_PLAYERAIRDECELERATION: player.stats.airDeceleration = value;
            case VAR_PLAYERGRAVITYSTRENGTH: player.stats.gravityStrength = value;
            case VAR_PLAYERJUMPSTRENGTH: player.stats.jumpStrength = value;
            case VAR_PLAYERROLLINGACCELERATION: player.stats.rollingAcceleration = value;
            case VAR_PLAYERROLLINGDECELERATION: player.stats.rollingDeceleration = value;
            case VAR_PLAYERFLAILING: player.flailing[arrayVal] = value;
            case VAR_PLAYERTIMER: player.timer = value;
            case VAR_PLAYERTILECOLLISIONS: player.tileCollisions = value;
            case VAR_PLAYEROBJECTINTERACTION: player.objectInteraction = value;
            case VAR_PLAYERANIMATIONSPEED: player.animationSpeed = value;
            case VAR_STAGEPAUSEENABLED: Scene.pauseEnabled = value != 0;
            case VAR_SCREENCAMERAENABLED: Scene.cameraEnabled = value;
            case VAR_SCREENCAMERASTYLE: Scene.cameraStyle = value;
            case VAR_MUSICVOLUME: Audio.setMusicVolume(value);
            case VAR_MUSICCURRENTTRACK: Audio.currentMusicTrack = value;
            case VAR_PLAYERVISIBLE: player.visible = value;
            case VAR_STAGENEWXBOUNDARY1: Scene.newXBoundary1 = value;
            case VAR_STAGENEWXBOUNDARY2: Scene.newXBoundary2 = value;
            case VAR_STAGENEWYBOUNDARY1: Scene.newYBoundary1 = value;
            case VAR_STAGENEWYBOUNDARY2: Scene.newYBoundary2 = value;
            case VAR_STAGEXBOUNDARY1: if (Scene.xBoundary1 != value) { Scene.xBoundary1 = value; Scene.newXBoundary1 = value; }
            case VAR_STAGEXBOUNDARY2: if (Scene.xBoundary2 != value) { Scene.xBoundary2 = value; Scene.newXBoundary2 = value; }
            case VAR_STAGEYBOUNDARY1: if (Scene.yBoundary1 != value) { Scene.yBoundary1 = value; Scene.newYBoundary1 = value; }
            case VAR_STAGEYBOUNDARY2: if (Scene.yBoundary2 != value) { Scene.yBoundary2 = value; Scene.newYBoundary2 = value; }
            default:
        }
    }

    static function executeOpcode(opcode:Int, opcodeSize:Int, scriptSub:Int, scriptCodePtr:Int, jumpTablePtr:Int, entity:Entity, player:Player, scriptInfo:ObjectScript):{newOpcodeSize:Int, newScriptDataPtr:Int} {
        var newDataPtr = -1;
        switch (opcode) {
            case FUNC_END: return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_EQUAL: scriptEng.operands[0] = scriptEng.operands[1];
            case FUNC_ADD: scriptEng.operands[0] += scriptEng.operands[1];
            case FUNC_SUB: scriptEng.operands[0] -= scriptEng.operands[1];
            case FUNC_INC: ++scriptEng.operands[0];
            case FUNC_DEC: --scriptEng.operands[0];
            case FUNC_MUL: scriptEng.operands[0] *= scriptEng.operands[1];
            case FUNC_DIV: scriptEng.operands[0] = Std.int(scriptEng.operands[0] / scriptEng.operands[1]);
            case FUNC_SHR: scriptEng.operands[0] >>= scriptEng.operands[1];
            case FUNC_SHL: scriptEng.operands[0] <<= scriptEng.operands[1];
            case FUNC_AND: scriptEng.operands[0] &= scriptEng.operands[1];
            case FUNC_OR: scriptEng.operands[0] |= scriptEng.operands[1];
            case FUNC_XOR: scriptEng.operands[0] ^= scriptEng.operands[1];
            case FUNC_NOT: scriptEng.operands[0] = ~scriptEng.operands[0];
            case FUNC_FLIPSIGN: scriptEng.operands[0] = -scriptEng.operands[0];
            case FUNC_CHECKEQUAL: scriptEng.checkResult = (scriptEng.operands[0] == scriptEng.operands[1]) ? 1 : 0; return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_CHECKGREATER: scriptEng.checkResult = (scriptEng.operands[0] > scriptEng.operands[1]) ? 1 : 0; return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_CHECKLOWER: scriptEng.checkResult = (scriptEng.operands[0] < scriptEng.operands[1]) ? 1 : 0; return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_CHECKNOTEQUAL: scriptEng.checkResult = (scriptEng.operands[0] != scriptEng.operands[1]) ? 1 : 0; return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_IFEQUAL:
                if (scriptEng.operands[1] != scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0]];
                jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_IFGREATER:
                if (scriptEng.operands[1] <= scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0]];
                jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_IFGREATEROREQUAL:
                if (scriptEng.operands[1] < scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0]];
                jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_IFLOWER:
                if (scriptEng.operands[1] >= scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0]];
                jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_IFLOWEROREQUAL:
                if (scriptEng.operands[1] > scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0]];
                jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_IFNOTEQUAL:
                if (scriptEng.operands[1] == scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0]];
                jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_ELSE:
                newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + jumpTableStack[jumpTableStackPos--] + 1];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_ENDIF: --jumpTableStackPos; return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_WEQUAL:
                if (scriptEng.operands[1] != scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0] + 1];
                else jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_WGREATER:
                if (scriptEng.operands[1] <= scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0] + 1];
                else jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_WGREATEROREQUAL:
                if (scriptEng.operands[1] < scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0] + 1];
                else jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_WLOWER:
                if (scriptEng.operands[1] >= scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0] + 1];
                else jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_WLOWEROREQUAL:
                if (scriptEng.operands[1] > scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0] + 1];
                else jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_WNOTEQUAL:
                if (scriptEng.operands[1] == scriptEng.operands[2]) newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0] + 1];
                else jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_LOOP:
                newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + jumpTableStack[jumpTableStackPos--]];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_SWITCH:
                jumpTableStack[++jumpTableStackPos] = scriptEng.operands[0];
                if (scriptEng.operands[1] < jumpTableData[jumpTablePtr + scriptEng.operands[0]] || scriptEng.operands[1] > jumpTableData[jumpTablePtr + scriptEng.operands[0] + 1])
                    newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0] + 2];
                else
                    newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + scriptEng.operands[0] + 4 + (scriptEng.operands[1] - jumpTableData[jumpTablePtr + scriptEng.operands[0]])];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_BREAK:
                newDataPtr = scriptCodePtr + jumpTableData[jumpTablePtr + jumpTableStack[jumpTableStackPos--] + 3];
                return {newOpcodeSize: 0, newScriptDataPtr: newDataPtr};
            case FUNC_ENDSWITCH: --jumpTableStackPos; return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_RAND: scriptEng.operands[0] = Std.random(scriptEng.operands[1]);
            case FUNC_SIN: scriptEng.operands[0] = RetroMath.sin512(scriptEng.operands[1]);
            case FUNC_COS: scriptEng.operands[0] = RetroMath.cos512(scriptEng.operands[1]);
            case FUNC_SIN256: scriptEng.operands[0] = RetroMath.sin256(scriptEng.operands[1]);
            case FUNC_COS256: scriptEng.operands[0] = RetroMath.cos256(scriptEng.operands[1]);
            case FUNC_SINCHANGE: scriptEng.operands[0] = scriptEng.operands[3] + (RetroMath.sin512(scriptEng.operands[1]) >> scriptEng.operands[2]) - scriptEng.operands[4];
            case FUNC_COSCHANGE: scriptEng.operands[0] = scriptEng.operands[3] + (RetroMath.cos512(scriptEng.operands[1]) >> scriptEng.operands[2]) - scriptEng.operands[4];
            case FUNC_ATAN2: return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_INTERPOLATE: scriptEng.operands[0] = (scriptEng.operands[2] * (0x100 - scriptEng.operands[3]) + scriptEng.operands[3] * scriptEng.operands[1]) >> 8;
            case FUNC_INTERPOLATEXY:
                scriptEng.operands[0] = (scriptEng.operands[3] * (0x100 - scriptEng.operands[6]) >> 8) + ((scriptEng.operands[6] * scriptEng.operands[2]) >> 8);
                scriptEng.operands[1] = (scriptEng.operands[5] * (0x100 - scriptEng.operands[6]) >> 8) + (scriptEng.operands[6] * scriptEng.operands[4] >> 8);
            case FUNC_LOADSPRITESHEET: scriptInfo.spriteSheetID = Sprite.addGraphicsFile(RetroString.arrayToString(scriptText)); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_REMOVESPRITESHEET: Sprite.removeGraphicsFile(RetroString.arrayToString(scriptText), -1); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWSPRITE:
                var frame = Animation.scriptFrames[scriptInfo.frameStartPtr + scriptEng.operands[0]];
                Drawing.drawSprite((entity.xPos >> 16) - Scene.xScrollOffset + frame.pivotX, (entity.yPos >> 16) - Scene.yScrollOffset + frame.pivotY, frame.width, frame.height, frame.sprX, frame.sprY, scriptInfo.spriteSheetID);
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWSPRITEXY:
                var frame = Animation.scriptFrames[scriptInfo.frameStartPtr + scriptEng.operands[0]];
                Drawing.drawSprite((scriptEng.operands[1] >> 16) - Scene.xScrollOffset + frame.pivotX, (scriptEng.operands[2] >> 16) - Scene.yScrollOffset + frame.pivotY, frame.width, frame.height, frame.sprX, frame.sprY, scriptInfo.spriteSheetID);
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWSPRITESCREENXY:
                var frame = Animation.scriptFrames[scriptInfo.frameStartPtr + scriptEng.operands[0]];
                Drawing.drawSprite(scriptEng.operands[1] + frame.pivotX, scriptEng.operands[2] + frame.pivotY, frame.width, frame.height, frame.sprX, frame.sprY, scriptInfo.spriteSheetID);
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWSPRITE3D: return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWNUMBERS:
                var i = 10;
                if (scriptEng.operands[6] != 0) {
                    while (scriptEng.operands[4] > 0) {
                        var frameID = Std.int(scriptEng.operands[3] % i / Std.int(i / 10)) + scriptEng.operands[0];
                        var numFrame = Animation.scriptFrames[scriptInfo.frameStartPtr + frameID];
                        Drawing.drawSprite(numFrame.pivotX + scriptEng.operands[1], numFrame.pivotY + scriptEng.operands[2], numFrame.width, numFrame.height, numFrame.sprX, numFrame.sprY, scriptInfo.spriteSheetID);
                        scriptEng.operands[1] -= scriptEng.operands[5];
                        i *= 10;
                        --scriptEng.operands[4];
                    }
                } else {
                    var extra = 10;
                    if (scriptEng.operands[3] != 0)
                        extra = 10 * scriptEng.operands[3];
                    while (scriptEng.operands[4] > 0) {
                        if (extra >= i) {
                            var frameID = Std.int(scriptEng.operands[3] % i / Std.int(i / 10)) + scriptEng.operands[0];
                            var numFrame = Animation.scriptFrames[scriptInfo.frameStartPtr + frameID];
                            Drawing.drawSprite(numFrame.pivotX + scriptEng.operands[1], numFrame.pivotY + scriptEng.operands[2], numFrame.width, numFrame.height, numFrame.sprX, numFrame.sprY, scriptInfo.spriteSheetID);
                        }
                        scriptEng.operands[1] -= scriptEng.operands[5];
                        i *= 10;
                        --scriptEng.operands[4];
                    }
                }
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWACTNAME:
                var charID = 0;
                switch (scriptEng.operands[3]) {
                    case 1:
                        charID = 0;
                        if (scriptEng.operands[4] == 1 && Scene.titleCardText[charID] != 0) {
                            var character = Scene.titleCardText[charID];
                            if (character == " ".code) character = 0;
                            if (character == "-".code) character = 0;
                            if (character >= "0".code && character <= "9".code) character -= 22;
                            if (character > "9".code && character < "f".code) character -= "A".code;
                            if (character <= -1) {
                                scriptEng.operands[1] += scriptEng.operands[5] + scriptEng.operands[6];
                            } else {
                                character += scriptEng.operands[0];
                                var actFrame = Animation.scriptFrames[scriptInfo.frameStartPtr + character];
                                Drawing.drawSprite(scriptEng.operands[1] + actFrame.pivotX, scriptEng.operands[2] + actFrame.pivotY, actFrame.width, actFrame.height, actFrame.sprX, actFrame.sprY, scriptInfo.spriteSheetID);
                                scriptEng.operands[1] += actFrame.width + scriptEng.operands[6];
                            }
                            scriptEng.operands[0] += 26;
                            charID++;
                        }
                        while (Scene.titleCardText[charID] != 0 && Scene.titleCardText[charID] != "-".code) {
                            var character = Scene.titleCardText[charID];
                            if (character == " ".code) character = 0;
                            if (character == "-".code) character = 0;
                            if (character > "/".code && character < ":".code) character -= 22;
                            if (character > "9".code && character < "f".code) character -= "A".code;
                            if (character <= -1) {
                                scriptEng.operands[1] += scriptEng.operands[5] + scriptEng.operands[6];
                            } else {
                                character += scriptEng.operands[0];
                                var actFrame = Animation.scriptFrames[scriptInfo.frameStartPtr + character];
                                Drawing.drawSprite(scriptEng.operands[1] + actFrame.pivotX, scriptEng.operands[2] + actFrame.pivotY, actFrame.width, actFrame.height, actFrame.sprX, actFrame.sprY, scriptInfo.spriteSheetID);
                                scriptEng.operands[1] += actFrame.width + scriptEng.operands[6];
                            }
                            charID++;
                        }
                    case 2:
                        charID = Scene.titleCardWord2;
                        if (scriptEng.operands[4] == 1 && Scene.titleCardText[charID] != 0) {
                            var character = Scene.titleCardText[charID];
                            if (character == " ".code) character = 0;
                            if (character == "-".code) character = 0;
                            if (character >= "0".code && character <= "9".code) character -= 22;
                            if (character > "9".code && character < "f".code) character -= "A".code;
                            if (character <= -1) {
                                scriptEng.operands[1] += scriptEng.operands[5] + scriptEng.operands[6];
                            } else {
                                character += scriptEng.operands[0];
                                var actFrame = Animation.scriptFrames[scriptInfo.frameStartPtr + character];
                                Drawing.drawSprite(scriptEng.operands[1] + actFrame.pivotX, scriptEng.operands[2] + actFrame.pivotY, actFrame.width, actFrame.height, actFrame.sprX, actFrame.sprY, scriptInfo.spriteSheetID);
                                scriptEng.operands[1] += actFrame.width + scriptEng.operands[6];
                            }
                            scriptEng.operands[0] += 26;
                            charID++;
                        }
                        while (Scene.titleCardText[charID] != 0) {
                            var character = Scene.titleCardText[charID];
                            if (character == " ".code) character = 0;
                            if (character == "-".code) character = 0;
                            if (character >= "0".code && character <= "9".code) character -= 22;
                            if (character > "9".code && character < "f".code) character -= "A".code;
                            if (character <= -1) {
                                scriptEng.operands[1] += scriptEng.operands[5] + scriptEng.operands[6];
                            } else {
                                character += scriptEng.operands[0];
                                var actFrame = Animation.scriptFrames[scriptInfo.frameStartPtr + character];
                                Drawing.drawSprite(scriptEng.operands[1] + actFrame.pivotX, scriptEng.operands[2] + actFrame.pivotY, actFrame.width, actFrame.height, actFrame.sprX, actFrame.sprY, scriptInfo.spriteSheetID);
                                scriptEng.operands[1] += actFrame.width + scriptEng.operands[6];
                            }
                            charID++;
                        }
                    default:
                }
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWMENU:
                Text.textMenuSurfaceNo = scriptInfo.spriteSheetID;
                Text.drawTextMenu(Text.gameMenu[scriptEng.operands[0]], scriptEng.operands[1], scriptEng.operands[2]);
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_SPRITEFRAME:
                if (scriptSub == SUB_SETUP && Animation.scriptFramesNo < Animation.SPRITEFRAME_COUNT) {
                    Animation.scriptFrames[Animation.scriptFramesNo].pivotX = scriptEng.operands[0];
                    Animation.scriptFrames[Animation.scriptFramesNo].pivotY = scriptEng.operands[1];
                    Animation.scriptFrames[Animation.scriptFramesNo].width = scriptEng.operands[2];
                    Animation.scriptFrames[Animation.scriptFramesNo].height = scriptEng.operands[3];
                    Animation.scriptFrames[Animation.scriptFramesNo].sprX = scriptEng.operands[4];
                    Animation.scriptFrames[Animation.scriptFramesNo].sprY = scriptEng.operands[5];
                    ++Animation.scriptFramesNo;
                }
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_SETDEBUGICON: return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_LOADPALETTE: Palette.loadPalette(RetroString.arrayToString(scriptText), scriptEng.operands[1], scriptEng.operands[2]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_ROTATEPALETTE: Palette.rotatePalette(scriptEng.operands[0], scriptEng.operands[1], scriptEng.operands[2] != 0); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_SETFADE: Palette.setFade(scriptEng.operands[0], scriptEng.operands[1], scriptEng.operands[2], scriptEng.operands[3], scriptEng.operands[4], scriptEng.operands[5]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_SETWATERCOLOR: return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_SETBLENDTABLE: Drawing.generateBlendTable(scriptEng.operands[0], scriptEng.operands[1], scriptEng.operands[2], scriptEng.operands[3]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_SETTINTTABLE: Drawing.generateTintTable(scriptEng.operands[0], scriptEng.operands[1], scriptEng.operands[2], scriptEng.operands[3], scriptEng.operands[4], scriptEng.operands[5]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_CLEARSCREEN: Drawing.clearScreen(scriptEng.operands[0]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWSPRITEFX:
                var fxFrame = Animation.scriptFrames[scriptInfo.frameStartPtr + scriptEng.operands[0]];
                switch (scriptEng.operands[1]) {
                    case 0:
                        Drawing.drawScaledSprite(entity.direction, (scriptEng.operands[2] >> 16) - Scene.xScrollOffset,
                            (scriptEng.operands[3] >> 16) - Scene.yScrollOffset, -fxFrame.pivotX, -fxFrame.pivotY, entity.scale,
                            entity.scale, fxFrame.width, fxFrame.height, fxFrame.sprX, fxFrame.sprY, scriptInfo.spriteSheetID);
                    case 1:
                        Drawing.drawRotatedSprite(entity.direction, (scriptEng.operands[2] >> 16) - Scene.xScrollOffset,
                            (scriptEng.operands[3] >> 16) - Scene.yScrollOffset, -fxFrame.pivotX, -fxFrame.pivotY,
                            fxFrame.sprX, fxFrame.sprY, fxFrame.width, fxFrame.height, entity.rotation, scriptInfo.spriteSheetID);
                    case 2:
                        switch (entity.inkEffect) {
                            case 0:
                                Drawing.drawSprite((scriptEng.operands[2] >> 16) - Scene.xScrollOffset + fxFrame.pivotX,
                                    (scriptEng.operands[3] >> 16) - Scene.yScrollOffset + fxFrame.pivotY,
                                    fxFrame.width, fxFrame.height, fxFrame.sprX, fxFrame.sprY, scriptInfo.spriteSheetID);
                            case 1:
                                Drawing.drawBlendedSprite((scriptEng.operands[2] >> 16) - Scene.xScrollOffset + fxFrame.pivotX,
                                    (scriptEng.operands[3] >> 16) - Scene.yScrollOffset + fxFrame.pivotY,
                                    fxFrame.width, fxFrame.height, fxFrame.sprX, fxFrame.sprY, scriptInfo.spriteSheetID);
                            default:
                        }
                    case 3:
                        if (entity.inkEffect == 2) {
                            Drawing.drawScaledTintMask(entity.direction, (scriptEng.operands[2] >> 16) - Scene.xScrollOffset,
                                (scriptEng.operands[3] >> 16) - Scene.yScrollOffset, -fxFrame.pivotX, -fxFrame.pivotY,
                                entity.scale, entity.scale, fxFrame.width, fxFrame.height, fxFrame.sprX, fxFrame.sprY, 0, scriptInfo.spriteSheetID);
                        } else {
                            Drawing.drawScaledSprite(entity.direction, (scriptEng.operands[2] >> 16) - Scene.xScrollOffset,
                                (scriptEng.operands[3] >> 16) - Scene.yScrollOffset, -fxFrame.pivotX, -fxFrame.pivotY, entity.scale,
                                entity.scale, fxFrame.width, fxFrame.height, fxFrame.sprX, fxFrame.sprY, scriptInfo.spriteSheetID);
                        }
                    default:
                }
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWSPRITESCREENFX:
                var sfxFrame = Animation.scriptFrames[scriptInfo.frameStartPtr + scriptEng.operands[0]];
                switch (scriptEng.operands[1]) {
                    case 0:
                        Drawing.drawScaledSprite(entity.direction, scriptEng.operands[2], scriptEng.operands[3],
                            -sfxFrame.pivotX, -sfxFrame.pivotY, entity.scale, entity.scale,
                            sfxFrame.width, sfxFrame.height, sfxFrame.sprX, sfxFrame.sprY, scriptInfo.spriteSheetID);
                    case 1:
                        Drawing.drawRotatedSprite(entity.direction, scriptEng.operands[2], scriptEng.operands[3],
                            -sfxFrame.pivotX, -sfxFrame.pivotY, sfxFrame.sprX, sfxFrame.sprY,
                            sfxFrame.width, sfxFrame.height, entity.rotation, scriptInfo.spriteSheetID);
                    case 2:
                        switch (entity.inkEffect) {
                            case 0:
                                Drawing.drawSprite(scriptEng.operands[2] + sfxFrame.pivotX, scriptEng.operands[3] + sfxFrame.pivotY,
                                    sfxFrame.width, sfxFrame.height, sfxFrame.sprX, sfxFrame.sprY, scriptInfo.spriteSheetID);
                            case 1:
                                Drawing.drawBlendedSprite(scriptEng.operands[2] + sfxFrame.pivotX, scriptEng.operands[3] + sfxFrame.pivotY,
                                    sfxFrame.width, sfxFrame.height, sfxFrame.sprX, sfxFrame.sprY, scriptInfo.spriteSheetID);
                            default:
                        }
                    case 3:
                        if (entity.inkEffect == 2) {
                            Drawing.drawScaledTintMask(entity.direction, scriptEng.operands[2], scriptEng.operands[3],
                                -sfxFrame.pivotX, -sfxFrame.pivotY, entity.scale, entity.scale,
                                sfxFrame.width, sfxFrame.height, sfxFrame.sprX, sfxFrame.sprY, 0, scriptInfo.spriteSheetID);
                        } else {
                            Drawing.drawScaledSprite(entity.direction, scriptEng.operands[2], scriptEng.operands[3],
                                -sfxFrame.pivotX, -sfxFrame.pivotY, entity.scale, entity.scale,
                                sfxFrame.width, sfxFrame.height, sfxFrame.sprX, sfxFrame.sprY, scriptInfo.spriteSheetID);
                        }
                    default:
                }
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWLIFEICON:
                var anim = PlayerManager.playerScriptList[PlayerManager.playerList[0].type].animations[PlayerManager.ANI_LIFEICON];
                var lifeFrame = anim.frames[0];
                Drawing.drawSprite(lifeFrame.pivotX + scriptEng.operands[0], lifeFrame.pivotY + scriptEng.operands[1], lifeFrame.width, lifeFrame.height, lifeFrame.sprX, lifeFrame.sprY, lifeFrame.sheetID);
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_SETUPMENU:
                var menu = Text.gameMenu[scriptEng.operands[0]];
                Text.setupTextMenu(menu, scriptEng.operands[1]);
                menu.selectionCount = scriptEng.operands[2];
                menu.alignment = scriptEng.operands[3];
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_ADDMENUENTRY:
                var menu = Text.gameMenu[scriptEng.operands[0]];
                menu.entryHighlight[menu.rowCount] = scriptEng.operands[2];
                Text.addTextMenuEntry(menu, RetroString.arrayToString(scriptText));
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_EDITMENUENTRY:
                var menu = Text.gameMenu[scriptEng.operands[0]];
                Text.editTextMenuEntry(menu, RetroString.arrayToString(scriptText), scriptEng.operands[2]);
                menu.entryHighlight[scriptEng.operands[2]] = scriptEng.operands[3];
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_LOADSTAGE: Scene.stageMode = Scene.STAGEMODE_LOAD; return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DRAWTINTRECT: Drawing.drawTintRect(scriptEng.operands[0], scriptEng.operands[1], scriptEng.operands[2], scriptEng.operands[3], scriptEng.operands[4]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_RESETOBJECTENTITY:
                if (scriptEng.operands[0] == 0) {
                    rsdk.core.Debug.printLog("RESETOBJECTENTITY on entity 0! operands=" + scriptEng.operands[0] + "," + scriptEng.operands[1] + "," + scriptEng.operands[2] + "," + scriptEng.operands[3] + "," + scriptEng.operands[4] + " objectLoop=" + Object.objectLoop + " loopType=" + Object.objectEntityList[Object.objectLoop].type);
                }
                var newEnt = Object.objectEntityList[scriptEng.operands[0]];
                newEnt.type = scriptEng.operands[1];
                newEnt.propertyValue = scriptEng.operands[2];
                newEnt.xPos = scriptEng.operands[3];
                newEnt.yPos = scriptEng.operands[4];
                newEnt.direction = 0; newEnt.frame = 0; newEnt.priority = 0; newEnt.rotation = 0;
                newEnt.state = 0; newEnt.drawOrder = 3; newEnt.scale = 512; newEnt.inkEffect = 0;
                for (v in 0...8) newEnt.values[v] = 0;
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_PLAYEROBJECTCOLLISION:
                switch (scriptEng.operands[0]) {
                    case 0: Collision.basicCollision((entity.xPos >> 16) + scriptEng.operands[1], (entity.yPos >> 16) + scriptEng.operands[2], (entity.xPos >> 16) + scriptEng.operands[3], (entity.yPos >> 16) + scriptEng.operands[4]);
                    case 1: Collision.boxCollision(entity.xPos + (scriptEng.operands[1] << 16), entity.yPos + (scriptEng.operands[2] << 16), entity.xPos + (scriptEng.operands[3] << 16), entity.yPos + (scriptEng.operands[4] << 16));
                    case 2: Collision.platformCollision(entity.xPos + (scriptEng.operands[1] << 16), entity.yPos + (scriptEng.operands[2] << 16), entity.xPos + (scriptEng.operands[3] << 16), entity.yPos + (scriptEng.operands[4] << 16));
                }
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_CREATETEMPOBJECT:
                if (Object.objectEntityList[scriptEng.arrayPosition[2]].type > 0 && ++scriptEng.arrayPosition[2] == Object.ENTITY_COUNT)
                    scriptEng.arrayPosition[2] = Object.TEMPENTITY_START;
                var temp = Object.objectEntityList[scriptEng.arrayPosition[2]];
                temp.type = scriptEng.operands[0]; temp.propertyValue = scriptEng.operands[1];
                temp.xPos = scriptEng.operands[2]; temp.yPos = scriptEng.operands[3];
                temp.direction = 0; temp.frame = 0; temp.priority = 1; temp.rotation = 0;
                temp.state = 0; temp.drawOrder = 3; temp.scale = 512; temp.inkEffect = 0;
                for (v in 0...8) temp.values[v] = 0;
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DEFAULTGROUNDMOVEMENT: PlayerManager.processDefaultGroundMovement(player); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DEFAULTAIRMOVEMENT: PlayerManager.processDefaultAirMovement(player); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DEFAULTROLLINGMOVEMENT: PlayerManager.processDefaultRollingMovement(player); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DEFAULTGRAVITYTRUE: PlayerManager.processDefaultGravityTrue(player); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DEFAULTGRAVITYFALSE: PlayerManager.processDefaultGravityFalse(player); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_DEFAULTJUMPACTION: PlayerManager.processDefaultJumpAction(player); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_SETMUSICTRACK: Audio.setMusicTrack(RetroString.arrayToString(scriptText), scriptEng.operands[1], scriptEng.operands[2] != 0); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_PLAYMUSIC: Audio.playMusic(scriptEng.operands[0]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_STOPMUSIC: Audio.stopMusic(); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_PLAYSFX: Audio.playSfx(scriptEng.operands[0], scriptEng.operands[1] != 0); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_STOPSFX: Audio.stopSfx(scriptEng.operands[0]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_SETSFXATTRIBUTES: Audio.setSfxAttributes(scriptEng.operands[0], scriptEng.operands[1], scriptEng.operands[2]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_OBJECTTILECOLLISION: if (scriptEng.operands[0] == 0) Collision.objectFloorCollision(scriptEng.operands[1], scriptEng.operands[2], scriptEng.operands[3]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_OBJECTTILEGRIP: if (scriptEng.operands[0] == 0) Collision.objectFloorGrip(scriptEng.operands[1], scriptEng.operands[2], scriptEng.operands[3]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_LOADVIDEO:
                Audio.pauseSound();
                scriptInfo.spriteSheetID = Sprite.addGraphicsFile(RetroString.arrayToString(scriptText));
                Audio.resumeSound();
                return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_NEXTVIDEOFRAME: Video.updateVideoFrame(); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_PLAYSTAGESFX: Audio.playSfx(Audio.noGlobalSFX + scriptEng.operands[0], scriptEng.operands[1] != 0); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            case FUNC_STOPSTAGESFX: Audio.stopSfx(Audio.noGlobalSFX + scriptEng.operands[0]); return {newOpcodeSize: 0, newScriptDataPtr: -1};
            default: return {newOpcodeSize: 0, newScriptDataPtr: -1};
        }
        return {newOpcodeSize: opcodeSize, newScriptDataPtr: -1};
    }

    static inline function intAbs(v:Int):Int { return v < 0 ? -v : v; }
}
