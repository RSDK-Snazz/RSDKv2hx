package rsdk.scene;

import rsdk.graphics.Animation;
import rsdk.graphics.Animation.SpriteAnimation;
import rsdk.input.Input;
import rsdk.core.RetroMath;
import rsdk.core.Reader;
import rsdk.core.Reader.FileInfo;
import rsdk.core.RetroString;
import rsdk.scene.Collision.CollisionModes;

using rsdk.scene.Collision.CollisionModes;

enum abstract PlayerAni(Int) to Int {
    var ANI_STOPPED = 0;
    var ANI_WAITING = 1;
    var ANI_BORED = 2;
    var ANI_LOOKINGUP = 3;
    var ANI_LOOKINGDOWN = 4;
    var ANI_WALKING = 5;
    var ANI_RUNNING = 6;
    var ANI_SKIDDING = 7;
    var ANI_PEELOUT = 8;
    var ANI_SPINDASH = 9;
    var ANI_JUMPING = 10;
    var ANI_BOUNCING = 11;
    var ANI_HURT = 12;
    var ANI_DYING = 13;
    var ANI_DROWNING = 14;
    var ANI_LIFEICON = 15;
    var ANI_FANROTATE = 16;
    var ANI_BREATHING = 17;
    var ANI_PUSHING = 18;
    var ANI_FLAILINGLEFT = 19;
    var ANI_FLAILINGRIGHT = 20;
    var ANI_SLIDING = 21;
    var ANI_FINISHPOSE = 23;
    var ANI_CORKSCREW = 34;
    var ANI_HANGING = 43;
}

enum abstract PlayerControlModes(Int) to Int {
    var CONTROLMODE_NONE = -1;
    var CONTROLMODE_NORMAL = 0;
    var CONTROLMODE_SIDEKICK = 1;
}


class PlayerMovementStats {
    public var topSpeed:Int = 0;
    public var acceleration:Int = 0;
    public var deceleration:Int = 0;
    public var airAcceleration:Int = 0;
    public var airDeceleration:Int = 0;
    public var gravityStrength:Int = 0;
    public var jumpStrength:Int = 0;
    public var rollingAcceleration:Int = 0;
    public var rollingDeceleration:Int = 0;

    public function new() {}
}

class Player {
    public var xPos:Int = 0;
    public var yPos:Int = 0;
    public var xVelocity:Int = 0;
    public var yVelocity:Int = 0;
    public var speed:Int = 0;
    public var screenXPos:Int = 0;
    public var screenYPos:Int = 0;
    public var angle:Int = 0;
    public var rotation:Int = 0;
    public var timer:Int = 0;
    public var type:Int = 0;
    public var state:Int = 0;
    public var collisionMode:Int = 0;
    public var animationTimer:Int = 0;
    public var animation:Int = 0;
    public var animationSpeed:Int = 0;
    public var prevAnimation:Int = 0;
    public var frame:Int = 0;
    public var direction:Int = 0;
    public var skidding:Int = 0;
    public var pushing:Int = 0;
    public var collisionPlane:Int = 0;
    public var controlMode:Int = 0;
    public var frictionLoss:Int = 0;
    public var lookPos:Int = 0;
    public var stats:PlayerMovementStats = new PlayerMovementStats();
    public var visible:Int = 1;
    public var tileCollisions:Int = 1;
    public var objectInteraction:Int = 1;
    public var left:Int = 0;
    public var right:Int = 0;
    public var up:Int = 0;
    public var down:Int = 0;
    public var jumpPress:Int = 0;
    public var jumpHold:Int = 0;
    public var followPlayer1:Int = 0;
    public var trackScroll:Int = 0;
    public var gravity:Int = 0;
    public var water:Int = 0;
    public var flailing:Array<Int> = [0, 0, 0];
    public var runningSpeed:Int = 0;
    public var walkingSpeed:Int = 0;
    public var jumpingSpeed:Int = 0;

    public function new() {}
}

class PlayerScript {
    public var scriptPath:Array<Int> = [for (i in 0...64) 0];
    public var scriptCodePtr_PlayerMain:Int = 0;
    public var jumpTablePtr_PlayerMain:Int = 0;
    public var scriptCodePtr_PlayerState:Array<Int> = [for (i in 0...256) 0];
    public var jumpTablePtr_PlayerState:Array<Int> = [for (i in 0...256) 0];
    public var animations:Array<SpriteAnimation> = [for (i in 0...64) new SpriteAnimation()];
    public var startWalkSpeed:Int = 0;
    public var startRunSpeed:Int = 0;
    public var startJumpSpeed:Int = 0;

