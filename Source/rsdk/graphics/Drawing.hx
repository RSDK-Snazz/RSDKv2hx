package rsdk.graphics;

import haxe.io.Bytes;
import rsdk.graphics.Palette;
import rsdk.core.RetroString;
import rsdk.core.RetroMath;
import rsdk.scene.Scene;
import rsdk.scene.Object;
import rsdk.scene.Script;
import rsdk.scene.Player;

enum abstract FlipFlags(Int) to Int {
    var FLIP_NONE = 0;
    var FLIP_X = 1;
    var FLIP_Y = 2;
    var FLIP_XY = 3;
}

enum abstract InkFlags(Int) to Int {
    var INK_NONE = 0;
    var INK_BLEND = 1;
    var INK_TINT = 2;
}

enum abstract DrawFXFlags(Int) to Int {
    var FX_SCALE = 0;
    var FX_ROTATE = 1;
    var FX_INK = 2;
    var FX_TINT = 3;
}

class DrawListEntry {
    public var entityRefs:Array<Int>;
    public var listSize:Int = 0;

    public function new(entityCount:Int) {
        entityRefs = [for (i in 0...entityCount) 0];
    }
}

class GFXSurface {
    public var fileName:Array<Int> = RetroString.createArray(0x40);
    public var height:Int = 0;
    public var width:Int = 0;
    public var dataPosition:Int = 0;

    public function new() {}
}

class Drawing {
    public static inline final SPRITESHEETS_MAX:Int = 16;
    public static inline final SURFACE_MAX:Int = 24;
    public static inline final GFXDATA_MAX:Int = 0x400000;
    public static inline final DRAWLAYER_COUNT:Int = 7;
    public static inline final ENTITY_COUNT:Int = 0x4A0;
    public static inline final SCREEN_YSIZE:Int = 240;
    public static inline final TILE_SIZE:Int = 16;
    public static inline final CHUNK_SIZE:Int = 128;
    public static inline final TILE_DATASIZE:Int = 0x1000;

    public static var SCREEN_XSIZE:Int = 320;
    public static var SCREEN_CENTERX:Int = 160;
    public static var SCREEN_SCROLL_LEFT:Int = 152;
    public static var SCREEN_SCROLL_RIGHT:Int = 168;

    public static var blendLookupTable:Array<Int> = [for (i in 0...0x10000) 0];
    public static var tintLookupTable1:Array<Int> = [for (i in 0...0x100) 0];
    public static var tintLookupTable2:Array<Int> = [for (i in 0...0x100) 0];
    public static var tintLookupTable3:Array<Int> = [for (i in 0...0x100) 0];
    public static var tintLookupTable4:Array<Int> = [for (i in 0...0x100) 0];

    public static var objectDrawOrderList:Array<DrawListEntry> = [for (i in 0...DRAWLAYER_COUNT) new DrawListEntry(ENTITY_COUNT)];

    public static var gfxDataPosition:Int = 0;
    public static var gfxSurface:Array<GFXSurface> = [for (i in 0...SURFACE_MAX) new GFXSurface()];
    public static var graphicData:Array<Int> = [for (i in 0...GFXDATA_MAX) 0];

    public static var frameBuffer:Array<Int> = null;
    public static var waterDrawPos:Int = SCREEN_YSIZE;
    public static var useRGB565Mode:Bool = false;


    public static function initRenderDevice():Bool {
        frameBuffer = [for (i in 0...SCREEN_XSIZE * SCREEN_YSIZE) 0];
        rsdk.core.Debug.printLog("initRenderDevice: frameBuffer allocated, size=" + frameBuffer.length);
        return true;
    }

    public static function releaseRenderDevice():Void {
        frameBuffer = null;
    }

    static var clearScreenLogged:Bool = false;
    public static function clearScreen(index:Int):Void {
        if (frameBuffer == null) return;
        if (!clearScreenLogged) {
            clearScreenLogged = true;
            rsdk.core.Debug.printLog("clearScreen called with index=" + index);
        }
        for (i in 0...SCREEN_XSIZE * SCREEN_YSIZE) {
            frameBuffer[i] = index;
        }
    }

    public static function clearGraphicsData():Void {
        for (i in 0...SURFACE_MAX) {
            for (j in 0...0x40) gfxSurface[i].fileName[j] = 0;
            gfxSurface[i].width = 0;
            gfxSurface[i].height = 0;
            gfxSurface[i].dataPosition = 0;
        }
        gfxDataPosition = 0;
    }

    public static function setScreenSize(width:Int, lineSize:Int):Void {
        SCREEN_XSIZE = width;
        SCREEN_CENTERX = Std.int(width / 2);
        SCREEN_SCROLL_LEFT = SCREEN_CENTERX - 8;
        SCREEN_SCROLL_RIGHT = SCREEN_CENTERX + 8;
        Object.OBJECT_BORDER_X2 = width + 0x80;
    }

    public static function flipScreen():Void {}

    public static function generateBlendTable(alpha:Int, type:Int, a3:Int, a4:Int):Void {
        switch (type) {
            case 0:
                for (y in 0...256) {
                    for (x in 0...256) {
                        var mixR = ((0xFF - alpha) * Palette.tilePalette[y].r + alpha * Palette.tilePalette[x].r) >> 8;
                        var mixG = ((0xFF - alpha) * Palette.tilePalette[y].g + alpha * Palette.tilePalette[x].g) >> 8;
                        var mixB = ((0xFF - alpha) * Palette.tilePalette[y].b + alpha * Palette.tilePalette[x].b) >> 8;
                        var index = 0;
                        var r = 0x7FFFFFFF;
                        var g = 0x7FFFFFFF;
                        var b = 0x7FFFFFFF;
                        for (i in 0...256) {
                            var mixR2 = Std.int(Math.abs(Palette.tilePalette[i].r - mixR));
                            var mixG2 = Std.int(Math.abs(Palette.tilePalette[i].g - mixG));
                            var mixB2 = Std.int(Math.abs(Palette.tilePalette[i].b - mixB));
                            if (mixR2 < r && mixG2 < g && mixB2 < b) {
                                r = mixR2;
                                g = mixG2;
                                b = mixB2;
                                index = i;
                            }
                        }
                        blendLookupTable[(0x100 * y) + x] = index;
                    }
                }
            case 1:
                for (y in 0...0x100) {
                    for (x in 0...0x100) {
                        var v1 = Std.int((Palette.tilePalette[y].b + Palette.tilePalette[y].g + Palette.tilePalette[y].r) / 3);
                        var v2 = Std.int((Palette.tilePalette[x].b + Palette.tilePalette[x].g + Palette.tilePalette[x].r) / 3);
                        blendLookupTable[0x100 * y + x] = a4 + Std.int(a3 * (((0xFF - alpha) * v1 + alpha * v2) >> 8) / 0x100);
                    }
                }
        }
    }

