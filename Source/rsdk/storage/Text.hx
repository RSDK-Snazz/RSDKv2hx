package rsdk.storage;

import rsdk.graphics.Drawing;

enum abstract TextInfoTypes(Int) to Int {
    var TEXTINFO_TEXTDATA = 0;
    var TEXTINFO_TEXTSIZE = 1;
    var TEXTINFO_ROWCOUNT = 2;
}

enum abstract TextMenuAlignments(Int) to Int {
    var MENU_ALIGN_LEFT = 0;
    var MENU_ALIGN_RIGHT = 1;
    var MENU_ALIGN_CENTER = 2;
}

class TextMenu {
    public static inline var TEXTDATA_COUNT:Int = 0x1000;
    public static inline var TEXTENTRY_COUNT:Int = 0x80;

    public var textData:Array<Int> = [for (i in 0...TEXTDATA_COUNT) 0];
    public var entryStart:Array<Int> = [for (i in 0...TEXTENTRY_COUNT) 0];
    public var entrySize:Array<Int> = [for (i in 0...TEXTENTRY_COUNT) 0];
    public var entryHighlight:Array<Int> = [for (i in 0...TEXTENTRY_COUNT) 0];
    public var textDataPos:Int = 0;
    public var rowCount:Int = 0;
    public var alignment:Int = 0;
    public var selectionCount:Int = 0;
    public var selection1:Int = 0;
    public var selection2:Int = 0;

    public function new() {}
}

class Text {
    public static inline var TEXTMENU_COUNT:Int = 2;
    public static inline var FONTCHAR_COUNT:Int = 0x400;
    public static inline var MENU_ALIGN_LEFT:Int = 0;
    public static inline var MENU_ALIGN_RIGHT:Int = 1;
    public static inline var MENU_ALIGN_CENTER:Int = 2;

    public static var gameMenu:Array<TextMenu> = [for (i in 0...TEXTMENU_COUNT) new TextMenu()];
    public static var textMenuSurfaceNo:Int = 0;

    public static function loadConfigListText(menu:TextMenu, listNo:Int):Void {}

    public static function setupTextMenu(menu:TextMenu, rowCount:Int):Void {
        menu.textDataPos = 0;
        menu.rowCount = rowCount;
    }

    public static function addTextMenuEntry(menu:TextMenu, text:String):Void {
        menu.entryStart[menu.rowCount] = menu.textDataPos;
        menu.entrySize[menu.rowCount] = 0;
        for (i in 0...text.length) {
            var c = text.charCodeAt(i);
            if (c == " ".code) c = 0;
            if (c > "/".code && c < ":".code) c -= 21;
            if (c > "9".code && c < "f".code) c -= "@".code;
            menu.textData[menu.textDataPos] = c;
            ++menu.textDataPos;
            ++menu.entrySize[menu.rowCount];
        }
        menu.rowCount++;
    }

    public static function editTextMenuEntry(menu:TextMenu, text:String, rowID:Int):Void {
        var pos = menu.entryStart[rowID];
        menu.entrySize[rowID] = 0;
        for (i in 0...text.length) {
            var c = text.charCodeAt(i);
            if (c == " ".code) c = 0;
            if (c > "/".code && c < ":".code) c -= 21;
            if (c > "9".code && c < "f".code) c -= "@".code;
            menu.textData[pos] = c;
            ++menu.entrySize[rowID];
            pos++;
        }
    }

    public static function drawTextMenuEntry(menu:TextMenu, rowID:Int, xPos:Int, yPos:Int, textHighlight:Int):Void {
        var id = menu.entryStart[rowID];
        for (i in 0...menu.entrySize[rowID]) {
            if (menu.textData[id] > 0)
                Drawing.drawSprite(xPos + 8 * i, yPos, 8, 8, textHighlight, 8 * menu.textData[id] - 8, textMenuSurfaceNo);
            ++id;
        }
    }

    public static function drawBlendedTextMenuEntry(menu:TextMenu, rowID:Int, xPos:Int, yPos:Int, textHighlight:Int):Void {
        var id = menu.entryStart[rowID];
        for (i in 0...menu.entrySize[rowID]) {
            if (menu.textData[id] > 0)
                Drawing.drawBlendedSprite(xPos + 8 * i, yPos, 8, 8, textHighlight, 8 * menu.textData[id] - 8, textMenuSurfaceNo);
            ++id;
        }
    }

