package funkin.util.frontend.modifiers;

enum abstract Modifiers(String) from String to String {
    var COS = "COS";
    var SIN = "SIN";
    var BOOST = "BOOST";
}

class BasicModifier
{
    public var name(default, null):String;
    public var eachNote(default, null):Bool;
    public var data:Array<Dynamic>;

    public function new(name:String, eachNote:Bool) {
        this.name = name;
        this.eachNote = eachNote;
        this.data = getDefaultValues();
    }

    public static function fromName(name:String):BasicModifier
    {
        return switch(name) {
            case COS: new CosModifier();
            case SIN: new SinModifier();
            case BOOST: new BoostModifier();
            case _: null;
        }
    }

    // For each strum note (that isnt a sustain)
    public function manageStrumNote(strum:NoteStrum, note:Note) {}

    // Called every frame
    public function manageStrumUpdate(strum:NoteStrum, elapsed:Float, timeElapsed:Float) {}

    // Called every song step
    public function manageStrumStep(strum:NoteStrum, step:Int) {}

    // Called every song beat
    public function manageStrumBeat(strum:NoteStrum, beat:Int) {}
    
    // Called every song section
    public function manageStrumSection(strum:NoteStrum, section:Int) {}

    public function getDefaultValues():Array<Dynamic> {
        return [];
    }
}