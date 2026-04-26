import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {
	public function new() {
		super();
		// 1280×720, 60 FPS
		addChild(new FlxGame(1280, 720, PlayState, 60, 60, true));

		// Para medir datos empíricos: BenchmarkState.
		// addChild(new FlxGame(1280, 720, BenchmarkState, 60, 60, true));
	}
}
