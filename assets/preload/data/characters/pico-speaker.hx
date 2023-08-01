importLib('Song', 'funkin.util.song');

var speaker:FlxSprite;
var picoNotes_ = [];

function createPost():Void {
    ScriptChar.x += 120;
    speaker = new FlxSprite(ScriptChar.x - 190, ScriptChar.y + 305.5);
    speaker.loadImage('characters/speakers');
    speaker.addAnim('speakers', 'speakers');
    speaker.playAnim('speakers', true);
    speaker.animation.curAnim.finish();
    ScriptChar.group.insert(0, speaker);

    speaker.flippedOffsets =  ScriptChar.flippedOffsets;
    speaker.flipX = ScriptChar.flipX;
    if (speaker.flippedOffsets) {
        speaker.x += 140;
    }

    if (Paths.exists(Paths.chart(GameVars.SONG.song, 'picospeaker'), "TEXT")) {
        picoNotes_ = Song.getSongNotes('picospeaker',  GameVars.SONG.song);
        initTankmenBG();
    }
}

function beatHit():Void {
    speaker.playAnim('speakers', true);
}

function startTimer():Void {
    speaker.playAnim('speakers', true);
}

function updatePost(elapsed)
{
    if (picoNotes_.length > 0) {
        updateTankmenBG(elapsed);
        if(Conductor.songPosition > picoNotes_[0][0])
        {
            var shootAnim:Int = 1;
            if (picoNotes_[0][1] >= 2)
                shootAnim = 3;
            shootAnim += FlxG.random.int(0, 1);

            ScriptChar.playAnim('shoot'+shootAnim, true);
            ScriptChar.specialAnim = true;
            ScriptChar.forceDance = false;
            picoNotes_.shift();
        }
    }
}

// Tankmen Run
function initTankmenBG() {
    if (getGroup('tankmanRun') != null) {
        for (i in 0...picoNotes_.length) {
            if (FlxG.random.bool(16)) {
                var tankman:FlxSprite = new FlxSprite(500, 200 + FlxG.random.int(50, 100)).loadImage('stress/tankmenRunning');
                tankman.addAnim('run', 'tankman running', 24, true);
                tankman.playAnim('run');
                tankman.animation.curAnim.curFrame = FlxG.random.int(0, tankman.animation.curAnim.numFrames - 1);
                tankman.scale.set(0.8,0.8);
                tankman.updateHitbox();

                tankman._dynamic.strumTime = picoNotes_[i][0];
                tankman.flipX = picoNotes_[i][1] > 2;
                tankman._dynamic.endingOffset = FlxG.random.float(50, 200);
                tankman._dynamic.tankSpeed = FlxG.random.float(0.6, 1);
                getGroup('tankmanRun').add(tankman);
            }
        }
    }
}

function updateTankmenBG(elapsed) {
    if (getGroup('tankmanRun') != null) {
        for (i in getGroup('tankmanRun').members) {
            if (i.alive) {
                var endDirection:Float = (FlxG.width * 0.74) + i._dynamic.endingOffset;
                if (i.flipX) {
                    endDirection = (FlxG.width * 0.02) - i._dynamic.endingOffset;
                    i.x = (endDirection + (Conductor.songPosition - i._dynamic.strumTime) * i._dynamic.tankSpeed);
                } else {
                    i.x = (endDirection - (Conductor.songPosition - i._dynamic.strumTime) * i._dynamic.tankSpeed);
                }
    
                if (Conductor.songPosition >= i._dynamic.strumTime) { 
                    // Kill the bitch
                    i.kill();
                }
            }
        }
    }
}