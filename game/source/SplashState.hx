package;

import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxState;

class SplashState extends FlxState
{
    public override function create():Void
    {
        FlxG.mouse.visible = false;

        var ggj:FlxSprite;
        add(ggj = new FlxSprite(0, 0, AssetPaths.ggjlogo__png));
        ggj.screenCenter(FlxAxes.XY);
        ggj.scale.set(.66, .66);

        FlxG.camera.fade(FlxColor.BLACK, 1, true, () ->
            {
                FlxG.sound.play(AssetPaths.madeinstl__wav, 1, false, null, true, () ->
                    {
                        FlxG.camera.fade(FlxColor.BLACK, 2, false, () ->
                            {
                                FlxG.switchState(new TitleState());
                            });
                    });
            });

        super.create();
    }
}
