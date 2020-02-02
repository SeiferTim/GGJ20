package;

import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import openfl.display.BitmapData;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.input.actions.FlxAction.FlxActionAnalog;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionManager;
import nape.callbacks.PreCallback;
import nape.callbacks.PreFlag;
import nape.callbacks.InteractionType;
import nape.callbacks.PreListener;
import nape.phys.BodyType;
import flixel.addons.nape.FlxNapeSprite;
import nape.geom.Vec2;
import nape.constraint.DistanceJoint;
import nape.constraint.Constraint;
import nape.phys.Body;
import nape.callbacks.CbType;
import nape.phys.Compound;
import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;

class PlayState extends FlxState
{
    private var frequency:Float = 100.0;
    private var damping:Float = 100.0;

    private final HAND_SPEED:Float = 800;

    private var leftNode:FlxPoint;
    private var rightNode:FlxPoint;

    private var leftHand:HandSegment;
    private var rightHand:HandSegment;

    private var body:FlxNapeSprite;

    private var leftArm:Array<HandSegment>;
    private var rightArm:Array<HandSegment>;

    private var leftHandCompound:Compound;
    private var rightHandCompound:Compound;
    private var bodyCompound:Compound;
    private var pullCompound:Compound;

    private var handType:CbType;
    private var bodyType:CbType;
    private var pullType:CbType;
    private var wallType:CbType;

    private inline static var NUM_ARM:Int = 64;

    private var leftPull:FlxNapeSprite;
    private var rightPull:FlxNapeSprite;

    private var leftAnchor:FlxNapeSprite;
    private var rightAnchor:FlxNapeSprite;

    public static var inputs:FlxActionManager;

    public static var l_up:FlxActionDigital;
    public static var l_down:FlxActionDigital;
    public static var l_left:FlxActionDigital;
    public static var l_right:FlxActionDigital;
    public static var l_close:FlxActionDigital;
    public static var l_open:FlxActionDigital;
    public static var l_move:FlxActionAnalog;

    public static var r_up:FlxActionDigital;
    public static var r_down:FlxActionDigital;
    public static var r_left:FlxActionDigital;
    public static var r_right:FlxActionDigital;
    public static var r_close:FlxActionDigital;
    public static var r_open:FlxActionDigital;
    public static var r_move:FlxActionAnalog;

    private var shipFrames:FlxTypedGroup<ShipFrame>;
    private var shipParts:FlxTypedGroup<ShipPart>;

    private var l_heldPiece:ShipPart = null;
    private var l_heldPos:FlxPoint;

    private var r_heldPiece:ShipPart = null;
    private var r_heldPos:FlxPoint;

    private var score_key:BitmapData;
    private var scorePos:FlxPoint;

    private var scoreText:FlxText;
    private var gameTime:Float;

    private var timerText:FlxText;
    private var maxTime:Float = (.75 * 60 * 1000);

    private var startText:FlxText;
    private var startBack:FlxSprite;

    private var paused:Bool = true;

    private var totalScore:Int = 0;
    private var totalText:FlxText;

    private var scoring:Bool = false;
    private var tmpScore:Int = 0;

    private var minScore:Int = 50;
    private var readyForReplay:Bool = false;

