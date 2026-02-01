package rsdk.graphics;

import rsdk.core.Reader;
import rsdk.core.Reader.FileInfo;
import rsdk.core.RetroString;
import rsdk.core.Debug;
import rsdk.graphics.Palette;
import rsdk.graphics.IndexedGif;
import rsdk.graphics.Video;

class Sprite {
    public static function addGraphicsFile(filePath:String):Int {
        var sheetPath:Array<Int> = RetroString.createArray(0x100);
        RetroString.strCopy(sheetPath, "Data/Sprites/");
        RetroString.strAdd(sheetPath, filePath);
        var sheetID = 0;
        while (RetroString.strLength(Drawing.gfxSurface[sheetID].fileName) > 0) {
            if (RetroString.strComp(Drawing.gfxSurface[sheetID].fileName, sheetPath))
                return sheetID;
            if (++sheetID >= Drawing.SPRITESHEETS_MAX)
                return 0;
        }
        var fileExtension = sheetPath[(RetroString.strLength(sheetPath) - 1) & 0xFF];
        var pathStr = RetroString.arrayToString(sheetPath);
        switch (fileExtension) {
            case 0x66: loadGIFFile(pathStr, sheetID);
            case 0x70: loadBMPFile(pathStr, sheetID);
            case 0x76: loadRSVFile(pathStr, sheetID);
            case 0x78: loadGFXFile(pathStr, sheetID);
            default: Debug.printLog("Unknown sprite extension: " + fileExtension);
        }
        var nonZeroCount = 0;
        var startPos = Drawing.gfxSurface[sheetID].dataPosition;
        var endPos = startPos + Drawing.gfxSurface[sheetID].width * Drawing.gfxSurface[sheetID].height;
        for (i in startPos...endPos) {
            if (Drawing.graphicData[i] > 0) nonZeroCount++;
        }
        Debug.printLog("Loaded sprite sheet " + sheetID + ": " + pathStr + " (surface: " + Drawing.gfxSurface[sheetID].width + "x" + Drawing.gfxSurface[sheetID].height + " at " + Drawing.gfxSurface[sheetID].dataPosition + ", nonZero=" + nonZeroCount + ")");
        return sheetID;
    }

    public static function removeGraphicsFile(filePath:String, sheetID:Int):Void {
        var filePathArr:Array<Int> = RetroString.createArray(0x100);
        RetroString.strCopy(filePathArr, filePath);
        if (sheetID < 0) {
            for (i in 0...Drawing.SURFACE_MAX) {
                if (RetroString.strLength(Drawing.gfxSurface[i].fileName) > 0 && RetroString.strComp(Drawing.gfxSurface[i].fileName, filePathArr))
                    sheetID = i;
            }
        }
        if (sheetID >= 0 && RetroString.strLength(Drawing.gfxSurface[sheetID].fileName) > 0) {
            RetroString.strCopy(Drawing.gfxSurface[sheetID].fileName, "");
            var dataPosStart = Drawing.gfxSurface[sheetID].dataPosition;
            var dataPosEnd = Drawing.gfxSurface[sheetID].dataPosition + Drawing.gfxSurface[sheetID].height * Drawing.gfxSurface[sheetID].width;
            var remaining = 0x200000 - dataPosEnd;
            for (i in 0...remaining) Drawing.graphicData[dataPosStart++] = Drawing.graphicData[dataPosEnd++];
            Drawing.gfxDataPosition -= Drawing.gfxSurface[sheetID].height * Drawing.gfxSurface[sheetID].width;
            for (i in 0...Drawing.SURFACE_MAX) {
                if (Drawing.gfxSurface[i].dataPosition > Drawing.gfxSurface[sheetID].dataPosition)
                    Drawing.gfxSurface[i].dataPosition -= Drawing.gfxSurface[sheetID].height * Drawing.gfxSurface[sheetID].width;
            }
        }
    }

    public static function loadBMPFile(filePath:String, sheetID:Int):Int {
        var info = new FileInfo();
        if (Reader.loadFile(filePath, info)) {
            var surface = Drawing.gfxSurface[sheetID];
            RetroString.strCopy(surface.fileName, filePath);

            var fileBuffer = 0;

            Reader.setFilePosition(18);
            fileBuffer = Reader.fileReadByte();
            surface.width = fileBuffer;
            fileBuffer = Reader.fileReadByte();
            surface.width += fileBuffer << 8;
            fileBuffer = Reader.fileReadByte();
            surface.width += fileBuffer << 16;
            fileBuffer = Reader.fileReadByte();
            surface.width += fileBuffer << 24;

            fileBuffer = Reader.fileReadByte();
            surface.height = fileBuffer;
            fileBuffer = Reader.fileReadByte();
            surface.height += fileBuffer << 8;
            fileBuffer = Reader.fileReadByte();
            surface.height += fileBuffer << 16;
            fileBuffer = Reader.fileReadByte();
            surface.height += fileBuffer << 24;

            Reader.setFilePosition(Std.int(info.fileSize - surface.height * surface.width));
            surface.dataPosition = Drawing.gfxDataPosition;
            var gfxDataPos = surface.dataPosition + surface.width * (surface.height - 1);
            for (y in 0...surface.height) {
                for (x in 0...surface.width) {
                    fileBuffer = Reader.fileReadByte();
                    Drawing.graphicData[gfxDataPos++] = fileBuffer;
                }
                gfxDataPos -= 2 * surface.width;
            }
            Drawing.gfxDataPosition += surface.height * surface.width;

            if (Drawing.gfxDataPosition >= Drawing.GFXDATA_MAX) {
                Drawing.gfxDataPosition = 0;
                Debug.printLog("WARNING: Exceeded max gfx size!");
            }

            Reader.closeFile();
            return 1;
        }
        return 0;
    }

