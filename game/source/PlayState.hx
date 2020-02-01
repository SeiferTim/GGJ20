package;

import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;

class PlayState extends FlxState
{

	private var handLeft:FlxSprite;
	private var handRight:FlxSprite;

	private  var leftNode:FlxPoint;
	private var rightNode:FlxPoint;

	private var leftAnchor:FlxPoint;
	private var rightAnchor:FlxPoint;





	override public function create():Void
	{

		
		FlxNapeSpace.init();
		FlxNapeSpace.createWalls(0, 0, FlxG.width,FlxG.height - 10, 10);


		// leftAnchor = FlxPoint.get((FlxG.width * .25)  - (handLeft.width/2),(FlxG.height * .5) - (handLeft.height/2));
		// rightAnchor = FlxPoint.get((FlxG.width * .75)  - (handRight.width/2),(FlxG.height * .5) - (handRight.height/2));


		// handLeft = new FlxSprite();
		// handLeft.makeGraphic(50,50,FlxColor.GRAY);

		// handLeft.x = leftAnchor.x;
		// handLeft.y = leftAnchor.y;

		// handRight = new FlxSprite();
		// handRight.makeGraphic(50,50,FlxColor.GRAY);

		// handRight.x = rightAnchor.x;
		// handRight.y = rightAnchor.y;

		// add(handLeft);
		// add(handRight);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