    override public function create():Void
    {
        add(new FlxSprite(0, 0, AssetPaths.SPACEWOW__jpg));

        FlxNapeSpace.init();
        // FlxNapeSpace.createWalls(0, 0, FlxG.width, FlxG.height - 10, 10); // don't think we want walls?
        FlxNapeSpace.space.gravity.setxy(0, 500);

        addInputs();

        shipFrames = new FlxTypedGroup<ShipFrame>();
        shipParts = new FlxTypedGroup<ShipPart>();

        add(shipFrames);
        add(shipParts);

        createBot();

        scoreText = new FlxText(0, 10, 0, "100% / 100%", 26);
        scoreText.alignment = FlxTextAlign.RIGHT;
        scoreText.fieldWidth = scoreText.width;
        scoreText.autoSize = false;
        scoreText.x = FlxG.width - scoreText.width;
        scoreText.text = '0% / $minScore%';
        add(scoreText);

        timerText = new FlxText(10, 10, 0, "", 26);
        add(timerText);

        totalText = new FlxText(10, 0, 0, "0", 26);
        totalText.y = FlxG.height - totalText.height - 10;
        add(totalText);

        startBack = new FlxSprite();
        startBack.makeGraphic(FlxG.width + 50, Std.int(FlxG.height * .2), 0x66000000);
        startBack.x = FlxG.width - 10;
        startBack.screenCenter(FlxAxes.Y);
        add(startBack);

        startText = new FlxText(0, 0, 0, "3", 64);
        startText.screenCenter(FlxAxes.XY);
        startText.scale.set(.01, .01);
        startText.alpha = 0;
        add(startText);

        FlxTween.tween(startBack, {x: (FlxG.width / 2) - (startBack.width / 2)}, .2, {
            type: FlxTweenType.ONESHOT,
            ease: FlxEase.backOut,
            onComplete: function(_)
            {
                FlxTween.tween(startText, {alpha: 1}, .2);
                FlxTween.tween(startText.scale, {x: 1, y: 1}, .4, {
                    type: FlxTweenType.ONESHOT,
                    ease: FlxEase.backOut,
                    onComplete: function(_)
                    {
                        FlxTween.tween(startText, {alpha: 0}, .2, {type: FlxTweenType.ONESHOT, startDelay: .4});
                        FlxTween.tween(startText.scale, {x: 2, y: 2}, .4, {
                            type: FlxTweenType.ONESHOT,
                            startDelay: .2,
                            onComplete: function(_)
                            {
                                startText.scale.set(.01, .01);
                                startText.text = "2";
                                startText.screenCenter(FlxAxes.XY);
                                FlxTween.tween(startText, {alpha: 1}, .2);
                                FlxTween.tween(startText.scale, {x: 1, y: 1}, .4, {
                                    type: FlxTweenType.ONESHOT,
                                    ease: FlxEase.backOut,
                                    onComplete: function(_)
                                    {
                                        FlxTween.tween(startText, {alpha: 0}, .2, {type: FlxTweenType.ONESHOT, startDelay: .4});
                                        FlxTween.tween(startText.scale, {x: 2, y: 2}, .4, {
                                            type: FlxTweenType.ONESHOT,
                                            startDelay: .2,
                                            onComplete: function(_)
                                            {
                                                startText.scale.set(.01, .01);
                                                startText.text = "1";
                                                startText.screenCenter(FlxAxes.XY);
                                                FlxTween.tween(startText, {alpha: 1}, .2);
                                                FlxTween.tween(startText.scale, {x: 1, y: 1}, .4, {
                                                    type: FlxTweenType.ONESHOT,
                                                    ease: FlxEase.backOut,
                                                    onComplete: function(_)
                                                    {
                                                        FlxTween.tween(startText, {alpha: 0}, .2, {type: FlxTweenType.ONESHOT, startDelay: .4});
                                                        FlxTween.tween(startText.scale, {x: 2, y: 2}, .4, {
                                                            type: FlxTweenType.ONESHOT,
                                                            startDelay: .2,
                                                            onComplete: function(_)
                                                            {
                                                                startText.scale.set(.01, .01);
                                                                startText.text = "START!";
                                                                startText.screenCenter(FlxAxes.XY);
                                                                FlxTween.tween(startText, {alpha: 1}, .2);
                                                                FlxTween.tween(startText.scale, {x: 1, y: 1}, .4, {
                                                                    type: FlxTweenType.ONESHOT,
                                                                    ease: FlxEase.backOut,
                                                                    onComplete: function(_)
                                                                    {
                                                                        FlxTween.tween(startText, {alpha: 0}, .2,
                                                                            {type: FlxTweenType.ONESHOT, startDelay: .4});
                                                                        FlxTween.tween(startText.scale, {x: 2, y: 2}, .4, {
                                                                            type: FlxTweenType.ONESHOT,
                                                                            startDelay: .2,
                                                                            onComplete: function(_)
                                                                            {
                                                                                startText.kill();
                                                                                FlxTween.tween(startBack, {x: -startBack.width}, .2, {
                                                                                    type: FlxTweenType.ONESHOT,
                                                                                    ease: FlxEase.backIn,
                                                                                    onComplete: function(_)
                                                                                    {
                                                                                        startBack.kill();
                                                                                        startGame();
                                                                                    }
                                                                                });
                                                                            }
                                                                        });
                                                                    }
                                                                });
                                                            }
                                                        });
                                                    }
                                                });
                                            }
                                        });
                                    }
                                });
                            }
                        });
                    }
                });
            }
        });

        FlxG.sound.playMusic(AssetPaths.Process_boogie__ogg, .5, true);

        super.create();
    }

