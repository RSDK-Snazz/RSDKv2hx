package rsdk.core;

import haxe.io.Bytes;
import sys.io.File;
import sys.FileSystem;
import rsdk.core.RetroString;
import rsdk.core.ModAPI;

class FileInfo {
    public var fileName:Array<Int> = RetroString.createArray(0x100);
    public var fileSize:Int = 0;
    public var vFileSize:Int = 0;
    public var readPos:Int = 0;
    public var bufferPosition:Int = 0;
    public var virtualFileOffset:Int = 0;
    public var encrypted:Bool = false;
    public var fileBuffer:Bytes = null;
    public var isMod:Bool = false;

    public function new() {}

    public function clear():Void {
        for (i in 0...0x100) fileName[i] = 0;
        fileSize = 0;
        vFileSize = 0;
        readPos = 0;
        bufferPosition = 0;
        virtualFileOffset = 0;
        encrypted = false;
        fileBuffer = null;
        isMod = false;
    }
}

class Reader {
    public static var binFileName:Array<Int> = RetroString.createArray(0x400);
    public static var fileName:Array<Int> = RetroString.createArray(0x100);
    public static var fileBuffer:Bytes = Bytes.alloc(0x2000);
    public static var fileSize:Int = 0;
    public static var vFileSize:Int = 0;
    public static var readPos:Int = 0;
    public static var readSize:Int = 0;
    public static var bufferPosition:Int = 0;
    public static var virtualFileOffset:Int = 0;
    public static var isModdedFile:Bool = false;

    public static var cFileHandle:Bytes = null;
    public static var cFilePos:Int = 0;

    public static function copyFilePath(dest:Array<Int>, src:String):Void {
        RetroString.strCopy(dest, src);
        var i = 0;
        while (dest[i] != 0) {
            if (dest[i] == 47) dest[i] = 92;
            i++;
        }
    }

    public static function checkBinFile(filePath:String):Bool {
        RetroEngine.useBinFile = false;
        RetroEngine.usingDataFileStore = false;

        if (FileSystem.exists(filePath)) {
            RetroEngine.useBinFile = true;
            RetroString.strCopy(binFileName, filePath);
            return true;
        }
        return false;
    }

    public static function loadFile(filePath:String, fileInfo:FileInfo):Bool {
        fileInfo.clear();

        cFileHandle = null;
        cFilePos = 0;

        var filePathBuf = filePath;
        var forceFolder = false;

        if (RetroEngine.forceFolder)
            RetroEngine.useBinFile = RetroEngine.usingDataFileStore;
        RetroEngine.forceFolder = false;
        RetroEngine.usingDataFileStore = RetroEngine.useBinFile;

        fileInfo.isMod = false;
        isModdedFile = false;

        RetroString.strCopy(fileInfo.fileName, "");
        RetroString.strCopy(fileName, "");

        var moddedPath = ModAPI.getModdedPath(filePathBuf);
        if (moddedPath != filePathBuf) {
            fileInfo.isMod = true;
            isModdedFile = true;
            forceFolder = true;
            RetroEngine.forceFolder = true;
            RetroEngine.useBinFile = false;
            filePathBuf = moddedPath;
        }

        if (RetroEngine.useBinFile && !forceFolder) {
            var binPath = RetroString.arrayToString(binFileName);
            if (!FileSystem.exists(binPath)) {
                Debug.printLog("Couldn't load file '" + filePath + "'");
                return false;
            }
            cFileHandle = File.getBytes(binPath);
            cFilePos = 0;
            fileSize = cFileHandle.length;
            bufferPosition = 0;
            readSize = 0;
            readPos = 0;

            RetroString.strCopy(fileInfo.fileName, filePath);
            RetroString.strCopy(fileName, filePath);
            if (!parseVirtualFileSystem(fileInfo)) {
                cFileHandle = null;
                Debug.printLog("Couldn't load file '" + filePath + "'");
                return false;
            }
            fileInfo.readPos = readPos;
            fileInfo.fileSize = vFileSize;
            fileInfo.virtualFileOffset = virtualFileOffset;
            fileInfo.bufferPosition = bufferPosition;
            fileInfo.encrypted = true;
        } else {
            RetroString.strCopy(fileInfo.fileName, filePathBuf);
            RetroString.strCopy(fileName, filePathBuf);
            if (!FileSystem.exists(filePathBuf)) {
                Debug.printLog("Couldn't load file '" + filePath + "' (tried: " + filePathBuf + ")");
                return false;
            }
            cFileHandle = File.getBytes(filePathBuf);
            cFilePos = 0;

            virtualFileOffset = 0;
            fileInfo.fileSize = cFileHandle.length;
            fileSize = fileInfo.fileSize;
            readPos = 0;
            fileInfo.readPos = readPos;
            fileInfo.virtualFileOffset = 0;
            fileInfo.bufferPosition = 0;
            fileInfo.encrypted = false;
        }
        bufferPosition = 0;
        readSize = 0;

        Debug.printLog("Loaded File '" + filePath + "'" + (isModdedFile ? " (modded)" : ""));
        return true;
    }

