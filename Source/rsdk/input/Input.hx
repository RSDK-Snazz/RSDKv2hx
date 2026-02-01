package rsdk.input;

import lime.ui.KeyCode;

enum abstract InputButtons(Int) to Int {
    var INPUT_UP = 0;
    var INPUT_DOWN = 1;
    var INPUT_LEFT = 2;
    var INPUT_RIGHT = 3;
    var INPUT_BUTTONA = 4;
    var INPUT_BUTTONB = 5;
    var INPUT_BUTTONC = 6;
    var INPUT_START = 7;
    var INPUT_ANY = 8;
    var INPUT_MAX = 9;
}

class InputData {
    public var up:Int = 0;
    public var down:Int = 0;
    public var left:Int = 0;
    public var right:Int = 0;
    public var A:Int = 0;
    public var B:Int = 0;
    public var C:Int = 0;
    public var start:Int = 0;

    public function new() {}
}

class InputButton {
    public var press:Bool = false;
    public var hold:Bool = false;
    public var keyMappings:KeyCode = UNKNOWN;
    public var contMappings:Int = 0;

    public function new() {}

    public function setHeld():Void {
        press = !hold;
        hold = true;
    }

    public function setReleased():Void {
        press = false;
        hold = false;
    }

    public function down():Bool {
        return press || hold;
    }
}

class Input {
    public static inline var INPUT_UP:Int = 0;
    public static inline var INPUT_DOWN:Int = 1;
    public static inline var INPUT_LEFT:Int = 2;
    public static inline var INPUT_RIGHT:Int = 3;
    public static inline var INPUT_BUTTONA:Int = 4;
    public static inline var INPUT_BUTTONB:Int = 5;
    public static inline var INPUT_BUTTONC:Int = 6;
    public static inline var INPUT_START:Int = 7;
    public static inline var INPUT_ANY:Int = 8;
    public static inline var INPUT_MAX:Int = 9;

    public static var gKeyPress:InputData = new InputData();
    public static var gKeyDown:InputData = new InputData();
    public static var anyPress:Bool = false;
    public static var inputDevice:Array<InputButton> = [for (i in 0...9) new InputButton()];
    public static var inputType:Int = 0;

    static var keyStates:Map<KeyCode, Bool> = new Map();
    static var initialized:Bool = false;

    public static function init():Void {
        if (initialized) return;
        initialized = true;

        inputDevice[INPUT_UP].keyMappings = UP;
        inputDevice[INPUT_DOWN].keyMappings = DOWN;
        inputDevice[INPUT_LEFT].keyMappings = LEFT;
        inputDevice[INPUT_RIGHT].keyMappings = RIGHT;
        inputDevice[INPUT_BUTTONA].keyMappings = Z;
        inputDevice[INPUT_BUTTONB].keyMappings = X;
        inputDevice[INPUT_BUTTONC].keyMappings = C;
        inputDevice[INPUT_START].keyMappings = RETURN;
        
        inputDevice[INPUT_UP].contMappings = 11;
        inputDevice[INPUT_DOWN].contMappings = 12;
        inputDevice[INPUT_LEFT].contMappings = 13;
        inputDevice[INPUT_RIGHT].contMappings = 14;
        inputDevice[INPUT_BUTTONA].contMappings = 0;
        inputDevice[INPUT_BUTTONB].contMappings = 1;
        inputDevice[INPUT_BUTTONC].contMappings = 2;
        inputDevice[INPUT_START].contMappings = 6;
    }

    public static function onKeyDown(keyCode:KeyCode):Void {
        keyStates.set(keyCode, true);
    }

    public static function onKeyUp(keyCode:KeyCode):Void {
        keyStates.set(keyCode, false);
    }

    public static function isKeyDown(keyCode:KeyCode):Bool {
        return keyStates.exists(keyCode) && keyStates.get(keyCode);
    }

    public static function readInputDevice():Void {
        init();

        var anyHeld = false;
        for (i in 0...INPUT_ANY) {
            if (isKeyDown(inputDevice[i].keyMappings)) {
                inputDevice[i].setHeld();
                anyHeld = true;
            } else if (inputDevice[i].hold) {
                inputDevice[i].setReleased();
            }
        }

        if (anyHeld) {
            if (!inputDevice[INPUT_ANY].hold)
                inputDevice[INPUT_ANY].setHeld();
        } else {
            if (inputDevice[INPUT_ANY].hold)
                inputDevice[INPUT_ANY].setReleased();
        }
    }

    public static function checkKeyPress(input:InputData, flags:Int):Void {
        if ((flags & 0x1) != 0)
            input.up = inputDevice[INPUT_UP].press ? 1 : 0;
        if ((flags & 0x2) != 0)
            input.down = inputDevice[INPUT_DOWN].press ? 1 : 0;
        if ((flags & 0x4) != 0)
            input.left = inputDevice[INPUT_LEFT].press ? 1 : 0;
        if ((flags & 0x8) != 0)
            input.right = inputDevice[INPUT_RIGHT].press ? 1 : 0;
        if ((flags & 0x10) != 0)
            input.A = inputDevice[INPUT_BUTTONA].press ? 1 : 0;
        if ((flags & 0x20) != 0)
            input.B = inputDevice[INPUT_BUTTONB].press ? 1 : 0;
        if ((flags & 0x40) != 0)
            input.C = inputDevice[INPUT_BUTTONC].press ? 1 : 0;
        if ((flags & 0x80) != 0) {
            input.start = inputDevice[INPUT_START].press ? 1 : 0;
            anyPress = inputDevice[INPUT_ANY].press;
        }
    }

    public static function checkKeyDown(input:InputData, flags:Int):Void {
        if ((flags & 0x1) != 0)
            input.up = inputDevice[INPUT_UP].hold ? 1 : 0;
        if ((flags & 0x2) != 0)
            input.down = inputDevice[INPUT_DOWN].hold ? 1 : 0;
        if ((flags & 0x4) != 0)
            input.left = inputDevice[INPUT_LEFT].hold ? 1 : 0;
        if ((flags & 0x8) != 0)
            input.right = inputDevice[INPUT_RIGHT].hold ? 1 : 0;
        if ((flags & 0x10) != 0)
            input.A = inputDevice[INPUT_BUTTONA].hold ? 1 : 0;
        if ((flags & 0x20) != 0)
            input.B = inputDevice[INPUT_BUTTONB].hold ? 1 : 0;
        if ((flags & 0x40) != 0)
            input.C = inputDevice[INPUT_BUTTONC].hold ? 1 : 0;
        if ((flags & 0x80) != 0)
            input.start = inputDevice[INPUT_START].hold ? 1 : 0;
    }

    public static function clearInput():Void {
        for (i in 0...INPUT_MAX) {
            inputDevice[i].press = false;
            inputDevice[i].hold = false;
        }
        gKeyPress = new InputData();
        gKeyDown = new InputData();
        anyPress = false;
    }
}