    private function startGame():Void
    {
        paused = false;
        addShip();
    }

    private function addShip():Void
    {
        gameTime = 0;

        var frame:ShipFrame;
        var part:ShipPart;
        var no:Int = FlxG.random.int(3, 5);
        var X:Int = 0;
        var Y:Int = FlxG.height;
        var height:Int = 0;
        var angle:Int = 0;
        var frameIndex:Int = -1;
        for (i in 0...no)
        {
            frame = shipFrames.recycle(ShipFrame);
            if (frame == null)
                frame = new ShipFrame();

            part = shipParts.recycle(ShipPart);
            if (part == null)
                part = new ShipPart();

            frameIndex = FlxG.random.int(0, frame.animation.frames - 1);
            angle = FlxG.random.int(0, 4) * 90;

            frame.spawn(0, 0, angle, frameIndex);
            part.spawn(FlxG.random.int(Std.int(FlxG.width * .33), Std.int(FlxG.width * .66)), (FlxG.height / 2) + FlxG.random.int(-40, 60), angle, frameIndex,
                i);
            shipFrames.add(frame);
            shipParts.add(part);

            frame.x = X;
            frame.y = 100 - (frame.height / 2);

            X += Std.int(frame.width);

            if (frame.y < Y)
                Y = Std.int(frame.y);
            if (frame.height + frame.y > height)
                height = Std.int(frame.height + frame.y);
        }

        var offX:Int = Std.int((FlxG.width / 2) - (X / 2));

        // Std.int((FlxG.width / 2) - ((X + shipFrames.members[0].width) / 2));
        var tmpP:ShipPart;
        var tmpF:ShipFrame;

        score_key = new BitmapData(X, height, FlxColor.BLACK);

        scorePos = FlxPoint.get(offX, Y);

        for (i in 0...shipFrames.members.length)
        {
            if (!(shipFrames.members[i].alive && shipParts.members[i].alive))
                continue;

            tmpF = shipFrames.members[i];

            tmpP = shipParts.members[i];

            tmpP.drawFrame();
            for (x in 0...tmpP.framePixels.width)
            {
                for (y in 0...tmpP.framePixels.height)
                {
                    if (tmpP.framePixels.getPixel32(x, y) != 0x0)
                    {
                        score_key.setPixel32(Std.int(x + tmpF.x), Std.int(y + tmpF.y - Y), FlxColor.WHITE);
                    }
                }
            }

            tmpF.x += offX;
        }

        FlxG.bitmapLog.add(score_key);
    }

