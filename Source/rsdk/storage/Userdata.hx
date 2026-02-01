package rsdk.storage;

import ini.Ini;
import rsdk.scene.Script;
import rsdk.core.RetroEngine;
import rsdk.audio.Audio;
import rsdk.graphics.Drawing;
import rsdk.input.Input;
import rsdk.core.RetroString;
import lime.ui.KeyCode;
import sys.io.File;
import sys.FileSystem;

class Userdata {
    public static inline var GLOBALVAR_COUNT:Int = 0x100;
    public static inline var MAX_VOLUME:Int = 100;
    
    public static var gamePath:String = "";
    
    static var keyCodeNames:Map<KeyCode, String> = [
        KeyCode.UP => "Up", KeyCode.DOWN => "Down", KeyCode.LEFT => "Left", KeyCode.RIGHT => "Right",
        KeyCode.RETURN => "Return", KeyCode.SPACE => "Space", KeyCode.ESCAPE => "Escape",
        KeyCode.BACKSPACE => "Backspace", KeyCode.TAB => "Tab",
        KeyCode.A => "A", KeyCode.B => "B", KeyCode.C => "C", KeyCode.D => "D", KeyCode.E => "E",
        KeyCode.F => "F", KeyCode.G => "G", KeyCode.H => "H", KeyCode.I => "I", KeyCode.J => "J",
        KeyCode.K => "K", KeyCode.L => "L", KeyCode.M => "M", KeyCode.N => "N", KeyCode.O => "O",
        KeyCode.P => "P", KeyCode.Q => "Q", KeyCode.R => "R", KeyCode.S => "S", KeyCode.T => "T",
        KeyCode.U => "U", KeyCode.V => "V", KeyCode.W => "W", KeyCode.X => "X", KeyCode.Y => "Y",
        KeyCode.Z => "Z",
        KeyCode.NUMBER_0 => "0", KeyCode.NUMBER_1 => "1", KeyCode.NUMBER_2 => "2",
        KeyCode.NUMBER_3 => "3", KeyCode.NUMBER_4 => "4", KeyCode.NUMBER_5 => "5",
        KeyCode.NUMBER_6 => "6", KeyCode.NUMBER_7 => "7", KeyCode.NUMBER_8 => "8",
        KeyCode.NUMBER_9 => "9",
        KeyCode.LEFT_SHIFT => "LShift", KeyCode.RIGHT_SHIFT => "RShift",
        KeyCode.LEFT_CTRL => "LCtrl", KeyCode.RIGHT_CTRL => "RCtrl",
        KeyCode.LEFT_ALT => "LAlt", KeyCode.RIGHT_ALT => "RAlt",
    ];
    
    static function keyCodeToName(code:KeyCode):String {
        if (keyCodeNames.exists(code)) return keyCodeNames.get(code);
        return Std.string(cast(code, Int));
    }
    
    static function nameToKeyCode(name:String):KeyCode {
        var num = Std.parseInt(name);
        if (num != null) return cast num;
        
        var upperName = name.toUpperCase();
        for (code => codeName in keyCodeNames) {
            if (codeName.toUpperCase() == upperName) return code;
        }
        return KeyCode.UNKNOWN;
    }
    
    public static function getGlobalVariableByName(name:String):Int {
        for (v in 0...Script.noGlobalVariables) {
            if (Script.globalVariableNames[v] == name)
                return Script.globalVariables[v];
        }
        return 0;
    }
    
    public static function setGlobalVariableByName(name:String, value:Int):Void {
        for (v in 0...Script.noGlobalVariables) {
            if (Script.globalVariableNames[v] == name) {
                Script.globalVariables[v] = value;
                break;
            }
        }
    }
    
