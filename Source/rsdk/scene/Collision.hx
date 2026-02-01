package rsdk.scene;

import rsdk.scene.Player;
import rsdk.scene.Scene;
import rsdk.graphics.Animation;
import rsdk.graphics.Animation.Hitbox;
import rsdk.core.RetroMath;
import rsdk.core.Debug;
import rsdk.scene.Object.FlipFlags;

enum abstract CollisionSides(Int) to Int {
    var CSIDE_FLOOR = 0;
    var CSIDE_LWALL = 1;
    var CSIDE_RWALL = 2;
    var CSIDE_ROOF = 3;
}

enum abstract CollisionModes(Int) to Int {
    var CMODE_FLOOR = 0;
    var CMODE_LWALL = 1;
    var CMODE_ROOF = 2;
    var CMODE_RWALL = 3;
}

enum abstract CollisionSolidity(Int) from Int to Int {
    var SOLID_ALL = 0;
    var SOLID_TOP = 1;
    var SOLID_LRB = 2;
    var SOLID_NONE = 3;
}

enum abstract ObjectCollisionTypes(Int) to Int {
    var C_TOUCH = 0;
    var C_BOX = 1;
    var C_PLATFORM = 2;
}

class CollisionSensor {
    public var xPos:Int = 0;
    public var yPos:Int = 0;
    public var angle:Int = 0;
    public var collided:Bool = false;

    public function new() {}
}

class Collision {
    public static inline var TILE_SIZE:Int = 16;

    public static var collisionLeft:Int = 0;
    public static var collisionTop:Int = 0;
    public static var collisionRight:Int = 0;
    public static var collisionBottom:Int = 0;

    public static var sensors:Array<CollisionSensor> = [for (i in 0...6) new CollisionSensor()];

    public static var checkResult:Int = 0;

    static inline function intAbs(v:Int):Int { return v < 0 ? -v : v; }

    public static function getPlayerCBox(script:PlayerScript):Hitbox {
        var player = PlayerManager.playerList[PlayerManager.playerNo];
        var anim = script.animations[player.animation];
        if (anim != null && anim.frames.length > player.frame) {
            return Animation.playerCBoxes[anim.frames[player.frame].hitboxID];
        }
        return Animation.playerCBoxes[0];
    }

    public static function getPlayerCBoxInstance(player:Player, script:PlayerScript):Hitbox {
        var anim = script.animations[player.animation];
        if (anim != null && anim.frames.length > player.frame) {
            return Animation.playerCBoxes[anim.frames[player.frame].hitboxID];
        }
        return Animation.playerCBoxes[0];
    }

