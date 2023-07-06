package funkin.util;

typedef StageJson = {
	var library:String;
    var skin:String;

	var gfOffsets:Array<Int>;
	var dadOffsets:Array<Int>;
	var bfOffsets:Array<Int>;

	var startCamOffsets:Array<Int>;
	var gfCamOffsets:Array<Int>;
	var dadCamOffsets:Array<Int>;
	var bfCamOffsets:Array<Int>;
}

class Stage {
    public var curStage:String = 'stage';
    public static var defaultStage:StageJson = {
        library: "",
        skin: "default",

        gfOffsets: [0,0],
        dadOffsets: [0,0],
        bfOffsets: [0,0],

        startCamOffsets: [0,0],
        gfCamOffsets: [0,0],
        dadCamOffsets: [0,0],
        bfCamOffsets: [0,0],
    };

    public static function getJsonData(stage:String):StageJson {
        if (Paths.exists(Paths.json('stages/$stage'), TEXT)) {
            var stageJson:StageJson = JsonUtil.getJson(stage, 'stages');
            return JsonUtil.checkJsonDefaults(defaultStage, stageJson);
        }
        return defaultStage;
    }
}