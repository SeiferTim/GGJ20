package;

import flixel.FlxSprite;
import axollib.GraphicsCache;

class ShipPart extends FlxSprite
{
    private var startWidth:Float;
    private var startHeight:Float;

    public var depth(default, null):Int = 0;

    public function new()
    {
        super();
        frames = GraphicsCache.loadGraphicFromAtlas("parts", AssetPaths.ship_parts__png, AssetPaths.ship_parts__xml).atlasFrames;
        startWidth = width;
        startHeight = height;
    }

    public function spawn(X:Float, Y:Float, Angle:Float, Frame:Int, Depth:Int):Void
    {
        depth = Depth;
        animation.frameIndex = Frame;
        drawFrame();
        updateHitbox();
        centerOffsets();
        reset(X - (width / 2), Y - (height / 2));
        // angle = Angle;
        // if (angle == 90 || angle == -90)
        // {
        //     width = startHeight;
        //     height = startWidth;
        // }
        // else
        // {
        //     width = startWidth;
        //     height = startHeight;
        // }
    }
}