    private function addInputs():Void
    {
        l_up = new FlxActionDigital();
        l_down = new FlxActionDigital();
        l_left = new FlxActionDigital();
        l_right = new FlxActionDigital();
        l_close = new FlxActionDigital();
        l_open = new FlxActionDigital();
        l_move = new FlxActionAnalog();

        r_up = new FlxActionDigital();
        r_down = new FlxActionDigital();
        r_left = new FlxActionDigital();
        r_right = new FlxActionDigital();
        r_close = new FlxActionDigital();
        r_open = new FlxActionDigital();
        r_move = new FlxActionAnalog();

        if (inputs == null)
        {
            inputs = FlxG.inputs.add(new FlxActionManager());
        }
        inputs.addActions([
            l_up, l_down, l_left, l_right, l_close, l_move, r_up, r_down, r_left, r_right, r_close, r_move, l_open, r_open
        ]);

        l_up.addKey(W, PRESSED);
        l_left.addKey(A, PRESSED);
        l_down.addKey(S, PRESSED);
        l_right.addKey(D, PRESSED);

        l_up.addGamepad(DPAD_UP, PRESSED);
        l_left.addGamepad(DPAD_LEFT, PRESSED);
        l_down.addGamepad(DPAD_DOWN, PRESSED);
        l_right.addGamepad(DPAD_RIGHT, PRESSED);

        l_up.addGamepad(LEFT_STICK_DIGITAL_UP, PRESSED);
        l_left.addGamepad(LEFT_STICK_DIGITAL_LEFT, PRESSED);
        l_down.addGamepad(LEFT_STICK_DIGITAL_DOWN, PRESSED);
        l_right.addGamepad(LEFT_STICK_DIGITAL_RIGHT, PRESSED);

        l_close.addKey(C, JUST_PRESSED);
        l_close.addGamepad(LEFT_TRIGGER, JUST_PRESSED);
        l_close.addGamepad(LEFT_TRIGGER_BUTTON, JUST_PRESSED);
        l_close.addGamepad(LEFT_STICK_CLICK, JUST_PRESSED);

        l_open.addKey(C, JUST_RELEASED);
        l_open.addGamepad(LEFT_TRIGGER, JUST_RELEASED);
        l_open.addGamepad(LEFT_TRIGGER_BUTTON, JUST_RELEASED);
        l_open.addGamepad(LEFT_STICK_CLICK, JUST_RELEASED);

        l_move.addGamepad(LEFT_ANALOG_STICK, MOVED, EITHER);

        r_up.addKey(UP, PRESSED);
        r_left.addKey(LEFT, PRESSED);
        r_down.addKey(DOWN, PRESSED);
        r_right.addKey(RIGHT, PRESSED);

        r_up.addGamepad(Y, PRESSED);
        r_left.addGamepad(X, PRESSED);
        r_down.addGamepad(A, PRESSED);
        r_right.addGamepad(B, PRESSED);

        r_up.addGamepad(RIGHT_STICK_DIGITAL_UP, PRESSED);
        r_left.addGamepad(RIGHT_STICK_DIGITAL_LEFT, PRESSED);
        r_down.addGamepad(RIGHT_STICK_DIGITAL_DOWN, PRESSED);
        r_right.addGamepad(RIGHT_STICK_DIGITAL_RIGHT, PRESSED);

        // r_close.addKey(SPACE, PRESSED);
        // r_close.addGamepad(RIGHT_TRIGGER, PRESSED);
        // r_close.addGamepad(RIGHT_TRIGGER_BUTTON, PRESSED);
        // r_close.addGamepad(RIGHT_STICK_CLICK, PRESSED);

        r_close.addKey(SPACE, JUST_PRESSED);
        r_close.addGamepad(RIGHT_TRIGGER, JUST_PRESSED);
        r_close.addGamepad(RIGHT_TRIGGER_BUTTON, JUST_PRESSED);
        r_close.addGamepad(RIGHT_STICK_CLICK, JUST_PRESSED);

        r_open.addKey(SPACE, JUST_RELEASED);
        r_open.addGamepad(RIGHT_TRIGGER, JUST_RELEASED);
        r_open.addGamepad(RIGHT_TRIGGER_BUTTON, JUST_RELEASED);
        r_open.addGamepad(RIGHT_STICK_CLICK, JUST_RELEASED);

        r_move.addGamepad(RIGHT_ANALOG_STICK, MOVED, EITHER);
    }

