package rsdk.core;

class RetroString {
    public static function strCopy(dest:Array<Int>, src:String):Void {
        for (i in 0...src.length) {
            dest[i] = src.charCodeAt(i);
        }
        dest[src.length] = 0;
    }

    public static function strCopyArr(dest:Array<Int>, src:Array<Int>):Void {
        var i = 0;
        while (src[i] != 0) {
            dest[i] = src[i];
            i++;
        }
        dest[i] = 0;
    }

    public static function strAdd(dest:Array<Int>, src:String):Void {
        var destStrPos = 0;
        var srcStrPos = 0;
        while (dest[destStrPos] != 0) destStrPos++;
        while (srcStrPos < src.length) {
            dest[destStrPos++] = src.charCodeAt(srcStrPos++);
        }
        dest[destStrPos] = 0;
    }

    public static function strAddArr(dest:Array<Int>, src:Array<Int>):Void {
        var destStrPos = 0;
        var srcStrPos = 0;
        while (dest[destStrPos] != 0) destStrPos++;
        while (src[srcStrPos] != 0) {
            dest[destStrPos++] = src[srcStrPos++];
        }
        dest[destStrPos] = 0;
    }

    public static function strComp(stringA:Array<Int>, stringB:Array<Int>):Bool {
        var i = 0;
        while (true) {
            var a = stringA[i];
            var b = stringB[i];
            if (a == b || a == b + 32 || a == b - 32) {
                if (a == 0) return true;
                i++;
            } else {
                return false;
            }
        }
        return true;
    }

    public static function strCompStr(stringA:Array<Int>, stringB:String):Bool {
        var i = 0;
        while (i < stringB.length) {
            var a = stringA[i];
            var b = stringB.charCodeAt(i);
            if (a == b || a == b + 32 || a == b - 32) {
                i++;
            } else {
                return false;
            }
        }
        return stringA[i] == 0;
    }

    public static function strLength(string:Array<Int>):Int {
        var len = 0;
        while (string[len] != 0) len++;
        return len;
    }

    public static function findStringToken(string:Array<Int>, token:String, stopID:Int):Int {
        var tokenCharID = 0;
        var tokenMatch = true;
        var stringCharID = 0;
        var foundTokenID = 0;

        while (string[stringCharID] != 0) {
            tokenCharID = 0;
            tokenMatch = true;
            while (tokenCharID < token.length) {
                if (string[tokenCharID + stringCharID] == 0)
                    return -1;
                if (string[tokenCharID + stringCharID] != token.charCodeAt(tokenCharID))
                    tokenMatch = false;
                tokenCharID++;
            }
            if (tokenMatch) {
                foundTokenID++;
                if (foundTokenID == stopID)
                    return stringCharID;
            }
            stringCharID++;
        }
        return -1;
    }

    public static function arrayToString(arr:Array<Int>):String {
        var result = "";
        var i = 0;
        while (arr[i] != 0) {
            result += String.fromCharCode(arr[i]);
            i++;
        }
        return result;
    }

    public static function stringToArray(str:String, ?size:Int):Array<Int> {
        var actualSize = size != null ? size : str.length + 1;
        var arr = [for (i in 0...actualSize) 0];
        for (i in 0...str.length) {
            arr[i] = str.charCodeAt(i);
        }
        arr[str.length] = 0;
        return arr;
    }

    public static function strCopyArray(dest:Array<Int>, src:Array<Int>):Void {
        var i = 0;
        while (src[i] != 0) {
            dest[i] = src[i];
            i++;
        }
        dest[i] = 0;
    }

    public static function createArray(size:Int):Array<Int> {
        return [for (i in 0...size) 0];
    }
}