    public static function generateTintTable(alpha:Int, a2:Int, type:Int, a4:Int, a5:Int, tableID:Int):Void {
        var tintTable:Array<Int> = switch (tableID) {
            case 0: tintLookupTable1;
            case 1: tintLookupTable2;
            case 2: tintLookupTable3;
            case 3: tintLookupTable4;
            default: null;
        };

        if (tintTable == null) return;

        switch (type) {
            case 0:
                for (i in 0...256) {
                    var val = Std.int((Palette.tilePalette[i].b + Palette.tilePalette[i].g + Palette.tilePalette[i].r) / 3);
                    tintTable[i] = a5 + Std.int(a4 * (((0xFF - alpha) * val + alpha * a2) >> 8) / 256);
                }
            case 1:
                for (i in 0...256) {
                    tintTable[i] = a5 + Std.int(a4 * (((0xFF - alpha) * Palette.tilePalette[i].r + alpha * a2) >> 8) / 256);
                }
            case 2:
                for (i in 0...256) {
                    tintTable[i] = a5 + Std.int(a4 * (((0xFF - alpha) * Palette.tilePalette[i].g + alpha * a2) >> 8) / 256);
                }
            case 3:
                for (i in 0...256) {
                    tintTable[i] = a5 + Std.int(a4 * (((0xFF - alpha) * Palette.tilePalette[i].b + alpha * a2) >> 8) / 256);
                }
        }
    }

    static var debugPlayerDrawCount:Int = 0;
    static var playerWasInList:Bool = false;
    static var playerMissingLogCount:Int = 0;
    static var playerWasDrawn:Bool = false;
    public static function drawObjectList(layer:Int):Void {
        var size = Object.objectDrawOrderList[layer].listSize;
        var foundPlayer = false;
        for (i in 0...size) {
            Object.objectLoop = Object.objectDrawOrderList[layer].entityRefs[i];
            var type = Object.objectEntityList[Object.objectLoop].type;
            if (Object.objectLoop == 0) {
                foundPlayer = true;
                if (playerWasDrawn && type != Object.OBJ_TYPE_PLAYER && playerMissingLogCount < 5) {
                    playerMissingLogCount++;
                }
            }
            if (type == Object.OBJ_TYPE_PLAYER) {
                playerWasDrawn = true;
                var player = PlayerManager.playerList[Object.objectLoop];
                PlayerManager.processPlayerAnimationChange(player);
                if (player.visible != 0) {
                    var script = PlayerManager.playerScriptList[player.type];
                    var anim = script.animations[player.animation];
                    if (anim == null) {
                        rsdk.core.Debug.printLog("ERROR: anim null for animation=" + player.animation);
                        continue;
                    }
                    if (player.frame >= anim.frames.length) {
                        rsdk.core.Debug.printLog("ERROR: frame " + player.frame + " out of bounds, anim " + player.animation + " has " + anim.frames.length + " frames");
                        continue;
                    }
                    var frame = anim.frames[player.frame];
                    drawPlayer(player, frame);
                }
            } else if (type != 0) {
                PlayerManager.playerNo = 0;
                if (Script.scriptData[Script.objectScriptList[type].subDraw.scriptCodePtr] > 0)
                    Script.processScript(Script.objectScriptList[type].subDraw.scriptCodePtr, Script.objectScriptList[type].subDraw.jumpTablePtr, Script.SUB_DRAW);
            }
        }
    }

    public static function drawStageGfx():Void {
        drawObjectList(0);
        if (Scene.activeTileLayers[0] < Scene.LAYER_COUNT) {
            switch (Scene.stageLayouts[Scene.activeTileLayers[0]].type) {
                case Scene.LAYER_HSCROLL: drawHLineScrollLayer(0);
                case Scene.LAYER_VSCROLL: drawVLineScrollLayer(0);
                case Scene.LAYER_3DCLOUD: draw3DCloudLayer(0);
                default:
            }
        }

        drawObjectList(1);
        if (Scene.activeTileLayers[1] < Scene.LAYER_COUNT) {
            switch (Scene.stageLayouts[Scene.activeTileLayers[1]].type) {
                case Scene.LAYER_HSCROLL: drawHLineScrollLayer(1);
                case Scene.LAYER_VSCROLL: drawVLineScrollLayer(1);
                case Scene.LAYER_3DCLOUD: draw3DCloudLayer(1);
                default:
            }
        }

        drawObjectList(2);
        if (Scene.activeTileLayers[2] < Scene.LAYER_COUNT) {
            switch (Scene.stageLayouts[Scene.activeTileLayers[2]].type) {
                case Scene.LAYER_HSCROLL: drawHLineScrollLayer(2);
                case Scene.LAYER_VSCROLL: drawVLineScrollLayer(2);
                case Scene.LAYER_3DCLOUD: draw3DCloudLayer(2);
                default:
            }
        }

        drawObjectList(3);
        drawObjectList(4);
        if (Scene.activeTileLayers[3] < Scene.LAYER_COUNT) {
            switch (Scene.stageLayouts[Scene.activeTileLayers[3]].type) {
                case Scene.LAYER_HSCROLL: drawHLineScrollLayer(3);
                case Scene.LAYER_VSCROLL: drawVLineScrollLayer(3);
                case Scene.LAYER_3DCLOUD: draw3DCloudLayer(3);
                default:
            }
        }

        drawObjectList(5);
        drawObjectList(6);
    }

