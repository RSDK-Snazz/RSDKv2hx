package rsdk.graphics;

import haxe.io.Bytes;

class IndexedGif {
    public var width:Int;
    public var height:Int;
    public var pixels:Array<Int>;
    public var palette:Array<Int>;

    public function new() {
        pixels = [];
        palette = [];
    }

    public static function parse(bytes:Bytes):IndexedGif {
        if (bytes == null || bytes.length < 13) return null;
        
        if (bytes.get(0) != 0x47 || bytes.get(1) != 0x49 || bytes.get(2) != 0x46) return null;
        
        var gif = new IndexedGif();
        var pos = 6;
        
        gif.width = bytes.get(pos) | (bytes.get(pos + 1) << 8);
        pos += 2;
        gif.height = bytes.get(pos) | (bytes.get(pos + 1) << 8);
        pos += 2;
        
        var packed = bytes.get(pos);
        pos++;
        var bgIndex = bytes.get(pos);
        pos++;
        var aspect = bytes.get(pos);
        pos++;
        
        var hasGlobalTable = (packed & 0x80) != 0;
        var globalTableSize = 1 << ((packed & 0x07) + 1);
        
        var globalPalette:Array<Int> = [];
        if (hasGlobalTable) {
            for (i in 0...globalTableSize) {
                var r = bytes.get(pos++);
                var g = bytes.get(pos++);
                var b = bytes.get(pos++);
                globalPalette.push((r << 16) | (g << 8) | b);
            }
        }
        gif.palette = globalPalette;
        
        while (pos < bytes.length) {
            var blockType = bytes.get(pos++);
            
            if (blockType == 0x2C) {
                var imgX = bytes.get(pos) | (bytes.get(pos + 1) << 8);
                pos += 2;
                var imgY = bytes.get(pos) | (bytes.get(pos + 1) << 8);
                pos += 2;
                var imgW = bytes.get(pos) | (bytes.get(pos + 1) << 8);
                pos += 2;
                var imgH = bytes.get(pos) | (bytes.get(pos + 1) << 8);
                pos += 2;
                
                var imgPacked = bytes.get(pos++);
                var hasLocalTable = (imgPacked & 0x80) != 0;
                var interlaced = (imgPacked & 0x40) != 0;
                var localTableSize = 1 << ((imgPacked & 0x07) + 1);
                
                if (hasLocalTable) {
                    gif.palette = [];
                    for (i in 0...localTableSize) {
                        var r = bytes.get(pos++);
                        var g = bytes.get(pos++);
                        var b = bytes.get(pos++);
                        gif.palette.push((r << 16) | (g << 8) | b);
                    }
                }
                
                gif.width = imgW;
                gif.height = imgH;
                
                var minCodeSize = bytes.get(pos++);
                var pixels = decodeLzw(bytes, pos, imgW * imgH, minCodeSize);
                pos = pixels.endPos;
                
                if (interlaced) {
                    var deinterlaced:Array<Int> = [for (i in 0...imgW * imgH) 0];
                    var srcIdx = 0;
                    var passes = [[0, 8], [4, 8], [2, 4], [1, 2]];
                    for (pass in passes) {
                        var startY = pass[0];
                        var stepY = pass[1];
                        var y = startY;
                        while (y < imgH) {
                            for (x in 0...imgW) {
                                if (srcIdx < pixels.data.length)
                                    deinterlaced[y * imgW + x] = pixels.data[srcIdx++];
                            }
                            y += stepY;
                        }
                    }
                    gif.pixels = deinterlaced;
                } else {
                    gif.pixels = pixels.data;
                }
                
                return gif;
            } else if (blockType == 0x21) {
                var extType = bytes.get(pos++);
                while (true) {
                    var blockSize = bytes.get(pos++);
                    if (blockSize == 0) break;
                    pos += blockSize;
                }
            } else if (blockType == 0x3B) {
                break;
            } else {
                break;
            }
        }
        
        return gif;
    }

    static function decodeLzw(bytes:Bytes, startPos:Int, pixelCount:Int, minCodeSize:Int):{data:Array<Int>, endPos:Int} {
        var result:Array<Int> = [];
        var pos = startPos;
        
        var clearCode = 1 << minCodeSize;
        var eoiCode = clearCode + 1;
        
        var codeSize = minCodeSize + 1;
        var codeMask = (1 << codeSize) - 1;
        
        var dict:Array<Array<Int>> = [];
        for (i in 0...clearCode) dict.push([i]);
        dict.push([]);
        dict.push([]);
        
        var bitBuffer = 0;
        var bitsInBuffer = 0;
        var blockSize = 0;
        var blockPos = 0;
        var blockData:Array<Int> = [];
        
        function readCode():Int {
            while (bitsInBuffer < codeSize) {
                if (blockPos >= blockSize) {
                    blockSize = bytes.get(pos++);
                    if (blockSize == 0) return eoiCode;
                    blockData = [];
                    for (i in 0...blockSize) blockData.push(bytes.get(pos++));
                    blockPos = 0;
                }
                bitBuffer |= blockData[blockPos++] << bitsInBuffer;
                bitsInBuffer += 8;
            }
            var code = bitBuffer & codeMask;
            bitBuffer >>= codeSize;
            bitsInBuffer -= codeSize;
            return code;
        }
        
        var prevCode = -1;
        while (result.length < pixelCount) {
            var code = readCode();
            
            if (code == clearCode) {
                dict = [];
                for (i in 0...clearCode) dict.push([i]);
                dict.push([]);
                dict.push([]);
                codeSize = minCodeSize + 1;
                codeMask = (1 << codeSize) - 1;
                prevCode = -1;
                continue;
            }
            
            if (code == eoiCode) break;
            
            var entry:Array<Int>;
            if (code < dict.length) {
                entry = dict[code];
                if (prevCode >= 0 && prevCode < dict.length) {
                    var newEntry = dict[prevCode].copy();
                    newEntry.push(entry[0]);
                    dict.push(newEntry);
                }
            } else if (code == dict.length && prevCode >= 0) {
                var newEntry = dict[prevCode].copy();
                newEntry.push(dict[prevCode][0]);
                dict.push(newEntry);
                entry = newEntry;
            } else {
                break;
            }
            
            for (val in entry) {
                if (result.length < pixelCount) result.push(val);
            }
            
            if (dict.length == (1 << codeSize) && codeSize < 12) {
                codeSize++;
                codeMask = (1 << codeSize) - 1;
            }
            
            prevCode = code;
        }
        
        while (blockSize > 0) {
            pos += blockSize - blockPos;
            blockSize = bytes.get(pos++);
            blockPos = 0;
        }
        
        return {data: result, endPos: pos};
    }
}