    public function new() {}
}

class PlayerManager {
    public static inline var PLAYER_COUNT:Int = 2;

    public static inline var ANI_STOPPED:Int = 0;
    public static inline var ANI_WAITING:Int = 1;
    public static inline var ANI_BORED:Int = 2;
    public static inline var ANI_LOOKINGUP:Int = 3;
    public static inline var ANI_LOOKINGDOWN:Int = 4;
    public static inline var ANI_WALKING:Int = 5;
    public static inline var ANI_RUNNING:Int = 6;
    public static inline var ANI_SKIDDING:Int = 7;
    public static inline var ANI_PEELOUT:Int = 8;
    public static inline var ANI_SPINDASH:Int = 9;
    public static inline var ANI_JUMPING:Int = 10;
    public static inline var ANI_BOUNCING:Int = 11;
    public static inline var ANI_HURT:Int = 12;
    public static inline var ANI_DYING:Int = 13;
    public static inline var ANI_DROWNING:Int = 14;
    public static inline var ANI_LIFEICON:Int = 15;
    public static inline var ANI_FANROTATE:Int = 16;
    public static inline var ANI_BREATHING:Int = 17;
    public static inline var ANI_PUSHING:Int = 18;
    public static inline var ANI_FLAILINGLEFT:Int = 19;
    public static inline var ANI_FLAILINGRIGHT:Int = 20;
    public static inline var ANI_SLIDING:Int = 21;
    public static inline var ANI_FINISHPOSE:Int = 23;
    public static inline var ANI_CORKSCREW:Int = 34;
    public static inline var ANI_HANGING:Int = 43;

    public static var playerList:Array<Player> = [for (i in 0...PLAYER_COUNT) new Player()];
    public static var playerScriptList:Array<PlayerScript> = [for (i in 0...PLAYER_COUNT) new PlayerScript()];
    public static var playerNo:Int = 0;
    public static var activePlayerCount:Int = 1;

    public static var delayUp:Int = 0;
    public static var delayDown:Int = 0;
    public static var delayLeft:Int = 0;
    public static var delayRight:Int = 0;
    public static var delayJumpPress:Int = 0;
    public static var delayJumpHold:Int = 0;

    public static function loadPlayerFromList(characterID:Int, playerID:Int):Void {
        var info = new FileInfo();
        var strBuf:Array<Int> = [for (i in 0...0x100) 0];
        if (Reader.loadFile("Data/Game/GameConfig.bin", info)) {
            var strLen = Reader.fileReadByte();
            for (i in 0...strLen) Reader.fileReadByte();

            strLen = Reader.fileReadByte();
            for (i in 0...strLen) Reader.fileReadByte();

            strLen = Reader.fileReadByte();
            for (i in 0...strLen) Reader.fileReadByte();

            var count = Reader.fileReadByte();
            for (s in 0...count) {
                strLen = Reader.fileReadByte();
                for (i in 0...strLen) Reader.fileReadByte();
            }

            count = Reader.fileReadByte();
            for (v in 0...count) {
                strLen = Reader.fileReadByte();
                for (i in 0...strLen) Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
            }

            count = Reader.fileReadByte();
            for (s in 0...count) {
                strLen = Reader.fileReadByte();
                for (i in 0...strLen) Reader.fileReadByte();
            }

            count = Reader.fileReadByte();
            for (p in 0...count) {
                strLen = Reader.fileReadByte();
                for (i in 0...strLen) strBuf[i] = Reader.fileReadByte();
                strBuf[strLen] = 0;

                var scriptLen = Reader.fileReadByte();
                for (i in 0...scriptLen) playerScriptList[p].scriptPath[i] = Reader.fileReadByte();
                playerScriptList[p].scriptPath[scriptLen] = 0;

                if (characterID == p) {
                    Reader.getFileInfo(info);
                    Reader.closeFile();
                    Animation.loadPlayerAnimation(RetroString.arrayToString(strBuf), playerID);
                    Reader.setFileInfo(info);
                }

                strLen = Reader.fileReadByte();
                for (i in 0...strLen) Reader.fileReadByte();
            }
            Reader.closeFile();
        }
    }

