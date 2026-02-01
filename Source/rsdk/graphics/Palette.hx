package rsdk.graphics;

import haxe.io.Bytes;
import rsdk.core.Reader;
import rsdk.core.Debug;

class Colour {
    public var r:Int = 0;
    public var g:Int = 0;
    public var b:Int = 0;
    public var a:Int = 0;

    public function new(r:Int = 0, g:Int = 0, b:Int = 0, a:Int = 255) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }
}

class Palette {
    public static inline final PALETTE_SIZE:Int = 0x100;

    public static var tilePalette32:Array<Int> = [for (i in 0...PALETTE_SIZE) 0];
    public static var tilePaletteW32:Array<Int> = [for (i in 0...PALETTE_SIZE) 0];
    public static var tilePalette32F:Array<Int> = [for (i in 0...PALETTE_SIZE) 0];
    public static var tilePaletteW32F:Array<Int> = [for (i in 0...PALETTE_SIZE) 0];

    public static var tilePalette16:Array<Int> = [for (i in 0...PALETTE_SIZE) 0];
    public static var tilePaletteW16:Array<Int> = [for (i in 0...PALETTE_SIZE) 0];
    public static var tilePalette16F:Array<Int> = [for (i in 0...PALETTE_SIZE) 0];
    public static var tilePaletteW16F:Array<Int> = [for (i in 0...PALETTE_SIZE) 0];

    public static var tilePalette:Array<Colour> = [for (i in 0...PALETTE_SIZE) new Colour()];
    public static var tilePaletteW:Array<Colour> = [for (i in 0...PALETTE_SIZE) new Colour()];
    public static var tilePaletteF:Array<Colour> = [for (i in 0...PALETTE_SIZE) new Colour()];
    public static var tilePaletteWF:Array<Colour> = [for (i in 0...PALETTE_SIZE) new Colour()];

    public static var paletteMode:Int = 0;

    public static inline function rgb888ToRgb565(r:Int, g:Int, b:Int):Int {
        return (b >> 3) | ((g >> 2) << 5) | ((r >> 3) << 11);
    }

    public static inline function packRgb888(r:Int, g:Int, b:Int):Int {
        return (0xFF << 24) | (r << 16) | (g << 8) | b;
    }

    public static function loadPalette(filePath:String, startIndex:Int, endIndex:Int):Void {
        var info = new rsdk.core.Reader.FileInfo();

        if (Reader.loadFile(filePath, info)) {
            Reader.setFilePosition(3 * startIndex);

            var colour = Bytes.alloc(3);
            for (i in startIndex...endIndex) {
                Reader.fileRead(colour, 0, 3);
                setPaletteEntry(i, colour.get(0), colour.get(1), colour.get(2));
            }
            Reader.closeFile();
            Debug.printLog("Loaded palette " + filePath + ", sample color[1]: r=" + tilePalette[1].r + " g=" + tilePalette[1].g + " b=" + tilePalette[1].b);
        }
    }

    public static function setPaletteEntry(index:Int, r:Int, g:Int, b:Int):Void {
        tilePalette32[index] = packRgb888(r, g, b);
        tilePalette16[index] = rgb888ToRgb565(r, g, b);
        tilePalette[index].r = r;
        tilePalette[index].g = g;
        tilePalette[index].b = b;
    }

    public static function rotatePalette(startIndex:Int, endIndex:Int, right:Bool):Void {
        if (right) {
            var startClr8 = tilePalette[endIndex];
            var startClr16 = tilePalette16[endIndex];
            var startClr32 = tilePalette32[endIndex];
            var i = endIndex;
            while (i > startIndex) {
                tilePalette[i] = tilePalette[i - 1];
                tilePalette16[i] = tilePalette16[i - 1];
                tilePalette32[i] = tilePalette32[i - 1];
                i--;
            }
            tilePalette[startIndex] = startClr8;
            tilePalette16[startIndex] = startClr16;
            tilePalette32[startIndex] = startClr32;
        } else {
            var startClr8 = tilePalette[startIndex];
            var startClr16 = tilePalette16[startIndex];
            var startClr32 = tilePalette32[startIndex];
            for (i in startIndex...endIndex) {
                tilePalette[i] = tilePalette[i + 1];
                tilePalette16[i] = tilePalette16[i + 1];
                tilePalette32[i] = tilePalette32[i + 1];
            }
            tilePalette[endIndex] = startClr8;
            tilePalette16[endIndex] = startClr16;
            tilePalette32[endIndex] = startClr32;
        }
    }

    public static function setFade(r:Int, g:Int, b:Int, a:Int, start:Int, end:Int):Void {
        paletteMode = 1;
        if (a > 0xFF) a = 0xFF;
        if (end <= 0xFF) end++;
        for (i in start...end) {
            var red = ((r * a + (0xFF - a) * tilePalette[i].r) >> 8) & 0xFF;
            var green = ((g * a + (0xFF - a) * tilePalette[i].g) >> 8) & 0xFF;
            var blue = ((b * a + (0xFF - a) * tilePalette[i].b) >> 8) & 0xFF;
            tilePalette16F[i] = rgb888ToRgb565(red, green, blue);
            tilePalette32F[i] = packRgb888(red, green, blue);
            tilePaletteF[i].r = red;
            tilePaletteF[i].g = green;
            tilePaletteF[i].b = blue;

            red = ((r * a + (0xFF - a) * tilePaletteW[i].r) >> 8) & 0xFF;
            green = ((g * a + (0xFF - a) * tilePaletteW[i].g) >> 8) & 0xFF;
            blue = ((b * a + (0xFF - a) * tilePaletteW[i].b) >> 8) & 0xFF;
            tilePaletteW16F[i] = rgb888ToRgb565(red, green, blue);
            tilePaletteW32F[i] = packRgb888(red, green, blue);
            tilePaletteWF[i].r = red;
            tilePaletteWF[i].g = green;
            tilePaletteWF[i].b = blue;
        }
    }

    public static function setWaterColour(r:Int, g:Int, b:Int, a:Int):Void {
        paletteMode = 1;
        if (a > 0xFF) a = 0xFF;
        for (i in 0...PALETTE_SIZE) {
            var red = ((r * a + (0xFF - a) * tilePalette[i].r) >> 8) & 0xFF;
            var green = ((g * a + (0xFF - a) * tilePalette[i].g) >> 8) & 0xFF;
            var blue = ((b * a + (0xFF - a) * tilePalette[i].b) >> 8) & 0xFF;
            tilePaletteW16[i] = rgb888ToRgb565(red, green, blue);
            tilePaletteW32[i] = packRgb888(red, green, blue);
            tilePaletteW[i].r = red;
            tilePaletteW[i].g = green;
            tilePaletteW[i].b = blue;
        }
    }

    public static function waterFlash():Void {
        paletteMode = 5;
        for (i in 0...PALETTE_SIZE) {
            tilePaletteW16F[i] = rgb888ToRgb565(0xFF, 0xFF, 0xFF);
            tilePaletteW32F[i] = packRgb888(0xFF, 0xFF, 0xFF);
            tilePaletteWF[i].r = 0xFF;
            tilePaletteWF[i].g = 0xFF;
            tilePaletteWF[i].b = 0xFF;
        }
    }
}