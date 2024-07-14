package funkin.util.song;

import haxe.Json;
import flixel.util.FlxSort;

import funkin.util.song.formats.OsuFormat;
import funkin.util.song.formats.SmFormat;
import funkin.util.song.formats.QuaFormat;
import funkin.util.song.formats.GhFormat;
import funkin.util.song.formats.FunkinFormat;

abstract NoteJson(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic>
{
	public var time(get, set):Float;
	inline function set_time(value):Float return this[0] = value;
	inline function get_time():Float return this[0];

	public var lane(get, set):Int;
	inline function set_lane(value):Int return this[1] = value;
	inline function get_lane():Int return this[1];

	public var length(get, set):Float;
	inline function set_length(value):Float return this[2] = value;
	inline function get_length():Float return this[2] ?? 0;

	public var type(get, set):String;
	inline function set_type(value):String return this[3] = value;
	inline function get_type():String return this[3];

	public inline function push(value:Dynamic) this.push(value);
	public inline function pop() return this.pop();
}

abstract EventJson(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic> {
	public var time(get, set):Float;
	inline function set_time(value):Float return this[0] = value;
	inline function get_time():Float return this[0];

	public var name(get, set):String;
	inline function set_name(value):String return this[1] = value;
	inline function get_name():String return this[1];

	public var values(get, set):Array<Dynamic>;
	inline function set_values(value):Array<Dynamic> return this[2] = value;
	inline function get_values():Array<Dynamic> return this[2];

	public inline function push(value:Dynamic) this.push(value);
	public inline function pop() return this.pop();
}

typedef SectionJson = {
	var ?sectionNotes:Array<NoteJson>;
	var ?sectionEvents:Array<EventJson>;
	var ?mustHitSection:Bool;
	var ?bpm:Float;
	var ?changeBPM:Bool;
}

typedef SongJson = {
	var song:String;
	var notes:Array<SectionJson>;
	var bpm:Float;
	var speed:Float;
	var offsets:Array<Int>;
	var stage:String;
	var players:Array<String>;
}

typedef SongMeta = {
	var events:Array<SectionJson>;
	var offsets:Array<Int>;
	var diffs:Array<String>;
	//var bpm:Float;
}

class Song
{
	private static final CHART_FORMATS:Array<String> = [
		'json', 					// Vanilla FNF
		'osu', 						// Osu! Mania
		'sm', 'ssc', 				// Stepmania
		'qua', 						// Quaver
		'chart'						// Guitar Hero
	];

	public static function loadFromFile(diff:String, folder:String):SongJson
	{
		folder = formatSongFolder(folder);
		
		CHART_FORMATS.fastForEach((format, i) -> {
			final chartPath:String = Paths.chart(folder, diff, format);
			var meta = getSongMeta(folder);
			if (meta != null) meta = meta.diffs.contains(diff) ? meta : null; // Only use if diff is included

			if (Paths.exists(chartPath, TEXT)) {
				switch (format) {
					case 'json':		return checkSong(parseJson(chartPath), meta, true, diff);		 		// Funkin chart
					case 'osu':			return checkSong(OsuFormat.convertSong(chartPath), meta, false, diff);	// Osu chart
					case 'sm' | 'ssc': 	return checkSong(SmFormat.convert(chartPath, diff), meta, false, diff); // Stepmania chart
					case 'qua': 		return checkSong(QuaFormat.convertSong(chartPath), meta, false, diff);	// Quaver chart
					case 'chart':		return checkSong(GhFormat.convertSong(chartPath), meta, false, diff);	// Guitar hero chart
				}
			}
		});

		trace('$folder-$diff CHART NOT FOUND');
		
		if (folder == "tutorial") if (diff == "hard") // Couldnt even find tutorial safe fail
		{
			throw 'Failed to load chart';
			return null;
		}
		
		return loadFromFile('hard', 'tutorial');
	}

	inline public static function getSongMeta(song:String):Null<SongMeta> {
		var meta = CoolUtil.getFileContent(Paths.songMeta(song));
		return meta.length > 0 ? cast Json.parse(meta) : null;
	}

	//Check null values and remove unused format variables
	public static function checkSong(?song:SongJson, ?meta:SongMeta, checkEngine:Bool = false, diff:String = ""):SongJson
	{
		if (checkEngine) {
			meta = FunkinFormat.metaCheck(meta, diff);
			song = FunkinFormat.songCheck(song, meta, diff);
		}

		song = JsonUtil.checkJson(getDefaultSong(), song);
		
		if (song.notes.length != 0) {
			song.notes.fastForEach((section, i) -> {
				checkSection(section);
				if (section.sectionNotes.length > 100 && !CoolUtil.debugMode) // Fuck off
					return getDefaultSong();
			});
		}
		else {
			song.notes.push(getDefaultSection());
		}

		// Apply song metaData
		if (meta != null) {
			song.offsets = meta.offsets.copy();
			
			meta.events.fastForEach((section, s) -> {
				if (Reflect.hasField(section, "sectionEvents")) {
					section.sectionEvents.copy().fastForEach((event, e) -> {
						song.notes[s].sectionEvents.push(event);
					});
				}
			});
		}

		return song;
	}

	public static function checkSection(section:Null<SectionJson> = null):SectionJson
	{
		section = JsonUtil.checkJson(getDefaultSection(), section);
		final foundNotes:Map<String, Int> = [];
		final uniqueNotes:Array<Array<Dynamic>> = []; // Skip duplicate notes

		section.sectionNotes.fastForEach((n, i) -> {
			var key = Math.floor(n[0]) + "-" + n[1] + "-" + n[3];
			if (!foundNotes.exists(key))
			{
				if (n[1] > Conductor.STRUMS_LENGTH - 1) // Convert extra key charts to 4 key
				{
					if (n[3] == null) n.push("default-extra");
					else if (n[3] == 0) n.unsafeSet(3, "default-extra");
					n.unsafeSet(1, n[1] % Conductor.STRUMS_LENGTH);
				}

				foundNotes.set(key, 0);
				uniqueNotes.push(n);
			}
		});

		foundNotes.clear();
		section.sectionNotes = uniqueNotes;

		return section;
	}

	public static function getSectionTime(song:SongJson, section:Int = 0):Float {
		var crochet:Float = (60000 / song.bpm);
        var time:Float = 0;

		checkAddSections(song, section);

		var i:Int = 0;
		while (i < section) {
			if (song.notes[i].changeBPM) {
				crochet = (60000 / song.notes[i].bpm);
			}

			time += Conductor.BEATS_PER_MEASURE * crochet;
			i++;
		}
        
		return time;
	}

	public static function checkAddSections(song:SongJson, index:Int, i:Int = 0):Void
	{
		final notes:Array<SectionJson> = song.notes;
		
		while (notes.length < index + 1)
			notes.push(getDefaultSection());

		while (i < index) {
			if (notes[i] == null)  notes.unsafeSet(i, getDefaultSection());
			i++;
		}
	}

	public static function getTimeSection(song:SongJson, time:Float):Int
	{
		var section:Int = 0;
		var startTime:Float = 0;
		var endTime:Float = getSectionTime(song, 1);

		while (!(time >= startTime && time < endTime))
		{
			section++;
			startTime = endTime;
			endTime = getSectionTime(song, section+1);
		}

		return section;
	}

	//Removes unused variables for smaller size
	public static function optimizeJson(input:SongJson, metaClear:Bool = false):SongJson
	{
		var song:SongJson = JsonUtil.copyJson(input);
		song.notes.fastForEach((sec, i) -> {
			if (!sec.changeBPM) {
				Reflect.deleteField(sec, 'changeBPM');
				Reflect.deleteField(sec, 'bpm');
			}

			if (sec.sectionNotes.length <= 0) {
				Reflect.deleteField(sec, 'sectionNotes');
			}
			else
			{
				sec.sectionNotes.fastForEach((note, i) -> {
					final type:String = Std.string(note[3]);
					if (type != null) if (type.length <= 0 || type == "default") {
						note.pop(); 
					}
				});
				sec.sectionNotes.sort(sortNotes);
			}

			if (sec.sectionEvents.length <= 0 || metaClear)
				Reflect.deleteField(sec, 'sectionEvents');

			if (sec.mustHitSection)
				Reflect.deleteField(sec, 'mustHitSection');
		});

		if (song.notes.length > 1)
		{
			while (true) {
				final lastSec = song.notes[song.notes.length - 1];
				if (lastSec == null) break;
				if (Reflect.fields(lastSec).length <= 0) 	song.notes.pop();
				else 										break;
			}
		}

		if (metaClear) {
			Reflect.deleteField(song, 'offsets');
			//Reflect.deleteField(song, 'bpm');
		}
		
		return song;
	}

	public static function parseJson(chartPath:String, rawJson:String = ""):SongJson
	{
		if (rawJson.length <= 0) {
			rawJson = CoolUtil.getFileContent(chartPath).trim();
			while (!rawJson.endsWith("}"))
				rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		return cast Json.parse(rawJson).song;
	}

	/*
		Use this function to get the sorted notes from a song as an array
		Used for pico in Stress, but you can use it on other cool stuff
	*/
	public static function getSongNotes(diff:String, song:String):Array<Array<Dynamic>>
	{
		final notes:Array<Array<Dynamic>> = [];
		
		loadFromFile(diff, song).notes.fastForEach((s, i) -> {
			if (s.sectionNotes != null) {
				s.sectionNotes.fastForEach((n, i) -> {
					notes.push(n);
				});
			}
		});

		notes.sort(sortNotes);
		return notes;
	}

	private static function sortNotes(note1:Array<Dynamic>, note2:Array<Dynamic>):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, note1[0], note2[0]);
	}

	public static function formatSongFolder(songName:String):String {
		var folder:String = "";
		songName.split("").fastForEach((char, i) -> {
			switch (char) {
				case "." | "?" | "*" | '"' | "'":
				case " " | ":":				folder = (folder + "-");
				default:					folder = (folder + char.toLowerCase());
			}
		});
		return folder;
	}

	inline public static function getDefaultSong():SongJson {
		return {
			song: 'Test',
			notes: [],
			bpm: 150,
			stage: 'stage',
			players: ['bf','dad','gf'],
			offsets: [0,0],
			speed: 1,
		};
	}

	inline public static function getDefaultSection():SectionJson {
		return {
			sectionNotes: [],
			sectionEvents: [],
			mustHitSection: true,
			bpm: 0,
			changeBPM: false
		};
	}
}