    static var wasJumping:Bool = false;
    public static function processPlayerAnimation(player:Player):Void {
        var script = playerScriptList[player.type];
        wasJumping = (player.animation == ANI_JUMPING);
        if (player.gravity == 0) {
            var speed = (Std.int(player.jumpingSpeed * intAbs(player.speed) / 6) >> 16) + 48;
            if (speed > 0xF0) speed = 0xF0;
            script.animations[ANI_JUMPING].speed = speed;

            switch (player.animation) {
                case ANI_WALKING:
                    script.animations[player.animation].speed = (Std.int(player.walkingSpeed * intAbs(player.speed) / 6) >> 16) + 20;
                case ANI_RUNNING:
                    speed = Std.int(player.runningSpeed * intAbs(player.speed) / 6) >> 16;
                    if (speed > 0xF0) speed = 0xF0;
                    script.animations[player.animation].speed = speed;
                case ANI_PEELOUT:
                    speed = Std.int(player.runningSpeed * intAbs(player.speed) / 6) >> 16;
                    if (speed > 0xF0) speed = 0xF0;
                    script.animations[player.animation].speed = speed;
                default:
            }
        }

        if (player.animationSpeed != 0)
            player.animationTimer += player.animationSpeed;
        else if (script.animations[player.animation] != null)
            player.animationTimer += script.animations[player.animation].speed;

        if (player.animation != player.prevAnimation) {
            var cbox0 = Animation.playerCBoxes[0].bottom[0];
            var cbox1 = Animation.playerCBoxes[1].bottom[0];
            var diff = cbox0 - cbox1;
            if (player.animation == ANI_JUMPING)
                player.yPos += diff << 16;
            if (player.prevAnimation == ANI_JUMPING)
                player.yPos -= diff << 16;
            player.prevAnimation = player.animation;
            player.frame = 0;
            player.animationTimer = 0;
        }

        if (player.animationTimer >= 0xF0) {
            player.animationTimer -= 0xF0;
            ++player.frame;
        }

        if (script.animations[player.animation] != null && player.frame >= script.animations[player.animation].frameCount) {
            player.frame = script.animations[player.animation].loopPoint;
        }
    }

    static inline function intAbs(v:Int):Int { return v < 0 ? -v : v; }

    public static function processPlayerAnimationChange(player:Player):Void {
        if (player.animation != player.prevAnimation) {
            var cbox0Bottom = Animation.playerCBoxes[0].bottom[0];
            var cbox1Bottom = Animation.playerCBoxes[1].bottom[0];
            var diff = cbox0Bottom - cbox1Bottom;
            player.prevAnimation = player.animation;
            player.frame = 0;
            player.animationTimer = 0;
        }
    }

    public static function processPlayerControl(player:Player):Void {
        if (player.controlMode == CONTROLMODE_NONE) {
            delayUp <<= 1;
            delayUp |= player.up;
            delayDown <<= 1;
            delayDown |= player.down;
            delayLeft <<= 1;
            delayLeft |= player.left;
            delayRight <<= 1;
            delayRight |= player.right;
            delayJumpPress <<= 1;
            delayJumpPress |= player.jumpPress;
            delayJumpHold <<= 1;
            delayJumpHold |= player.jumpHold;
        } else if (player.controlMode == CONTROLMODE_SIDEKICK) {
            player.up = delayUp >> 15;
            player.down = delayDown >> 15;
            player.left = delayLeft >> 15;
            player.right = delayRight >> 15;
            player.jumpPress = delayJumpPress >> 15;
            player.jumpHold = delayJumpHold >> 15;
        } else if (player.controlMode == CONTROLMODE_NORMAL) {
            player.up = Input.gKeyDown.up;
            player.down = Input.gKeyDown.down;
            if (Input.gKeyDown.left == 0 || Input.gKeyDown.right == 0) {
                player.left = Input.gKeyDown.left;
                player.right = Input.gKeyDown.right;
            } else {
                player.left = 0;
                player.right = 0;
            }
            player.jumpHold = (Input.gKeyDown.C != 0 || Input.gKeyDown.B != 0 || Input.gKeyDown.A != 0) ? 1 : 0;
            player.jumpPress = (Input.gKeyPress.C != 0 || Input.gKeyPress.B != 0 || Input.gKeyPress.A != 0) ? 1 : 0;
            delayUp <<= 1;
            delayUp |= player.up;
            delayDown <<= 1;
            delayDown |= player.down;
            delayLeft <<= 1;
            delayLeft |= player.left;
            delayRight <<= 1;
            delayRight |= player.right;
            delayJumpPress <<= 1;
            delayJumpPress |= player.jumpPress;
            delayJumpHold <<= 1;
            delayJumpHold |= player.jumpHold;
        }
    }