    public static function closeFile():Bool {
        cFileHandle = null;
        cFilePos = 0;
        return true;
    }

    public static function fileRead(dest:Bytes, destOffset:Int, size:Int):Void {
        if (readPos <= fileSize) {
            if (RetroEngine.useBinFile && !RetroEngine.forceFolder) {
                var i = 0;
                while (i < size) {
                    if (bufferPosition == readSize) fillFileBuffer();
                    dest.set(destOffset + i, fileBuffer.get(bufferPosition++) ^ 0xFF);
                    i++;
                }
            } else {
                var i = 0;
                while (i < size) {
                    if (bufferPosition == readSize) fillFileBuffer();
                    dest.set(destOffset + i, fileBuffer.get(bufferPosition++));
                    i++;
                }
            }
        }
    }

    public static function fileReadByte():Int {
        if (readPos <= fileSize) {
            if (bufferPosition == readSize) fillFileBuffer();
            if (RetroEngine.useBinFile && !RetroEngine.forceFolder) {
                return fileBuffer.get(bufferPosition++) ^ 0xFF;
            } else {
                return fileBuffer.get(bufferPosition++);
            }
        }
        return 0;
    }

    public static function fillFileBuffer():Int {
        if (readPos + 0x2000 <= fileSize)
            readSize = 0x2000;
        else
            readSize = fileSize - readPos;

        for (i in 0...readSize) {
            fileBuffer.set(i, cFileHandle.get(cFilePos + i));
        }
        cFilePos += readSize;
        readPos += readSize;
        bufferPosition = 0;
        return readSize;
    }

    public static function parseVirtualFileSystem(fileInfo:FileInfo):Bool {
        var filename = RetroString.createArray(0x50);
        var fullFilename = RetroString.createArray(0x50);
        var stringBuffer = RetroString.createArray(0x50);
        var dirCount:Int = 0;
        var fileOffset:Int = 0;
        var fNamePos:Int = 0;
        var headerSize:Int = 0;
        var fBuffer:Int = 0;

        var j:Int = 0;
        virtualFileOffset = 0;

        var i = 0;
        while (fileInfo.fileName[i] != 0) {
            if (fileInfo.fileName[i] == 47) {
                fNamePos = i;
                j = 0;
            } else {
                j++;
            }
            fullFilename[i] = fileInfo.fileName[i];
            i++;
        }
        fNamePos++;
        for (k in 0...j) {
            filename[k] = fileInfo.fileName[k + fNamePos];
        }
        filename[j] = 0;
        fullFilename[fNamePos] = 0;

        cFilePos = 0;
        RetroEngine.useBinFile = false;
        bufferPosition = 0;
        readSize = 0;
        readPos = 0;

        fBuffer = fileReadByte();
        headerSize = fBuffer;
        fBuffer = fileReadByte();
        headerSize += fBuffer << 8;
        fBuffer = fileReadByte();
        headerSize += fBuffer << 16;
        fBuffer = fileReadByte();
        headerSize += fBuffer << 24;

        fBuffer = fileReadByte();
        dirCount = fBuffer;

        i = 0;
        fileOffset = 0;
        var nextFileOffset:Int = 0;
        while (i < dirCount) {
            fBuffer = fileReadByte();
            for (k in 0...fBuffer) {
                stringBuffer[k] = fileReadByte();
            }
            stringBuffer[fBuffer] = 0;

            if (RetroString.strComp(fullFilename, stringBuffer)) {
                fBuffer = fileReadByte();
                fileOffset = fBuffer;
                fBuffer = fileReadByte();
                fileOffset += fBuffer << 8;
                fBuffer = fileReadByte();
                fileOffset += fBuffer << 16;
                fBuffer = fileReadByte();
                fileOffset += fBuffer << 24;

                if (i == dirCount - 1) {
                    nextFileOffset = fileSize - headerSize;
                } else {
                    fBuffer = fileReadByte();
                    for (k in 0...fBuffer) {
                        var b = fileReadByte();
                        stringBuffer[k] = b ^ (-1 - fBuffer);
                    }
                    stringBuffer[fBuffer] = 0;

                    fBuffer = fileReadByte();
                    nextFileOffset = fBuffer;
                    fBuffer = fileReadByte();
                    nextFileOffset += fBuffer << 8;
                    fBuffer = fileReadByte();
                    nextFileOffset += fBuffer << 16;
                    fBuffer = fileReadByte();
                    nextFileOffset += fBuffer << 24;
                }
                i = dirCount;
            } else {
                fileOffset = -1;
                fileReadByte();
                fileReadByte();
                fileReadByte();
                fileReadByte();
                i++;
            }
        }

        if (fileOffset == -1) {
            RetroEngine.useBinFile = true;
            return false;
        }

        cFilePos = fileOffset + headerSize;
        bufferPosition = 0;
        readSize = 0;
        readPos = cFilePos;
        virtualFileOffset = fileOffset + headerSize;

        i = 0;
        while (i < 1) {
            fBuffer = fileReadByte();
            virtualFileOffset++;
            j = 0;
            while (j < fBuffer) {
                stringBuffer[j] = fileReadByte();
                j++;
                virtualFileOffset++;
            }
            stringBuffer[j] = 0;

            if (RetroString.strComp(filename, stringBuffer)) {
                i = 1;
                fBuffer = fileReadByte();
                j = fBuffer;
                fBuffer = fileReadByte();
                j += fBuffer << 8;
                fBuffer = fileReadByte();
                j += fBuffer << 16;
                fBuffer = fileReadByte();
                j += fBuffer << 24;
                virtualFileOffset += 4;
                vFileSize = j;
            } else {
                fBuffer = fileReadByte();
                j = fBuffer;
                fBuffer = fileReadByte();
                j += fBuffer << 8;
                fBuffer = fileReadByte();
                j += fBuffer << 16;
                fBuffer = fileReadByte();
                j += fBuffer << 24;
                virtualFileOffset += 4;
                virtualFileOffset += j;
            }

            if (virtualFileOffset >= nextFileOffset + headerSize) {
                RetroEngine.useBinFile = true;
                return false;
            }
            cFilePos = virtualFileOffset;
            bufferPosition = 0;
            readSize = 0;
            readPos = virtualFileOffset;
        }
        RetroEngine.useBinFile = true;
        return true;
    }

