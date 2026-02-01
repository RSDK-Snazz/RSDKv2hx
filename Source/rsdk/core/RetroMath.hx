package rsdk.core;

class RetroMath {
    public static inline final RSDK_PI:Float = 3.1415927;

    public static var sinValue512:Array<Int> = [for (i in 0...0x200) 0];
    public static var cosValue512:Array<Int> = [for (i in 0...0x200) 0];
    public static var sinValue256:Array<Int> = [for (i in 0...0x100) 0];
    public static var cosValue256:Array<Int> = [for (i in 0...0x100) 0];

    public static function calculateTrigAngles():Void {
        for (i in 0...0x200) {
            var val = Math.sin((i / 256.0) * RSDK_PI);
            sinValue512[i] = Std.int(val * 512.0);
            val = Math.cos((i / 256.0) * RSDK_PI);
            cosValue512[i] = Std.int(val * 512.0);
        }

        cosValue512[0] = 0x200;
        cosValue512[128] = 0;
        cosValue512[256] = -0x200;
        cosValue512[384] = 0;
        sinValue512[0] = 0;
        sinValue512[128] = 0x200;
        sinValue512[256] = 0;
        sinValue512[384] = -0x200;

        for (i in 0...0x100) {
            sinValue256[i] = sinValue512[i * 2] >> 1;
            cosValue256[i] = cosValue512[i * 2] >> 1;
        }
    }

    public static function sin512(angle:Int):Int {
        if (angle < 0) angle = 0x200 - angle;
        angle &= 0x1FF;
        return sinValue512[angle];
    }

    public static function cos512(angle:Int):Int {
        if (angle < 0) angle = 0x200 - angle;
        angle &= 0x1FF;
        return cosValue512[angle];
    }

    public static function sin256(angle:Int):Int {
        if (angle < 0) angle = 0x100 - angle;
        angle &= 0xFF;
        return sinValue256[angle];
    }

    public static function cos256(angle:Int):Int {
        if (angle < 0) angle = 0x100 - angle;
        angle &= 0xFF;
        return cosValue256[angle];
    }
}