    public static function setMovementStats(stats:PlayerMovementStats):Void {
        stats.topSpeed = 0x60000;
        stats.acceleration = 0xC00;
        stats.deceleration = 0xC00;
        stats.airAcceleration = 0x1800;
        stats.airDeceleration = 0x600;
        stats.gravityStrength = 0x3800;
        stats.jumpStrength = 0x68000;
        stats.rollingDeceleration = 0x2000;
    }

    public static function processDefaultAirMovement(player:Player):Void {
        if (player.speed <= -player.stats.topSpeed) {
            if (player.left != 0)
                player.direction = 1;
        } else if (player.left != 0) {
            player.speed -= player.stats.airAcceleration;
            player.direction = 1;
        }
        if (player.speed >= player.stats.topSpeed) {
            if (player.right != 0)
                player.direction = 0;
        } else if (player.right != 0) {
            player.speed += player.stats.airAcceleration;
            player.direction = 0;
        }
        if (player.yVelocity > -0x40001 && player.yVelocity < 1)
            player.speed -= player.speed >> 5;
    }

    public static function processDefaultGravityFalse(player:Player):Void {
        player.trackScroll = 0;
        player.xVelocity = (player.speed * RetroMath.cos256(player.angle)) >> 8;
        player.yVelocity = (player.speed * RetroMath.sin256(player.angle)) >> 8;
    }

    public static function processDefaultGravityTrue(player:Player):Void {
        player.trackScroll = 1;
        player.yVelocity += player.stats.gravityStrength;
        if (player.yVelocity >= -0x33CB0) {
            player.timer = 0;
        } else if (player.jumpHold == 0 && player.timer > 0) {
            player.timer = 0;
            player.yVelocity = -0x3C800;
            player.speed -= player.speed >> 5;
        }
        player.xVelocity = player.speed;
        if (player.rotation <= 0 || player.rotation >= 128) {
            if (player.rotation > 127 && player.rotation < 256) {
                player.rotation += 2;
                if (player.rotation > 255) {
                    player.rotation = 0;
                }
            }
        } else {
            player.rotation -= 2;
            if (player.rotation < 1)
                player.rotation = 0;
        }
    }

    public static function processDefaultGroundMovement(player:Player):Void {
        if (player.frictionLoss <= 0) {
            if (player.left != 0 && player.speed > -player.stats.topSpeed) {
                if (player.speed <= 0) {
                    player.speed -= player.stats.acceleration;
                    player.skidding = 0;
                } else {
                    if (player.speed > 0x40000)
                        player.skidding = 16;
                    if (player.speed >= 0x8000) {
                        player.speed -= 0x8000;
                    } else {
                        player.speed = -0x8000;
                        player.skidding = 0;
                    }
                }
            }
            if (player.right != 0 && player.speed < player.stats.topSpeed) {
                if (player.speed >= 0) {
                    player.speed += player.stats.acceleration;
                    player.skidding = 0;
                } else {
                    if (player.speed < -0x40000)
                        player.skidding = 16;
                    if (player.speed <= -0x8000) {
                        player.speed += 0x8000;
                    } else {
                        player.speed = 0x8000;
                        player.skidding = 0;
                    }
                }
            }

            if (player.left != 0 && player.speed <= 0)
                player.direction = 1;
            if (player.right != 0 && player.speed >= 0)
                player.direction = 0;

            if (player.left != 0 || player.right != 0) {
                switch (player.collisionMode) {
                    case CMODE_FLOOR: player.speed += RetroMath.sin256(player.angle) << 13 >> 8;
                    case CMODE_LWALL:
                        if (player.angle >= 176) {
                            player.speed += (RetroMath.sin256(player.angle) << 13 >> 8);
                        } else {
                            if (player.speed < -0x60000 || player.speed > 0x60000)
                                player.speed += RetroMath.sin256(player.angle) << 13 >> 8;
                            else
                                player.speed += 0x1400 * RetroMath.sin256(player.angle) >> 8;
                        }
                    case CMODE_ROOF:
                        if (player.speed < -0x60000 || player.speed > 0x60000)
                            player.speed += RetroMath.sin256(player.angle) << 13 >> 8;
                        else
                            player.speed += 0x1400 * RetroMath.sin256(player.angle) >> 8;
                    case CMODE_RWALL:
                        if (player.angle <= 80) {
                            player.speed += RetroMath.sin256(player.angle) << 13 >> 8;
                        } else {
                            if (player.speed < -0x60000 || player.speed > 0x60000)
                                player.speed += RetroMath.sin256(player.angle) << 13 >> 8;
                            else
                                player.speed += 0x1400 * RetroMath.sin256(player.angle) >> 8;
                        }
                    default:
                }

                if (player.angle > 192) {
                    if (player.angle < 226 && player.left == 0) {
                        if (player.right != 0 && player.speed < 0x20000) {
                            if (player.speed > -0x60000)
                                player.frictionLoss = 30;
                        }
                    }
                }
                if (player.angle > 30) {
                    if (player.angle < 64 && player.left != 0) {
                        if (player.right == 0 && player.speed > -0x20000) {
                            if (player.speed < 0x60000)
                                player.frictionLoss = 30;
                        }
                    }
                }
            } else {
                if (player.speed < 0) {
                    player.speed += player.stats.deceleration;
                    if (player.speed > 0)
                        player.speed = 0;
                }
                if (player.speed > 0) {
                    player.speed -= player.stats.deceleration;
                    if (player.speed < 0)
                        player.speed = 0;
                }
                if (player.speed < -0x4000 || player.speed > 0x4000)
                    player.speed += RetroMath.sin256(player.angle) << 13 >> 8;
                if ((player.angle > 30 && player.angle < 64) || (player.angle > 192 && player.angle < 226)) {
                    if (player.speed > -0x10000 && player.speed < 0x10000)
                        player.frictionLoss = 30;
                }
            }
        } else {
            --player.frictionLoss;
            player.speed = (RetroMath.sin256(player.angle) << 13 >> 8) + player.speed;
        }
    }