    public static function findFloorPosition(player:Player, sensor:CollisionSensor, startY:Int):Void {
        var c = 0;
        var angle = sensor.angle;
        var tsm1 = TILE_SIZE - 1;
        var i = 0;
        while (i < TILE_SIZE * 3) {
            if (!sensor.collided) {
                var xp = sensor.xPos >> 16;
                var chunkX = xp >> 7;
                var tileX = (xp & 0x7F) >> 4;
                var yp = (sensor.yPos >> 16) + i - TILE_SIZE;
                var chunkY = yp >> 7;
                var tileY = (yp & 0x7F) >> 4;
                if (xp > -1 && yp > -1) {
                    var tile = Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6;
                    tile += tileX + (tileY << 3);
                    var tileIndex = Scene.stageTiles.tileIndex[tile];
                    if (Scene.stageTiles.collisionFlags[player.collisionPlane][tile] != SOLID_LRB
                        && Scene.stageTiles.collisionFlags[player.collisionPlane][tile] != SOLID_NONE) {
                        switch (Scene.stageTiles.direction[tile]) {
                            case FLIP_NONE:
                                c = (xp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].floorMasks[c] >= 0x40) {
                                } else {
                                    sensor.yPos = Scene.tileCollisions[player.collisionPlane].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    sensor.angle = Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF;
                                }
                            case FLIP_X:
                                c = tsm1 - (xp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].floorMasks[c] >= 0x40) {
                                } else {
                                    sensor.yPos = Scene.tileCollisions[player.collisionPlane].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    sensor.angle = 0x100 - (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF);
                                }
                            case FLIP_Y:
                                c = (xp & 15) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].roofMasks[c] <= -0x40) {
                                } else {
                                    sensor.yPos = tsm1 - Scene.tileCollisions[player.collisionPlane].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    var cAngle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF000000) >> 24;
                                    sensor.angle = (-0x80 - cAngle) & 0xFF;
                                }
                            case FLIP_XY:
                                c = tsm1 - (xp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].roofMasks[c] <= -0x40) {
                                } else {
                                    sensor.yPos = tsm1 - Scene.tileCollisions[player.collisionPlane].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    var cAngle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF000000) >> 24;
                                    sensor.angle = 0x100 - ((-0x80 - cAngle) & 0xFF);
                                }
                            default:
                        }
                    }

                    if (sensor.collided) {
                        if (sensor.angle < 0) sensor.angle += 0x100;
                        if (sensor.angle > 0xFF) sensor.angle -= 0x100;

                        if ((intAbs(sensor.angle - angle) > 0x20) && (intAbs(sensor.angle - 0x100 - angle) > 0x20)
                            && (intAbs(sensor.angle + 0x100 - angle) > 0x20)) {
                            sensor.yPos = startY << 16;
                            sensor.collided = false;
                            sensor.angle = angle;
                            i = TILE_SIZE * 3;
                        } else if (sensor.yPos - startY > (TILE_SIZE >> 1)) {
                            sensor.yPos = startY << 16;
                            sensor.collided = false;
                        } else if (sensor.yPos - startY < -(TILE_SIZE >> 1)) {
                            sensor.yPos = startY << 16;
                            sensor.collided = false;
                        }
                    }
                }
            }
            i += TILE_SIZE;
        }
    }

    public static function findLWallPosition(player:Player, sensor:CollisionSensor, startX:Int):Void {
        var c = 0;
        var angle = sensor.angle;
        var tsm1 = TILE_SIZE - 1;
        var i = 0;
        while (i < TILE_SIZE * 3) {
            if (!sensor.collided) {
                var xp = (sensor.xPos >> 16) + i - TILE_SIZE;
                var chunkX = xp >> 7;
                var tileX = (xp & 0x7F) >> 4;
                var yp = sensor.yPos >> 16;
                var chunkY = yp >> 7;
                var tileY = (yp & 0x7F) >> 4;
                if (xp > -1 && yp > -1) {
                    var tile = Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6;
                    tile += tileX + (tileY << 3);
                    var tileIndex = Scene.stageTiles.tileIndex[tile];
                    if (Scene.stageTiles.collisionFlags[player.collisionPlane][tile] < (SOLID_NONE:Int)) {
                        switch (Scene.stageTiles.direction[tile]) {
                            case FLIP_NONE:
                                c = (yp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].lWallMasks[c] >= 0x40) {
                                } else {
                                    sensor.xPos = Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                    sensor.angle = ((Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF00) >> 8);
                                }
                            case FLIP_X:
                                c = (yp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].rWallMasks[c] <= -0x40) {
                                } else {
                                    sensor.xPos = tsm1 - Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                    sensor.angle = 0x100 - ((Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF0000) >> 16);
                                }
                            case FLIP_Y:
                                c = tsm1 - (yp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].lWallMasks[c] >= 0x40) {
                                } else {
                                    sensor.xPos = Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                    var cAngle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF00) >> 8;
                                    sensor.angle = (-0x80 - cAngle) & 0xFF;
                                }
                            case FLIP_XY:
                                c = tsm1 - (yp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].rWallMasks[c] <= -0x40) {
                                } else {
                                    sensor.xPos = tsm1 - Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                    var cAngle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF0000) >> 16;
                                    sensor.angle = 0x100 - ((-0x80 - cAngle) & 0xFF);
                                }
                            default:
                        }
                    }

                    if (sensor.collided) {
                        if (sensor.angle < 0) sensor.angle += 0x100;
                        if (sensor.angle > 0xFF) sensor.angle -= 0x100;

                        if (intAbs(angle - sensor.angle) > 0x200) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                            sensor.angle = angle;
                            i = TILE_SIZE * 3;
                        } else if (sensor.xPos - startX > (TILE_SIZE >> 1)) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                        } else if (sensor.xPos - startX < -(TILE_SIZE >> 1)) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                        }
                    }
                }
            }
            i += TILE_SIZE;
        }
    }

    public static function findRoofPosition(player:Player, sensor:CollisionSensor, startY:Int):Void {
        var c = 0;
        var angle = sensor.angle;
        var tsm1 = TILE_SIZE - 1;
        var i = 0;
        while (i < TILE_SIZE * 3) {
            if (!sensor.collided) {
                var xp = sensor.xPos >> 16;
                var chunkX = xp >> 7;
                var tileX = (xp & 0x7F) >> 4;
                var yp = (sensor.yPos >> 16) + TILE_SIZE - i;
                var chunkY = yp >> 7;
                var tileY = (yp & 0x7F) >> 4;
                if (xp > -1 && yp > -1) {
                    var tile = Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6;
                    tile += tileX + (tileY << 3);
                    var tileIndex = Scene.stageTiles.tileIndex[tile];
                    if (Scene.stageTiles.collisionFlags[player.collisionPlane][tile] < (SOLID_NONE:Int)) {
                        switch (Scene.stageTiles.direction[tile]) {
                            case FLIP_NONE:
                                c = (xp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].roofMasks[c] <= -0x40) {
                                } else {
                                    sensor.yPos = Scene.tileCollisions[player.collisionPlane].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    sensor.angle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF000000) >> 24;
                                }
                            case FLIP_X:
                                c = tsm1 - (xp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].roofMasks[c] <= -0x40) {
                                } else {
                                    sensor.yPos = Scene.tileCollisions[player.collisionPlane].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    sensor.angle = 0x100 - ((Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF000000) >> 24);
                                }
                            case FLIP_Y:
                                c = (xp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].floorMasks[c] >= 0x40) {
                                } else {
                                    sensor.yPos = tsm1 - Scene.tileCollisions[player.collisionPlane].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    var cAngle = Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF;
                                    sensor.angle = (-0x80 - cAngle) & 0xFF;
                                }
                            case FLIP_XY:
                                c = tsm1 - (xp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].floorMasks[c] >= 0x40) {
                                } else {
                                    sensor.yPos = tsm1 - Scene.tileCollisions[player.collisionPlane].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    var cAngle = Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF;
                                    sensor.angle = 0x100 - ((-0x80 - cAngle) & 0xFF);
                                }
                            default:
                        }
                    }

                    if (sensor.collided) {
                        if (sensor.angle < 0) sensor.angle += 0x100;
                        if (sensor.angle > 0xFF) sensor.angle -= 0x100;

                        if (sensor.yPos - startY > tsm1) {
                            sensor.yPos = startY << 16;
                            sensor.collided = false;
                        }
                        if (sensor.yPos - startY < -tsm1) {
                            sensor.yPos = startY << 16;
                            sensor.collided = false;
                        }
                    }
                }
            }
            i += TILE_SIZE;
        }
    }

    public static function findRWallPosition(player:Player, sensor:CollisionSensor, startX:Int):Void {
        var c = 0;
        var angle = sensor.angle;
        var tsm1 = TILE_SIZE - 1;
        var i = 0;
        while (i < TILE_SIZE * 3) {
            if (!sensor.collided) {
                var xp = (sensor.xPos >> 16) + TILE_SIZE - i;
                var chunkX = xp >> 7;
                var tileX = (xp & 0x7F) >> 4;
                var yp = sensor.yPos >> 16;
                var chunkY = yp >> 7;
                var tileY = (yp & 0x7F) >> 4;
                if (xp > -1 && yp > -1) {
                    var tile = Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6;
                    tile += tileX + (tileY << 3);
                    var tileIndex = Scene.stageTiles.tileIndex[tile];
                    if (Scene.stageTiles.collisionFlags[player.collisionPlane][tile] < (SOLID_NONE:Int)) {
                        switch (Scene.stageTiles.direction[tile]) {
                            case FLIP_NONE:
                                c = (yp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].rWallMasks[c] <= -0x40) {
                                } else {
                                    sensor.xPos = Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                    sensor.angle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF0000) >> 16;
                                }
                            case FLIP_X:
                                c = (yp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].lWallMasks[c] >= 0x40) {
                                } else {
                                    sensor.xPos = tsm1 - Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                    sensor.angle = 0x100 - ((Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF00) >> 8);
                                }
                            case FLIP_Y:
                                c = tsm1 - (yp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].rWallMasks[c] <= -0x40) {
                                } else {
                                    sensor.xPos = Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                    var cAngle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF0000) >> 16;
                                    sensor.angle = (-0x80 - cAngle) & 0xFF;
                                }
                            case FLIP_XY:
                                c = tsm1 - (yp & tsm1) + (tileIndex << 4);
                                if (Scene.tileCollisions[player.collisionPlane].lWallMasks[c] >= 0x40) {
                                } else {
                                    sensor.xPos = tsm1 - Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                    var cAngle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF00) >> 8;
                                    sensor.angle = 0x100 - ((-0x80 - cAngle) & 0xFF);
                                }
                            default:
                        }
                    }

                    if (sensor.collided) {
                        if (sensor.angle < 0) sensor.angle += 0x100;
                        if (sensor.angle > 0xFF) sensor.angle -= 0x100;

                        if (intAbs(sensor.angle - angle) > 0x20) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                            sensor.angle = angle;
                            i = TILE_SIZE * 3;
                        } else if (sensor.xPos - startX > (TILE_SIZE >> 1)) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                        } else if (sensor.xPos - startX < -(TILE_SIZE >> 1)) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                        }
                    }
                }
            }
            i += TILE_SIZE;
        }
    }

    public static function floorCollision(player:Player, sensor:CollisionSensor):Void {
        var c = 0;
        var startY = sensor.yPos >> 16;
        var tsm1 = TILE_SIZE - 1;
        var i = 0;
        while (i < TILE_SIZE * 3) {
            if (!sensor.collided) {
                var xp = sensor.xPos >> 16;
                var chunkX = xp >> 7;
                var tileX = (xp & 0x7F) >> 4;
                var yp = (sensor.yPos >> 16) + i - TILE_SIZE;
                var chunkY = yp >> 7;
                var tileY = (yp & 0x7F) >> 4;
                if (xp > -1 && yp > -1) {
                    var tile = Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6;
                    tile += tileX + (tileY << 3);
                    var tileIndex = Scene.stageTiles.tileIndex[tile];
                    if (Scene.stageTiles.collisionFlags[player.collisionPlane][tile] != SOLID_LRB
                        && Scene.stageTiles.collisionFlags[player.collisionPlane][tile] != SOLID_NONE) {
                        switch (Scene.stageTiles.direction[tile]) {
                            case FLIP_NONE:
                                c = (xp & tsm1) + (tileIndex << 4);
                                if ((yp & tsm1) <= Scene.tileCollisions[player.collisionPlane].floorMasks[c] + i - TILE_SIZE
                                    || Scene.tileCollisions[player.collisionPlane].floorMasks[c] >= tsm1) {
                                } else {
                                    sensor.yPos = Scene.tileCollisions[player.collisionPlane].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    sensor.angle = Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF;
                                }
                            case FLIP_X:
                                c = tsm1 - (xp & tsm1) + (tileIndex << 4);
                                if ((yp & tsm1) <= Scene.tileCollisions[player.collisionPlane].floorMasks[c] + i - TILE_SIZE
                                    || Scene.tileCollisions[player.collisionPlane].floorMasks[c] >= tsm1) {
                                } else {
                                    sensor.yPos = Scene.tileCollisions[player.collisionPlane].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    sensor.angle = 0x100 - (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF);
                                }
                            case FLIP_Y:
                                c = (xp & tsm1) + (tileIndex << 4);
                                if ((yp & tsm1) <= tsm1 - Scene.tileCollisions[player.collisionPlane].roofMasks[c] + i - TILE_SIZE) {
                                } else {
                                    sensor.yPos = tsm1 - Scene.tileCollisions[player.collisionPlane].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    var cAngle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF000000) >> 24;
                                    sensor.angle = (-0x80 - cAngle) & 0xFF;
                                }
                            case FLIP_XY:
                                c = tsm1 - (xp & tsm1) + (tileIndex << 4);
                                if ((yp & tsm1) <= tsm1 - Scene.tileCollisions[player.collisionPlane].roofMasks[c] + i - TILE_SIZE) {
                                } else {
                                    sensor.yPos = tsm1 - Scene.tileCollisions[player.collisionPlane].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    var cAngle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF000000) >> 24;
                                    sensor.angle = 0x100 - ((-0x80 - cAngle) & 0xFF);
                                }
                            default:
                        }
                    }

                    if (sensor.collided) {
                        if (sensor.angle < 0) sensor.angle += 0x100;
                        if (sensor.angle > 0xFF) sensor.angle -= 0x100;

                        if (sensor.yPos - startY > (TILE_SIZE - 2)) {
                            sensor.yPos = startY << 16;
                            sensor.collided = false;
                        } else if (sensor.yPos - startY < -(TILE_SIZE + 1)) {
                            sensor.yPos = startY << 16;
                            sensor.collided = false;
                        }
                    }
                }
            }
            i += TILE_SIZE;
        }
    }

    public static function lWallCollision(player:Player, sensor:CollisionSensor):Void {
        var c = 0;
        var startX = sensor.xPos >> 16;
        var tsm1 = TILE_SIZE - 1;
        var i = 0;
        while (i < TILE_SIZE * 3) {
            if (!sensor.collided) {
                var xp = (sensor.xPos >> 16) + i - TILE_SIZE;
                var chunkX = xp >> 7;
                var tileX = (xp & 0x7F) >> 4;
                var yp = sensor.yPos >> 16;
                var chunkY = yp >> 7;
                var tileY = (yp & 0x7F) >> 4;
                if (xp > -1 && yp > -1) {
                    var tile = Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6;
                    tile += tileX + (tileY << 3);
                    var tileIndex = Scene.stageTiles.tileIndex[tile];
                    if (Scene.stageTiles.collisionFlags[player.collisionPlane][tile] != SOLID_TOP
                        && Scene.stageTiles.collisionFlags[player.collisionPlane][tile] < (SOLID_NONE:Int)) {
                        switch (Scene.stageTiles.direction[tile]) {
                            case FLIP_NONE:
                                c = (yp & tsm1) + (tileIndex << 4);
                                if ((xp & tsm1) <= Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + i - TILE_SIZE) {
                                } else {
                                    sensor.xPos = Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                }
                            case FLIP_X:
                                c = (yp & tsm1) + (tileIndex << 4);
                                if ((xp & tsm1) <= tsm1 - Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + i - TILE_SIZE) {
                                } else {
                                    sensor.xPos = tsm1 - Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                }
                            case FLIP_Y:
                                c = tsm1 - (yp & tsm1) + (tileIndex << 4);
                                if ((xp & tsm1) <= Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + i - TILE_SIZE) {
                                } else {
                                    sensor.xPos = Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                }
                            case FLIP_XY:
                                c = tsm1 - (yp & tsm1) + (tileIndex << 4);
                                if ((xp & tsm1) <= tsm1 - Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + i - TILE_SIZE) {
                                } else {
                                    sensor.xPos = tsm1 - Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                }
                            default:
                        }
                    }

                    if (sensor.collided) {
                        if (sensor.xPos - startX > tsm1) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                        } else if (sensor.xPos - startX < -tsm1) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                        }
                    }
                }
            }
            i += TILE_SIZE;
        }
    }

    public static function roofCollision(player:Player, sensor:CollisionSensor):Void {
        var c = 0;
        var startY = sensor.yPos >> 16;
        var tsm1 = TILE_SIZE - 1;
        var i = 0;
        while (i < TILE_SIZE * 3) {
            if (!sensor.collided) {
                var xp = sensor.xPos >> 16;
                var chunkX = xp >> 7;
                var tileX = (xp & 0x7F) >> 4;
                var yp = (sensor.yPos >> 16) + TILE_SIZE - i;
                var chunkY = yp >> 7;
                var tileY = (yp & 0x7F) >> 4;
                if (xp > -1 && yp > -1) {
                    var tile = Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6;
                    tile += tileX + (tileY << 3);
                    var tileIndex = Scene.stageTiles.tileIndex[tile];
                    if (Scene.stageTiles.collisionFlags[player.collisionPlane][tile] != SOLID_TOP
                        && Scene.stageTiles.collisionFlags[player.collisionPlane][tile] < (SOLID_NONE:Int)) {
                        switch (Scene.stageTiles.direction[tile]) {
                            case FLIP_NONE:
                                c = (xp & tsm1) + (tileIndex << 4);
                                if ((yp & tsm1) >= Scene.tileCollisions[player.collisionPlane].roofMasks[c] + TILE_SIZE - i) {
                                } else {
                                    sensor.yPos = Scene.tileCollisions[player.collisionPlane].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    sensor.angle = (Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF000000) >> 24;
                                }
                            case FLIP_X:
                                c = tsm1 - (xp & tsm1) + (tileIndex << 4);
                                if ((yp & tsm1) >= Scene.tileCollisions[player.collisionPlane].roofMasks[c] + TILE_SIZE - i) {
                                } else {
                                    sensor.yPos = Scene.tileCollisions[player.collisionPlane].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    sensor.angle = 0x100 - ((Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF000000) >> 24);
                                }
                            case FLIP_Y:
                                c = (xp & tsm1) + (tileIndex << 4);
                                if ((yp & tsm1) >= tsm1 - Scene.tileCollisions[player.collisionPlane].floorMasks[c] + TILE_SIZE - i) {
                                } else {
                                    sensor.yPos = tsm1 - Scene.tileCollisions[player.collisionPlane].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    var cAngle = Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF;
                                    sensor.angle = (-0x80 - cAngle) & 0xFF;
                                }
                            case FLIP_XY:
                                c = tsm1 - (xp & tsm1) + (tileIndex << 4);
                                if ((yp & tsm1) >= tsm1 - Scene.tileCollisions[player.collisionPlane].floorMasks[c] + TILE_SIZE - i) {
                                } else {
                                    sensor.yPos = tsm1 - Scene.tileCollisions[player.collisionPlane].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                    sensor.collided = true;
                                    var cAngle = Scene.tileCollisions[player.collisionPlane].angles[tileIndex] & 0xFF;
                                    sensor.angle = 0x100 - ((-0x80 - cAngle) & 0xFF);
                                }
                            default:
                        }
                    }

                    if (sensor.collided) {
                        if (sensor.angle < 0) sensor.angle += 0x100;
                        if (sensor.angle > 0xFF) sensor.angle -= 0x100;

                        if (sensor.yPos - startY > (TILE_SIZE - 2)) {
                            sensor.yPos = startY << 16;
                            sensor.collided = false;
                        } else if (sensor.yPos - startY < -(TILE_SIZE - 2)) {
                            sensor.yPos = startY << 16;
                            sensor.collided = false;
                        }
                    }
                }
            }
            i += TILE_SIZE;
        }
    }

    public static function rWallCollision(player:Player, sensor:CollisionSensor):Void {
        var c = 0;
        var startX = sensor.xPos >> 16;
        var tsm1 = TILE_SIZE - 1;
        var i = 0;
        while (i < TILE_SIZE * 3) {
            if (!sensor.collided) {
                var xp = (sensor.xPos >> 16) + TILE_SIZE - i;
                var chunkX = xp >> 7;
                var tileX = (xp & 0x7F) >> 4;
                var yp = sensor.yPos >> 16;
                var chunkY = yp >> 7;
                var tileY = (yp & 0x7F) >> 4;
                if (xp > -1 && yp > -1) {
                    var tile = Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6;
                    tile += tileX + (tileY << 3);
                    var tileIndex = Scene.stageTiles.tileIndex[tile];
                    if (Scene.stageTiles.collisionFlags[player.collisionPlane][tile] != SOLID_TOP
                        && Scene.stageTiles.collisionFlags[player.collisionPlane][tile] < (SOLID_NONE:Int)) {
                        switch (Scene.stageTiles.direction[tile]) {
                            case FLIP_NONE:
                                c = (yp & tsm1) + (tileIndex << 4);
                                if ((xp & tsm1) >= Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + TILE_SIZE - i) {
                                } else {
                                    sensor.xPos = Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                }
                            case FLIP_X:
                                c = (yp & tsm1) + (tileIndex << 4);
                                if ((xp & tsm1) >= tsm1 - Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + TILE_SIZE - i) {
                                } else {
                                    sensor.xPos = tsm1 - Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                }
                            case FLIP_Y:
                                c = tsm1 - (yp & tsm1) + (tileIndex << 4);
                                if ((xp & tsm1) >= Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + TILE_SIZE - i) {
                                } else {
                                    sensor.xPos = Scene.tileCollisions[player.collisionPlane].rWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                }
                            case FLIP_XY:
                                c = tsm1 - (yp & tsm1) + (tileIndex << 4);
                                if ((xp & tsm1) >= tsm1 - Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + TILE_SIZE - i) {
                                } else {
                                    sensor.xPos = tsm1 - Scene.tileCollisions[player.collisionPlane].lWallMasks[c] + (chunkX << 7) + (tileX << 4);
                                    sensor.collided = true;
                                }
                            default:
                        }
                    }

                    if (sensor.collided) {
                        if (sensor.xPos - startX > tsm1) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                        } else if (sensor.xPos - startX < -tsm1) {
                            sensor.xPos = startX << 16;
                            sensor.collided = false;
                        }
                    }
                }
            }
            i += TILE_SIZE;
        }
    }

    public static function setPathGripSensors(player:Player):Void {
        var script = PlayerManager.playerScriptList[PlayerManager.playerNo];
        var playerHitbox = getPlayerCBox(script);
        switch (player.collisionMode) {
            case CMODE_FLOOR:
                collisionLeft = playerHitbox.left[0];
                collisionTop = playerHitbox.top[0];
                collisionRight = playerHitbox.right[0];
                collisionBottom = playerHitbox.bottom[0];
                sensors[0].yPos = sensors[4].yPos + (collisionBottom << 16);
                sensors[1].yPos = sensors[0].yPos;
                sensors[2].yPos = sensors[0].yPos;
                sensors[3].yPos = sensors[4].yPos + 0x40000;
                sensors[0].xPos = sensors[4].xPos + ((playerHitbox.left[1] - 1) << 16);
                sensors[1].xPos = sensors[4].xPos;
                sensors[2].xPos = sensors[4].xPos + (playerHitbox.right[1] << 16);
                if (player.speed > 0) {
                    sensors[3].xPos = sensors[4].xPos + ((collisionRight + 1) << 16);
                } else {
                    sensors[3].xPos = sensors[4].xPos + ((collisionLeft - 1) << 16);
                }
            case CMODE_LWALL:
                collisionLeft = playerHitbox.left[2];
                collisionTop = playerHitbox.top[2];
                collisionRight = playerHitbox.right[2];
                collisionBottom = playerHitbox.bottom[2];
                sensors[0].xPos = sensors[4].xPos + (collisionRight << 16);
                sensors[1].xPos = sensors[0].xPos;
                sensors[2].xPos = sensors[0].xPos;
                sensors[3].xPos = sensors[4].xPos + 0x40000;
                sensors[0].yPos = sensors[4].yPos + ((playerHitbox.top[3] - 1) << 16);
                sensors[1].yPos = sensors[4].yPos;
                sensors[2].yPos = sensors[4].yPos + (playerHitbox.bottom[3] << 16);
                if (player.speed > 0) {
                    sensors[3].yPos = sensors[4].yPos + (collisionTop << 16);
                } else {
                    sensors[3].yPos = sensors[4].yPos + ((collisionBottom - 1) << 16);
                }
            case CMODE_ROOF:
                collisionLeft = playerHitbox.left[4];
                collisionTop = playerHitbox.top[4];
                collisionRight = playerHitbox.right[4];
                collisionBottom = playerHitbox.bottom[4];
                sensors[0].yPos = sensors[4].yPos + ((collisionTop - 1) << 16);
                sensors[1].yPos = sensors[0].yPos;
                sensors[2].yPos = sensors[0].yPos;
                sensors[3].yPos = sensors[4].yPos - 0x40000;
                sensors[0].xPos = sensors[4].xPos + ((playerHitbox.left[5] - 1) << 16);
                sensors[1].xPos = sensors[4].xPos;
                sensors[2].xPos = sensors[4].xPos + (playerHitbox.right[5] << 16);
                if (player.speed < 0) {
                    sensors[3].xPos = sensors[4].xPos + ((collisionRight + 1) << 16);
                } else {
                    sensors[3].xPos = sensors[4].xPos + ((collisionLeft - 1) << 16);
                }
            case CMODE_RWALL:
                collisionLeft = playerHitbox.left[6];
                collisionTop = playerHitbox.top[6];
                collisionRight = playerHitbox.right[6];
                collisionBottom = playerHitbox.bottom[6];
                sensors[0].xPos = sensors[4].xPos + ((collisionLeft - 1) << 16);
                sensors[1].xPos = sensors[0].xPos;
                sensors[2].xPos = sensors[0].xPos;
                sensors[3].xPos = sensors[4].xPos - 0x40000;
                sensors[0].yPos = sensors[4].yPos + ((playerHitbox.top[7] - 1) << 16);
                sensors[1].yPos = sensors[4].yPos;
                sensors[2].yPos = sensors[4].yPos + (playerHitbox.bottom[7] << 16);
                if (player.speed > 0) {
                    sensors[3].yPos = sensors[4].yPos + (collisionBottom << 16);
                } else {
                    sensors[3].yPos = sensors[4].yPos + ((collisionTop - 1) << 16);
                }
            default:
        }
    }

    public static function processTracedCollision(player:Player):Void {
        var script = PlayerManager.playerScriptList[PlayerManager.playerNo];
        var playerHitbox = getPlayerCBox(script);
        collisionLeft = playerHitbox.left[0];
        collisionTop = playerHitbox.top[0];
        collisionRight = playerHitbox.right[0];
        collisionBottom = playerHitbox.bottom[0];

        var movingDown = 0;
        var movingUp = 0;
        var movingLeft = 0;
        var movingRight = 0;

        if (player.xVelocity < 0) {
            movingRight = 0;
        } else {
            movingRight = 1;
            sensors[0].yPos = ((collisionTop + 4) << 16) + player.yPos;
            sensors[1].yPos = ((collisionBottom - 4) << 16) + player.yPos;
            sensors[0].xPos = (collisionRight << 16) + player.xPos;
            sensors[1].xPos = (collisionRight << 16) + player.xPos;
        }
        if (player.xVelocity > 0) {
            movingLeft = 0;
        } else {
            movingLeft = 1;
            sensors[2].yPos = ((collisionTop + 4) << 16) + player.yPos;
            sensors[3].yPos = ((collisionBottom - 4) << 16) + player.yPos;
            sensors[2].xPos = ((collisionLeft - 1) << 16) + player.xPos;
            sensors[3].xPos = ((collisionLeft - 1) << 16) + player.xPos;
        }
        sensors[4].xPos = ((collisionLeft + 1) << 16) + player.xPos;
        sensors[5].xPos = ((collisionRight - 2) << 16) + player.xPos;
        sensors[0].collided = false;
        sensors[1].collided = false;
        sensors[2].collided = false;
        sensors[3].collided = false;
        sensors[4].collided = false;
        sensors[5].collided = false;

        movingDown = 0;
        movingUp = 0;
        if (player.yVelocity < 0) {
            movingUp = 1;
            sensors[4].yPos = ((collisionTop - 1) << 16) + player.yPos;
            sensors[5].yPos = ((collisionTop - 1) << 16) + player.yPos;
        } else if (player.yVelocity > 0) {
            movingDown = 1;
            sensors[4].yPos = (collisionBottom << 16) + player.yPos;
            sensors[5].yPos = (collisionBottom << 16) + player.yPos;
        }

        var xDif = ((player.xVelocity + player.xPos) >> 16) - (player.xPos >> 16);
        var yDif = ((player.yVelocity + player.yPos) >> 16) - (player.yPos >> 16);
        var absXDif = intAbs(xDif);
        var absYDif = intAbs(yDif);
        var cnt = 1;
        var xVel = player.xVelocity;
        var yVel = player.yVelocity;

        if (absXDif != 0 || absYDif != 0) {
            if (absXDif <= absYDif) {
                xVel = Std.int((xDif << 16) / absYDif);
                cnt = absYDif;
                yVel = if (yDif >= 0) 0x10000 else -0x10000;
            } else {
                yVel = Std.int((yDif << 16) / absXDif);
                cnt = absXDif;
                xVel = if (xDif >= 0) 0x10000 else -0x10000;
            }
        }

        while (cnt > 0) {
            cnt--;

            if (movingRight == 1) {
                for (i in 0...2) {
                    if (!sensors[i].collided) {
                        sensors[i].xPos += xVel;
                        sensors[i].yPos += yVel;
                        lWallCollision(player, sensors[i]);
                    }
                }
                if (sensors[0].collided || sensors[1].collided) {
                    movingRight = 2;
                    cnt = 0;
                    xVel = 0;
                }
            }

            if (movingLeft == 1) {
                for (i in 2...4) {
                    if (!sensors[i].collided) {
                        sensors[i].xPos += xVel;
                        sensors[i].yPos += yVel;
                        rWallCollision(player, sensors[i]);
                    }
                }
                if (sensors[2].collided || sensors[3].collided) {
                    movingLeft = 2;
                    cnt = 0;
                    xVel = 0;
                }
            }

            if (movingDown == 1) {
                for (i in 4...6) {
                    if (!sensors[i].collided) {
                        sensors[i].xPos += xVel;
                        sensors[i].yPos += yVel;
                        floorCollision(player, sensors[i]);
                    }
                }
                if (sensors[4].collided || sensors[5].collided) {
                    movingDown = 2;
                    cnt = 0;
                }
            } else if (movingUp == 1) {
                for (i in 4...6) {
                    if (!sensors[i].collided) {
                        sensors[i].xPos += xVel;
                        sensors[i].yPos += yVel;
                        roofCollision(player, sensors[i]);
                    }
                }
                if (sensors[4].collided || sensors[5].collided) {
                    movingUp = 2;
                    cnt = 0;
                }
            }
        }

        if (movingLeft == 2 || movingRight == 2) {
            if (movingRight == 2) {
                player.xVelocity = 0;
                player.speed = 0;
                if (!sensors[0].collided || !sensors[1].collided) {
                    if (sensors[0].collided) {
                        player.xPos = (sensors[0].xPos - collisionRight) << 16;
                    } else if (sensors[1].collided) {
                        player.xPos = (sensors[1].xPos - collisionRight) << 16;
                    }
                } else if (sensors[0].xPos >= sensors[1].xPos) {
                    player.xPos = (sensors[1].xPos - collisionRight) << 16;
                } else {
                    player.xPos = (sensors[0].xPos - collisionRight) << 16;
                }
            }
            if (movingLeft == 2) {
                player.xVelocity = 0;
                player.speed = 0;
                if (!sensors[2].collided || !sensors[3].collided) {
                    if (sensors[2].collided) {
                        player.xPos = (sensors[2].xPos - collisionLeft + 1) << 16;
                    } else if (sensors[3].collided) {
                        player.xPos = (sensors[3].xPos - collisionLeft + 1) << 16;
                    }
                } else if (sensors[2].xPos <= sensors[3].xPos) {
                    player.xPos = (sensors[3].xPos - collisionLeft + 1) << 16;
                } else {
                    player.xPos = (sensors[2].xPos - collisionLeft + 1) << 16;
                }
            }
        } else {
            player.xPos += player.xVelocity;
        }

        if (movingUp < 2 && movingDown < 2) {
            player.yPos += player.yVelocity;
            return;
        }

        if (movingDown == 2) {
            player.gravity = 0;
            if (sensors[4].collided && sensors[5].collided) {
                if (sensors[4].yPos >= sensors[5].yPos) {
                    player.yPos = (sensors[5].yPos - collisionBottom) << 16;
                    player.angle = sensors[5].angle;
                } else {
                    player.yPos = (sensors[4].yPos - collisionBottom) << 16;
                    player.angle = sensors[4].angle;
                }
            } else if (sensors[4].collided) {
                player.yPos = (sensors[4].yPos - collisionBottom) << 16;
                player.angle = sensors[4].angle;
            } else if (sensors[5].collided) {
                player.yPos = (sensors[5].yPos - collisionBottom) << 16;
                player.angle = sensors[5].angle;
            }
            if (player.angle > 0xA0 && player.angle < 0xE0 && player.collisionMode != CMODE_LWALL) {
                player.collisionMode = CMODE_LWALL;
            }
            if (player.angle > 0x20 && player.angle < 0x60 && player.collisionMode != CMODE_RWALL) {
                player.collisionMode = CMODE_RWALL;
            }
            player.rotation = player.angle;

            player.speed += (player.yVelocity * RetroMath.sin256(player.angle) >> 8);
            player.yVelocity = 0;
        }

        if (movingUp == 2) {
            player.yVelocity = 0;
            if (sensors[4].collided && sensors[5].collided) {
                if (sensors[4].yPos <= sensors[5].yPos) {
                    player.yPos = (sensors[5].yPos - collisionTop + 1) << 16;
                } else {
                    player.yPos = (sensors[4].yPos - collisionTop + 1) << 16;
                }
            } else if (sensors[4].collided) {
                player.yPos = (sensors[4].yPos - collisionTop + 1) << 16;
            } else if (sensors[5].collided) {
                player.yPos = (sensors[5].yPos - collisionTop + 1) << 16;
            }
        }
    }

    public static function processPathGrip(player:Player):Void {
        sensors[4].xPos = player.xPos;
        sensors[4].yPos = player.yPos;
        for (i in 0...6) {
            sensors[i].angle = player.angle;
            sensors[i].collided = false;
        }
        setPathGripSensors(player);
        var absSpeed = intAbs(player.speed);
        var checkDist = absSpeed >> 18;
        absSpeed &= 0x3FFFF;
        var cMode = player.collisionMode;

        while (checkDist > -1) {
            var cos:Int;
            var sin:Int;
            if (checkDist >= 1) {
                cos = RetroMath.cos256(player.angle) << 10;
                sin = RetroMath.sin256(player.angle) << 10;
                checkDist--;
            } else {
                cos = absSpeed * RetroMath.cos256(player.angle) >> 8;
                sin = absSpeed * RetroMath.sin256(player.angle) >> 8;
                checkDist = -1;
            }

            if (player.speed < 0) {
                cos = -cos;
                sin = -sin;
            }

            sensors[0].collided = false;
            sensors[1].collided = false;
            sensors[2].collided = false;
            sensors[4].xPos += cos;
            sensors[4].yPos += sin;
            var tileDistance = -1;

            switch (player.collisionMode) {
                case CMODE_FLOOR:
                    for (i in 0...3) {
                        sensors[i].xPos += cos;
                        sensors[i].yPos += sin;
                        findFloorPosition(player, sensors[i], sensors[i].yPos >> 16);
                    }

                    tileDistance = -1;
                    for (i in 0...3) {
                        if (tileDistance > -1) {
                            if (sensors[i].collided) {
                                if (sensors[i].yPos < sensors[tileDistance].yPos)
                                    tileDistance = i;
                                if (sensors[i].yPos == sensors[tileDistance].yPos && (sensors[i].angle < 0x08 || sensors[i].angle > 0xF8))
                                    tileDistance = i;
                            }
                        } else if (sensors[i].collided)
                            tileDistance = i;
                    }

                    if (tileDistance <= -1) {
                        checkDist = -1;
                    } else {
                        sensors[0].yPos = sensors[tileDistance].yPos << 16;
                        sensors[0].angle = sensors[tileDistance].angle;
                        sensors[1].yPos = sensors[0].yPos;
                        sensors[1].angle = sensors[0].angle;
                        sensors[2].yPos = sensors[0].yPos;
                        sensors[2].angle = sensors[0].angle;
                        sensors[3].yPos = sensors[0].yPos - 0x40000;
                        sensors[3].angle = sensors[0].angle;
                        sensors[4].xPos = sensors[1].xPos;
                        sensors[4].yPos = sensors[0].yPos - (collisionBottom << 16);
                    }

                    sensors[3].xPos += cos;
                    if (player.speed > 0)
                        lWallCollision(player, sensors[3]);
                    if (player.speed < 0)
                        rWallCollision(player, sensors[3]);

                    if (sensors[0].angle > 0xA0 && sensors[0].angle < 0xE0 && player.collisionMode != CMODE_LWALL)
                        player.collisionMode = CMODE_LWALL;
                    if (sensors[0].angle > 0x20 && sensors[0].angle < 0x60 && player.collisionMode != CMODE_RWALL)
                        player.collisionMode = CMODE_RWALL;

                case CMODE_LWALL:
                    for (i in 0...3) {
                        sensors[i].xPos += cos;
                        sensors[i].yPos += sin;
                        findLWallPosition(player, sensors[i], sensors[i].xPos >> 16);
                    }

                    tileDistance = -1;
                    for (i in 0...3) {
                        if (tileDistance > -1) {
                            if (sensors[i].xPos < sensors[tileDistance].xPos && sensors[i].collided)
                                tileDistance = i;
                        } else if (sensors[i].collided)
                            tileDistance = i;
                    }

                    if (tileDistance <= -1) {
                        checkDist = -1;
                    } else {
                        sensors[0].xPos = sensors[tileDistance].xPos << 16;
                        sensors[0].angle = sensors[tileDistance].angle;
                        sensors[1].xPos = sensors[0].xPos;
                        sensors[1].angle = sensors[0].angle;
                        sensors[2].xPos = sensors[0].xPos;
                        sensors[2].angle = sensors[0].angle;
                        sensors[4].yPos = sensors[1].yPos;
                        sensors[4].xPos = sensors[1].xPos - (collisionRight << 16);
                    }

                    if ((sensors[0].angle < 0x20 || sensors[0].angle > 0xE0) && player.collisionMode != CMODE_FLOOR)
                        player.collisionMode = CMODE_FLOOR;
                    if (sensors[0].angle > 0x60 && sensors[0].angle < 0xA0 && player.collisionMode != CMODE_ROOF)
                        player.collisionMode = CMODE_ROOF;

                case CMODE_ROOF:
                    for (i in 0...3) {
                        sensors[i].xPos += cos;
                        sensors[i].yPos += sin;
                        findRoofPosition(player, sensors[i], sensors[i].yPos >> 16);
                    }

                    tileDistance = -1;
                    for (i in 0...3) {
                        if (tileDistance > -1) {
                            if (sensors[i].yPos > sensors[tileDistance].yPos && sensors[i].collided)
                                tileDistance = i;
                        } else if (sensors[i].collided)
                            tileDistance = i;
                    }

                    if (tileDistance <= -1) {
                        checkDist = -1;
                    } else {
                        sensors[0].yPos = sensors[tileDistance].yPos << 16;
                        sensors[0].angle = sensors[tileDistance].angle;
                        sensors[1].yPos = sensors[0].yPos;
                        sensors[1].angle = sensors[0].angle;
                        sensors[2].yPos = sensors[0].yPos;
                        sensors[2].angle = sensors[0].angle;
                        sensors[3].yPos = sensors[0].yPos + 0x40000;
                        sensors[3].angle = sensors[0].angle;
                        sensors[4].xPos = sensors[1].xPos;
                        sensors[4].yPos = sensors[0].yPos - ((collisionTop - 1) << 16);
                    }

                    sensors[3].xPos += cos;
                    if (player.speed > 0)
                        rWallCollision(player, sensors[3]);
                    if (player.speed < 0)
                        lWallCollision(player, sensors[3]);
                    if (sensors[0].angle > 0xA0 && sensors[0].angle < 0xE0 && player.collisionMode != CMODE_LWALL)
                        player.collisionMode = CMODE_LWALL;
                    if (sensors[0].angle > 0x20 && sensors[0].angle < 0x60 && player.collisionMode != CMODE_RWALL)
                        player.collisionMode = CMODE_RWALL;

                case CMODE_RWALL:
                    for (i in 0...3) {
                        sensors[i].xPos += cos;
                        sensors[i].yPos += sin;
                        findRWallPosition(player, sensors[i], sensors[i].xPos >> 16);
                    }

                    tileDistance = -1;
                    for (i in 0...3) {
                        if (tileDistance > -1) {
                            if (sensors[i].xPos > sensors[tileDistance].xPos && sensors[i].collided)
                                tileDistance = i;
                        } else if (sensors[i].collided)
                            tileDistance = i;
                    }

                    if (tileDistance <= -1) {
                        checkDist = -1;
                    } else {
                        sensors[0].xPos = sensors[tileDistance].xPos << 16;
                        sensors[0].angle = sensors[tileDistance].angle;
                        sensors[1].xPos = sensors[0].xPos;
                        sensors[1].angle = sensors[0].angle;
                        sensors[2].xPos = sensors[0].xPos;
                        sensors[2].angle = sensors[0].angle;
                        sensors[4].yPos = sensors[1].yPos;
                        sensors[4].xPos = sensors[1].xPos - ((collisionLeft - 1) << 16);
                    }

                    if ((sensors[0].angle < 0x20 || sensors[0].angle > 0xE0) && player.collisionMode != CMODE_FLOOR)
                        player.collisionMode = CMODE_FLOOR;
                    if (sensors[0].angle > 0x60 && sensors[0].angle < 0xA0 && player.collisionMode != CMODE_ROOF)
                        player.collisionMode = CMODE_ROOF;
                default:
            }

            if (tileDistance > -1)
                player.angle = sensors[0].angle;

            if (!sensors[3].collided)
                setPathGripSensors(player);
            else
                checkDist = -2;
        }

        switch (cMode) {
            case CMODE_FLOOR:
                if (sensors[0].collided || sensors[1].collided || sensors[2].collided) {
                    player.angle = sensors[0].angle;
                    player.rotation = player.angle;
                    player.flailing[0] = sensors[0].collided ? 1 : 0;
                    player.flailing[1] = sensors[1].collided ? 1 : 0;
                    player.flailing[2] = sensors[2].collided ? 1 : 0;
                    if (!sensors[3].collided) {
                        player.pushing = 0;
                        player.xPos = sensors[4].xPos;
                    } else {
                        if (player.speed > 0)
                            player.xPos = (sensors[3].xPos - collisionRight) << 16;
                        if (player.speed < 0)
                            player.xPos = (sensors[3].xPos - collisionLeft + 1) << 16;
                        player.speed = 0;
                        if ((player.left != 0 || player.right != 0) && player.pushing < 2)
                            player.pushing++;
                    }
                    player.yPos = sensors[4].yPos;
                } else {
                    player.gravity = 1;
                    player.collisionMode = CMODE_FLOOR;
                    player.xVelocity = RetroMath.cos256(player.angle) * player.speed >> 8;
                    player.yVelocity = RetroMath.sin256(player.angle) * player.speed >> 8;
                    player.speed = player.xVelocity;
                    player.angle = 0;
                    if (!sensors[3].collided) {
                        player.pushing = 0;
                        player.xPos += player.xVelocity;
                    } else {
                        if (player.speed > 0)
                            player.xPos = (sensors[3].xPos - collisionRight) << 16;
                        if (player.speed < 0)
                            player.xPos = (sensors[3].xPos - collisionLeft + 1) << 16;
                        player.speed = 0;
                        if ((player.left != 0 || player.right != 0) && player.pushing < 2)
                            player.pushing++;
                    }
                    player.yPos += player.yVelocity;
                }

            case CMODE_LWALL:
                if (!sensors[0].collided && !sensors[1].collided && !sensors[2].collided) {
                    player.gravity = 1;
                    player.collisionMode = CMODE_FLOOR;
                    player.xVelocity = RetroMath.cos256(player.angle) * player.speed >> 8;
                    player.yVelocity = RetroMath.sin256(player.angle) * player.speed >> 8;
                    player.speed = player.xVelocity;
                    player.angle = 0;
                } else if (player.speed >= 0x20000 || player.speed <= -1) {
                    player.angle = sensors[0].angle;
                    player.rotation = player.angle;
                } else {
                    player.gravity = 1;
                    player.angle = 0;
                    player.collisionMode = CMODE_FLOOR;
                    player.speed = player.xVelocity;
                }
                player.xPos = sensors[4].xPos;
                player.yPos = sensors[4].yPos;

            case CMODE_ROOF:
                if (!sensors[0].collided && !sensors[1].collided && !sensors[2].collided) {
                    player.gravity = 1;
                    player.collisionMode = CMODE_FLOOR;
                    player.xVelocity = RetroMath.cos256(player.angle) * player.speed >> 8;
                    player.yVelocity = RetroMath.sin256(player.angle) * player.speed >> 8;
                    player.angle = 0;
                    player.speed = player.xVelocity;
                } else if (player.speed <= -0x20000 || player.speed >= 0x20000) {
                    player.angle = sensors[0].angle;
                    player.rotation = player.angle;
                } else {
                    player.gravity = 1;
                    player.angle = 0;
                    player.collisionMode = CMODE_FLOOR;
                    player.speed = player.xVelocity;
                }
                if (!sensors[3].collided) {
                    player.xPos = sensors[4].xPos;
                } else {
                    if (player.speed > 0)
                        player.xPos = (sensors[3].xPos - collisionRight) << 16;
                    if (player.speed < 0)
                        player.xPos = (sensors[3].xPos - collisionLeft + 1) << 16;
                    player.speed = 0;
                }
                player.yPos = sensors[4].yPos;

            case CMODE_RWALL:
                if (!sensors[0].collided && !sensors[1].collided && !sensors[2].collided) {
                    player.gravity = 1;
                    player.collisionMode = CMODE_FLOOR;
                    player.xVelocity = RetroMath.cos256(player.angle) * player.speed >> 8;
                    player.yVelocity = RetroMath.sin256(player.angle) * player.speed >> 8;
                    player.speed = player.xVelocity;
                    player.angle = 0;
                } else if (player.speed <= -0x20000 || player.speed >= 1) {
                    player.angle = sensors[0].angle;
                    player.rotation = player.angle;
                } else {
                    player.gravity = 1;
                    player.angle = 0;
                    player.collisionMode = CMODE_FLOOR;
                    player.speed = player.xVelocity;
                }
                player.xPos = sensors[4].xPos;
                player.yPos = sensors[4].yPos;
            default:
        }
    }

    public static function processPlayerTileCollisions(player:Player):Void {
        player.flailing[0] = 0;
        player.flailing[1] = 0;
        player.flailing[2] = 0;
        if (player.gravity == 1)
            processTracedCollision(player);
        else
            processPathGrip(player);
    }

    public static function basicCollision(left:Int, top:Int, right:Int, bottom:Int):Void {
        var player = PlayerManager.playerList[PlayerManager.playerNo];
        var script = PlayerManager.playerScriptList[PlayerManager.playerNo];
        var cbox = getPlayerCBox(script);
        collisionLeft = player.xPos >> 16;
        collisionTop = player.yPos >> 16;
        collisionRight = collisionLeft;
        collisionBottom = collisionTop;
        collisionLeft += cbox.left[0];
        collisionTop += cbox.top[0];
        collisionRight += cbox.right[0];
        collisionBottom += cbox.bottom[0];

        checkResult = 0;
        if (right > collisionLeft && left < collisionRight && bottom > collisionTop && top < collisionBottom)
            checkResult = 1;
        Script.scriptEng.checkResult = checkResult;
    }

    public static function boxCollision(left:Int, top:Int, right:Int, bottom:Int):Void {
        var player = PlayerManager.playerList[PlayerManager.playerNo];
        var script = PlayerManager.playerScriptList[PlayerManager.playerNo];
        var cbox = getPlayerCBox(script);

        collisionLeft = cbox.left[0];
        collisionTop = cbox.top[0];
        collisionRight = cbox.right[0];
        collisionBottom = cbox.bottom[0];
        checkResult = 0;

        var spd = 0;
        switch (player.collisionMode) {
            case CMODE_FLOOR, CMODE_ROOF:
                spd = if (player.xVelocity != 0) intAbs(player.xVelocity) else intAbs(player.speed);
            case CMODE_LWALL, CMODE_RWALL:
                spd = intAbs(player.xVelocity);
            default:
        }

        if (spd <= intAbs(player.yVelocity)) {
            sensors[0].collided = false;
            sensors[1].collided = false;
            sensors[2].collided = false;
            sensors[0].xPos = player.xPos + ((collisionLeft + 2) << 16);
            sensors[1].xPos = player.xPos;
            sensors[2].xPos = player.xPos + ((collisionRight - 2) << 16);
            sensors[0].yPos = player.yPos + (collisionBottom << 16);
            sensors[1].yPos = sensors[0].yPos;
            sensors[2].yPos = sensors[0].yPos;
            if (player.yVelocity > -1) {
                for (i in 0...3) {
                    if (sensors[i].xPos > left && sensors[i].xPos < right && sensors[i].yPos >= top && player.yPos - player.yVelocity < top) {
                        sensors[i].collided = true;
                        player.flailing[i] = 1;
                    }
                }
            }
            if (sensors[2].collided || sensors[1].collided || sensors[0].collided) {
                if (player.gravity == 0 && (player.collisionMode == CMODE_RWALL || player.collisionMode == CMODE_LWALL)) {
                    player.xVelocity = 0;
                    player.speed = 0;
                }
                player.yPos = top - (collisionBottom << 16);
                player.gravity = 0;
                player.yVelocity = 0;
                player.angle = 0;
                player.rotation = 0;
                player.collisionMode = CMODE_FLOOR;
                checkResult = 1;
            } else {
                sensors[0].collided = false;
                sensors[1].collided = false;
                sensors[0].xPos = player.xPos + ((collisionLeft + 2) << 16);
                sensors[1].xPos = player.xPos + ((collisionRight - 2) << 16);
                sensors[0].yPos = player.yPos + (collisionTop << 16);
                sensors[1].yPos = sensors[0].yPos;
                for (i in 0...2) {
                    if (sensors[i].xPos > left && sensors[i].xPos < right && sensors[i].yPos <= bottom && player.yPos - player.yVelocity > bottom) {
                        sensors[i].collided = true;
                    }
                }
                if (sensors[1].collided || sensors[0].collided) {
                    if (player.gravity == 1) {
                        player.yPos = bottom - (collisionTop << 16);
                    }
                    if (player.yVelocity < 1)
                        player.yVelocity = 0;
                    checkResult = 4;
                } else {
                    sensors[0].collided = false;
                    sensors[1].collided = false;
                    sensors[0].xPos = player.xPos + (collisionRight << 16);
                    sensors[1].xPos = sensors[0].xPos;
                    sensors[0].yPos = player.yPos - 0x20000;
                    sensors[1].yPos = player.yPos + 0x80000;
                    for (i in 0...2) {
                        if (sensors[i].xPos >= left && player.xPos - player.xVelocity < left && sensors[1].yPos > top && sensors[0].yPos < bottom) {
                            sensors[i].collided = true;
                        }
                    }
                    if (sensors[1].collided || sensors[0].collided) {
                        player.xPos = left - (collisionRight << 16);
                        if (player.xVelocity > 0) {
                            if (player.direction == 0)
                                player.pushing = 2;
                            player.xVelocity = 0;
                            player.speed = 0;
                        }
                        checkResult = 2;
                    } else {
                        sensors[0].collided = false;
                        sensors[1].collided = false;
                        sensors[0].xPos = player.xPos + (collisionLeft << 16);
                        sensors[1].xPos = sensors[0].xPos;
                        sensors[0].yPos = player.yPos - 0x20000;
                        sensors[1].yPos = player.yPos + 0x80000;
                        for (i in 0...2) {
                            if (sensors[i].xPos <= right && player.xPos - player.xVelocity > right && sensors[1].yPos > top && sensors[0].yPos < bottom) {
                                sensors[i].collided = true;
                            }
                        }
                        if (sensors[1].collided || sensors[0].collided) {
                            player.xPos = right - (collisionLeft << 16);
                            if (player.xVelocity < 0) {
                                if (player.direction == 1)
                                    player.pushing = 2;
                                player.xVelocity = 0;
                                player.speed = 0;
                            }
                            checkResult = 3;
                        }
                    }
                }
            }
        } else {
            sensors[0].collided = false;
            sensors[1].collided = false;
            sensors[0].xPos = player.xPos + (collisionRight << 16);
            sensors[1].xPos = sensors[0].xPos;
            sensors[0].yPos = player.yPos - 0x20000;
            sensors[1].yPos = player.yPos + 0x80000;
            for (i in 0...2) {
                if (sensors[i].xPos >= left && player.xPos - player.xVelocity < left && sensors[1].yPos > top && sensors[0].yPos < bottom) {
                    sensors[i].collided = true;
                }
            }
            if (sensors[1].collided || sensors[0].collided) {
                player.xPos = left - (collisionRight << 16);
                if (player.xVelocity > 0) {
                    if (player.direction == 0) {
                        player.pushing = 2;
                    }
                    player.xVelocity = 0;
                    player.speed = 0;
                }
                checkResult = 2;
            } else {
                sensors[0].collided = false;
                sensors[1].collided = false;
                sensors[0].xPos = player.xPos + (collisionLeft << 16);
                sensors[1].xPos = sensors[0].xPos;
                sensors[0].yPos = player.yPos - 0x20000;
                sensors[1].yPos = player.yPos + 0x80000;
                for (i in 0...2) {
                    if (sensors[i].xPos <= right && player.xPos - player.xVelocity > right && sensors[1].yPos > top && sensors[0].yPos < bottom) {
                        sensors[i].collided = true;
                    }
                }
                if (sensors[1].collided || sensors[0].collided) {
                    player.xPos = right - (collisionLeft << 16);
                    if (player.xVelocity < 0) {
                        if (player.direction == 1) {
                            player.pushing = 2;
                        }
                        player.xVelocity = 0;
                        player.speed = 0;
                    }
                    checkResult = 3;
                } else {
                    sensors[0].collided = false;
                    sensors[1].collided = false;
                    sensors[2].collided = false;
                    sensors[0].xPos = player.xPos + ((collisionLeft + 2) << 16);
                    sensors[1].xPos = player.xPos;
                    sensors[2].xPos = player.xPos + ((collisionRight - 2) << 16);
                    sensors[0].yPos = player.yPos + (collisionBottom << 16);
                    sensors[1].yPos = sensors[0].yPos;
                    sensors[2].yPos = sensors[0].yPos;
                    if (player.yVelocity > -1) {
                        for (i in 0...3) {
                            if (sensors[i].xPos > left && sensors[i].xPos < right && sensors[i].yPos >= top && player.yPos - player.yVelocity < top) {
                                sensors[i].collided = true;
                                player.flailing[i] = 1;
                            }
                        }
                    }
                    if (sensors[2].collided || sensors[1].collided || sensors[0].collided) {
                        if (player.gravity == 0 && (player.collisionMode == CMODE_RWALL || player.collisionMode == CMODE_LWALL)) {
                            player.xVelocity = 0;
                            player.speed = 0;
                        }
                        player.yPos = top - (collisionBottom << 16);
                        player.gravity = 0;
                        player.yVelocity = 0;
                        player.angle = 0;
                        player.rotation = 0;
                        player.collisionMode = CMODE_FLOOR;
                        checkResult = 1;
                    } else {
                        sensors[0].collided = false;
                        sensors[1].collided = false;
                        sensors[0].xPos = player.xPos + ((collisionLeft + 2) << 16);
                        sensors[1].xPos = player.xPos + ((collisionRight - 2) << 16);
                        sensors[0].yPos = player.yPos + (collisionTop << 16);
                        sensors[1].yPos = sensors[0].yPos;
                        for (i in 0...2) {
                            if (sensors[i].xPos > left && sensors[i].xPos < right && sensors[i].yPos <= bottom && player.yPos - player.yVelocity > bottom) {
                                sensors[i].collided = true;
                            }
                        }
                        if (sensors[1].collided || sensors[0].collided) {
                            if (player.gravity == 1) {
                                player.yPos = bottom - (collisionTop << 16);
                            }
                            if (player.yVelocity < 1)
                                player.yVelocity = 0;
                            checkResult = 4;
                        }
                    }
                }
            }
        }
        Script.scriptEng.checkResult = checkResult;
    }

    public static function platformCollision(left:Int, top:Int, right:Int, bottom:Int):Void {
        var player = PlayerManager.playerList[PlayerManager.playerNo];
        var script = PlayerManager.playerScriptList[PlayerManager.playerNo];
        var cbox = getPlayerCBox(script);

        collisionLeft = cbox.left[0];
        collisionTop = cbox.top[0];
        collisionRight = cbox.right[0];
        collisionBottom = cbox.bottom[0];
        sensors[0].collided = false;
        sensors[1].collided = false;
        sensors[2].collided = false;
        sensors[0].xPos = player.xPos + ((collisionLeft + 1) << 16);
        sensors[1].xPos = player.xPos;
        sensors[2].xPos = player.xPos + (collisionRight << 16);
        sensors[0].yPos = player.yPos + (collisionBottom << 16);
        sensors[1].yPos = sensors[0].yPos;
        sensors[2].yPos = sensors[0].yPos;
        checkResult = 0;
        for (i in 0...3) {
            if (sensors[i].xPos > left && sensors[i].xPos < right && sensors[i].yPos > top - 2 && sensors[i].yPos < bottom && player.yVelocity >= 0) {
                sensors[i].collided = true;
                player.flailing[i] = 1;
            }
        }

        if (!sensors[0].collided && !sensors[1].collided && !sensors[2].collided) {
            Script.scriptEng.checkResult = checkResult;
            return;
        }
        if (player.gravity == 0 && (player.collisionMode == CMODE_RWALL || player.collisionMode == CMODE_LWALL)) {
            player.xVelocity = 0;
            player.speed = 0;
        }
        player.yPos = top - (collisionBottom << 16);
        player.gravity = 0;
        player.yVelocity = 0;
        player.angle = 0;
        player.rotation = 0;
        player.collisionMode = CMODE_FLOOR;
        checkResult = 1;
        Script.scriptEng.checkResult = checkResult;
    }

    public static function objectFloorCollision(xOffset:Int, yOffset:Int, cPath:Int):Void {
        checkResult = 0;
        var entity = Object.objectEntityList[Object.objectLoop];
        var xp = (entity.xPos >> 16) + xOffset;
        var yp = (entity.yPos >> 16) + yOffset;
        if (xp > 0 && xp < Scene.stageLayouts[0].xsize << 7 && yp > 0 && yp < Scene.stageLayouts[0].ysize << 7) {
            var chunkX = xp >> 7;
            var tileX = (xp & 0x7F) >> 4;
            var chunkY = yp >> 7;
            var tileY = (yp & 0x7F) >> 4;
            var chunk = (Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6) + tileX + (tileY << 3);
            var tileIndex = Scene.stageTiles.tileIndex[chunk];
            if (Scene.stageTiles.collisionFlags[cPath][chunk] != SOLID_LRB && Scene.stageTiles.collisionFlags[cPath][chunk] != SOLID_NONE) {
                var c = 0;
                switch (Scene.stageTiles.direction[chunk]) {
                    case 0:
                        c = (xp & 15) + (tileIndex << 4);
                        if ((yp & 15) > Scene.tileCollisions[cPath].floorMasks[c]) {
                            yp = Scene.tileCollisions[cPath].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                            checkResult = 1;
                        }
                    case 1:
                        c = 15 - (xp & 15) + (tileIndex << 4);
                        if ((yp & 15) > Scene.tileCollisions[cPath].floorMasks[c]) {
                            yp = Scene.tileCollisions[cPath].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                            checkResult = 1;
                        }
                    case 2:
                        c = (xp & 15) + (tileIndex << 4);
                        if ((yp & 15) > 15 - Scene.tileCollisions[cPath].roofMasks[c]) {
                            yp = 15 - Scene.tileCollisions[cPath].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                            checkResult = 1;
                        }
                    case 3:
                        c = 15 - (xp & 15) + (tileIndex << 4);
                        if ((yp & 15) > 15 - Scene.tileCollisions[cPath].roofMasks[c]) {
                            yp = 15 - Scene.tileCollisions[cPath].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                            checkResult = 1;
                        }
                    default:
                }
            }
            if (checkResult != 0) {
                entity.yPos = (yp - yOffset) << 16;
            }
        }
        Script.scriptEng.checkResult = checkResult;
    }

    public static function objectFloorGrip(xOffset:Int, yOffset:Int, cPath:Int):Void {
        checkResult = 0;
        var entity = Object.objectEntityList[Object.objectLoop];
        var xp = (entity.xPos >> 16) + xOffset;
        var yp = (entity.yPos >> 16) + yOffset;
        var origY = yp;
        yp -= 16;
        for (iter in 0...3) {
            if (xp > 0 && xp < Scene.stageLayouts[0].xsize << 7 && yp > 0 && yp < Scene.stageLayouts[0].ysize << 7 && checkResult == 0) {
                var chunkX = xp >> 7;
                var tileX = (xp & 0x7F) >> 4;
                var chunkY = yp >> 7;
                var tileY = (yp & 0x7F) >> 4;
                var chunk = (Scene.stageLayouts[0].tiles[chunkX + (chunkY << 8)] << 6) + tileX + (tileY << 3);
                var tileIndex = Scene.stageTiles.tileIndex[chunk];
                if (Scene.stageTiles.collisionFlags[cPath][chunk] != SOLID_LRB && Scene.stageTiles.collisionFlags[cPath][chunk] != SOLID_NONE) {
                    var c = 0;
                    switch (Scene.stageTiles.direction[chunk]) {
                        case 0:
                            c = (xp & 15) + (tileIndex << 4);
                            if (Scene.tileCollisions[cPath].floorMasks[c] < 64) {
                                entity.yPos = Scene.tileCollisions[cPath].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                checkResult = 1;
                            }
                        case 1:
                            c = 15 - (xp & 15) + (tileIndex << 4);
                            if (Scene.tileCollisions[cPath].floorMasks[c] < 64) {
                                entity.yPos = Scene.tileCollisions[cPath].floorMasks[c] + (chunkY << 7) + (tileY << 4);
                                checkResult = 1;
                            }
                        case 2:
                            c = (xp & 15) + (tileIndex << 4);
                            if (Scene.tileCollisions[cPath].roofMasks[c] > -64) {
                                entity.yPos = 15 - Scene.tileCollisions[cPath].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                checkResult = 1;
                            }
                        case 3:
                            c = 15 - (xp & 15) + (tileIndex << 4);
                            if (Scene.tileCollisions[cPath].roofMasks[c] > -64) {
                                entity.yPos = 15 - Scene.tileCollisions[cPath].roofMasks[c] + (chunkY << 7) + (tileY << 4);
                                checkResult = 1;
                            }
                        default:
                    }
                }
            }
            yp += 16;
        }
        if (checkResult != 0) {
            if (intAbs(entity.yPos - origY) < 16) {
                entity.yPos = (entity.yPos - yOffset) << 16;
            } else {
                entity.yPos = (origY - yOffset) << 16;
                checkResult = 0;
            }
        }
        Script.scriptEng.checkResult = checkResult;
    }
}