    private function createBot():Void
    {
        leftNode = FlxPoint.get((FlxG.width * .2), (FlxG.height * .5));
        rightNode = FlxPoint.get((FlxG.width * .8), (FlxG.height * .5));
        leftHandCompound = new Compound();
        rightHandCompound = new Compound();
        bodyCompound = new Compound();
        pullCompound = new Compound();

        leftHandCompound.space = FlxNapeSpace.space;
        rightHandCompound.space = FlxNapeSpace.space;
        bodyCompound.space = FlxNapeSpace.space;
        pullCompound.space = FlxNapeSpace.space;

        handType = new CbType();
        bodyType = new CbType();
        pullType = new CbType();
        wallType = new CbType();

        leftArm = new Array<HandSegment>();
        rightArm = new Array<HandSegment>();
        leftPull = new FlxNapeSprite();
        rightPull = new FlxNapeSprite();

        leftAnchor = new FlxNapeSprite();
        rightAnchor = new FlxNapeSprite();

        body = new FlxNapeSprite();

        body.loadGraphic(AssetPaths.body__png);
        body.createRectangularBody(body.width, body.height, BodyType.DYNAMIC);
        // body.setBodyMaterial(0.2, 1.0, 1.4, 1.0, 0.01);

        body.body.cbTypes.push(bodyType);
        body.body.allowRotation = false;
        body.body.allowMovement = false;
        body.body.position.x = FlxG.width / 2;
        body.body.position.y = FlxG.height - (body.height / 2);
        body.body.compound = bodyCompound;
        add(body);

        leftAnchor.createCircularBody(2, BodyType.DYNAMIC);
        leftAnchor.body.cbTypes.push(bodyType);
        leftAnchor.body.allowMovement = false;
        leftAnchor.body.allowRotation = false;
        leftAnchor.body.position.x = FlxG.width * .33;
        leftAnchor.body.position.y = FlxG.height + 10;
        leftAnchor.body.compound = bodyCompound;
        add(leftAnchor);

        rightAnchor.createCircularBody(2, BodyType.DYNAMIC);
        rightAnchor.body.cbTypes.push(bodyType);
        rightAnchor.body.allowMovement = false;
        rightAnchor.body.allowRotation = false;
        rightAnchor.body.position.x = FlxG.width * .66;
        rightAnchor.body.position.y = FlxG.height + 10;
        rightAnchor.body.compound = bodyCompound;
        add(rightAnchor);

        leftPull.makeGraphic(4, 4, FlxColor.RED);
        leftPull.createCircularBody(4, BodyType.DYNAMIC);
        leftPull.body.cbTypes.push(pullType);
        // add(leftPull);
        leftPull.body.position.x = leftNode.x;
        leftPull.body.position.y = leftNode.y;
        leftPull.body.gravMass = 0;
        leftPull.body.compound = pullCompound;
        leftPull.body.allowMovement = false;

        rightPull.makeGraphic(4, 4, FlxColor.RED);
        rightPull.createCircularBody(4, BodyType.DYNAMIC);
        rightPull.body.cbTypes.push(pullType);
        // add(rightPull);
        rightPull.body.position.x = rightNode.x;
        rightPull.body.position.y = rightNode.y;
        rightPull.body.gravMass = 0;
        rightPull.body.compound = pullCompound;
        rightPull.body.allowMovement = false;

        for (i in 0...NUM_ARM)
        {
            var a:HandSegment = new HandSegment(i == NUM_ARM - 1);
            a.body.cbTypes.push(handType);

            leftArm.push(a);
            add(a);
            a.body.position.x = leftNode.x;
            a.body.position.y = leftNode.y;
            a.body.compound = leftHandCompound;

            var b:HandSegment = new HandSegment(i == NUM_ARM - 1);
            b.body.cbTypes.push(handType);
            rightArm.push(b);
            add(b);
            b.body.position.x = rightNode.x;
            b.body.position.y = rightNode.y;
            b.body.compound = rightHandCompound;
        }

        for (i in 0...NUM_ARM - 1)
        {
            var a1:Body = leftArm[i].body;
            var a2:Body = leftArm[i + 1].body;
            var c:Constraint = new DistanceJoint(a1, a2, Vec2.weak(0, 0), Vec2.weak(0, 0), 4, 7);
            c.damping = damping;

            c.stiff = true; // i + 1 == NUM_ARM - 1;
            c.frequency = frequency;
            c.space = FlxNapeSpace.space;

            a1 = rightArm[i].body;
            a2 = rightArm[i + 1].body;
            c = new DistanceJoint(a1, a2, Vec2.weak(0, 0), Vec2.weak(0, 0), 4, 7);
            c.damping = damping;

            c.stiff = true;
            c.frequency = frequency;
            c.space = FlxNapeSpace.space;
        }

        leftHand = leftArm[NUM_ARM - 1];
        rightHand = rightArm[NUM_ARM - 1];

        var c:Constraint;
        c = new DistanceJoint(leftArm[0].body, leftAnchor.body, Vec2.weak(0, 0), Vec2.weak(0, 0), 0, 0);
        c.damping = damping;
        c.stiff = true;
        c.frequency = frequency;
        c.space = FlxNapeSpace.space;

        c = new DistanceJoint(rightArm[0].body, rightAnchor.body, Vec2.weak(0, 0), Vec2.weak(0, 0), 0, 0);
        c.damping = damping;
        c.stiff = true;
        c.frequency = frequency;
        c.space = FlxNapeSpace.space;

        c = new DistanceJoint(leftHand.body, leftPull.body, Vec2.weak(0, 0), Vec2.weak(0, 0), 0, 20);
        c.damping = damping;
        c.stiff = true;
        c.frequency = 600;
        c.space = FlxNapeSpace.space;

        c = new DistanceJoint(rightHand.body, rightPull.body, Vec2.weak(0, 0), Vec2.weak(0, 0), 0, 20);
        c.damping = damping;
        c.stiff = true;
        c.frequency = 600;
        c.space = FlxNapeSpace.space;

        var listener = new PreListener(InteractionType.COLLISION, bodyType, bodyType, ignoreCollision, 0, true);
        listener.space = FlxNapeSpace.space;

        // listener = new PreListener(InteractionType.COLLISION, pullType, wallType, ignoreCollision, 0, true);
        // listener.space = FlxNapeSpace.space;

        listener = new PreListener(InteractionType.COLLISION, handType, bodyType, ignoreCollision, 0, true);
        listener.space = FlxNapeSpace.space;

        listener = new PreListener(InteractionType.COLLISION, pullType, bodyType, ignoreCollision, 0, true);
        listener.space = FlxNapeSpace.space;

        listener = new PreListener(InteractionType.COLLISION, handType, handType, ignoreCollision, 0, true);
        listener.space = FlxNapeSpace.space;

        listener = new PreListener(InteractionType.COLLISION, handType, pullType, ignoreCollision, 0, true);
        listener.space = FlxNapeSpace.space;
    }