    static var debugJumpCount:Int = 0;
    public static function processDefaultJumpAction(player:Player):Void {
        player.frictionLoss = 0;
        player.gravity = 1;
        player.xVelocity = (player.speed * RetroMath.cos256(player.angle) + player.stats.jumpStrength * RetroMath.sin256(player.angle)) >> 8;
        player.yVelocity = (player.speed * RetroMath.sin256(player.angle) + -player.stats.jumpStrength * RetroMath.cos256(player.angle)) >> 8;
        player.speed = player.xVelocity;
        player.trackScroll = 1;
        player.animation = ANI_JUMPING;
        player.angle = 0;
        player.collisionMode = CMODE_FLOOR;
        player.timer = 1;
    }

    public static function processDefaultRollingMovement(player:Player):Void {
        if (player.right != 0 && player.speed < 0)
            player.speed += player.stats.rollingDeceleration;
        if (player.left != 0 && player.speed > 0)
            player.speed -= player.stats.rollingDeceleration;

        if (player.speed < 0) {
            player.speed += player.stats.airDeceleration;
            if (player.speed > 0)
                player.speed = 0;
        }
        if (player.speed > 0) {
            player.speed -= player.stats.airDeceleration;
            if (player.speed < 0)
                player.speed = 0;
        }
        if ((player.angle < 12 || player.angle > 244) && player.speed == 0)
            player.state = 0;

        if (player.speed <= 0) {
            if (RetroMath.sin256(player.angle) >= 0) {
                player.speed += (player.stats.rollingDeceleration * RetroMath.sin256(player.angle) >> 8);
            } else {
                player.speed += 0x5000 * RetroMath.sin256(player.angle) >> 8;
            }
        } else if (RetroMath.sin256(player.angle) <= 0) {
            player.speed += (player.stats.rollingDeceleration * RetroMath.sin256(player.angle) >> 8);
        } else {
            player.speed += 0x5000 * RetroMath.sin256(player.angle) >> 8;
        }

        if (player.speed > 0x180000)
            player.speed = 0x180000;
    }

    public static function processDebugMode(player:Player):Void {
        if (player.down != 0 || player.up != 0 || player.right != 0 || player.left != 0) {
            if (player.speed < 0x100000) {
                player.speed += 0xC00;
                if (player.speed > 0x100000)
                    player.speed = 0x100000;
            }
        } else {
            player.speed = 0;
        }

        if (Input.gKeyDown.left != 0)
            player.xPos -= player.speed;
        if (Input.gKeyDown.right != 0)
            player.xPos += player.speed;
        if (Input.gKeyDown.up != 0)
            player.yPos -= player.speed;
        if (Input.gKeyDown.down != 0)
            player.yPos += player.speed;
    }

}