    public static function loadGIFFile(filePath:String, sheetID:Int):Int {
        var fileBytes = Reader.loadFileAsBytes(filePath);
        if (fileBytes == null) {
            Debug.printLog("loadGIFFile: Failed to load: " + filePath);
            return 0;
        }
        
        var gif = IndexedGif.parse(fileBytes);
        
        if (gif == null || gif.pixels.length == 0) {
            Debug.printLog("loadGIFFile: Failed to decode GIF: " + filePath);
            return 0;
        }
        
        var surface = Drawing.gfxSurface[sheetID];
        RetroString.strCopy(surface.fileName, filePath);
        surface.width = gif.width;
        surface.height = gif.height;
        surface.dataPosition = Drawing.gfxDataPosition;
        
        Debug.printLog("loadGIFFile: width=" + surface.width + " height=" + surface.height + " dataPos=" + surface.dataPosition);
        
        Drawing.gfxDataPosition += surface.width * surface.height;
        if (Drawing.gfxDataPosition >= Drawing.GFXDATA_MAX) {
            Drawing.gfxDataPosition = 0;
            Debug.printLog("WARNING: Exceeded max gfx surface size!");
            return 0;
        }
        
        var pos = surface.dataPosition;
        for (i in 0...gif.pixels.length) {
            Drawing.graphicData[pos++] = gif.pixels[i];
        }
        
        var nonZero = 0;
        for (i in surface.dataPosition...surface.dataPosition + 100) {
            if (Drawing.graphicData[i] > 0) nonZero++;
        }
        Debug.printLog("loadGIFFile: first 100 pixels have " + nonZero + " non-zero");
        
        return 1;
    }

    public static function loadGFXFile(filePath:String, sheetID:Int):Int {
        var info = new FileInfo();
        if (Reader.loadFile(filePath, info)) {
            var surface = Drawing.gfxSurface[sheetID];
            RetroString.strCopy(surface.fileName, filePath);

            var fileBuffer = 0;
            fileBuffer = Reader.fileReadByte();
            surface.width = fileBuffer << 8;
            fileBuffer = Reader.fileReadByte();
            surface.width += fileBuffer;
            fileBuffer = Reader.fileReadByte();
            surface.height = fileBuffer << 8;
            fileBuffer = Reader.fileReadByte();
            surface.height += fileBuffer;

            for (i in 0...0xFF) {
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
            }

            surface.dataPosition = Drawing.gfxDataPosition;
            var gfxDataPos = surface.dataPosition;
            while (true) {
                var buf0 = Reader.fileReadByte();
                if (buf0 == 0xFF) {
                    var buf1 = Reader.fileReadByte();
                    if (buf1 == 0xFF) {
                        break;
                    } else {
                        var buf2 = Reader.fileReadByte();
                        for (i in 0...buf2) Drawing.graphicData[gfxDataPos++] = buf1;
                    }
                } else {
                    Drawing.graphicData[gfxDataPos++] = buf0;
                }
            }

            Drawing.gfxDataPosition += surface.height * surface.width;

            if (Drawing.gfxDataPosition >= Drawing.GFXDATA_MAX) {
                Drawing.gfxDataPosition = 0;
                Debug.printLog("WARNING: Exceeded max gfx size!");
            }

            Reader.closeFile();
            return 1;
        }
        return 0;
    }

    public static function loadRSVFile(filePath:String, sheetID:Int):Int {
        var info = new FileInfo();
        if (Reader.loadFile(filePath, info)) {
            var surface = Drawing.gfxSurface[sheetID];
            RetroString.strCopy(surface.fileName, filePath);

            Video.videoSurface = sheetID;
            Video.currentVideoFrame = 0;

            var fileBuffer = 0;

            fileBuffer = Reader.fileReadByte();
            Video.videoFrameCount = fileBuffer;
            fileBuffer = Reader.fileReadByte();
            Video.videoFrameCount += fileBuffer << 8;

            fileBuffer = Reader.fileReadByte();
            Video.videoWidth = fileBuffer;
            fileBuffer = Reader.fileReadByte();
            Video.videoWidth += fileBuffer << 8;

            fileBuffer = Reader.fileReadByte();
            Video.videoHeight = fileBuffer;
            fileBuffer = Reader.fileReadByte();
            Video.videoHeight += fileBuffer << 8;

            Video.videoFilePos = Reader.getFilePosition();
            Video.videoPlaying = true;
            surface.width = Video.videoWidth;
            surface.height = Video.videoHeight;
            surface.dataPosition = Drawing.gfxDataPosition;
            Drawing.gfxDataPosition += surface.width * surface.height;

            if (Drawing.gfxDataPosition >= Drawing.GFXDATA_MAX) {
                Drawing.gfxDataPosition = 0;
                Debug.printLog("WARNING: Exceeded max gfx size!");
            }

            return 1;
        }
        return 0;
    }

    public static function clearGraphicsData():Void {
        for (i in 0...Drawing.SURFACE_MAX) {
            RetroString.strCopy(Drawing.gfxSurface[i].fileName, "");
            Drawing.gfxSurface[i].width = 0;
            Drawing.gfxSurface[i].height = 0;
            Drawing.gfxSurface[i].dataPosition = 0;
        }
        Drawing.gfxDataPosition = 0;
    }
}
