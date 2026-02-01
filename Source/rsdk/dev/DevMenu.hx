package rsdk.dev;

import rsdk.graphics.Drawing;
import rsdk.graphics.Palette;
import rsdk.scene.Scene;
import rsdk.scene.Script;
import rsdk.audio.Audio;
import rsdk.input.Input;
import rsdk.core.RetroEngine;
import rsdk.core.RetroString;
import rsdk.core.ModAPI;
import rsdk.storage.Userdata;
import rsdk.dev.DevFont;

enum abstract DevMenuAlign(Int) to Int {
    var ALIGN_LEFT = 0;
    var ALIGN_CENTER = 1;
    var ALIGN_RIGHT = 2;
}

class DevMenu {
    public static var state:Void->Void = null;
    public static var selection:Int = 0;
    public static var scrollPos:Int = 0;
    public static var timer:Int = 0;
    public static var listPos:Int = 0;
    public static var playerListPos:Int = 0;
    public static var sceneState:Int = 0;
    public static var storedStageMode:Int = 0;
    public static var modsChanged:Bool = false;
    
    public static inline var SCREEN_CENTERX:Int = 160;
    public static inline var SCREEN_CENTERY:Int = 120;
    
    public static function drawDevString(str:String, x:Int, y:Int, align:Int, color:Int):Void {
        var color16 = packRGB888((color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF);
        
        var charOffset = 0;
        var linesRemain = true;
        
        while (linesRemain) {
            linesRemain = false;
            
            var lineSize = 0;
            var lineStart = charOffset;
            while (charOffset < str.length) {
                var cur = str.charCodeAt(charOffset);
                if (cur == '\n'.code) {
                    linesRemain = true;
                    charOffset++;
                    break;
                }
                charOffset++;
                lineSize++;
            }
            
            if (y >= 0 && y < Drawing.SCREEN_YSIZE - 7) {
                var offset = 0;
                switch (align) {
                    case ALIGN_LEFT: offset = 0;
                    case ALIGN_CENTER: offset = 4 * lineSize;
                    case ALIGN_RIGHT: offset = 8 * lineSize;
                }
                var drawX = x - offset;
                
                for (c in 0...lineSize) {
                    var charCode = str.charCodeAt(lineStart + c);
                    if (drawX >= 0 && drawX < Drawing.SCREEN_XSIZE - 7) {
                        if (charCode >= 0 && charCode < 128) {
                            var stencilOffset = 64 * charCode;
                            for (h in 0...8) {
                                for (w in 0...8) {
                                    var fbIdx = (drawX + w) + (y + h) * Drawing.SCREEN_XSIZE;
                                    if (fbIdx >= 0 && fbIdx < Drawing.frameBuffer.length) {
                                        var stencilIdx = stencilOffset + h * 8 + w;
                                        if (DevFont.devTextStencil.length > stencilIdx) {
                                            if (DevFont.devTextStencil.get(stencilIdx) != 0)
                                                Drawing.frameBuffer[fbIdx] = color16;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    drawX += 8;
                }
            }
            
            y += 8;
        }
    }
    
    public static function drawDevRect(x:Int, y:Int, width:Int, height:Int, color:Int, alpha:Int):Void {
        if (x < 0) { width += x; x = 0; }
        if (y < 0) { height += y; y = 0; }
        if (x + width > Drawing.SCREEN_XSIZE) width = Drawing.SCREEN_XSIZE - x;
        if (y + height > Drawing.SCREEN_YSIZE) height = Drawing.SCREEN_YSIZE - y;
        
        if (width <= 0 || height <= 0) return;
        
        var r = (color >> 16) & 0xFF;
        var g = (color >> 8) & 0xFF;
        var b = color & 0xFF;
        
        if (alpha >= 0xFF) {
            var color16 = packRGB888(r, g, b);
            for (h in 0...height) {
                for (w in 0...width) {
                    var fbIdx = (x + w) + (y + h) * Drawing.SCREEN_XSIZE;
                    if (fbIdx >= 0 && fbIdx < Drawing.frameBuffer.length)
                        Drawing.frameBuffer[fbIdx] = color16;
                }
            }
        } else {
            for (h in 0...height) {
                for (w in 0...width) {
                    var fbIdx = (x + w) + (y + h) * Drawing.SCREEN_XSIZE;
                    if (fbIdx >= 0 && fbIdx < Drawing.frameBuffer.length) {
                        var pixel = Drawing.frameBuffer[fbIdx];
                        var bgR = ((pixel >> 11) & 0x1F) << 3;
                        var bgG = ((pixel >> 5) & 0x3F) << 2;
                        var bgB = (pixel & 0x1F) << 3;
                        
                        var blendR = (r * alpha + bgR * (0xFF - alpha)) >> 8;
                        var blendG = (g * alpha + bgG * (0xFF - alpha)) >> 8;
                        var blendB = (b * alpha + bgB * (0xFF - alpha)) >> 8;
                        
                        Drawing.frameBuffer[fbIdx] = packRGB888(blendR, blendG, blendB);
                    }
                }
            }
        }
    }
    
    static function packRGB888(r:Int, g:Int, b:Int):Int {
        return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3);
    }
    
    public static function openDevMenu():Void {
        state = mainMenu;
        selection = 0;
        scrollPos = 0;
        timer = 0;
        listPos = 0;
        playerListPos = 0;
        
        if (RetroEngine.gameMode == RetroEngine.ENGINE_INITDEVMENU) {
            sceneState = RetroEngine.ENGINE_DEVMENU;
            storedStageMode = 0;
        } else {
            sceneState = RetroEngine.gameMode;
            storedStageMode = Scene.stageMode;
        }
        RetroEngine.gameMode = RetroEngine.ENGINE_DEVMENU;
        
        for (i in 0...Drawing.SCREEN_XSIZE * Drawing.SCREEN_YSIZE) {
            var paletteIdx = Drawing.frameBuffer[i] & 0xFF;
            var color = Palette.tilePalette[paletteIdx];
            Drawing.frameBuffer[i] = packRGB888(color.r, color.g, color.b);
        }
        
        Drawing.useRGB565Mode = true;
        
        Audio.pauseSound();
    }
    
    public static function closeDevMenu():Void {
        Drawing.useRGB565Mode = false;
        
        for (i in 0...Drawing.SCREEN_XSIZE * Drawing.SCREEN_YSIZE) {
            Drawing.frameBuffer[i] = 0;
        }
        
        RetroEngine.gameMode = sceneState;
        Scene.stageMode = storedStageMode;
        Audio.resumeSound();
    }
    
    public static function processDevMenu():Void {
        Input.checkKeyPress(Input.gKeyPress, 0xFF);
        Input.checkKeyDown(Input.gKeyDown, 0xFF);
        
        if (state != null)
            state();
    }
    
    public static function mainMenu():Void {
        var selectionCount = 6;
        var selectionColors = [0x808090, 0x808090, 0x808090, 0x808090, 0x808090, 0x808090];
        var selectionNames = ["Resume", "Restart", "Stage Select", "Options", "Mods", "Exit"];
        selectionColors[selection] = 0xF0F0F0;
        
        var y = SCREEN_CENTERY - 80;
        drawDevRect(SCREEN_CENTERX - 128, SCREEN_CENTERY - 84, 0x100, 0x30, 0x000080, 0xC0);
        drawDevString("RETRO ENGINE V2", SCREEN_CENTERX, y, ALIGN_CENTER, 0xF0F0F0);
        
        y += 8;
        drawDevString("Dev Menu", SCREEN_CENTERX, y, ALIGN_CENTER, 0xF0F0F0);
        
        y += 8;
        if (modsChanged) {
            drawDevString("Game will restart on resume!", SCREEN_CENTERX, y, ALIGN_CENTER, 0xF08080);
        }
        
        y += 8;
        drawDevString(RetroString.arrayToString(RetroEngine.gameWindowText), SCREEN_CENTERX, y, ALIGN_CENTER, 0x808090);
        
        y += 8;
        drawDevString("Haxe port by Hiro/f4r3vr", SCREEN_CENTERX, y, ALIGN_CENTER, 0x808090);
        
        y += 24;
        drawDevRect(SCREEN_CENTERX - 128, y - 8, 0x100, 0x50, 0x000080, 0xC0);
        
        for (i in 0...selectionCount) {
            drawDevString(selectionNames[i], SCREEN_CENTERX, y, ALIGN_CENTER, selectionColors[i]);
            y += 10;
        }
        
        if (Input.gKeyPress.up == 1) {
            selection--;
            if (selection < 0) selection = selectionCount - 1;
            timer = 1;
        } else if (Input.gKeyDown.up == 1) {
            if (timer != 0) timer = (timer + 1) & 7;
            else {
                selection--;
                if (selection < 0) selection = selectionCount - 1;
                timer = (timer + 1) & 7;
            }
        }
        
        if (Input.gKeyPress.down == 1) {
            selection++;
            if (selection >= selectionCount) selection = 0;
            timer = 1;
        } else if (Input.gKeyDown.down == 1) {
            if (timer != 0) timer = (timer + 1) & 7;
            else {
                selection++;
                if (selection >= selectionCount) selection = 0;
                timer = (timer + 1) & 7;
            }
        }
        
        if (Input.gKeyPress.start == 1 || Input.gKeyPress.A == 1) {
            switch (selection) {
                case 0: // Resume
                    if (modsChanged) {
                        ModAPI.refreshEngine();
                        modsChanged = false;
                        Drawing.useRGB565Mode = false;
                        for (i in 0...Drawing.SCREEN_XSIZE * Drawing.SCREEN_YSIZE) {
                            Drawing.frameBuffer[i] = 0;
                        }
                        Scene.resetCurrentStageFolder();
                        Scene.stageMode = STAGEMODE_LOAD;
                        RetroEngine.gameMode = RetroEngine.ENGINE_MAINGAME;
                        Audio.stopMusic();
                    } else {
                        closeDevMenu();
                    }
                case 1: // Restart
                    Drawing.useRGB565Mode = false;
                    for (i in 0...Drawing.SCREEN_XSIZE * Drawing.SCREEN_YSIZE) {
                        Drawing.frameBuffer[i] = 0;
                    }
                    if (modsChanged) {
                        ModAPI.refreshEngine();
                        modsChanged = false;
                        Scene.resetCurrentStageFolder();
                    }
                    Scene.stageMode = STAGEMODE_LOAD;
                    RetroEngine.gameMode = RetroEngine.ENGINE_MAINGAME;
                    Audio.stopMusic();
                case 2: // Stage Select
                    state = categorySelectMenu;
                    selection = 0;
                    scrollPos = 0;
                case 3: // Options
                    state = optionsMenu;
                    selection = 0;
                case 4: // Mods
                    ModAPI.initMods();
                    if (ModAPI.modList.length > 0) {
                        state = modsMenu;
                        selection = 0;
                        scrollPos = 0;
                    }
                case 5: // Exit
                    RetroEngine.running = false;
            }
        }
        
        if (Input.gKeyPress.B == 1) {
            if (modsChanged) {
                ModAPI.refreshEngine();
                modsChanged = false;
                Drawing.useRGB565Mode = false;
                for (i in 0...Drawing.SCREEN_XSIZE * Drawing.SCREEN_YSIZE) {
                    Drawing.frameBuffer[i] = 0;
                }
                Scene.resetCurrentStageFolder();
                Scene.stageMode = STAGEMODE_LOAD;
                RetroEngine.gameMode = RetroEngine.ENGINE_MAINGAME;
                Audio.stopMusic();
            } else {
                closeDevMenu();
            }
        }
    }
    
    public static function categorySelectMenu():Void {
        var selectionColors = [0x808090, 0x808090, 0x808090, 0x808090];
        if (selection >= 0 && selection < 4) selectionColors[selection] = 0xF0F0F0;
        
        var dy = SCREEN_CENTERY;
        drawDevRect(SCREEN_CENTERX - 128, dy - 84, 0x100, 0x30, 0x000080, 0xC0);
        
        dy -= 68;
        drawDevString("SELECT STAGE CATEGORY", SCREEN_CENTERX, dy, ALIGN_CENTER, 0xF0F0F0);
        drawDevRect(SCREEN_CENTERX - 128, dy + 36, 0x100, 0x48, 0x000080, 0xC0);
        
        var categoryNames = ["Presentation", "Regular Stages", "Bonus Stages", "Special Stages"];
        var categoryCount = 4;
        
        var y = dy + 40;
        for (i in 0...categoryCount) {
            drawDevString(categoryNames[i], SCREEN_CENTERX - 64, y, ALIGN_LEFT, selectionColors[i]);
            y += 8;
        }
        
        if (Input.gKeyPress.up == 1) {
            if (--selection < 0) selection = categoryCount - 1;
            timer = 1;
        } else if (Input.gKeyDown.up == 1) {
            if (timer == 0 && --selection < 0) selection = categoryCount - 1;
            timer = (timer + 1) & 7;
        }
        
        if (Input.gKeyPress.down == 1) {
            if (++selection >= categoryCount) selection = 0;
            timer = 1;
        } else if (Input.gKeyDown.down == 1) {
            if (timer == 0 && ++selection >= categoryCount) selection = 0;
            timer = (timer + 1) & 7;
        }
        
        if (Input.gKeyPress.start == 1 || Input.gKeyPress.A == 1) {
            listPos = selection;
            state = sceneSelectMenu;
            selection = 0;
            scrollPos = 0;
        }
        
        if (Input.gKeyPress.B == 1) {
            state = mainMenu;
            selection = 2;
            scrollPos = 0;
        }
    }
    
    public static function sceneSelectMenu():Void {
        var selectionColors = [for (i in 0...8) 0x808090];
        var visibleSelection = selection - scrollPos;
        if (visibleSelection >= 0 && visibleSelection < 8)
            selectionColors[visibleSelection] = 0xF0F0F0;
        
        var dy = SCREEN_CENTERY;
        drawDevRect(SCREEN_CENTERX - 128, dy - 84, 0x100, 0x30, 0x000080, 0xC0);
        
        dy -= 68;
        drawDevString("SELECT STAGE SCENE", SCREEN_CENTERX, dy, ALIGN_CENTER, 0xF0F0F0);
        drawDevRect(SCREEN_CENTERX - 128, dy + 36, 0x100, 0x48, 0x000080, 0xC0);
        
        var stageCount = Scene.stageListCount[listPos];
        
        var y = dy + 40;
        for (i in 0...8) {
            if (scrollPos + i < stageCount) {
                var stageName = RetroString.arrayToString(Scene.stageList[listPos][scrollPos + i].name);
                drawDevString(stageName, SCREEN_CENTERX + 96, y, ALIGN_RIGHT, selectionColors[i]);
                y += 8;
            }
        }
        
        if (Input.gKeyPress.up == 1) {
            if (--selection < 0) selection = stageCount - 1;
            if (selection >= scrollPos) {
                if (selection > scrollPos + 7) scrollPos = selection - 7;
            } else {
                scrollPos = selection;
            }
            timer = 1;
        } else if (Input.gKeyDown.up == 1) {
            if (timer == 0 && --selection < 0) selection = stageCount - 1;
            timer = (timer + 1) & 7;
            if (selection >= scrollPos) {
                if (selection > scrollPos + 7) scrollPos = selection - 7;
            } else {
                scrollPos = selection;
            }
        }
        
        if (Input.gKeyPress.down == 1) {
            if (++selection >= stageCount) selection = 0;
            if (selection >= scrollPos) {
                if (selection > scrollPos + 7) scrollPos = selection - 7;
            } else {
                scrollPos = selection;
            }
            timer = 1;
        } else if (Input.gKeyDown.down == 1) {
            if (timer == 0 && ++selection >= stageCount) selection = 0;
            timer = (timer + 1) & 7;
            if (selection >= scrollPos) {
                if (selection > scrollPos + 7) scrollPos = selection - 7;
            } else {
                scrollPos = selection;
            }
        }
        
        if (Input.gKeyPress.start == 1 || Input.gKeyPress.A == 1) {
            Drawing.useRGB565Mode = false;
            for (i in 0...Drawing.SCREEN_XSIZE * Drawing.SCREEN_YSIZE) {
                Drawing.frameBuffer[i] = 0;
            }
            Scene.debugMode = Input.gKeyDown.A == 1;
            Scene.activeStageList = listPos;
            Scene.stageListPosition = selection;
            Scene.stageMode = STAGEMODE_LOAD;
            RetroEngine.gameMode = RetroEngine.ENGINE_MAINGAME;
            Userdata.setGlobalVariableByName("lampPostID", 0);
            Audio.stopMusic();
        }
        
        if (Input.gKeyPress.B == 1) {
            state = categorySelectMenu;
            selection = listPos;
            scrollPos = 0;
        }
    }
    
    public static function optionsMenu():Void {
        var selectionCount = 3;
        var selectionColors = [0x808090, 0x808090, 0x808090];
        selectionColors[selection] = 0xF0F0F0;
        
        var dy = SCREEN_CENTERY;
        drawDevRect(SCREEN_CENTERX - 128, dy - 84, 256, 0x30, 0x000080, 0xC0);
        
        dy -= 68;
        drawDevString("OPTIONS", SCREEN_CENTERX, dy, ALIGN_CENTER, 0xF0F0F0);
        
        dy += 44;
        drawDevRect(SCREEN_CENTERX - 128, dy - 8, 0x100, 0x48, 0x000080, 0xC0);
        
        drawDevString("Video Settings", SCREEN_CENTERX, dy, ALIGN_CENTER, selectionColors[0]);
        dy += 12;
        drawDevString("Audio Settings", SCREEN_CENTERX, dy, ALIGN_CENTER, selectionColors[1]);
        dy += 12;
        drawDevString("Back", SCREEN_CENTERX, dy, ALIGN_CENTER, selectionColors[2]);
        
        if (Input.gKeyPress.up == 1) {
            if (--selection < 0) selection = selectionCount - 1;
            timer = 1;
        } else if (Input.gKeyDown.up == 1) {
            if (timer == 0 && --selection < 0) selection = selectionCount - 1;
            timer = (timer + 1) & 7;
        }
        
        if (Input.gKeyPress.down == 1) {
            if (++selection >= selectionCount) selection = 0;
            timer = 1;
        } else if (Input.gKeyDown.down == 1) {
            if (timer == 0 && ++selection >= selectionCount) selection = 0;
            timer = (timer + 1) & 7;
        }
        
        if (Input.gKeyPress.start == 1 || Input.gKeyPress.A == 1) {
            switch (selection) {
                case 0: state = videoOptionsMenu; selection = 0;
                case 1: state = audioOptionsMenu; selection = 0;
                case 2: state = mainMenu; selection = 3;
            }
        }
        
        if (Input.gKeyPress.B == 1) {
            state = mainMenu;
            selection = 3;
        }
    }
    
    public static function videoOptionsMenu():Void {
        var selectionCount = 3;
        var selectionColors = [0x808090, 0x808090, 0x808090];
        selectionColors[selection] = 0xF0F0F0;
        
        var dy = SCREEN_CENTERY;
        drawDevRect(SCREEN_CENTERX - 128, dy - 84, 0x100, 0x30, 0x000080, 0xC0);
        
        dy -= 68;
        drawDevString("VIDEO SETTINGS", SCREEN_CENTERX, dy, ALIGN_CENTER, 0xF0F0F0);
        
        dy += 44;
        drawDevRect(SCREEN_CENTERX - 128, dy - 8, 0x100, 0x48, 0x000080, 0xC0);
        
        drawDevString("Window Scale:", SCREEN_CENTERX - 96, dy, ALIGN_LEFT, selectionColors[0]);
        drawDevString(Std.string(RetroEngine.windowScale) + "x", SCREEN_CENTERX + 80, dy, ALIGN_CENTER, 0xF0F080);
        
        dy += 12;
        drawDevString("Fullscreen:", SCREEN_CENTERX - 96, dy, ALIGN_LEFT, selectionColors[1]);
        drawDevString(RetroEngine.startFullScreen ? "YES" : "NO", SCREEN_CENTERX + 80, dy, ALIGN_CENTER, 0xF0F080);
        
        dy += 16;
        drawDevString("Back", SCREEN_CENTERX, dy, ALIGN_CENTER, selectionColors[2]);
        
        if (Input.gKeyPress.up == 1) {
            if (--selection < 0) selection = selectionCount - 1;
            timer = 1;
        } else if (Input.gKeyDown.up == 1) {
            if (timer == 0 && --selection < 0) selection = selectionCount - 1;
            timer = (timer + 1) & 7;
        }
        
        if (Input.gKeyPress.down == 1) {
            if (++selection >= selectionCount) selection = 0;
            timer = 1;
        } else if (Input.gKeyDown.down == 1) {
            if (timer == 0 && ++selection >= selectionCount) selection = 0;
            timer = (timer + 1) & 7;
        }
        
        switch (selection) {
            case 0:
                if (Input.gKeyPress.left == 1 && RetroEngine.windowScale > 1)
                    RetroEngine.windowScale--;
                if (Input.gKeyPress.right == 1 && RetroEngine.windowScale < 4)
                    RetroEngine.windowScale++;
            case 1:
                if (Input.gKeyPress.left == 1 || Input.gKeyPress.right == 1)
                    RetroEngine.startFullScreen = !RetroEngine.startFullScreen;
            case 2:
                if (Input.gKeyPress.start == 1 || Input.gKeyPress.A == 1) {
                    state = optionsMenu;
                    selection = 0;
                }
        }
        
        if (Input.gKeyPress.B == 1) {
            state = optionsMenu;
            selection = 0;
        }
    }
    
    public static function audioOptionsMenu():Void {
        var selectionCount = 3;
        var selectionColors = [0x808090, 0x808090, 0x808090];
        selectionColors[selection] = 0xF0F0F0;
        
        var dy = SCREEN_CENTERY;
        drawDevRect(SCREEN_CENTERX - 128, dy - 84, 0x100, 0x30, 0x000080, 0xC0);
        
        dy -= 68;
        drawDevString("AUDIO SETTINGS", SCREEN_CENTERX, dy, ALIGN_CENTER, 0xF0F0F0);
        
        dy += 44;
        drawDevRect(SCREEN_CENTERX - 128, dy - 8, 0x100, 0x48, 0x000080, 0xC0);
        
        drawDevString("Music Vol:", SCREEN_CENTERX - 96, dy, ALIGN_LEFT, selectionColors[0]);
        drawDevRect(SCREEN_CENTERX + 8, dy, 112, 8, 0x000000, 0xFF);
        drawDevRect(SCREEN_CENTERX + 9, dy + 1, Std.int(Audio.bgmVolume * 1.1), 6, 0xF0F0F0, 0xFF);
        
        dy += 16;
        drawDevString("SFX Vol:", SCREEN_CENTERX - 96, dy, ALIGN_LEFT, selectionColors[1]);
        drawDevRect(SCREEN_CENTERX + 8, dy, 112, 8, 0x000000, 0xFF);
        drawDevRect(SCREEN_CENTERX + 9, dy + 1, Std.int(Audio.sfxVolume * 1.1), 6, 0xF0F0F0, 0xFF);
        
        dy += 16;
        drawDevString("Back", SCREEN_CENTERX, dy, ALIGN_CENTER, selectionColors[2]);
        
        if (Input.gKeyPress.up == 1) {
            if (--selection < 0) selection = selectionCount - 1;
            timer = 1;
        } else if (Input.gKeyDown.up == 1) {
            if (timer == 0 && --selection < 0) selection = selectionCount - 1;
            timer = (timer + 1) & 7;
        }
        
        if (Input.gKeyPress.down == 1) {
            if (++selection >= selectionCount) selection = 0;
            timer = 1;
        } else if (Input.gKeyDown.down == 1) {
            if (timer == 0 && ++selection >= selectionCount) selection = 0;
            timer = (timer + 1) & 7;
        }
        
        switch (selection) {
            case 0:
                if (Input.gKeyDown.left == 1) {
                    Audio.bgmVolume--;
                    if (Audio.bgmVolume < 0) Audio.bgmVolume = 0;
                    Audio.setMusicVolume(Audio.bgmVolume);
                }
                if (Input.gKeyDown.right == 1) {
                    Audio.bgmVolume++;
                    if (Audio.bgmVolume > Audio.MAX_VOLUME) Audio.bgmVolume = Audio.MAX_VOLUME;
                    Audio.setMusicVolume(Audio.bgmVolume);
                }
            case 1:
                if (Input.gKeyDown.left == 1) {
                    Audio.sfxVolume--;
                    if (Audio.sfxVolume < 0) Audio.sfxVolume = 0;
                }
                if (Input.gKeyDown.right == 1) {
                    Audio.sfxVolume++;
                    if (Audio.sfxVolume > Audio.MAX_VOLUME) Audio.sfxVolume = Audio.MAX_VOLUME;
                }
            case 2:
                if (Input.gKeyPress.start == 1 || Input.gKeyPress.A == 1) {
                    state = optionsMenu;
                    selection = 1;
                }
        }
        
        if (Input.gKeyPress.B == 1) {
            state = optionsMenu;
            selection = 1;
        }
    }
    
    public static function modsMenu():Void {
        var selectionColors = [0x808090, 0x808090, 0x808090, 0x808090, 0x808090, 0x808090, 0x808090, 0x808090];
        var visibleSelection = selection - scrollPos;
        if (visibleSelection >= 0 && visibleSelection < 8)
            selectionColors[visibleSelection] = 0xF0F0F0;
        
        var dy = SCREEN_CENTERY;
        drawDevRect(SCREEN_CENTERX - 128, dy - 84, 0x100, 0x30, 0x000080, 0xC0);
        
        dy -= 68;
        drawDevString("MANAGE MODS", SCREEN_CENTERX, dy, ALIGN_CENTER, 0xF0F0F0);
        drawDevRect(SCREEN_CENTERX - 128, dy + 36, 0x100, 0x48, 0x000080, 0xC0);
        
        var y = dy + 40;
        var modCount = ModAPI.modList.length;
        
        for (i in 0...8) {
            if (scrollPos + i < modCount) {
                var mod = ModAPI.modList[scrollPos + i];
                var modName = mod.name;
                if (modName.length > 20) {
                    modName = modName.substr(0, 17) + "...";
                }
                drawDevString(modName, SCREEN_CENTERX - 96, y, ALIGN_LEFT, selectionColors[i]);
                drawDevString(mod.active ? "Y" : "N", SCREEN_CENTERX + 96, y, ALIGN_RIGHT, selectionColors[i]);
                y += 8;
            }
        }
        
        var preselection = selection;
        
        if (Input.gKeyPress.up == 1) {
            if (--selection < 0) selection = modCount - 1;
            
            if (selection >= scrollPos) {
                if (selection > scrollPos + 7)
                    scrollPos = selection - 7;
            } else {
                scrollPos = selection;
            }
            timer = 1;
        } else if (Input.gKeyDown.up == 1) {
            if (timer == 0 && --selection < 0) selection = modCount - 1;
            
            timer = (timer + 1) & 7;
            
            if (selection >= scrollPos) {
                if (selection > scrollPos + 7)
                    scrollPos = selection - 7;
            } else {
                scrollPos = selection;
            }
        }
        
        if (Input.gKeyPress.down == 1) {
            if (++selection >= modCount) selection = 0;
            
            if (selection >= scrollPos) {
                if (selection > scrollPos + 7)
                    scrollPos = selection - 7;
            } else {
                scrollPos = selection;
            }
            timer = 1;
        } else if (Input.gKeyDown.down == 1) {
            if (timer == 0 && ++selection >= modCount) selection = 0;
            
            timer = (timer + 1) & 7;
            
            if (selection >= scrollPos) {
                if (selection > scrollPos + 7)
                    scrollPos = selection - 7;
            } else {
                scrollPos = selection;
            }
        }
        
        if (Input.gKeyPress.start == 1 || Input.gKeyPress.A == 1 || Input.gKeyPress.left == 1 || Input.gKeyPress.right == 1) {
            if (selection < modCount) {
                ModAPI.toggleMod(selection);
                modsChanged = true;
            }
        }
        
        if (Input.gKeyDown.C == 1) {
            if (preselection != selection && selection < modCount && preselection < modCount) {
                ModAPI.moveMod(preselection, selection);
                modsChanged = true;
            }
        }
        
        if (Input.gKeyPress.B == 1) {
            ModAPI.saveMods();
            state = mainMenu;
            selection = 4;
            scrollPos = 0;
        }
    }
}
