package funkin.util.modding;

class ModdingUtil {
    //Mod folders
    public static var modFolders:Array<String> = [];
    public static var modFoldersMap:Map<String, Bool>;
    private static var folderExceptions:Array<String> = [
        'data',
        'fonts',
        'images',
        'music',
        'songs',
        'sounds'
    ];
    public static var curModFolder:Null<String> = null;
    
    //Scripts
    public static var playStateScripts:Array<FunkScript> = [];
    public static var globalScripts:Array<FunkScript> = [];
    public static var scriptsMap:Map<String, FunkScript>;

    inline public static function clearScripts(global:Bool = false):Void {
        scriptsMap = new Map<String, FunkScript>();
        global ? globalScripts : playStateScripts = [];
    }

    inline public static function reloadModFolders():Void {
        modFoldersMap = new Map<String, Bool>();
        modFolders = getModFolderList();
        getDefModFolder();
    }

    public static function getDefModFolder():Void {
        if (modFolders.length > 0) {
            for (mod in modFolders) {
                if (modFoldersMap.get(mod)) {
                    curModFolder = mod;
                    trace(curModFolder);
                    return;
                }
            }
        }
        curModFolder = null;
    }

    inline public static function getModFolderList():Array<String> {
		var guh:Array<String> = [];
		#if desktop
		if (FileSystem.exists('mods')) {
			for (folder in FileSystem.readDirectory('mods')) {
                if (!folderExceptions.contains(folder) && FileSystem.isDirectory('mods/$folder')) {
                    modFoldersMap.set(folder, true);
                    guh.push(folder);
                }
			}
		}
		#end
		return guh;
	}

    inline public static function addScript(path:String, global:Bool = false, ?scriptVarNames:Array<String>, ?scriptVars:Array<Dynamic>):Void {
        consoleTrace('[ADD] $path / $global', FlxColor.LIME);
        var scriptCode:String = CoolUtil.getFileContent(path);
        var piss:FunkScript = new FunkScript(scriptCode);
        piss.scriptID = path;

        if (scriptVarNames != null && scriptVars != null) {
            for (i in 0...scriptVars.length) {
                piss.addVar(scriptVarNames[i], scriptVars[i]);
            }
        }

        scriptsMap.set(path, piss);
        (global ? globalScripts : playStateScripts).push(piss);
    }

    inline public static function setModFolder(modName:String, activated:Bool):Void {
        modFoldersMap.set(modName, activated);
    }

    inline public static function errorTrace(text:String):Void {
        consoleTrace('[ERROR] $text', FlxColor.RED);
    }

    inline public static function consoleTrace(text:String, ?color:Int):Void {
        var console = MusicBeatState.game.scriptConsole;
        console.exists ? console.consoleTrace(text, color) : console.addToTraceList(text, color);
    }

    inline public static function addCall(name:String, ?args:Dynamic, global:Bool = false):Void {
        for (script in (global ? globalScripts : playStateScripts)) {
            try             script.callback(name,args)
            catch(e:Any)    errorTrace('${script.scriptID} / ${Std.string(e)}');
        }
    }

    inline public static function getScriptList(folder:String = 'scripts/global', assets:Bool = true, globalMod:Bool = true, curMod:Bool = true, allMods:Bool = false):Array<String> {
        var scriptList:Array<String> = (assets) ? Paths.getFileList(TEXT, true, 'hx', 'assets/$folder') : [];
        #if desktop
        scriptList = scriptList.concat(Paths.getModFileList(folder, 'hx', true, globalMod, curMod, allMods));
        #end
        return scriptList;
    }
}