package;

import axollib.GraphicsCache;
import flixel.FlxSprite;

class ShipFrame extends FlxSprite
{
    private var startWidth:Float;
    private var startHeight:Float;

    public function new()
    {
        super();
        frames = GraphicsCache.loadGraphicFromAtlas("frames", AssetPaths.ship_frames__png, AssetPaths.ship_frames__xml).atlasFrames;
        startWidth = width;
        startHeight = height;
    }

    public function spawn(X:Float, Y:Float, Angle:Float, Frame:Int):Void
    {
        animation.frameIndex = Frame;
        drawFrame();
        updateHitbox();
        centerOffsets();
        reset(X, Y);
    }
}