    public static function drawStageTextEntry(menu:TextMenu, rowID:Int, xPos:Int, yPos:Int, textHighlight:Int):Void {
        var id = menu.entryStart[rowID];
        for (i in 0...menu.entrySize[rowID]) {
            if (menu.textData[id] > 0) {
                if (i == menu.entrySize[rowID] - 1)
                    Drawing.drawSprite(xPos + 8 * i, yPos, 8, 8, 0, 8 * menu.textData[id] - 8, textMenuSurfaceNo);
                else
                    Drawing.drawSprite(xPos + 8 * i, yPos, 8, 8, textHighlight, 8 * menu.textData[id] - 8, textMenuSurfaceNo);
            }
            id++;
        }
    }

    public static function drawTextMenu(menu:TextMenu, xPos:Int, yPos:Int):Void {
        if (menu.selectionCount == 3) {
            menu.selection2 = -1;
            for (i in 0...menu.selection1 + 1) {
                if (menu.entryHighlight[i] == 1) {
                    menu.selection2 = i;
                }
            }
        }
        switch (menu.alignment) {
            case MENU_ALIGN_LEFT:
                for (i in 0...menu.rowCount) {
                    switch (menu.selectionCount) {
                        case 1:
                            if (i == menu.selection1)
                                drawTextMenuEntry(menu, i, xPos, yPos, 8);
                            else
                                drawTextMenuEntry(menu, i, xPos, yPos, 0);
                        case 2:
                            if (i == menu.selection1 || i == menu.selection2)
                                drawTextMenuEntry(menu, i, xPos, yPos, 8);
                            else
                                drawTextMenuEntry(menu, i, xPos, yPos, 0);
                        case 3:
                            if (i == menu.selection1)
                                drawTextMenuEntry(menu, i, xPos, yPos, 8);
                            else
                                drawTextMenuEntry(menu, i, xPos, yPos, 0);
                            if (i == menu.selection2 && i != menu.selection1)
                                drawStageTextEntry(menu, i, xPos, yPos, 8);
                        default:
                    }
                    yPos += 8;
                }
            case MENU_ALIGN_RIGHT:
                for (i in 0...menu.rowCount) {
                    var textX = xPos - (menu.entrySize[i] << 3);
                    switch (menu.selectionCount) {
                        case 1:
                            if (i == menu.selection1)
                                drawTextMenuEntry(menu, i, textX, yPos, 8);
                            else
                                drawTextMenuEntry(menu, i, textX, yPos, 0);
                        case 2:
                            if (i == menu.selection1 || i == menu.selection2)
                                drawTextMenuEntry(menu, i, textX, yPos, 8);
                            else
                                drawTextMenuEntry(menu, i, textX, yPos, 0);
                        case 3:
                            if (i == menu.selection1)
                                drawTextMenuEntry(menu, i, textX, yPos, 8);
                            else
                                drawTextMenuEntry(menu, i, textX, yPos, 0);
                            if (i == menu.selection2 && i != menu.selection1)
                                drawStageTextEntry(menu, i, textX, yPos, 8);
                        default:
                    }
                    yPos += 8;
                }
            case MENU_ALIGN_CENTER:
                for (i in 0...menu.rowCount) {
                    var textX = xPos - (menu.entrySize[i] >> 1 << 3);
                    switch (menu.selectionCount) {
                        case 1:
                            if (i == menu.selection1)
                                drawTextMenuEntry(menu, i, textX, yPos, 8);
                            else
                                drawTextMenuEntry(menu, i, textX, yPos, 0);
                        case 2:
                            if (i == menu.selection1 || i == menu.selection2)
                                drawTextMenuEntry(menu, i, textX, yPos, 8);
                            else
                                drawTextMenuEntry(menu, i, textX, yPos, 0);
                        case 3:
                            if (i == menu.selection1)
                                drawTextMenuEntry(menu, i, textX, yPos, 8);
                            else
                                drawTextMenuEntry(menu, i, textX, yPos, 0);
                            if (i == menu.selection2 && i != menu.selection1)
                                drawStageTextEntry(menu, i, textX, yPos, 8);
                        default:
                    }
                    yPos += 8;
                }
            default:
        }
    }
}