package funkin.states.editors.chart;

import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import haxe.io.Bytes;
import lime.media.AudioBuffer;

/*
    Inspired by the Kade Engine waveform class
    https://github.com/Kade-github/Kade-Engine/blob/stable/source/Waveform.hx
*/

class ChartWaveform extends FlxSprite {
    public var audioBuffer:AudioBuffer;
	public var audioBytes:Bytes;
    public var soundOffset:Float = 0;

    public function new(sound:FlxSound) {
        super();
        @:privateAccess {
            if (sound._sound == null || sound._sound.__buffer == null) return;
            audioBuffer = sound._sound.__buffer;
            audioBytes = sound._sound.__buffer.data.toBytes();
        }
        makeGraphic(ChartGrid.GRID_SIZE * Conductor.STRUMS_LENGTH, ChartGrid.GRID_SIZE * Conductor.STEPS_SECTION_LENGTH, FlxColor.TRANSPARENT);

        color = 0x5e3c92;
        alpha = 0.8;
        drawWaveform();
    }

    public function updateWaveform() {
        drawWaveform(ChartingState.getSecTime(ChartingState.instance.sectionIndex) - soundOffset, ChartingState.getSecTime(ChartingState.instance.sectionIndex + 1) - soundOffset);
    }

    function clearPixels() {
        pixels.fillRect(new Rectangle(0,0,width,height), FlxColor.fromRGB(0,0,0,1));
    }

    public function getIndexTime(time:Float) {
        var index = time * audioBuffer.sampleRate / 1000;
        index = Math.max(index, 0);
        return index;
    }

    public function drawWaveform(startTime:Float = 0, endTime:Float = 0) {
        if (!visible) return;
        clearPixels();
        var startIndex:Int = Std.int(getIndexTime(startTime) * 4);
        var endIndex:Int = Std.int(getIndexTime(endTime) * 4);
        var indexLength:Int = endIndex - startIndex;

        var lastBytes:Array<Int> = [];
        var useBytes:Array<Int> = [];

        var i:Int = 0; // Get a scaled down average
        while(i < indexLength) {
            var byte:Int = audioBytes.getUInt16(i + startIndex);
            lastBytes.push(byte);
            if (lastBytes.length == 128) {
                var sum:Int = 0;
                for (num in lastBytes) sum += num;
                var average:Int = Std.int(sum / lastBytes.length);
                useBytes.push(average);
                lastBytes = [];
            }
            i++;
        }

        var mid = width * 0.5;
        var points:Array<FlxPoint> = [new FlxPoint(mid,0)];

        i = 0;
        var min:Float = 0;
		var max:Float = 0;
        var _length = useBytes.length;  // Get draw points
        while(i < _length) {
            var byte = useBytes[i];
            var lineY = FlxMath.remapToRange(i, 0, _length, 0, height);
            if (byte > 0) {
                if (byte > 65535 / 2) byte -= 65535;
                var sample:Float = (byte / 65535);
                if (sample > 0)         if (sample > max) max = sample;
                else if (sample < 0)    if (sample < min) min = sample;
    
                var pixelsMin:Float = Math.abs(min * 300);
                var pixelsMax:Float = max * 300;
                min = max = 0;
    
                var lineWidth = (pixelsMin + pixelsMax) * 0.5;
                points.push(new FlxPoint(mid + lineWidth, lineY));
                points.push(new FlxPoint(mid - lineWidth, lineY));
            } else points.push(new FlxPoint(mid, lineY));
            i++;
        }
        points.push(new FlxPoint(mid,height));
        FlxSpriteUtil.drawPolygon(this, points, FlxColor.WHITE, {thickness: 0.75, color:FlxColor.WHITE}); // Draw waveform
    }
}