package rsdk.core;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import rsdk.core.Debug;
import rsdk.core.RetroEngine;
import rsdk.core.RetroString;
import rsdk.audio.Audio;

class ModInfo {
    public var name:String = "";
    public var desc:String = "";
    public var author:String = "";
    public var version:String = "";
    public var folder:String = "";
    public var active:Bool = false;
    public var fileMap:Map<String, String> = new Map();
    
    public function new() {}
}

class ModAPI {
    public static var modList:Array<ModInfo> = [];
    public static var activeMod:Int = -1;
    public static var modsPath:String = "";
    
    public static inline function setActiveMod(id:Int):Void {
        activeMod = id;
    }
    
    public static function initMods():Void {
        modList = [];
        
        var modPath = modsPath + "mods";
        
        if (!FileSystem.exists(modPath) || !FileSystem.isDirectory(modPath)) {
            Debug.printLog("Mods folder not found: " + modPath);
            return;
        }
        
        var configPath = modPath + "/modconfig.ini";
        if (FileSystem.exists(configPath)) {
            try {
                var content = File.getContent(configPath);
                var lines = content.split("\n");
                var inModsSection = false;
                
                for (line in lines) {
                    var trimmed = StringTools.trim(line);
                    if (trimmed == "[mods]") {
                        inModsSection = true;
                        continue;
                    }
                    if (StringTools.startsWith(trimmed, "[") && trimmed != "[mods]") {
                        inModsSection = false;
                        continue;
                    }
                    
                    if (inModsSection && trimmed.indexOf("=") > 0) {
                        var parts = trimmed.split("=");
                        var folder = StringTools.trim(parts[0]);
                        var activeStr = StringTools.trim(parts[1]).toLowerCase();
                        var active = activeStr == "true" || activeStr == "1";
                        
                        var info = loadMod(modPath, folder, active);
                        if (info != null) {
                            modList.push(info);
                        }
                    }
                }
            } catch (e:Dynamic) {
                Debug.printLog("Error reading modconfig.ini: " + Std.string(e));
            }
        }
        
        try {
            for (entry in FileSystem.readDirectory(modPath)) {
                var entryPath = modPath + "/" + entry;
                if (FileSystem.isDirectory(entryPath)) {
                    var alreadyLoaded = false;
                    for (mod in modList) {
                        if (mod.folder == entry) {
                            alreadyLoaded = true;
                            break;
                        }
                    }
                    
                    if (!alreadyLoaded) {
                        var info = loadMod(modPath, entry, false);
                        if (info != null) {
                            modList.push(info);
                        }
                    }
                }
            }
        } catch (e:Dynamic) {
            Debug.printLog("Mods folder scanning error: " + Std.string(e));
        }
        
        Debug.printLog("Loaded " + modList.length + " mod(s)");
    }
    
    public static function loadMod(modsPath:String, folder:String, active:Bool):ModInfo {
        var modDir = modsPath + "/" + folder;
        var modIniPath = modDir + "/mod.ini";
        
        if (!FileSystem.exists(modIniPath)) {
            return null;
        }
        
        var info = new ModInfo();
        info.name = "Unnamed Mod";
        info.desc = "";
        info.author = "Unknown Author";
        info.version = "1.0.0";
        info.folder = folder;
        info.active = active;
        
        try {
            var content = File.getContent(modIniPath);
            var lines = content.split("\n");
            
            for (line in lines) {
                var trimmed = StringTools.trim(line);
                if (trimmed.indexOf("=") > 0) {
                    var eqPos = trimmed.indexOf("=");
                    var key = StringTools.trim(trimmed.substr(0, eqPos)).toLowerCase();
                    var value = StringTools.trim(trimmed.substr(eqPos + 1));
                    
                    switch (key) {
                        case "name": if (value != "") info.name = value;
                        case "description": if (value != "") info.desc = value;
                        case "author": if (value != "") info.author = value;
                        case "version": if (value != "") info.version = value;
                    }
                }
            }
        } catch (e:Dynamic) {
            Debug.printLog("Error reading mod.ini for " + folder + ": " + Std.string(e));
        }
        
        scanModFolder(info, modsPath);
        
        Debug.printLog("Loaded mod: " + info.name + " v" + info.version + " by " + info.author + " (active=" + info.active + ", files=" + Lambda.count(info.fileMap) + ")");
        
        return info;
    }
    
