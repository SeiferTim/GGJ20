package;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxAxes;
import flixel.text.FlxText;
import flixel.FlxState;

class TitleState extends FlxState
{
    private var leaving:Bool = false;

    public override function create():Void
    {
        // add things

        add(new FlxSprite(0, 0, AssetPaths.title__png));

        var text:FlxText = new FlxText(0, 0, 0, "Press Any Button to Play", 26);

        text.color = FlxColor.BLACK;
        text.borderColor = FlxColor.WHITE;
        text.borderStyle = FlxTextBorderStyle.OUTLINE;
        text.borderSize = 2;
        text.screenCenter(FlxAxes.X);
        text.y = FlxG.height - text.height - 10;
        add(text);

        super.create();
    }

    public override function update(elapsed:Float):Void
    {
        if (!leaving && (FlxG.keys.anyJustPressed([SPACE]) || FlxG.gamepads.anyButton()))
        {
            leaving = false;
            FlxG.switchState(new PlayState());
        }

        super.update(elapsed);
    }
}
