package;

import flixel.FlxG;
import flixel.util.FlxAxes;
import flixel.text.FlxText;
import flixel.FlxState;

class TitleState extends FlxState
{

    private var leaving:Bool = false;

    override function create() {
        
        // add things
        
        var text:FlxText = new FlxText();
        text.text= "Press Space to Play";
        text.screenCenter(FlxAxes.XY);
        add(text);

        super.create();
    }

    override  function update(elapsed:Float) {
        
        if (!leaving && FlxG.keys.anyJustPressed([SPACE]))
            {
                leaving = false;
                FlxG.switchState(new PlayState());
            }

        super.update(elapsed);
    }
}