    override public function update(elapsed:Float):Void
    {
        if (!paused)
        {
            doMovement(elapsed);

            updateGameTime(elapsed);
        }
        else if (scoring)
        {
            scoring = false;
            var f:ShipFrame;
            var p:ShipPart;
            for (i in 0...shipParts.members.length)
            {
                p = shipParts.members[i];
                f = shipFrames.members[i];

                FlxTween.tween(p, {y: -100}, .5, {
                    type: FlxTweenType.ONESHOT,
                    ease: FlxEase.backIn,
                    startDelay: .2 * i,
                    onComplete: function(_)
                    {
                        p.kill();
                    }
                });
                FlxTween.tween(f, {alpha: 0}, .1, {
                    type: FlxTweenType.ONESHOT,
                    ease: FlxEase.sineOut,
                    startDelay: 1,
                    onComplete: i != 0 ? null : function(_)
                    {
                        f.kill();
                        var gameOver:Bool = false;
                        if (tmpScore < minScore)
                        {
                            gameOver = true;
                        }

                        totalScore += tmpScore * 77;
                        totalText.text = Std.string(totalScore);
                        if (gameOver)
                        {
                            gameOverStart();
                        }
                        else
                        {
                            shipParts.clear();
                            shipFrames.clear();
                            minScore = FlxMath.minInt(100, minScore + 2);
                            maxTime += 10000;
                            addShip();
                            paused = false;
                        }
                        scoreText.text = '0% / $minScore%';
                    }
                });
            }
        }
        else if (readyForReplay)
        {
            if (FlxG.keys.anyJustPressed([ANY]) || FlxG.gamepads.anyButton())
                FlxG.resetState();
        }

        super.update(elapsed);
    }

    private function gameOverStart():Void
    {
        var gameOverBack:FlxSprite;
        var gameOverText:FlxText;
        var gameOverScore:FlxText;
        var gameOverAgain:FlxText;

        gameOverBack = new FlxSprite();
        gameOverBack.makeGraphic(FlxG.width, FlxG.height, 0x66000000);
        gameOverBack.alpha = 0;
        add(gameOverBack);

        gameOverText = new FlxText(0, 0, 0, "GAME OVER", 48);
        gameOverText.screenCenter(FlxAxes.XY);
        gameOverText.y -= gameOverText.height + 10;
        gameOverText.alpha = 0;
        add(gameOverText);

        gameOverScore = new FlxText(0, 0, 0, 'Score: $totalScore', 26);
        gameOverScore.screenCenter(FlxAxes.X);
        gameOverScore.y = (FlxG.height / 2) + 10;
        gameOverScore.alpha = 0;
        add(gameOverScore);

        gameOverAgain = new FlxText(0, 0, 0, "Press Any Button to Play Again", 26);
        gameOverAgain.screenCenter(FlxAxes.X);
        gameOverAgain.y = FlxG.height - gameOverAgain.height - 10;
        gameOverAgain.alpha = 0;
        add(gameOverAgain);

        FlxTween.tween(gameOverBack, {alpha: 1}, .33, {
            type: FlxTweenType.ONESHOT,
            ease: FlxEase.sineOut,
            onComplete: function(_)
            {
                FlxTween.tween(gameOverText, {alpha: 1}, .2, {
                    type: FlxTweenType.ONESHOT,
                    ease: FlxEase.sineOut,
                    startDelay: .1,
                    onComplete: function(_)
                    {
                        FlxTween.tween(gameOverScore, {alpha: 1}, .2, {
                            type: FlxTweenType.ONESHOT,
                            ease: FlxEase.sineOut,
                            startDelay: .1,
                            onComplete: function(_)
                            {
                                FlxTween.tween(gameOverAgain, {alpha: 1}, .2, {
                                    type: FlxTweenType.ONESHOT,
                                    ease: FlxEase.sineOut,
                                    startDelay: .1,
                                    onComplete: function(_)
                                    {
                                        readyForReplay = true;
                                    }
                                });
                            }
                        });
                    }
                });
            }
        });
    }