    public static function initUserdata():Void {
        gamePath = "";
        
        Input.init();
        
        var settingsPath = "settings.ini";
        if (!FileSystem.exists(settingsPath)) {
            RetroEngine.devMenu = false;
            RetroEngine.engineDebugMode = false;
            RetroEngine.startList = 0xFF;
            RetroEngine.startStage = 0xFF;
            RetroEngine.fastForwardSpeed = 8;
            RetroString.strCopy(RetroEngine.dataFile, "Data.bin");
            
            RetroEngine.startList_Game = RetroEngine.startList;
            RetroEngine.startStage_Game = RetroEngine.startStage;
            
            RetroEngine.startFullScreen = false;
            RetroEngine.borderless = false;
            RetroEngine.vsync = false;
            RetroEngine.enhancedScaling = true;
            RetroEngine.windowScale = 2;
            Drawing.SCREEN_XSIZE = 320;
            RetroEngine.refreshRate = 60;
            RetroEngine.colourMode = 1;
            
            Audio.bgmVolume = MAX_VOLUME;
            Audio.sfxVolume = MAX_VOLUME;
            
            writeSettings();
        } else {
            try {
                var content = File.getContent(settingsPath);
                var ini = Ini.parse(content);
                
                if (Reflect.hasField(ini, "Dev")) {
                    var dev:Dynamic = Reflect.field(ini, "Dev");
                    RetroEngine.devMenu = getBool(dev, "DevMenu", false);
                    RetroEngine.engineDebugMode = getBool(dev, "EngineDebugMode", false);
                    RetroEngine.startList = getInt(dev, "StartingCategory", 0xFF);
                    RetroEngine.startStage = getInt(dev, "StartingScene", 0xFF);
                    RetroEngine.fastForwardSpeed = getInt(dev, "FastForwardSpeed", 8);
                    RetroString.strCopy(RetroEngine.dataFile, getString(dev, "DataFile", "Data.bin"));
                } else {
                    RetroEngine.devMenu = false;
                    RetroEngine.engineDebugMode = false;
                    RetroEngine.startList = 0xFF;
                    RetroEngine.startStage = 0xFF;
                    RetroEngine.fastForwardSpeed = 8;
                    RetroString.strCopy(RetroEngine.dataFile, "Data.bin");
                }
                
                RetroEngine.startList_Game = RetroEngine.startList;
                RetroEngine.startStage_Game = RetroEngine.startStage;
                
                if (Reflect.hasField(ini, "Window")) {
                    var win:Dynamic = Reflect.field(ini, "Window");
                    RetroEngine.startFullScreen = getBool(win, "FullScreen", false);
                    RetroEngine.borderless = getBool(win, "Borderless", false);
                    RetroEngine.vsync = getBool(win, "VSync", false);
                    RetroEngine.enhancedScaling = getBool(win, "EnhancedScaling", true);
                    RetroEngine.windowScale = getInt(win, "WindowScale", 2);
                    Drawing.SCREEN_XSIZE = getInt(win, "ScreenWidth", 320);
                    RetroEngine.refreshRate = getInt(win, "RefreshRate", 60);
                    RetroEngine.colourMode = getInt(win, "ColourMode", 1);
                } else {
                    RetroEngine.startFullScreen = false;
                    RetroEngine.borderless = false;
                    RetroEngine.vsync = false;
                    RetroEngine.enhancedScaling = true;
                    RetroEngine.windowScale = 2;
                    Drawing.SCREEN_XSIZE = 320;
                    RetroEngine.refreshRate = 60;
                    RetroEngine.colourMode = 1;
                }
                
                if (Reflect.hasField(ini, "Audio")) {
                    var audio:Dynamic = Reflect.field(ini, "Audio");
                    Audio.bgmVolume = Std.int(getFloat(audio, "BGMVolume", 1.0) * MAX_VOLUME);
                    Audio.sfxVolume = Std.int(getFloat(audio, "SFXVolume", 1.0) * MAX_VOLUME);
                } else {
                    Audio.bgmVolume = MAX_VOLUME;
                    Audio.sfxVolume = MAX_VOLUME;
                }
                
                if (Audio.bgmVolume > MAX_VOLUME) Audio.bgmVolume = MAX_VOLUME;
                if (Audio.bgmVolume < 0) Audio.bgmVolume = 0;
                if (Audio.sfxVolume > MAX_VOLUME) Audio.sfxVolume = MAX_VOLUME;
                if (Audio.sfxVolume < 0) Audio.sfxVolume = 0;
                
                if (Reflect.hasField(ini, "Keyboard 1")) {
                    var kb:Dynamic = Reflect.field(ini, "Keyboard 1");
                    Input.inputDevice[Input.INPUT_UP].keyMappings = getKeyCode(kb, "Up", KeyCode.UP);
                    Input.inputDevice[Input.INPUT_DOWN].keyMappings = getKeyCode(kb, "Down", KeyCode.DOWN);
                    Input.inputDevice[Input.INPUT_LEFT].keyMappings = getKeyCode(kb, "Left", KeyCode.LEFT);
                    Input.inputDevice[Input.INPUT_RIGHT].keyMappings = getKeyCode(kb, "Right", KeyCode.RIGHT);
                    Input.inputDevice[Input.INPUT_BUTTONA].keyMappings = getKeyCode(kb, "A", KeyCode.Z);
                    Input.inputDevice[Input.INPUT_BUTTONB].keyMappings = getKeyCode(kb, "B", KeyCode.X);
                    Input.inputDevice[Input.INPUT_BUTTONC].keyMappings = getKeyCode(kb, "C", KeyCode.C);
                    Input.inputDevice[Input.INPUT_START].keyMappings = getKeyCode(kb, "Start", KeyCode.RETURN);
                }
                
                if (Reflect.hasField(ini, "Controller 1")) {
                    var ct:Dynamic = Reflect.field(ini, "Controller 1");
                    Input.inputDevice[Input.INPUT_UP].contMappings = getInt(ct, "Up", 11);
                    Input.inputDevice[Input.INPUT_DOWN].contMappings = getInt(ct, "Down", 12);
                    Input.inputDevice[Input.INPUT_LEFT].contMappings = getInt(ct, "Left", 13);
                    Input.inputDevice[Input.INPUT_RIGHT].contMappings = getInt(ct, "Right", 14);
                    Input.inputDevice[Input.INPUT_BUTTONA].contMappings = getInt(ct, "A", 0);
                    Input.inputDevice[Input.INPUT_BUTTONB].contMappings = getInt(ct, "B", 1);
                    Input.inputDevice[Input.INPUT_BUTTONC].contMappings = getInt(ct, "C", 2);
                    Input.inputDevice[Input.INPUT_START].contMappings = getInt(ct, "Start", 6);
                }
                
            } catch (e:Dynamic) {
                RetroEngine.devMenu = false;
                RetroEngine.startList = 0xFF;
                RetroEngine.startStage = 0xFF;
                Audio.bgmVolume = MAX_VOLUME;
                Audio.sfxVolume = MAX_VOLUME;
            }
        }
        
        Drawing.setScreenSize(Drawing.SCREEN_XSIZE, Drawing.SCREEN_YSIZE);
    }
    
