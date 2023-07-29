var cutsceneTankman_Body:FunkinSprite;
var cutsceneTankman_Head:FunkinSprite;

function create()
{
    if (!GameVars.isStoryMode)
    {
        PlayState.inCutscene = true;

        cutsceneTankman_Body = new FunkinSprite('tankmanCutscene_body', [PlayState.dad.x, PlayState.dad.y + 155], [1,1]);
        cutsceneTankman_Body.addAnim('godEffingDamnIt', 'body/BODY_3_10');
        cutsceneTankman_Body.addAnim('lookWhoItIs', 'body/BODY_3_20');

        cutsceneTankman_Body.addOffset('godEffingDamnIt', 95, 160);
        cutsceneTankman_Body.addOffset('lookWhoItIs', 5, 32);

        cutsceneTankman_Head = new FunkinSprite('tankmanCutscene_head', [PlayState.dad.x + 60, PlayState.dad.y - 10], [1,1]);
        cutsceneTankman_Head.addAnim('godEffingDamnIt', 'HEAD_3_10');
        cutsceneTankman_Head.addAnim('lookWhoItIs', 'HEAD_3_20');

        cutsceneTankman_Head.addOffset('godEffingDamnIt', 30, 25);
        cutsceneTankman_Head.addOffset('lookWhoItIs', 10, 10);

        //PlayState.dad.alpha = 0.6;
        PlayState.dad.visible = false;
        PlayState.dadGroup.add(cutsceneTankman_Body);
        PlayState.dadGroup.add(cutsceneTankman_Head);
    }
}

function startCutscene()
{
    PlayState.showUI(false);

    var soundPath:String = 'stressCutscene';
    if (!getPref('naughty'))
        soundPath = 'song3censor';

    var stressCutscene:FlxSound = new FlxSound().loadEmbedded(Paths.sound(soundPath));
    FlxG.sound.list.add(stressCutscene);

    PlayState.camFollow.x = PlayState.dad.x + 400;
    PlayState.camFollow.y = PlayState.dad.y + 170;
    FlxTween.tween(PlayState.camGame, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});

    // God effing damn it
    new FlxTimer().start(0.1, function(tmr:FlxTimer)
    {
        cutsceneTankman_Body.playAnim('godEffingDamnIt', true);
        cutsceneTankman_Head.playAnim('godEffingDamnIt', true);
        stressCutscene.play(true);
    });

    // Zoom to GF
    new FlxTimer().start(15.2, function(tmr:FlxTimer)
    {
        //PlayState.gf.visible = false;
        FlxTween.tween(PlayState.camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
        FlxTween.tween(PlayState.camGame, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});
    });

    // Pico appears
    new FlxTimer().start(17.5, function(tmr:FlxTimer)
    {
        zoomBack();
    });

    // Look who it is
    new FlxTimer().start(19.5, function(tmr:FlxTimer)
    {
        cutsceneTankman_Body.playAnim('lookWhoItIs', true);
        cutsceneTankman_Head.playAnim('lookWhoItIs', true);
        cutsceneTankman_Head.visible = true;
    });

    //Focus to tankman
    new FlxTimer().start(20, function(tmr:FlxTimer)
    {
        PlayState.camFollow.x = PlayState.dad.x + 500;
        PlayState.camFollow.y = PlayState.dad.y + 170;
    });

    //Little Cunt
    new FlxTimer().start(31.2, function(tmr:FlxTimer)
    {
        PlayState.boyfriend.playAnim('singUPmiss', true);

        //Snap the camera
        PlayState.camFollow.x = PlayState.boyfriend.x + 260;
        PlayState.camFollow.y = PlayState.boyfriend.y + 160;
        //PlayState.camGame.focusOn(PlayState.camFollow.getPosition());

        FlxTween.tween(PlayState.camGame, {zoom: 0.9 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
    });

    new FlxTimer().start(32.2, function(tmr:FlxTimer)
    {
        PlayState.boyfriend.dance();
        zoomBack();
    });

    //Fade Sound
    new FlxTimer().start(34.5, function(tmr:FlxTimer)
    {
        stressCutscene.fadeOut(1.5, 0);
    });

    //End Cutscene
    new FlxTimer().start(35.5, function(tmr:FlxTimer)
    {
        PlayState.dad.visible = true;
        cutsceneTankman_Body.visible = false;
        cutsceneTankman_Head.visible = false;
        FlxTween.tween(PlayState.camGame, {zoom: PlayState.defaultCamZoom}, Conductor.crochet / 255, {ease: FlxEase.cubeInOut});
        PlayState.startCountdown();
    });

    if (!getPref('naughty'))
    {
        var censorBar:FunkinSprite = new FunkinSprite('censor', [300,450], [1,1]);
        censorBar.addAnim('mouth censor', 'mouth censor', 24, true);
        censorBar.addOffset('mouth censor', 75, 0);
        censorBar.playAnim('mouth censor', true);
        censorBar.visible = false;
        PlayState.add(censorBar);
    
        var censorTimes:Array<Dynamic> =
        [
            [4.63,true,[300,450]],      [4.77,false],   //SHIT
            [25,true,[275,435]],        [25.27,false],  //SCHOOL
            [25.38,true],               [25.86,false],
            [30.68,true,[375,475]],     [31.06,false],  //CUNT
            [33.79,true,[300,450]],     [34.28,false],
        ];
    
        for (censorThing in censorTimes)
        {
            new FlxTimer().start(censorThing[0], function(tmr:FlxTimer)
            {
                censorBar.visible = censorThing[1];
                if (censorThing[2] != null)
                {
                    censorBar.x = censorThing[2][0];
                    censorBar.y = censorThing[2][1];
                }
            });
        }
    }
}

function zoomBack()
{
	PlayState.camFollow.x = 630;
    PlayState.camFollow.y = 425;
	PlayState.camGame.zoom = 0.8;
}

var catchedGF:Bool = false;
function updatePost()
{
    /*if (curCutscenePicoAnim == 'picoArrives_1')
    {
        if (cutscenePico.anim.get_curFrame() >= 2 && !catchedGF)
        {
            catchedGF = true;
            PlayState.boyfriend.playAnim('catch');
            PlayState.boyfriend.animation.finishCallback = function(){PlayState.boyfriend.dance();};
        }
    }*/

    if (cutsceneTankman_Head.animation.curAnim != null) {
        if (cutsceneTankman_Head.animation.curAnim.name == 'godEffingDamnIt') {
            cutsceneTankman_Head.visible = !cutsceneTankman_Head.animation.curAnim.finished;
        }
    }
}