    private function updateGameTime(elapsed:Float):Void
    {
        gameTime += elapsed;
        if (gameTime * 1000 >= maxTime)
        {
            gameTime = maxTime;
            paused = true;
            timerText.text = "00:00.0000";
            gameEnd();
        }
        else
        {
            var d = DateTools.parse(maxTime - (gameTime * 1000));
            timerText.text = StringTools.lpad(Std.string(d.minutes), "0", 2)
                + ":"
                + StringTools.lpad(Std.string(d.seconds), "0", 2)
                + "."
                + StringTools.rpad(Std.string(Std.int(d.ms)), "0", 4).substr(0, 4);
        }
    }

    public function gameEnd():Void
    {
        scoring = true;

        leftHand.handState = OPEN;
        if (l_heldPiece != null)
        {
            l_heldPiece.y = FlxMath.bound(l_heldPiece.y, 2, FlxG.height - l_heldPiece.height - 2);
            l_heldPiece.x = FlxMath.bound(l_heldPiece.x, 2, FlxG.width - l_heldPiece.width - 2);
        }
        l_heldPiece = null;

        rightHand.handState = OPEN;
        if (r_heldPiece != null)
        {
            r_heldPiece.y = FlxMath.bound(r_heldPiece.y, 2, FlxG.height - r_heldPiece.height - 2);
            r_heldPiece.x = FlxMath.bound(r_heldPiece.x, 2, FlxG.width - r_heldPiece.width - 2);
        }
        r_heldPiece = null;
        checkScore();
    }

    private function checkScore():Void
    {
        var score:BitmapData = new BitmapData(score_key.width, score_key.height, false, FlxColor.BLACK);
        var part:ShipPart;
        for (i in 0...shipParts.members.length)
        {
            part = shipParts.members[i];
            part.drawFrame();
            for (x in 0...part.framePixels.width)
            {
                if (part.x + x >= scorePos.x && part.x + x <= scorePos.x + score_key.width)
                {
                    for (y in 0...part.framePixels.height)
                    {
                        if (part.y + y >= scorePos.y && part.y + y <= scorePos.y + score_key.height)
                        {
                            if (part.framePixels.getPixel32(x, y) != 0x0)
                            {
                                score.setPixel32(Std.int(part.x + x - scorePos.x), Std.int(part.y + y - scorePos.y), FlxColor.WHITE);
                            }
                        }
                    }
                }
            }
        }

        var score_amount:Int = 0;
        var score_min:Int = 0;
        for (x in 0...score.width)
        {
            for (y in 0...score.height)
            {
                if (score_key.getPixel32(x, y) == FlxColor.WHITE)
                {
                    score_min++;
                    if (score.getPixel32(x, y) == FlxColor.WHITE)
                    {
                        score_amount++;
                    }
                }
            }
        }
        tmpScore = Std.int(100 * (score_amount / score_min));
        scoreText.text = Std.string(tmpScore) + '% / $minScore%';

        FlxG.bitmapLog.add(score);
    }

