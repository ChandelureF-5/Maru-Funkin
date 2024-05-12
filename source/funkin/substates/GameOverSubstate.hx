package funkin.substates;

class GameOverSubstate extends MusicBeatSubstate
{
	static var instance:GameOverSubstate;
	var char:Character;
	var camFollow:FlxObject;

	var skinFolder:String;
	var deathSound:FlxSound = null;
	var lockedOn:Bool = false;

	public static function cacheSounds():Void {
		var char = resolveChar();
		var folder = resolveFolder(char);
		Paths.sound(folder + "fnf_loss_sfx");
		Paths.music(folder + "gameOverEnd");
		Paths.music(folder + "gameOver");
	}

	inline static function resolveChar() {
		return  PlayState.instance?.boyfriend ?? null;
	}

	inline static function resolveFolder(?char:Character) {
		var suffix = (char == null || char.gameOverSuffix == "") ? "default" : char.gameOverSuffix;
		return "skins/" + (suffix.endsWith("/") ? suffix.substr(0, suffix.length - 1) : suffix) + "/";
	}

	public function new(x:Float, y:Float):Void {
		super();
		instance = this;

		FlxG.camera.bgColor = FlxColor.BLACK;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		if (PlayState.instance.startTimer != null)
			PlayState.instance.startTimer.cancel();

		#if mobile MobileTouch.setLayout(NONE); #end

		var bf = resolveChar();
		skinFolder = resolveFolder(bf);

		char = new Character(x, y, bf != null ? bf.gameOverChar : "bf-dead", true);
		PlayState.instance.boyfriend.stageOffsets.copyTo(char.stageOffsets);
		char.setXY(x,y);
		add(char);

		Conductor.songPosition = 0;
		Conductor.bpm = 100;

		deathSound = CoolUtil.playSound(skinFolder + 'fnf_loss_sfx');
		char.playAnim('firstDeath');

		camFollow = new FlxObject();
		add(camFollow);

		var midPoint = char.getGraphicMidpoint();
		camFollow.x = midPoint.x - char.camOffsets.x;
		camFollow.y = midPoint.y - char.camOffsets.y;

		ModdingUtil.addCall('startGameOver');
	}

	function lockCamToChar() {
		PlayState.instance.camGame.follow(camFollow, LOCKON, 0.01);
		lockedOn = true;
	}

	public var lockFrame:Int = 12;

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (char.animation.curAnim != null)
		{
			if (char.animation.curAnim.name == 'firstDeath')
			{
				if (char.animation.curAnim.curFrame >= lockFrame) if (!lockedOn)
					lockCamToChar();
		
				if (char.animation.curAnim.finished) {
					CoolUtil.playMusic(skinFolder + 'gameOver');
					musicBeat.targetSound = FlxG.sound.music;
					gameOverDance();
					ModdingUtil.addCall('musicGameOver');
				}
			}
		}

		if (#if mobile MobileTouch.justPressed() #else getKey('ACCEPT', JUST_PRESSED) #end)
		{
			restartSong();
		}
 
		if (getKey('BACK', JUST_PRESSED))
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			
			PlayState.deathCounter = 0;
			PlayState.clearCache = true;
			ModdingUtil.addCall('exitGameOver');
			CoolUtil.switchState((PlayState.isStoryMode) ? new StoryMenuState(): new FreeplayState());
		}

		if (exitTimer > 0) {
			exitTimer -= elapsed;
			if (exitTimer <= 0) {
				PlayState.clearCache = false;
				SkinUtil.setCurSkin('default');
				FlxG.resetState();
			}
		}
	}

	override function beatHit(curBeat:Int):Void {
		super.beatHit(curBeat);
		ModdingUtil.addCall('beatHitGameOver', [curBeat]);

		if (!isEnding) {
			gameOverDance();
		}
	}

	function gameOverDance():Void {
		if (char.animOffsets.exists('deathLoopRight') && char.animOffsets.exists('deathLoopLeft')) {
			char.danced = !char.danced;
			char.playAnim((char.danced) ? 'deathLoopRight' : 'deathLoopLeft');
		}
		else if (char.animOffsets.exists('deathLoop')) {
			char.playAnim('deathLoop');
		}
	}

	var isEnding:Bool = false;
	var exitTimer:Float = 0;

	function restartSong():Void {
		if (!isEnding)
		{
			isEnding = true;
			char.playAnim('deathConfirm', true);
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			var endSound = new FlxSound().loadEmbedded(Paths.music(skinFolder + 'gameOverEnd'));
			endSound.autoDestroy = true;
			endSound.play();
			
			deathSound.stop();

			if (!lockedOn) lockCamToChar();

			new FlxTimer().start(0.7, (tmr:FlxTimer) -> {
				exitTimer = 2;
				PlayState.instance.camGame.fade(FlxColor.BLACK, 2);
			});

			ModdingUtil.addCall('resetGameOver');
		}
	}

	override function destroy() {
		super.destroy();
		if (instance == this)
			instance = null;
	}
}