    public static function getFileInfo(fileInfo:FileInfo):Void {
        RetroString.strCopyArr(fileInfo.fileName, fileName);
        fileInfo.bufferPosition = bufferPosition;
        fileInfo.readPos = readPos - readSize;
        fileInfo.fileSize = fileSize;
        fileInfo.vFileSize = vFileSize;
        fileInfo.virtualFileOffset = virtualFileOffset;
        fileInfo.isMod = isModdedFile;
    }

    public static function setFileInfo(fileInfo:FileInfo):Void {
        RetroEngine.forceFolder = false;
        if (!fileInfo.isMod) {
            RetroEngine.useBinFile = RetroEngine.usingDataFileStore;
        } else {
            RetroEngine.forceFolder = true;
            RetroEngine.useBinFile = false;
        }

        isModdedFile = fileInfo.isMod;
        if (RetroEngine.useBinFile && !RetroEngine.forceFolder) {
            var binPath = RetroString.arrayToString(binFileName);
            cFileHandle = File.getBytes(binPath);
            cFilePos = 0;
            virtualFileOffset = fileInfo.virtualFileOffset;
            vFileSize = fileInfo.fileSize;
            fileSize = cFileHandle.length;
            readPos = fileInfo.readPos;
            cFilePos = readPos;
            fillFileBuffer();
            bufferPosition = fileInfo.bufferPosition;
        } else {
            RetroString.strCopyArr(fileName, fileInfo.fileName);
            var path = RetroString.arrayToString(fileInfo.fileName);
            cFileHandle = File.getBytes(path);
            cFilePos = 0;
            virtualFileOffset = 0;
            fileSize = fileInfo.fileSize;
            readPos = fileInfo.readPos;
            cFilePos = readPos;
            fillFileBuffer();
            bufferPosition = fileInfo.bufferPosition;
        }
    }

    public static function getFilePosition():Int {
        if (RetroEngine.useBinFile)
            return bufferPosition + readPos - readSize - virtualFileOffset;
        else
            return bufferPosition + readPos - readSize;
    }

    public static function setFilePosition(newPos:Int):Void {
        if (RetroEngine.useBinFile) {
            readPos = virtualFileOffset + newPos;
        } else {
            readPos = newPos;
        }
        cFilePos = readPos;
        fillFileBuffer();
    }

    public static function reachedEndOfFile():Bool {
        if (RetroEngine.useBinFile)
            return bufferPosition + readPos - readSize - virtualFileOffset >= vFileSize;
        else
            return bufferPosition + readPos - readSize >= fileSize;
    }

    public static function loadFileAsBytes(filePath:String):Bytes {
        var info = new FileInfo();
        if (!loadFile(filePath, info)) {
            return null;
        }
        
        var totalSize = info.fileSize;
        var result = Bytes.alloc(totalSize);
        
        for (i in 0...totalSize) {
            result.set(i, fileReadByte());
        }
        
        closeFile();
        return result;
    }

    public static function loadFileAsBytesRaw(filePath:String):Bytes {
        var info = new FileInfo();
        if (!loadFile(filePath, info)) {
            return null;
        }
        
        var totalSize = info.fileSize;
        var result = Bytes.alloc(totalSize);
        
        for (i in 0...totalSize) {
            result.set(i, fileReadByteRaw());
        }
        
        closeFile();
        return result;
    }

    public static function fileReadByteRaw():Int {
        if (readPos <= fileSize) {
            if (bufferPosition == readSize) fillFileBuffer();
            return fileBuffer.get(bufferPosition++);
        }
        return 0;
    }
}