    private function doMovement(elapsed:Float):Void
    {
        var xChange:Int = 0;
        var yChange:Int = 0;
        var a:Int = 0;

        var highest:Int = -1;
        var dropped:Bool = false;

        if (l_close.triggered)
        {
            leftHand.handState = CLOSED;
            for (i in shipParts)
            {
                if (i.overlaps(leftHand) && i.depth > highest && i != r_heldPiece)
                {
                    if (FlxG.pixelPerfectOverlap(i, leftHand))
                    {
                        l_heldPiece = i;
                        l_heldPos = FlxPoint.get(i.x - leftHand.x, i.y - leftHand.y);
                    }
                }
            }
        }
        else if (l_open.triggered)
        {
            leftHand.handState = OPEN;
            if (l_heldPiece != null)
            {
                dropped = true;
                l_heldPiece.y = FlxMath.bound(l_heldPiece.y, 2, FlxG.height - l_heldPiece.height - 2);
                l_heldPiece.x = FlxMath.bound(l_heldPiece.x, 2, FlxG.width - l_heldPiece.width - 2);
            }
            l_heldPiece = null;
        }

        highest = -1;
        if (r_close.triggered)
        {
            rightHand.handState = CLOSED;
            for (i in shipParts)
            {
                if (i.overlaps(rightHand) && i.depth > highest && i != l_heldPiece)
                {
                    if (FlxG.pixelPerfectOverlap(i, rightHand))
                    {
                        r_heldPiece = i;
                        r_heldPos = FlxPoint.get(i.x - rightHand.x, i.y - rightHand.y);
                    }
                }
            }
        }
        else if (r_open.triggered)
        {
            rightHand.handState = OPEN;
            if (r_heldPiece != null)
            {
                dropped = true;
                r_heldPiece.y = FlxMath.bound(r_heldPiece.y, 2, FlxG.height - r_heldPiece.height - 2);
                r_heldPiece.x = FlxMath.bound(r_heldPiece.x, 2, FlxG.width - r_heldPiece.width - 2);
            }
            r_heldPiece = null;
        }

        if (dropped)
            checkScore();

        if (l_heldPiece != null)
        {
            l_heldPiece.x = leftHand.x + l_heldPos.x;
            l_heldPiece.y = leftHand.y + l_heldPos.y;
        }
        if (r_heldPiece != null)
        {
            r_heldPiece.x = rightHand.x + r_heldPos.x;
            r_heldPiece.y = rightHand.y + r_heldPos.y;
        }

        if (l_left.triggered && !l_right.triggered)
        {
            xChange = -1;
            //
        }
        else if (l_right.triggered && !l_left.triggered)
        {
            xChange = 1;
        }

        if (l_up.triggered && !l_down.triggered)
        {
            yChange = -1;
        }
        else if (l_down.triggered && !l_up.triggered)
        {
            yChange = 1;
        }
        if (xChange != 0 || yChange != 0)
        {
            leftPull.body.position.x += HAND_SPEED * elapsed * xChange * ((xChange != 0 && yChange != 0) ? .707 : 1);
            leftPull.body.position.y += HAND_SPEED * elapsed * yChange * ((xChange != 0 && yChange != 0) ? .707 : 1);

            if (xChange == 1)
            {
                if (yChange == 1)
                    a = 135;
                else if (yChange == -1)
                    a = 45;
                else
                    a = 90;
            }
            else if (xChange == -1)
            {
                if (yChange == 1)
                    a = -135;
                else if (yChange == -1)
                    a = -45;
                else
                    a = -90;
            }
            else
            {
                if (yChange == 1)
                    a = 180;
                else if (yChange == -1)
                    a = 0;
            }
            if (leftHand.handState == OPEN)
                leftHand.body.rotation = FlxAngle.TO_RAD * a;

            leftPull.body.position.x = FlxMath.bound(leftPull.body.position.x, 10, FlxG.width - 10);
            leftPull.body.position.y = FlxMath.bound(leftPull.body.position.y, 10, FlxG.height - 10);
        }
        xChange = yChange = 0;
        if (r_left.triggered && !r_right.triggered)
        {
            xChange = -1;
        }
        else if (r_right.triggered && !r_left.triggered)
        {
            xChange = 1;
        }

        if (r_up.triggered && !r_down.triggered)
        {
            yChange = -1;
        }
        else if (r_down.triggered && !r_up.triggered)
        {
            yChange = 1;
        }

        if (xChange != 0 || yChange != 0)
        {
            rightPull.body.position.x += HAND_SPEED * elapsed * xChange * ((xChange != 0 && yChange != 0) ? .707 : 1);
            rightPull.body.position.y += HAND_SPEED * elapsed * yChange * ((xChange != 0 && yChange != 0) ? .707 : 1);

            if (xChange == 1)
            {
                if (yChange == 1)
                    a = 135;
                else if (yChange == -1)
                    a = 45;
                else
                    a = 90;
            }
            else if (xChange == -1)
            {
                if (yChange == 1)
                    a = -135;
                else if (yChange == -1)
                    a = -45;
                else
                    a = -90;
            }
            else
            {
                if (yChange == 1)
                    a = 180;
                else if (yChange == -1)
                    a = 0;
            }

            if (rightHand.handState == OPEN)
                rightHand.body.rotation = FlxAngle.TO_RAD * a;

            rightPull.body.position.x = FlxMath.bound(rightPull.body.position.x, 10, FlxG.width - 10);
            rightPull.body.position.y = FlxMath.bound(rightPull.body.position.y, 10, FlxG.height - 10);
        }
    }

    private function ignoreCollision(cb:PreCallback):PreFlag
    {
        return PreFlag.IGNORE;
    }
}