    static function getBool(obj:Dynamic, field:String, def:Bool):Bool {
        if (Reflect.hasField(obj, field)) return Reflect.field(obj, field);
        return def;
    }
    
    static function getInt(obj:Dynamic, field:String, def:Int):Int {
        if (Reflect.hasField(obj, field)) return Std.int(Reflect.field(obj, field));
        return def;
    }
    
    static function getFloat(obj:Dynamic, field:String, def:Float):Float {
        if (Reflect.hasField(obj, field)) return Reflect.field(obj, field);
        return def;
    }
    
    static function getString(obj:Dynamic, field:String, def:String):String {
        if (Reflect.hasField(obj, field)) return Std.string(Reflect.field(obj, field));
        return def;
    }
    
    static function getKeyCode(obj:Dynamic, field:String, def:KeyCode):KeyCode {
        if (Reflect.hasField(obj, field)) {
            var val:Dynamic = Reflect.field(obj, field);
            if (Std.isOfType(val, Int)) return cast val;
            if (Std.isOfType(val, String)) return nameToKeyCode(val);
        }
        return def;
    }
    
    public static function writeSettings():Void {
        var content = new StringBuf();
        
        content.add("[Dev]\n");
        content.add("; Enable this flag to activate dev menu via the ESC key\n");
        content.add("DevMenu=" + (RetroEngine.devMenu ? "true" : "false") + "\n");
        content.add("; Enable this flag to activate features used for debugging the engine\n");
        content.add("EngineDebugMode=" + (RetroEngine.engineDebugMode ? "true" : "false") + "\n");
        content.add("; Sets the starting category ID\n");
        content.add("StartingCategory=" + RetroEngine.startList + "\n");
        content.add("; Sets the starting scene ID\n");
        content.add("StartingScene=" + RetroEngine.startStage + "\n");
        content.add("; Determines how fast the game will be when fastforwarding is active\n");
        content.add("FastForwardSpeed=" + RetroEngine.fastForwardSpeed + "\n");
        content.add("; Determines what Datafile will be loaded\n");
        content.add("DataFile=" + RetroString.arrayToString(RetroEngine.dataFile) + "\n");
        
        content.add("\n[Window]\n");
        content.add("; Determines if the window will be fullscreen or not\n");
        content.add("FullScreen=" + (RetroEngine.startFullScreen ? "true" : "false") + "\n");
        content.add("; Determines if the window will be borderless or not\n");
        content.add("Borderless=" + (RetroEngine.borderless ? "true" : "false") + "\n");
        content.add("; Determines if VSync will be active or not\n");
        content.add("VSync=" + (RetroEngine.vsync ? "true" : "false") + "\n");
        content.add("; Determines if Enhanced Scaling will be active or not\n");
        content.add("EnhancedScaling=" + (RetroEngine.enhancedScaling ? "true" : "false") + "\n");
        content.add("; How big the window will be\n");
        content.add("WindowScale=" + RetroEngine.windowScale + "\n");
        content.add("; How wide the base screen will be in pixels\n");
        content.add("ScreenWidth=" + Drawing.SCREEN_XSIZE + "\n");
        content.add("; Determines the target FPS\n");
        content.add("RefreshRate=" + RetroEngine.refreshRate + "\n");
        content.add("; Determines the output colour mode (0 = 8-bit, 1 = 16-bit, 2 = 32-bit)\n");
        content.add("ColourMode=" + RetroEngine.colourMode + "\n");
        
        content.add("\n[Audio]\n");
        content.add("BGMVolume=" + (Audio.bgmVolume / MAX_VOLUME) + "\n");
        content.add("SFXVolume=" + (Audio.sfxVolume / MAX_VOLUME) + "\n");
        
        content.add("\n[Keyboard 1]\n");
        content.add("; Keyboard Mappings for P1\n");
        content.add("Up=" + keyCodeToName(Input.inputDevice[Input.INPUT_UP].keyMappings) + "\n");
        content.add("Down=" + keyCodeToName(Input.inputDevice[Input.INPUT_DOWN].keyMappings) + "\n");
        content.add("Left=" + keyCodeToName(Input.inputDevice[Input.INPUT_LEFT].keyMappings) + "\n");
        content.add("Right=" + keyCodeToName(Input.inputDevice[Input.INPUT_RIGHT].keyMappings) + "\n");
        content.add("A=" + keyCodeToName(Input.inputDevice[Input.INPUT_BUTTONA].keyMappings) + "\n");
        content.add("B=" + keyCodeToName(Input.inputDevice[Input.INPUT_BUTTONB].keyMappings) + "\n");
        content.add("C=" + keyCodeToName(Input.inputDevice[Input.INPUT_BUTTONC].keyMappings) + "\n");
        content.add("Start=" + keyCodeToName(Input.inputDevice[Input.INPUT_START].keyMappings) + "\n");
        
        content.add("\n[Controller 1]\n");
        content.add("; Controller Mappings for P1\n");
        content.add("Up=" + Input.inputDevice[Input.INPUT_UP].contMappings + "\n");
        content.add("Down=" + Input.inputDevice[Input.INPUT_DOWN].contMappings + "\n");
        content.add("Left=" + Input.inputDevice[Input.INPUT_LEFT].contMappings + "\n");
        content.add("Right=" + Input.inputDevice[Input.INPUT_RIGHT].contMappings + "\n");
        content.add("A=" + Input.inputDevice[Input.INPUT_BUTTONA].contMappings + "\n");
        content.add("B=" + Input.inputDevice[Input.INPUT_BUTTONB].contMappings + "\n");
        content.add("C=" + Input.inputDevice[Input.INPUT_BUTTONC].contMappings + "\n");
        content.add("Start=" + Input.inputDevice[Input.INPUT_START].contMappings + "\n");
        
        try {
            File.saveContent("settings.ini", content.toString());
        } catch (e:Dynamic) {}
    }
}