    public static function scanModFolder(info:ModInfo, modsPath:String):Void {
        if (info == null) return;
        
        var modDir = modsPath + "/" + info.folder;
        
        var dataPath = modDir + "/Data";
        if (FileSystem.exists(dataPath) && FileSystem.isDirectory(dataPath)) {
            scanDirectory(info, dataPath, "Data");
        }
        
        var scriptsPath = modDir + "/Scripts";
        if (FileSystem.exists(scriptsPath) && FileSystem.isDirectory(scriptsPath)) {
            scanDirectory(info, scriptsPath, "Scripts");
        }
    }
    
    static function scanDirectory(info:ModInfo, basePath:String, prefix:String):Void {
        try {
            for (entry in FileSystem.readDirectory(basePath)) {
                var fullPath = basePath + "/" + entry;
                if (FileSystem.isDirectory(fullPath)) {
                    scanDirectory(info, fullPath, prefix + "/" + entry);
                } else {
                    var relativePath = prefix + "/" + entry;
                    var lowerPath = relativePath.toLowerCase();
                    lowerPath = StringTools.replace(lowerPath, "\\", "/");
                    info.fileMap.set(lowerPath, fullPath);
                }
            }
        } catch (e:Dynamic) {
            Debug.printLog("Error scanning mod folder: " + Std.string(e));
        }
    }
    
    public static function saveMods():Void {
        var modPath = modsPath + "mods";
        
        if (!FileSystem.exists(modPath) || !FileSystem.isDirectory(modPath)) {
            return;
        }
        
        var content = new StringBuf();
        content.add("[mods]\n");
        
        for (mod in modList) {
            content.add(mod.folder + "=" + (mod.active ? "true" : "false") + "\n");
        }
        
        try {
            File.saveContent(modPath + "/modconfig.ini", content.toString());
            Debug.printLog("Saved mod configuration");
        } catch (e:Dynamic) {
            Debug.printLog("Error saving modconfig.ini: " + Std.string(e));
        }
    }
    
    public static function getModdedPath(originalPath:String):String {
        var lowerPath = originalPath.toLowerCase();
        lowerPath = StringTools.replace(lowerPath, "\\", "/");
        
        var i = modList.length - 1;
        while (i >= 0) {
            var mod = modList[i];
            if (mod.active) {
                if (mod.fileMap.exists(lowerPath)) {
                    var moddedPath = mod.fileMap.get(lowerPath);
                    Debug.printLog("Mod redirect: " + originalPath + " -> " + moddedPath);
                    return moddedPath;
                }
            }
            i--;
        }
        
        return originalPath;
    }
    
    public static function refreshEngine():Void {
        RetroEngine.loadGameConfig("Data/Game/GameConfig.bin");
        
        Audio.releaseGlobalSfx();
        Audio.loadGlobalSfx();
        
        saveMods();
        
        Debug.printLog("Engine refreshed after mod changes");
    }
    
    public static function getActiveModCount():Int {
        var count = 0;
        for (mod in modList) {
            if (mod.active) count++;
        }
        return count;
    }
    
    public static function toggleMod(index:Int):Void {
        if (index >= 0 && index < modList.length) {
            modList[index].active = !modList[index].active;
        }
    }
    
    public static function moveMod(index:Int, newIndex:Int):Void {
        if (index < 0 || index >= modList.length) return;
        if (newIndex < 0 || newIndex >= modList.length) return;
        if (index == newIndex) return;
        
        var mod = modList[index];
        modList.splice(index, 1);
        modList.insert(newIndex, mod);
    }
}