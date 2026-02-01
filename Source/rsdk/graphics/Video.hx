package rsdk.graphics;

import rsdk.core.Reader;
import rsdk.graphics.Drawing;
import rsdk.graphics.Palette;
import rsdk.graphics.IndexedGif;

class Video {
    public static var currentVideoFrame:Int = 0;
    public static var videoFrameCount:Int = 0;
    public static var videoWidth:Int = 0;
    public static var videoHeight:Int = 0;
    public static var videoSurface:Int = 0;
    public static var videoFilePos:Int = 0;
    public static var videoPlaying:Bool = false;

    public static function updateVideoFrame():Void {
        if (videoPlaying) {
            if (videoFrameCount <= currentVideoFrame) {
                videoPlaying = false;
                Reader.closeFile();
            } else {
                var surface = Drawing.gfxSurface[videoSurface];
                
                var fileBuffer = Reader.fileReadByte();
                videoFilePos += fileBuffer;
                fileBuffer = Reader.fileReadByte();
                videoFilePos += fileBuffer << 8;
                fileBuffer = Reader.fileReadByte();
                videoFilePos += fileBuffer << 16;
                fileBuffer = Reader.fileReadByte();
                videoFilePos += fileBuffer << 24;

                for (i in 0...0x80) {
                    var r = Reader.fileReadByte();
                    var g = Reader.fileReadByte();
                    var b = Reader.fileReadByte();
                    Palette.setPaletteEntry(i, r, g, b);
                }
                Palette.setPaletteEntry(0, 0, 0, 0);

                fileBuffer = Reader.fileReadByte();
                while (fileBuffer != 0x2C) fileBuffer = Reader.fileReadByte();

                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                
                var paletteType = Reader.fileReadByte();
                var interlaced = ((paletteType & 0x40) >> 6) != 0;
                if ((paletteType >> 7) == 1) {
                    for (c in 0x80...0x100) {
                        Reader.fileReadByte();
                        Reader.fileReadByte();
                        Reader.fileReadByte();
                    }
                }
                
                readGifPictureData(surface.width, surface.height, interlaced, surface.dataPosition);

                Reader.setFilePosition(videoFilePos);
                currentVideoFrame++;
            }
        }
    }

    static var gifDecoder:GifDecoderState = new GifDecoderState();
    static var codeMasks:Array<Int> = [0, 1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095];

    static function readGifPictureData(width:Int, height:Int, interlaced:Bool, offset:Int):Void {
        var passStart = [0, 4, 2, 1];
        var passStep = [8, 8, 4, 2];
        initGifDecoder();
        if (interlaced) {
            for (pass in 0...4) {
                var y = passStart[pass];
                while (y < height) {
                    readGifLine(width, y * width + offset);
                    y += passStep[pass];
                }
            }
        } else {
            for (h in 0...height) readGifLine(width, h * width + offset);
        }
    }

    static function initGifDecoder():Void {
        var val = Reader.fileReadByte();
        gifDecoder.fileState = 0;
        gifDecoder.position = 0;
        gifDecoder.bufferSize = 0;
        gifDecoder.buffer[0] = 0;
        gifDecoder.depth = val;
        gifDecoder.clearCode = 1 << val;
        gifDecoder.eofCode = gifDecoder.clearCode + 1;
        gifDecoder.runningCode = gifDecoder.eofCode + 1;
        gifDecoder.runningBits = val + 1;
        gifDecoder.maxCodePlusOne = 1 << gifDecoder.runningBits;
        gifDecoder.stackPtr = 0;
        gifDecoder.prevCode = 4098;
        gifDecoder.shiftState = 0;
        gifDecoder.shiftData = 0;
        for (i in 0...4096) gifDecoder.prefix[i] = 4098;
    }

