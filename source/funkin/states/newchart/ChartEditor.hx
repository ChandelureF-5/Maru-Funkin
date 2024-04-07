package funkin.states.newchart;

class ChartEditor extends MusicBeatState
{
    public static var SONG:SwagSong;

    var bg:FlxSpriteExt;
    var grid:ChartGrid;
    
    override function create()
    {
        super.create();

        setupSong("bopeebo", "hard");

        bg = new FlxSpriteExt().loadImage("menuDesat");
        bg.scrollFactor.set();
        bg.color = 0xFF242424;
        add(bg);

        grid = new ChartGrid();
        add(grid);
    }

    public static function setupSong(song:String, diff:String, ?input:SwagSong):SwagSong
    {
        return SONG = input ?? Song.loadFromFile(diff, song);
    }
}