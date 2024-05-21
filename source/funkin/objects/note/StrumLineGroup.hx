package funkin.objects.note;

class StrumLineGroup extends TypedSpriteGroup<NoteStrum> {
    public var initPos:Array<FlxPoint> = [];
    public static var strumLineY:Float = 50;
    
    var startX:Float = 0;
    var offsetY:Float = 0;

    public function new(p:Int = 0, lanes:Int = Conductor.NOTE_DATA_LENGTH) {
        super(9);
        startX = NoteUtil.noteWidth * 0.666 + (FlxG.width * 0.5) * p;
        offsetY = Preferences.getPref('downscroll') ? 10 : -10;
        
        final isPlayer:Bool = p == 1;
        for (i in 0...lanes) {
			final strumNote = addStrum(i);
			ModdingUtil.addCall('generateStrum', [strumNote, isPlayer]);
		}
    }

    public static final DEFAULT_CONTROL_CHECKS:Array<InputType->Bool> = [
        (t:InputType) -> return Controls.getKey('NOTE_LEFT', t),
        (t:InputType) -> return Controls.getKey('NOTE_DOWN', t),
        (t:InputType) -> return Controls.getKey('NOTE_UP', t),
        (t:InputType) -> return Controls.getKey('NOTE_RIGHT', t)
    ];

    static inline var seperateWidth:Int = NoteUtil.noteWidth + 5;

    public function insertStrum(position:Int = 0) {
        if (members.length >= 9) return null; // STOP
        for (i in position...members.length) {
            final strum = members[i];
            if (strum == null) continue;
            strum.x += seperateWidth;
            strum.ID++;
        }
        return addStrum(position);
    }

    public function introStrums() {
        members.fastForEach((strum, i) -> {
            strum.alpha = 0;
			strum.y += offsetY;
            FlxTween.tween(strum, {y: strum.y - offsetY, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * strum.noteData)});
        });
    }

    public function addStrum(noteData:Int = 0) {
        if (members.length >= 9) return null; // STOP
        final strumX:Float =  startX + seperateWidth * noteData;
		final strumNote:NoteStrum = new NoteStrum(strumX, strumLineY, noteData);
		strumNote.ID = noteData;
		strumNote.updateHitbox();
		strumNote.scrollFactor.set();
        add(strumNote);
        initPos.push(strumNote.getPosition());

        if (noteData < DEFAULT_CONTROL_CHECKS.length) {
            strumNote.controlFunction = DEFAULT_CONTROL_CHECKS[noteData];
        }

        return strumNote;
    }

    override function destroy() {
        super.destroy();
        initPos = FlxDestroyUtil.putArray(initPos);
    }
}