    public static function drawHLineScrollLayer(layerID:Int):Void {
        if (frameBuffer == null) return;
        var layer = Scene.stageLayouts[Scene.activeTileLayers[layerID]];
        var screenwidth16 = (SCREEN_XSIZE >> 4) - 1;
        var layerwidth = layer.xsize;
        var layerheight = layer.ysize;
        var aboveMidPoint = layerID >= Scene.tLayerMidPoint;

        var yscrollOffset = 0;
        var deformationIdx = 0;
        var deformationIdxW = 0;

        if (Scene.activeTileLayers[layerID] != 0) {
            var yScroll = Scene.yScrollOffset * layer.parallaxFactor >> 6;
            var fullheight = layerheight << 7;
            layer.scrollPos += layer.scrollSpeed;
            if (layer.scrollPos > fullheight << 16)
                layer.scrollPos -= fullheight << 16;
            yscrollOffset = (yScroll + (layer.scrollPos >> 16)) % fullheight;
            layerheight = fullheight >> 7;
            deformationIdx = (yscrollOffset + Scene.deformationPos3) & 0xFF;
            deformationIdxW = (yscrollOffset + waterDrawPos + Scene.deformationPos4) & 0xFF;
        } else {
            Scene.lastXSize = layer.xsize;
            yscrollOffset = Scene.yScrollOffset;
            for (i in 0...Scene.PARALLAX_COUNT) Scene.hParallax.linePos[i] = Scene.xScrollOffset;
            deformationIdx = (yscrollOffset + Scene.deformationPos1) & 0xFF;
            deformationIdxW = (yscrollOffset + waterDrawPos + Scene.deformationPos2) & 0xFF;
        }

        if (layer.type == Scene.LAYER_HSCROLL) {
            if (Scene.lastXSize != layerwidth) {
                var fullLayerwidth = layerwidth << 7;
                for (i in 0...Scene.hParallax.entryCount) {
                    Scene.hParallax.linePos[i] = Scene.xScrollOffset * Scene.hParallax.parallaxFactor[i] >> 7;
                    Scene.hParallax.scrollPos[i] += Scene.hParallax.scrollSpeed[i];
                    if (Scene.hParallax.scrollPos[i] > fullLayerwidth << 16)
                        Scene.hParallax.scrollPos[i] -= fullLayerwidth << 16;
                    if (Scene.hParallax.scrollPos[i] < 0)
                        Scene.hParallax.scrollPos[i] += fullLayerwidth << 16;
                    Scene.hParallax.linePos[i] += Scene.hParallax.scrollPos[i] >> 16;
                    Scene.hParallax.linePos[i] %= fullLayerwidth;
                }
            }
            Scene.lastXSize = layerwidth;
        }

        var pixelBufferIdx = 0;
        var tileYPos = yscrollOffset % (layerheight << 7);
        if (tileYPos < 0) tileYPos += layerheight << 7;
        var scrollIndexPos = tileYPos;
        var tileY16 = tileYPos & 0xF;
        var chunkY = tileYPos >> 7;
        var tileY = (tileYPos & 0x7F) >> 4;

        var drawableLines = [waterDrawPos, SCREEN_YSIZE - waterDrawPos];
        for (part in 0...2) {
            var linesToDraw = drawableLines[part];
            while (linesToDraw > 0) {
                linesToDraw--;
                var scrollIdx = layer.lineScroll[scrollIndexPos % layer.lineScroll.length];
                var chunkX = Scene.hParallax.linePos[scrollIdx];
                if (part == 0) {
                    var deform = 0;
                    if (Scene.hParallax.deform[scrollIdx] != 0)
                        deform = Scene.bgDeformationData3[deformationIdx];
                    chunkX += deform;
                    deformationIdx = (deformationIdx + 1) & 0xFF;
                } else {
                    if (Scene.hParallax.deform[scrollIdx] != 0)
                        chunkX += Scene.bgDeformationData4[deformationIdxW];
                    deformationIdxW = (deformationIdxW + 1) & 0xFF;
                }
                scrollIndexPos++;
                var fullLayerwidth = layerwidth << 7;
                if (chunkX < 0) chunkX += fullLayerwidth;
                if (chunkX >= fullLayerwidth) chunkX -= fullLayerwidth;
                var chunkXPos = chunkX >> 7;
                var tilePxXPos = chunkX & 0xF;
                var tileXPxRemain = TILE_SIZE - tilePxXPos;
                var chunk = (layer.tiles[chunkXPos + (chunkY << 8)] << 6) + ((chunkX & 0x7F) >> 4) + 8 * tileY;
                var tileOffsetY = TILE_SIZE * tileY16;
                var tileOffsetYFlipX = TILE_SIZE * tileY16 + 0xF;
                var tileOffsetYFlipY = TILE_SIZE * (0xF - tileY16);
                var tileOffsetYFlipXY = TILE_SIZE * (0xF - tileY16) + 0xF;
                var lineRemain = SCREEN_XSIZE;

                var aboveMidPointInt = aboveMidPoint ? 1 : 0;
                if (Scene.stageTiles.visualPlane[chunk] == aboveMidPointInt) {
                    var tilePxLineCnt = TILE_SIZE - tilePxXPos;
                    lineRemain -= tilePxLineCnt;
                    var dir = Scene.stageTiles.direction[chunk];
                    var gfxBase = Scene.stageTiles.gfxDataPos[chunk];
                    if (dir == FLIP_NONE) {
                        var gfxPos = tileOffsetY + gfxBase + tilePxXPos;
                        for (px in 0...tilePxLineCnt) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx++;
                            gfxPos++;
                        }
                    } else if (dir == FLIP_X) {
                        var gfxPos = tileOffsetYFlipX + gfxBase - tilePxXPos;
                        for (px in 0...tilePxLineCnt) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx++;
                            gfxPos--;
                        }
                    } else if (dir == FLIP_Y) {
                        var gfxPos = tileOffsetYFlipY + gfxBase + tilePxXPos;
                        for (px in 0...tilePxLineCnt) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx++;
                            gfxPos++;
                        }
                    } else {
                        var gfxPos = tileOffsetYFlipXY + gfxBase - tilePxXPos;
                        for (px in 0...tilePxLineCnt) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx++;
                            gfxPos--;
                        }
                    }
                } else {
                    pixelBufferIdx += tileXPxRemain;
                    lineRemain -= tileXPxRemain;
                }

                var chunkTileX = ((chunkX & 0x7F) >> 4) + 1;
                var tilesPerLine = screenwidth16;
                while (tilesPerLine > 0) {
                    tilesPerLine--;
                    if (chunkTileX < 8) {
                        chunk++;
                    } else {
                        chunkXPos++;
                        if (chunkXPos == layerwidth) chunkXPos = 0;
                        chunkTileX = 0;
                        chunk = (layer.tiles[chunkXPos + (chunkY << 8)] << 6) + 8 * tileY;
                    }
                    lineRemain -= TILE_SIZE;

                    if (Scene.stageTiles.visualPlane[chunk] == aboveMidPointInt) {
                        var dir = Scene.stageTiles.direction[chunk];
                        var gfxBase = Scene.stageTiles.gfxDataPos[chunk];
                        if (dir == FLIP_NONE) {
                            var gfxPos = gfxBase + tileOffsetY;
                            for (px in 0...TILE_SIZE) {
                                var gfx = Scene.tileGfx[gfxPos];
                                if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                                pixelBufferIdx++;
                                gfxPos++;
                            }
                        } else if (dir == FLIP_X) {
                            var gfxPos = gfxBase + tileOffsetYFlipX;
                            for (px in 0...TILE_SIZE) {
                                var gfx = Scene.tileGfx[gfxPos];
                                if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                                pixelBufferIdx++;
                                gfxPos--;
                            }
                        } else if (dir == FLIP_Y) {
                            var gfxPos = gfxBase + tileOffsetYFlipY;
                            for (px in 0...TILE_SIZE) {
                                var gfx = Scene.tileGfx[gfxPos];
                                if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                                pixelBufferIdx++;
                                gfxPos++;
                            }
                        } else {
                            var gfxPos = gfxBase + tileOffsetYFlipXY;
                            for (px in 0...TILE_SIZE) {
                                var gfx = Scene.tileGfx[gfxPos];
                                if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                                pixelBufferIdx++;
                                gfxPos--;
                            }
                        }
                    } else {
                        pixelBufferIdx += TILE_SIZE;
                    }
                    chunkTileX++;
                }

                while (lineRemain > 0) {
                    if (chunkTileX < 8) {
                        chunk++;
                    } else {
                        chunkXPos++;
                        if (chunkXPos == layerwidth) chunkXPos = 0;
                        chunkTileX = 0;
                        chunk = (layer.tiles[chunkXPos + (chunkY << 8)] << 6) + 8 * tileY;
                    }
                    chunkTileX++;

                    var tilePxLineCnt = lineRemain >= TILE_SIZE ? TILE_SIZE : lineRemain;
                    lineRemain -= tilePxLineCnt;
                    if (Scene.stageTiles.visualPlane[chunk] == aboveMidPointInt) {
                        var dir = Scene.stageTiles.direction[chunk];
                        var gfxBase = Scene.stageTiles.gfxDataPos[chunk];
                        if (dir == FLIP_NONE) {
                            var gfxPos = gfxBase + tileOffsetY;
                            for (px in 0...tilePxLineCnt) {
                                var gfx = Scene.tileGfx[gfxPos];
                                if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                                pixelBufferIdx++;
                                gfxPos++;
                            }
                        } else if (dir == FLIP_X) {
                            var gfxPos = gfxBase + tileOffsetYFlipX;
                            for (px in 0...tilePxLineCnt) {
                                var gfx = Scene.tileGfx[gfxPos];
                                if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                                pixelBufferIdx++;
                                gfxPos--;
                            }
                        } else if (dir == FLIP_Y) {
                            var gfxPos = gfxBase + tileOffsetYFlipY;
                            for (px in 0...tilePxLineCnt) {
                                var gfx = Scene.tileGfx[gfxPos];
                                if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                                pixelBufferIdx++;
                                gfxPos++;
                            }
                        } else {
                            var gfxPos = gfxBase + tileOffsetYFlipXY;
                            for (px in 0...tilePxLineCnt) {
                                var gfx = Scene.tileGfx[gfxPos];
                                if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                                pixelBufferIdx++;
                                gfxPos--;
                            }
                        }
                    } else {
                        pixelBufferIdx += tilePxLineCnt;
                    }
                }

                tileY16++;
                if (tileY16 >= TILE_SIZE) {
                    tileY16 = 0;
                    tileY++;
                }
                if (tileY >= 8) {
                    chunkY++;
                    if (chunkY == layerheight) {
                        chunkY = 0;
                        scrollIndexPos -= 0x80 * layerheight;
                    }
                    tileY = 0;
                }
            }
        }
    }

    public static function drawVLineScrollLayer(layerID:Int):Void {
        if (frameBuffer == null) return;
        var layer = Scene.stageLayouts[Scene.activeTileLayers[layerID]];
        if (layer.xsize == 0 || layer.ysize == 0) return;

        var layerwidth = layer.xsize;
        var layerheight = layer.ysize;
        var aboveMidPoint = layerID >= Scene.tLayerMidPoint;
        var aboveMidPointInt = aboveMidPoint ? 1 : 0;

        var xscrollOffset = 0;
        var deformationIdx = 0;

        if (Scene.activeTileLayers[layerID] != 0) {
            var xScroll = Scene.xScrollOffset * layer.parallaxFactor >> 6;
            var fullLayerwidth = layerwidth << 7;
            layer.scrollPos += layer.scrollSpeed;
            if (layer.scrollPos > fullLayerwidth << 16)
                layer.scrollPos -= fullLayerwidth << 16;
            xscrollOffset = (xScroll + (layer.scrollPos >> 16)) % fullLayerwidth;
            layerwidth = fullLayerwidth >> 7;
            deformationIdx = (xscrollOffset + Scene.deformationPos3) & 0xFF;
        } else {
            Scene.lastYSize = layer.ysize;
            xscrollOffset = Scene.xScrollOffset;
            Scene.vParallax.linePos[0] = Scene.yScrollOffset;
            Scene.vParallax.deform[0] = 1;
            deformationIdx = (Scene.xScrollOffset + Scene.deformationPos1) & 0xFF;
        }

        if (layer.type == Scene.LAYER_VSCROLL) {
            if (Scene.lastYSize != layerheight) {
                var fullLayerheight = layerheight << 7;
                for (i in 0...Scene.vParallax.entryCount) {
                    Scene.vParallax.linePos[i] = Scene.yScrollOffset * Scene.vParallax.parallaxFactor[i] >> 7;
                    Scene.vParallax.scrollPos[i] += Scene.vParallax.scrollPos[i] << 16;
                    if (Scene.vParallax.scrollPos[i] > fullLayerheight << 16)
                        Scene.vParallax.scrollPos[i] -= fullLayerheight << 16;
                    Scene.vParallax.linePos[i] += Scene.vParallax.scrollPos[i] >> 16;
                    Scene.vParallax.linePos[i] %= fullLayerheight;
                }
                layerheight = fullLayerheight >> 7;
            }
            Scene.lastYSize = layerheight;
        }

        var tileXPos = xscrollOffset % (layerheight << 7);
        if (tileXPos < 0) tileXPos += layerheight << 7;
        var scrollIndexPos = tileXPos;
        var chunkX = tileXPos >> 7;
        var tileX16 = tileXPos & 0xF;
        var tileX = (tileXPos & 0x7F) >> 4;

        var drawableLines = SCREEN_XSIZE;
        while (drawableLines > 0) {
            drawableLines--;
            var pixelBufferIdx = drawableLines;
            var scrollIdx = layer.lineScroll[scrollIndexPos % layer.lineScroll.length];
            var chunkY = Scene.vParallax.linePos[scrollIdx];
            if (Scene.vParallax.deform[scrollIdx] != 0)
                chunkY += Scene.bgDeformationData1[deformationIdx];
            deformationIdx = (deformationIdx + 1) & 0xFF;
            scrollIndexPos++;

            var fullLayerHeight = layerheight << 7;
            if (chunkY < 0) chunkY += fullLayerHeight;
            if (chunkY >= fullLayerHeight) chunkY -= fullLayerHeight;

            var chunkYPos = chunkY >> 7;
            var tileYVal = chunkY & 0xF;
            var tileYPxRemain = TILE_SIZE - tileYVal;
            var chunk = (layer.tiles[chunkX + (chunkY >> 7 << 8)] << 6) + tileX + 8 * ((chunkY & 0x7F) >> 4);
            var tileOffsetXFlipX = 0xF - tileX16;
            var tileOffsetXFlipY = tileX16 + SCREEN_YSIZE;
            var tileOffsetXFlipXY = 0xFF - tileX16;
            var lineRemain = SCREEN_YSIZE;

            var tilePxLineCnt = tileYPxRemain;
            if (Scene.stageTiles.visualPlane[chunk] == aboveMidPointInt) {
                lineRemain -= tilePxLineCnt;
                var dir = Scene.stageTiles.direction[chunk];
                var gfxBase = Scene.stageTiles.gfxDataPos[chunk];
                if (dir == FLIP_NONE) {
                    var gfxPos = TILE_SIZE * tileYVal + tileX16 + gfxBase;
                    for (px in 0...tilePxLineCnt) {
                        var gfx = Scene.tileGfx[gfxPos];
                        if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                        pixelBufferIdx += SCREEN_XSIZE;
                        gfxPos += TILE_SIZE;
                    }
                } else if (dir == FLIP_X) {
                    var gfxPos = TILE_SIZE * tileYVal + tileOffsetXFlipX + gfxBase;
                    for (px in 0...tilePxLineCnt) {
                        var gfx = Scene.tileGfx[gfxPos];
                        if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                        pixelBufferIdx += SCREEN_XSIZE;
                        gfxPos += TILE_SIZE;
                    }
                } else if (dir == FLIP_Y) {
                    var gfxPos = tileOffsetXFlipY + gfxBase - TILE_SIZE * tileYVal;
                    for (px in 0...tilePxLineCnt) {
                        var gfx = Scene.tileGfx[gfxPos];
                        if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                        pixelBufferIdx += SCREEN_XSIZE;
                        gfxPos -= TILE_SIZE;
                    }
                } else {
                    var gfxPos = tileOffsetXFlipXY + gfxBase - TILE_SIZE * tileYVal;
                    for (px in 0...tilePxLineCnt) {
                        var gfx = Scene.tileGfx[gfxPos];
                        if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                        pixelBufferIdx += SCREEN_XSIZE;
                        gfxPos -= TILE_SIZE;
                    }
                }
            } else {
                pixelBufferIdx += SCREEN_XSIZE * tileYPxRemain;
                lineRemain -= tilePxLineCnt;
            }

            var chunkTileY = ((chunkY & 0x7F) >> 4) + 1;
            var tilesPerLine = (SCREEN_YSIZE >> 4) - 1;
            while (tilesPerLine > 0) {
                tilesPerLine--;
                if (chunkTileY < 8) {
                    chunk += 8;
                } else {
                    chunkYPos++;
                    if (chunkYPos == layerheight) chunkYPos = 0;
                    chunkTileY = 0;
                    chunk = (layer.tiles[chunkX + (chunkYPos << 8)] << 6) + tileX;
                }
                lineRemain -= TILE_SIZE;

                if (Scene.stageTiles.visualPlane[chunk] == aboveMidPointInt) {
                    var dir = Scene.stageTiles.direction[chunk];
                    var gfxBase = Scene.stageTiles.gfxDataPos[chunk];
                    if (dir == FLIP_NONE) {
                        var gfxPos = gfxBase + tileX16;
                        for (px in 0...TILE_SIZE) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx += SCREEN_XSIZE;
                            gfxPos += TILE_SIZE;
                        }
                    } else if (dir == FLIP_X) {
                        var gfxPos = gfxBase + tileOffsetXFlipX;
                        for (px in 0...TILE_SIZE) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx += SCREEN_XSIZE;
                            gfxPos += TILE_SIZE;
                        }
                    } else if (dir == FLIP_Y) {
                        var gfxPos = gfxBase + tileOffsetXFlipY;
                        for (px in 0...TILE_SIZE) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx += SCREEN_XSIZE;
                            gfxPos -= TILE_SIZE;
                        }
                    } else {
                        var gfxPos = gfxBase + tileOffsetXFlipXY;
                        for (px in 0...TILE_SIZE) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx += SCREEN_XSIZE;
                            gfxPos -= TILE_SIZE;
                        }
                    }
                } else {
                    pixelBufferIdx += SCREEN_XSIZE * TILE_SIZE;
                }
                chunkTileY++;
            }

            while (lineRemain > 0) {
                if (chunkTileY < 8) {
                    chunk += 8;
                } else {
                    chunkYPos++;
                    if (chunkYPos == layerheight) chunkYPos = 0;
                    chunkTileY = 0;
                    chunk = (layer.tiles[chunkX + (chunkYPos << 8)] << 6) + tileX;
                }
                chunkTileY++;

                tilePxLineCnt = lineRemain >= TILE_SIZE ? TILE_SIZE : lineRemain;
                lineRemain -= tilePxLineCnt;
                if (Scene.stageTiles.visualPlane[chunk] == aboveMidPointInt) {
                    var dir = Scene.stageTiles.direction[chunk];
                    var gfxBase = Scene.stageTiles.gfxDataPos[chunk];
                    if (dir == FLIP_NONE) {
                        var gfxPos = gfxBase + tileX16;
                        for (px in 0...tilePxLineCnt) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx += SCREEN_XSIZE;
                            gfxPos += TILE_SIZE;
                        }
                    } else if (dir == FLIP_X) {
                        var gfxPos = gfxBase + tileOffsetXFlipX;
                        for (px in 0...tilePxLineCnt) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx += SCREEN_XSIZE;
                            gfxPos += TILE_SIZE;
                        }
                    } else if (dir == FLIP_Y) {
                        var gfxPos = gfxBase + tileOffsetXFlipY;
                        for (px in 0...tilePxLineCnt) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx += SCREEN_XSIZE;
                            gfxPos -= TILE_SIZE;
                        }
                    } else {
                        var gfxPos = gfxBase + tileOffsetXFlipXY;
                        for (px in 0...tilePxLineCnt) {
                            var gfx = Scene.tileGfx[gfxPos];
                            if (gfx > 0) frameBuffer[pixelBufferIdx] = gfx;
                            pixelBufferIdx += SCREEN_XSIZE;
                            gfxPos -= TILE_SIZE;
                        }
                    }
                } else {
                    pixelBufferIdx += SCREEN_XSIZE * tilePxLineCnt;
                }
            }

            tileX16++;
            if (tileX16 >= TILE_SIZE) {
                tileX16 = 0;
                tileX++;
            }
            if (tileX >= 8) {
                chunkX++;
                if (chunkX == layerwidth) {
                    chunkX = 0;
                    scrollIndexPos -= 0x80 * layerwidth;
                }
                tileX = 0;
            }
        }
    }

    public static function draw3DCloudLayer(layerID:Int):Void {
        var layer = Scene.stageLayouts[Scene.activeTileLayers[layerID]];
    }

    public static function drawPlayer(player:Player, frame:Animation.SpriteFrame):Void {
        var rotation = 0;
        var anim = player.animation;
        if (anim == PlayerManager.ANI_RUNNING || anim == PlayerManager.ANI_WALKING || anim == PlayerManager.ANI_PEELOUT || anim == PlayerManager.ANI_CORKSCREW) {
            if (player.rotation >= 0x80)
                rotation = 0x200 - ((266 - player.rotation) >> 5 << 6);
            else
                rotation = (player.rotation + 10) >> 5 << 6;
        }
        drawRotatedSprite(player.direction, player.screenXPos, player.screenYPos, -frame.pivotX, -frame.pivotY, frame.sprX, frame.sprY, frame.width, frame.height, rotation, frame.sheetID);
    }

    public static function drawSprite(xPos:Int, yPos:Int, width:Int, height:Int, sprX:Int, sprY:Int, sheetID:Int):Void {
        if (frameBuffer == null) return;

        if (width + xPos > SCREEN_XSIZE) width = SCREEN_XSIZE - xPos;
        if (xPos < 0) {
            sprX -= xPos;
            width += xPos;
            xPos = 0;
        }
        if (height + yPos > SCREEN_YSIZE) height = SCREEN_YSIZE - yPos;
        if (yPos < 0) {
            sprY -= yPos;
            height += yPos;
            yPos = 0;
        }
        if (width <= 0 || height <= 0) return;

        var surface = gfxSurface[sheetID];
        var pitch = SCREEN_XSIZE - width;
        var gfxPitch = surface.width - width;
        var gfxPos = sprX + surface.width * sprY + surface.dataPosition;
        var pixelPos = xPos + SCREEN_XSIZE * yPos;

        for (h in 0...height) {
            for (w in 0...width) {
                var gfxData = graphicData[gfxPos];
                if (gfxData > 0)
                    frameBuffer[pixelPos] = gfxData;
                gfxPos++;
                pixelPos++;
            }
            pixelPos += pitch;
            gfxPos += gfxPitch;
        }
    }

    public static function drawScaledSprite(direction:Int, xPos:Int, yPos:Int, pivotX:Int, pivotY:Int, scaleX:Int, scaleY:Int, width:Int, height:Int, sprX:Int, sprY:Int, sheetID:Int):Void {
        if (frameBuffer == null) return;

        var roundedYPos = 0;
        var roundedXPos = 0;
        var truescaleX = 4 * scaleX;
        var truescaleY = 4 * scaleY;
        var widthM1 = width - 1;
        var trueXPos = xPos - (truescaleX * pivotX >> 11);
        width = truescaleX * width >> 11;
        var trueYPos = yPos - (truescaleY * pivotY >> 11);
        height = truescaleY * height >> 11;
        var finalscaleX = Std.int(2048.0 / truescaleX * 2048.0);
        var finalscaleY = Std.int(2048.0 / truescaleY * 2048.0);
        if (width + trueXPos > SCREEN_XSIZE) {
            width = SCREEN_XSIZE - trueXPos;
        }

        if (direction != 0) {
            if (trueXPos < 0) {
                widthM1 -= trueXPos * -finalscaleX >> 11;
                roundedXPos = (trueXPos & 0xFFFF) * (-finalscaleX & 0xFFFF) & 0x7FF;
                width += trueXPos;
                trueXPos = 0;
            }
        } else if (trueXPos < 0) {
            sprX += trueXPos * -finalscaleX >> 11;
            roundedXPos = (trueXPos & 0xFFFF) * (-finalscaleX & 0xFFFF) & 0x7FF;
            width += trueXPos;
            trueXPos = 0;
        }

        if (height + trueYPos > SCREEN_YSIZE) {
            height = SCREEN_YSIZE - trueYPos;
        }
        if (trueYPos < 0) {
            sprY += trueYPos * -finalscaleY >> 11;
            roundedYPos = (trueYPos & 0xFFFF) * (-finalscaleY & 0xFFFF) & 0x7FF;
            height += trueYPos;
            trueYPos = 0;
        }

        if (width <= 0 || height <= 0) return;

        var surface = gfxSurface[sheetID];
        var pitch = SCREEN_XSIZE - width;
        var gfxwidth = surface.width;
        var gfxDataStart = sprX + surface.width * sprY + surface.dataPosition;
        var pixelBufferIdx = trueXPos + SCREEN_XSIZE * trueYPos;

        if (direction == FLIP_X) {
            var gfxDataPos = gfxDataStart + widthM1;
            var gfxPitch = 0;
            for (hh in 0...height) {
                var roundXPos = roundedXPos;
                for (ww in 0...width) {
                    if (graphicData[gfxDataPos] > 0)
                        frameBuffer[pixelBufferIdx] = graphicData[gfxDataPos];
                    var offsetX = finalscaleX + roundXPos;
                    gfxDataPos -= offsetX >> 11;
                    gfxPitch += offsetX >> 11;
                    roundXPos = offsetX & 0x7FF;
                    pixelBufferIdx++;
                }
                pixelBufferIdx += pitch;
                var offsetY = finalscaleY + roundedYPos;
                gfxDataPos += gfxPitch + (offsetY >> 11) * gfxwidth;
                roundedYPos = offsetY & 0x7FF;
                gfxPitch = 0;
            }
        } else {
            var gfxDataPos = gfxDataStart;
            var gfxPitch = 0;
            for (hh in 0...height) {
                var roundXPos = roundedXPos;
                for (ww in 0...width) {
                    if (graphicData[gfxDataPos] > 0)
                        frameBuffer[pixelBufferIdx] = graphicData[gfxDataPos];
                    var offsetX = finalscaleX + roundXPos;
                    gfxDataPos += offsetX >> 11;
                    gfxPitch += offsetX >> 11;
                    roundXPos = offsetX & 0x7FF;
                    pixelBufferIdx++;
                }
                pixelBufferIdx += pitch;
                var offsetY = finalscaleY + roundedYPos;
                gfxDataPos += (offsetY >> 11) * gfxwidth - gfxPitch;
                roundedYPos = offsetY & 0x7FF;
                gfxPitch = 0;
            }
        }
    }

    public static function drawRotatedSprite(direction:Int, xPos:Int, yPos:Int, pivotX:Int, pivotY:Int, sprX:Int, sprY:Int, width:Int, height:Int, rotation:Int, sheetID:Int):Void {
        if (frameBuffer == null) return;

        var sprXPos = (pivotX + sprX) << 9;
        var sprYPos = (pivotY + sprY) << 9;
        var fullwidth = width + sprX;
        var fullheight = height + sprY;
        var angle = rotation & 0x1FF;
        if (angle < 0) angle += 0x200;
        if (angle != 0) angle = 0x200 - angle;
        var sine = RetroMath.sinValue512[angle];
        var cosine = RetroMath.cosValue512[angle];
        var xPositions = [0, 0, 0, 0];
        var yPositions = [0, 0, 0, 0];

        if (direction == FLIP_X) {
            xPositions[0] = xPos + ((sine * (-pivotY - 2) + cosine * (pivotX + 2)) >> 9);
            yPositions[0] = yPos + ((cosine * (-pivotY - 2) - sine * (pivotX + 2)) >> 9);
            xPositions[1] = xPos + ((sine * (-pivotY - 2) + cosine * (pivotX - width - 2)) >> 9);
            yPositions[1] = yPos + ((cosine * (-pivotY - 2) - sine * (pivotX - width - 2)) >> 9);
            xPositions[2] = xPos + ((sine * (height - pivotY + 2) + cosine * (pivotX + 2)) >> 9);
            yPositions[2] = yPos + ((cosine * (height - pivotY + 2) - sine * (pivotX + 2)) >> 9);
            var a = pivotX - width - 2;
            var b = height - pivotY + 2;
            xPositions[3] = xPos + ((sine * b + cosine * a) >> 9);
            yPositions[3] = yPos + ((cosine * b - sine * a) >> 9);
        } else {
            xPositions[0] = xPos + ((sine * (-pivotY - 2) + cosine * (-pivotX - 2)) >> 9);
            yPositions[0] = yPos + ((cosine * (-pivotY - 2) - sine * (-pivotX - 2)) >> 9);
            xPositions[1] = xPos + ((sine * (-pivotY - 2) + cosine * (width - pivotX + 2)) >> 9);
            yPositions[1] = yPos + ((cosine * (-pivotY - 2) - sine * (width - pivotX + 2)) >> 9);
            xPositions[2] = xPos + ((sine * (height - pivotY + 2) + cosine * (-pivotX - 2)) >> 9);
            yPositions[2] = yPos + ((cosine * (height - pivotY + 2) - sine * (-pivotX - 2)) >> 9);
            var a = width - pivotX + 2;
            var b = height - pivotY + 2;
            xPositions[3] = xPos + ((sine * b + cosine * a) >> 9);
            yPositions[3] = yPos + ((cosine * b - sine * a) >> 9);
        }

        var left = SCREEN_XSIZE;
        for (i in 0...4) {
            if (xPositions[i] < left) left = xPositions[i];
        }
        if (left < 0) left = 0;

        var right = 0;
        for (i in 0...4) {
            if (xPositions[i] > right) right = xPositions[i];
        }
        if (right > SCREEN_XSIZE) right = SCREEN_XSIZE;
        var maxX = right - left;

        var top = SCREEN_YSIZE;
        for (i in 0...4) {
            if (yPositions[i] < top) top = yPositions[i];
        }
        if (top < 0) top = 0;

        var bottom = 0;
        for (i in 0...4) {
            if (yPositions[i] > bottom) bottom = yPositions[i];
        }
        if (bottom > SCREEN_YSIZE) bottom = SCREEN_YSIZE;
        var maxY = bottom - top;

        if (maxX <= 0 || maxY <= 0) return;

        var surface = gfxSurface[sheetID];
        var pitch = SCREEN_XSIZE - maxX;
        var pixelBufferIdx = left + SCREEN_XSIZE * top;
        var startX = left - xPos;
        var startY = top - yPos;
        var shiftPivot = (sprX << 9) - 1;
        fullwidth <<= 9;
        var shiftheight = (sprY << 9) - 1;
        fullheight <<= 9;
        var gfxDataBase = surface.dataPosition;
        if (cosine < 0 || sine < 0)
            sprYPos += sine + cosine;

        if (direction == FLIP_X) {
            var drawX = sprXPos - (cosine * startX - sine * startY) - 0x100;
            var drawY = cosine * startY + sprYPos + sine * startX;
            for (yy in 0...maxY) {
                var finalX = drawX;
                var finalY = drawY;
                for (xx in 0...maxX) {
                    if (finalX > shiftPivot && finalX < fullwidth && finalY > shiftheight && finalY < fullheight) {
                        var index = graphicData[gfxDataBase + ((finalY >> 9) * surface.width) + (finalX >> 9)];
                        if (index > 0)
                            frameBuffer[pixelBufferIdx] = index;
                    }
                    pixelBufferIdx++;
                    finalX -= cosine;
                    finalY += sine;
                }
                drawX += sine;
                drawY += cosine;
                pixelBufferIdx += pitch;
            }
        } else {
            var drawX = sprXPos + cosine * startX - sine * startY;
            var drawY = cosine * startY + sprYPos + sine * startX;
            for (yy in 0...maxY) {
                var finalX = drawX;
                var finalY = drawY;
                for (xx in 0...maxX) {
                    if (finalX > shiftPivot && finalX < fullwidth && finalY > shiftheight && finalY < fullheight) {
                        var index = graphicData[gfxDataBase + ((finalY >> 9) * surface.width) + (finalX >> 9)];
                        if (index > 0)
                            frameBuffer[pixelBufferIdx] = index;
                    }
                    pixelBufferIdx++;
                    finalX += cosine;
                    finalY += sine;
                }
                drawX -= sine;
                drawY += cosine;
                pixelBufferIdx += pitch;
            }
        }
    }

    public static function drawBlendedSprite(xPos:Int, yPos:Int, width:Int, height:Int, sprX:Int, sprY:Int, sheetID:Int):Void {
        if (frameBuffer == null) return;

        if (width + xPos > SCREEN_XSIZE) width = SCREEN_XSIZE - xPos;
        if (xPos < 0) {
            sprX -= xPos;
            width += xPos;
            xPos = 0;
        }
        if (height + yPos > SCREEN_YSIZE) height = SCREEN_YSIZE - yPos;
        if (yPos < 0) {
            sprY -= yPos;
            height += yPos;
            yPos = 0;
        }
        if (width <= 0 || height <= 0) return;

        var surface = gfxSurface[sheetID];
        var pitch = SCREEN_XSIZE - width;
        var gfxPitch = surface.width - width;
        var gfxPos = sprX + surface.width * sprY + surface.dataPosition;
        var pixelPos = xPos + SCREEN_XSIZE * yPos;

        for (h in 0...height) {
            for (w in 0...width) {
                var gfxData = graphicData[gfxPos];
                if (gfxData > 0)
                    frameBuffer[pixelPos] = blendLookupTable[(0x100 * frameBuffer[pixelPos]) + gfxData];
                gfxPos++;
                pixelPos++;
            }
            pixelPos += pitch;
            gfxPos += gfxPitch;
        }
    }

    public static function drawTintRect(xPos:Int, yPos:Int, width:Int, height:Int, tintID:Int):Void {
        if (frameBuffer == null) return;

        if (width + xPos > SCREEN_XSIZE) width = SCREEN_XSIZE - xPos;
        if (xPos < 0) {
            width += xPos;
            xPos = 0;
        }
        if (height + yPos > SCREEN_YSIZE) height = SCREEN_YSIZE - yPos;
        if (yPos < 0) {
            height += yPos;
            yPos = 0;
        }
        if (width < 0 || height < 0) return;

        var tintTable:Array<Int> = switch (tintID) {
            case 0: tintLookupTable1;
            case 1: tintLookupTable2;
            case 2: tintLookupTable3;
            case 3: tintLookupTable4;
            default: null;
        };
        if (tintTable == null) return;

        var yOffset = SCREEN_XSIZE - width;
        var pixelPos = xPos + SCREEN_XSIZE * yPos;

        for (h in 0...height) {
            for (w in 0...width) {
                frameBuffer[pixelPos] = tintTable[frameBuffer[pixelPos]];
                pixelPos++;
            }
            pixelPos += yOffset;
        }
    }

    public static function drawScaledTintMask(direction:Int, xPos:Int, yPos:Int, pivotX:Int, pivotY:Int, scaleX:Int, scaleY:Int, width:Int, height:Int, sprX:Int, sprY:Int, tintID:Int, sheetID:Int):Void {
        if (frameBuffer == null) return;

        var roundedYPos = 0;
        var roundedXPos = 0;
        var truescaleX = 4 * scaleX;
        var truescaleY = 4 * scaleY;
        var widthM1 = width - 1;
        var trueXPos = xPos - (truescaleX * pivotX >> 11);
        width = truescaleX * width >> 11;
        var trueYPos = yPos - (truescaleY * pivotY >> 11);
        height = truescaleY * height >> 11;
        var finalscaleX = Std.int(2048.0 / truescaleX * 2048.0);
        var finalscaleY = Std.int(2048.0 / truescaleY * 2048.0);
        if (width + trueXPos > SCREEN_XSIZE) {
            width = SCREEN_XSIZE - trueXPos;
        }

        if (direction != 0) {
            if (trueXPos < 0) {
                widthM1 -= trueXPos * -finalscaleX >> 11;
                roundedXPos = (trueXPos & 0xFFFF) * (-finalscaleX & 0xFFFF) & 0x7FF;
                width += trueXPos;
                trueXPos = 0;
            }
        } else if (trueXPos < 0) {
            sprX += trueXPos * -finalscaleX >> 11;
            roundedXPos = (trueXPos & 0xFFFF) * (-finalscaleX & 0xFFFF) & 0x7FF;
            width += trueXPos;
            trueXPos = 0;
        }

        if (height + trueYPos > SCREEN_YSIZE) {
            height = SCREEN_YSIZE - trueYPos;
        }
        if (trueYPos < 0) {
            sprY += trueYPos * -finalscaleY >> 11;
            roundedYPos = (trueYPos & 0xFFFF) * (-finalscaleY & 0xFFFF) & 0x7FF;
            height += trueYPos;
            trueYPos = 0;
        }

        if (width <= 0 || height <= 0) return;

        var tintTable:Array<Int> = switch (tintID) {
            case 0: tintLookupTable1;
            case 1: tintLookupTable2;
            case 2: tintLookupTable3;
            case 3: tintLookupTable4;
            default: null;
        };
        if (tintTable == null) return;

        var surface = gfxSurface[sheetID];
        var pitch = SCREEN_XSIZE - width;
        var gfxwidth = surface.width;
        var gfxDataStart = sprX + surface.width * sprY + surface.dataPosition;
        var pixelBufferIdx = trueXPos + SCREEN_XSIZE * trueYPos;

        if (direction == FLIP_X) {
            var gfxDataPos = gfxDataStart + widthM1;
            var gfxPitch = 0;
            for (hh in 0...height) {
                var roundXPos = roundedXPos;
                for (ww in 0...width) {
                    if (graphicData[gfxDataPos] > 0)
                        frameBuffer[pixelBufferIdx] = tintTable[frameBuffer[pixelBufferIdx]];
                    var offsetX = finalscaleX + roundXPos;
                    gfxDataPos -= offsetX >> 11;
                    gfxPitch += offsetX >> 11;
                    roundXPos = offsetX & 0x7FF;
                    pixelBufferIdx++;
                }
                pixelBufferIdx += pitch;
                var offsetY = finalscaleY + roundedYPos;
                gfxDataPos += gfxPitch + (offsetY >> 11) * gfxwidth;
                roundedYPos = offsetY & 0x7FF;
                gfxPitch = 0;
            }
        } else {
            var gfxDataPos = gfxDataStart;
            var gfxPitch = 0;
            for (hh in 0...height) {
                var roundXPos = roundedXPos;
                for (ww in 0...width) {
                    if (graphicData[gfxDataPos] > 0)
                        frameBuffer[pixelBufferIdx] = tintTable[frameBuffer[pixelBufferIdx]];
                    var offsetX = finalscaleX + roundXPos;
                    gfxDataPos += offsetX >> 11;
                    gfxPitch += offsetX >> 11;
                    roundXPos = offsetX & 0x7FF;
                    pixelBufferIdx++;
                }
                pixelBufferIdx += pitch;
                var offsetY = finalscaleY + roundedYPos;
                gfxDataPos += (offsetY >> 11) * gfxwidth - gfxPitch;
                roundedYPos = offsetY & 0x7FF;
                gfxPitch = 0;
            }
        }
    }

    static var getFrameBufferLogged:Bool = false;
    public static function getFrameBufferPixels():Bytes {
        if (frameBuffer == null) return null;
        
        if (!getFrameBufferLogged) {
            getFrameBufferLogged = true;
            var nonZero = 0;
            var sampleIdx = frameBuffer[0];
            for (i in 0...SCREEN_XSIZE * SCREEN_YSIZE) {
                if (frameBuffer[i] > 0) nonZero++;
            }
            var sampleClr = Palette.tilePalette[sampleIdx];
            rsdk.core.Debug.printLog("getFrameBufferPixels: frameBuffer has " + nonZero + " non-zero pixels, sample[0]=" + sampleIdx + " -> RGB(" + sampleClr.r + "," + sampleClr.g + "," + sampleClr.b + ")");
        }

        var pixels = Bytes.alloc(SCREEN_XSIZE * SCREEN_YSIZE * 4);
        var waterPos = waterDrawPos;
        if (waterPos > SCREEN_YSIZE) waterPos = SCREEN_YSIZE;

        if (useRGB565Mode) {
            for (y in 0...SCREEN_YSIZE) {
                for (x in 0...SCREEN_XSIZE) {
                    var rgb565 = frameBuffer[y * SCREEN_XSIZE + x];
                    var pos = (y * SCREEN_XSIZE + x) * 4;
                    var r = ((rgb565 >> 11) & 0x1F) << 3;
                    var g = ((rgb565 >> 5) & 0x3F) << 2;
                    var b = (rgb565 & 0x1F) << 3;
                    pixels.set(pos, b);
                    pixels.set(pos + 1, g);
                    pixels.set(pos + 2, r);
                    pixels.set(pos + 3, 0xFF);
                }
            }
            return pixels;
        }

        if (Palette.paletteMode != 0) {
            for (y in 0...waterPos) {
                for (x in 0...SCREEN_XSIZE) {
                    var idx = frameBuffer[y * SCREEN_XSIZE + x];
                    var clr = Palette.tilePaletteF[idx];
                    var pos = (y * SCREEN_XSIZE + x) * 4;
                    pixels.set(pos, clr.b);
                    pixels.set(pos + 1, clr.g);
                    pixels.set(pos + 2, clr.r);
                    pixels.set(pos + 3, 0xFF);
                }
            }
            for (y in waterPos...SCREEN_YSIZE) {
                for (x in 0...SCREEN_XSIZE) {
                    var idx = frameBuffer[y * SCREEN_XSIZE + x];
                    var clr = Palette.tilePaletteWF[idx];
                    var pos = (y * SCREEN_XSIZE + x) * 4;
                    pixels.set(pos, clr.b);
                    pixels.set(pos + 1, clr.g);
                    pixels.set(pos + 2, clr.r);
                    pixels.set(pos + 3, 0xFF);
                }
            }
        } else {
            for (y in 0...waterPos) {
                for (x in 0...SCREEN_XSIZE) {
                    var idx = frameBuffer[y * SCREEN_XSIZE + x];
                    var clr = Palette.tilePalette[idx];
                    var pos = (y * SCREEN_XSIZE + x) * 4;
                    pixels.set(pos, clr.b);
                    pixels.set(pos + 1, clr.g);
                    pixels.set(pos + 2, clr.r);
                    pixels.set(pos + 3, 0xFF);
                }
            }
            for (y in waterPos...SCREEN_YSIZE) {
                for (x in 0...SCREEN_XSIZE) {
                    var idx = frameBuffer[y * SCREEN_XSIZE + x];
                    var clr = Palette.tilePaletteW[idx];
                    var pos = (y * SCREEN_XSIZE + x) * 4;
                    pixels.set(pos, clr.b);
                    pixels.set(pos + 1, clr.g);
                    pixels.set(pos + 2, clr.r);
                    pixels.set(pos + 3, 0xFF);
                }
            }
        }

        return pixels;
    }
}
