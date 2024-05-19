package funkin.substates;

class CharSelectSubstate extends MusicBeatSubstate
{
    public static var lastChar:String = 'bf';
    var selectFunction:()->Void;

    var curFolder:Int = 0;
    var curSelected:Array<Int> = [];
    var iconArray:Array<Array<HealthIcon>> = [];
    var charArray:Array<Array<MenuAlphabet>> = [];
    var folderTxt:Alphabet;

    var textGroup:TypedGroup<MenuAlphabet>;

	public function new(?selectFunction:()->Void):Void {
		super();
        this.selectFunction = selectFunction;

        var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.antialiasing = false;
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

        folderTxt = new Alphabet(0, 10);
        folderTxt.scrollFactor.set();
        folderTxt.color = FlxColor.YELLOW;

        var vanillaSort = CoolUtil.getFileContent(Paths.txt("characters/characters-sort", null, false)).split(",");
        var modSort = CoolUtil.getFileContent(Paths.txt("characters/characters-sort")).split(',');
       
        var vanillaChars:Array<String> = CoolUtil.customSort(Paths.getFileList(TEXT, false, 'json', 'data/characters'), vanillaSort);
        var modChars:Array<String> = CoolUtil.customSort(Paths.getModFileList('data/characters', 'json', false), modSort);

        var listsToAdd:Array<Array<String>> = [vanillaChars, modChars];

        textGroup = new TypedGroup<MenuAlphabet>();
        add(textGroup);

        listsToAdd.fastForEach((folder, f) ->
        {
            iconArray.push([]);
            charArray.push([]);
            curSelected.push(0);

            folder.fastForEach((item, i) -> {
                var charText:MenuAlphabet = new MenuAlphabet(5, (70 * i) + 30, item, true, i);
                charText.scrollFactor.set();
                charText.forceX = false;
                charText.snapPosition();
                textGroup.add(charText);
                    
                var iconName:String = Character.getCharData(item).icon;
                var charIcon:HealthIcon = new HealthIcon(iconName);
                charIcon.scrollFactor.set();
                charIcon.sprTracker = charText;
                add(charIcon);

                iconArray.unsafeGet(f).push(charIcon);
                charArray.unsafeGet(f).push(charText);
            });
        });

        changeFolder();
        add(folderTxt);
        cameras = [CoolUtil.getTopCam()];
    }
    
    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (getKey('UI_UP', JUST_PRESSED))		changeSelection(-1);
		if (getKey('UI_DOWN', JUST_PRESSED))	changeSelection(1);
        if (getKey('UI_LEFT', JUST_PRESSED))	changeFolder(-1);
		if (getKey('UI_RIGHT', JUST_PRESSED))	changeFolder(1);
        if (getKey('ACCEPT', JUST_PRESSED))     selectChar();
        else if (getKey('BACK', JUST_PRESSED))  close();
    }
    
    function selectChar():Void {
        lastChar = charArray[curFolder][curSelected[curFolder]].text;
        if (selectFunction != null) selectFunction();
        close();
    }

    function changeFolder(change:Int = 0):Void {
        if (curSelected.length <= 0) return;
        
        curFolder = FlxMath.wrap(curFolder + change, 0, curSelected.length - 1);
        if (change != 0) CoolUtil.playSound('scrollMenu', 0.4);
    
        switch(curFolder) {
            case 0: folderTxt.text = 'Base game';
            case 1: folderTxt.text = 'Mods';
        }

        folderTxt.x = FlxG.width - folderTxt.width - 10;

        charArray.fastForEach((folder, f) -> {
            var show = (f == curFolder);
            for (i in 0...folder.length) {
                folder[i].visible = show;
                iconArray[f][i].visible = show;
            }
        });
        
        changeSelection();
    }

    function changeSelection(change:Int = 0):Void
    {
        if (charArray[curFolder].length <= 0)
            return;

        curSelected[curFolder] = FlxMath.wrap(curSelected[curFolder] + change, 0, charArray[curFolder].length - 1);
        if (change != 0) CoolUtil.playSound('scrollMenu', 0.4);

        charArray[curFolder].fastForEach((item, i) -> {
            item.targetY = i - curSelected[curFolder];
            item.alpha = (item.targetY == 0) ? 1 : 0.6;
            iconArray[curFolder][i].alpha = item.alpha;
        });
	}
}