    static function readGifLine(length:Int, offset:Int):Void {
        var i = 0;
        var stackPtr = gifDecoder.stackPtr;
        var eofCode = gifDecoder.eofCode;
        var clearCode = gifDecoder.clearCode;
        var prevCode = gifDecoder.prevCode;
        
        while (stackPtr != 0 && i < length) {
            Drawing.graphicData[offset + i] = gifDecoder.stack[--stackPtr];
            i++;
        }
        
        while (i < length) {
            var gifCode = readGifCode();
            if (gifCode == eofCode) {
                if (i != length - 1 || gifDecoder.pixelCount != 0) return;
                i++;
            } else if (gifCode == clearCode) {
                for (j in 0...4096) gifDecoder.prefix[j] = 4098;
                gifDecoder.runningCode = gifDecoder.eofCode + 1;
                gifDecoder.runningBits = gifDecoder.depth + 1;
                gifDecoder.maxCodePlusOne = 1 << gifDecoder.runningBits;
                prevCode = 4098;
                gifDecoder.prevCode = 4098;
            } else {
                if (gifCode < clearCode) {
                    Drawing.graphicData[offset + i] = gifCode;
                    i++;
                } else {
                    if (gifCode < 0 || gifCode > 4095) return;
                    var code:Int;
                    if (gifDecoder.prefix[gifCode] == 4098) {
                        if (gifCode != gifDecoder.runningCode - 2) return;
                        code = prevCode;
                        var traced = traceGifPrefix(prevCode, clearCode);
                        gifDecoder.suffix[gifDecoder.runningCode - 2] = traced;
                        gifDecoder.stack[stackPtr++] = traced;
                    } else {
                        code = gifCode;
                    }
                    var c = 0;
                    while (c++ <= 4095 && code > clearCode && code <= 4095) {
                        gifDecoder.stack[stackPtr++] = gifDecoder.suffix[code];
                        code = gifDecoder.prefix[code];
                    }
                    if (c >= 4095 || code > 4095) return;
                    gifDecoder.stack[stackPtr++] = code;
                    while (stackPtr != 0 && i < length) {
                        Drawing.graphicData[offset + i] = gifDecoder.stack[--stackPtr];
                        i++;
                    }
                }
                if (prevCode != 4098) {
                    if (gifDecoder.runningCode < 2 || gifDecoder.runningCode > 4097) return;
                    gifDecoder.prefix[gifDecoder.runningCode - 2] = prevCode;
                    if (gifCode == gifDecoder.runningCode - 2) {
                        gifDecoder.suffix[gifDecoder.runningCode - 2] = traceGifPrefix(prevCode, clearCode);
                    } else {
                        gifDecoder.suffix[gifDecoder.runningCode - 2] = traceGifPrefix(gifCode, clearCode);
                    }
                }
                prevCode = gifCode;
            }
        }
        gifDecoder.prevCode = prevCode;
        gifDecoder.stackPtr = stackPtr;
    }

    static function readGifCode():Int {
        while (gifDecoder.shiftState < gifDecoder.runningBits) {
            var b = readGifByte();
            gifDecoder.shiftData |= b << gifDecoder.shiftState;
            gifDecoder.shiftState += 8;
        }
        var result = gifDecoder.shiftData & codeMasks[gifDecoder.runningBits];
        gifDecoder.shiftData >>= gifDecoder.runningBits;
        gifDecoder.shiftState -= gifDecoder.runningBits;
        gifDecoder.runningCode++;
        if (gifDecoder.runningCode > gifDecoder.maxCodePlusOne && gifDecoder.runningBits < 12) {
            gifDecoder.maxCodePlusOne <<= 1;
            gifDecoder.runningBits++;
        }
        return result;
    }

    static function readGifByte():Int {
        if (gifDecoder.fileState == 1) return 0;
        
        if (gifDecoder.position == gifDecoder.bufferSize) {
            var b = Reader.fileReadByte();
            gifDecoder.bufferSize = b;
            if (gifDecoder.bufferSize == 0) {
                gifDecoder.fileState = 1;
                return 0;
            }
            for (i in 0...gifDecoder.bufferSize) {
                gifDecoder.buffer[i] = Reader.fileReadByte();
            }
            var result = gifDecoder.buffer[0];
            gifDecoder.position = 1;
            return result;
        } else {
            return gifDecoder.buffer[gifDecoder.position++];
        }
    }

    static function traceGifPrefix(code:Int, clearCode:Int):Int {
        var i = 0;
        var c = code;
        while (c > clearCode && i++ <= 4095) c = gifDecoder.prefix[c];
        return c;
    }
}

class GifDecoderState {
    public var depth:Int = 0;
    public var clearCode:Int = 0;
    public var eofCode:Int = 0;
    public var runningCode:Int = 0;
    public var runningBits:Int = 0;
    public var prevCode:Int = 0;
    public var currentCode:Int = 0;
    public var maxCodePlusOne:Int = 0;
    public var stackPtr:Int = 0;
    public var shiftState:Int = 0;
    public var fileState:Int = 0;
    public var position:Int = 0;
    public var bufferSize:Int = 0;
    public var shiftData:Int = 0;
    public var pixelCount:Int = 0;
    public var buffer:Array<Int> = [for (i in 0...256) 0];
    public var stack:Array<Int> = [for (i in 0...4096) 0];
    public var suffix:Array<Int> = [for (i in 0...4096) 0];
    public var prefix:Array<Int> = [for (i in 0...4096) 0];

    public function new() {}
}