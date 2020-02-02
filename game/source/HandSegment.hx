package;

import axollib.GraphicsCache;
import flixel.addons.nape.FlxNapeSprite;

class HandSegment extends FlxNapeSprite
{
    public var isHand(default, null):Bool = false;

    public var handState(default, set):HandState = NONE;

    public function new(IsHand:Bool = false)
    {
        super();
        frames = GraphicsCache.loadGraphicFromAtlas("hand", AssetPaths.hand__png, AssetPaths.hand__xml).atlasFrames;
        isHand = IsHand;
        if (isHand)
        {
            animation.frameName = "hand_open.png";
            handState = OPEN;
            // offset.y = 60;
            origin.y = 60;
            createCircularBody(4);
            body.allowRotation = true;
        }
        else
        {
            animation.frameName = "segment.png";
            createCircularBody(2);
            body.allowRotation = false;
        }

        setBodyMaterial(0.0, 100.0, 100.0, 100.0, 100.0);
        body.gravMass = 2;
    }

    // private function set_isHand(Value:Bool):Bool
    // {
    //     if (!isHand && Value)
    //     {
    //         isHand = Value;
    //         animation.frameName = "hand_open.png";
    //         handState = OPEN;
    //         createCircularBody(height);
    //     }
    //     return isHand;
    // }

    private function set_handState(Value:HandState):HandState
    {
        if (isHand)
        {
            handState = Value;
            switch (handState)
            {
                case OPEN:
                    animation.frameName = "hand_open.png";
                case CLOSED:
                    animation.frameName = "hand_closed.png";
                default:
                    animation.frameName = "segment.png";
            }
        }
        return handState;
    }
}

enum HandState
{
    NONE;
    OPEN;
    CLOSED;
}
