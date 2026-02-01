package;

import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.RenderContext;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.utils.UInt8Array;
import haxe.io.Bytes;

import rsdk.core.RetroEngine;
import rsdk.core.RetroString;
import rsdk.core.Debug;
import rsdk.graphics.Drawing;
import rsdk.graphics.Palette;
import rsdk.scene.Scene;
import rsdk.input.Input;

class Main extends Application {
    var screenImage:Image;
    var initialized:Bool = false;

    public override function onWindowCreate():Void {
        RetroEngine.init();
        
        var gameTitle = RetroString.arrayToString(RetroEngine.gameWindowText);
        if (!RetroEngine.useBinFile) {
            gameTitle += " (Using Data Folder)";
        }
        window.title = gameTitle;
        
        var buffer = new ImageBuffer(new lime.utils.UInt8Array(Drawing.SCREEN_XSIZE * Drawing.SCREEN_YSIZE * 4), Drawing.SCREEN_XSIZE, Drawing.SCREEN_YSIZE);
        screenImage = new Image(buffer, 0, 0, Drawing.SCREEN_XSIZE, Drawing.SCREEN_YSIZE);
        
        Drawing.clearScreen(0);
        
        for (i in 0...16) {
            Palette.setPaletteEntry(i, i * 16, i * 16, i * 16);
        }
        Palette.setPaletteEntry(0xF0, 0, 0, 128);
        
        initialized = true;
        Debug.printLog("Window created, engine initialized");
    }

    public override function update(deltaTime:Int):Void {
        if (!initialized) return;
        if (!RetroEngine.gameRunning) return;
        
        Input.readInputDevice();
        Scene.processStage();
    }

    static var renderLogged:Bool = false;
    public override function render(context:RenderContext):Void {
        if (!initialized) { if (!renderLogged) { renderLogged = true; Debug.printLog("render: not initialized"); } return; }
        if (screenImage == null) { if (!renderLogged) { renderLogged = true; Debug.printLog("render: screenImage null"); } return; }
        if (screenImage.buffer == null) { if (!renderLogged) { renderLogged = true; Debug.printLog("render: buffer null"); } return; }
        if (screenImage.buffer.data == null) { if (!renderLogged) { renderLogged = true; Debug.printLog("render: buffer.data null"); } return; }

        var pixels = Drawing.getFrameBufferPixels();
        if (pixels == null) { if (!renderLogged) { renderLogged = true; Debug.printLog("render: pixels null"); } return; }
        
        if (!renderLogged) {
            renderLogged = true;
            Debug.printLog("render: drawing " + Drawing.SCREEN_XSIZE + "x" + Drawing.SCREEN_YSIZE + " context=" + context.type);
        }

        var imgData = screenImage.buffer.data;
        for (y in 0...Drawing.SCREEN_YSIZE) {
            for (x in 0...Drawing.SCREEN_XSIZE) {
                var srcPos = (y * Drawing.SCREEN_XSIZE + x) * 4;
                var dstPos = (y * Drawing.SCREEN_XSIZE + x) * 4;
                imgData[dstPos] = pixels.get(srcPos);
                imgData[dstPos + 1] = pixels.get(srcPos + 1);
                imgData[dstPos + 2] = pixels.get(srcPos + 2);
                imgData[dstPos + 3] = pixels.get(srcPos + 3);
            }
        }

        switch (context.type) {
            case CAIRO:
                var cairo = context.cairo;
                if (cairo != null) {
                    var imgSurface = lime.graphics.cairo.CairoImageSurface.fromImage(screenImage);
                    var pattern = lime.graphics.cairo.CairoPattern.createForSurface(imgSurface);
                    pattern.filter = NEAREST;
                    
                    var scaleX = window.width / Drawing.SCREEN_XSIZE;
                    var scaleY = window.height / Drawing.SCREEN_YSIZE;
                    var scale = Math.min(scaleX, scaleY);
                    
                    var offsetX = (window.width - Drawing.SCREEN_XSIZE * scale) / 2;
                    var offsetY = (window.height - Drawing.SCREEN_YSIZE * scale) / 2;
                    
                    cairo.save();
                    cairo.translate(offsetX, offsetY);
                    cairo.scale(scale, scale);
                    cairo.source = pattern;
                    cairo.paint();
                    cairo.restore();
                }
            default:
        }
    }

    public override function onKeyDown(keyCode:KeyCode, modifier:KeyModifier):Void {
        Input.onKeyDown(keyCode);
        switch (keyCode) {
            case ESCAPE:
                RetroEngine.gameRunning = false;
                Sys.exit(0);
            default:
	    }
    }

    public override function onKeyUp(keyCode:KeyCode, modifier:KeyModifier):Void {
        Input.onKeyUp(keyCode);
    }
}