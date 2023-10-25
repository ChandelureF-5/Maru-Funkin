package funkin.graphics;

import flixel.system.FlxAssets;
import flixel.math.FlxMatrix;
import flixel.graphics.frames.FlxFrame;
import openfl.text.TextFormat;
import openfl.text.TextField;

// rappergf >:3

enum TextStyle {
    NONE;
    OUTLINE(thickness:Float, ?quality:Int, ?color:FlxColor);
    SHADOW(offset:FlxPoint, ?color:FlxColor);
}

class FlxFunkText extends FlxSprite {
    public var text(default, set):String = "";
    function set_text(value:String) {
        if (value != text) {
            textField.text = value;
            drawTextField();
        }
        return text = value;
    }

    public var size(default, set):Int = 16;
    function set_size(value:Int) {
        if (value != textFormat.size) {
            textFormat.size = value;
            updateFormat();
        }
        return value;
    }

    public var font(default, set):String = "vcr";
    function set_font(value:String = "vcr") {
        if (font != value) {
            final _font = Paths.font(value);
            textFormat.font = Paths.exists(_font, FONT) ? OpenFlAssets.getFont(_font).fontName : FlxAssets.FONT_DEFAULT;
            font = textFormat.font;
            updateFormat();
        }
        return value;
    }

    function updateFormat() {
        textField.defaultTextFormat = textFormat;
        textField.setTextFormat(textFormat);
        drawTextField();
    }

    public var textWidth(get, never):Float;
    public var textHeight(get, never):Float;
    function get_textWidth() @:privateAccess return textField.__textEngine.textWidth;
    function get_textHeight() @:privateAccess return textField.__textEngine.textHeight;

    function drawTextField() {        
        _textMatrix.tx = textField.x;
        _textMatrix.ty = textField.y;

        @:privateAccess
        textField.__textEngine.update();
        pixels.fillRect(_fillRect, FlxColor.TRANSPARENT);
        pixels.draw(textField, _textMatrix, null, null, null, antialiasing);
    }

    public var alignment(default, set):String = "left";
    function set_alignment(value:String) {
        alignment = alignment.toLowerCase().trim();
        if (alignment != value) {
            alignment = value;
            switch (alignment) {
                case "right": textFormat.align = RIGHT;
                case "center": textFormat.align = CENTER;
                default: textFormat.align = LEFT;
            }
            updateFormat();
        }
        return value;
    }
    
    var textField:TextField;
    var textFormat:TextFormat;
    var _fillRect:Rectangle;
    var _textMatrix:FlxMatrix;

    public function new(X:Float=0, Y:Float=0, Text:String="", ?canvasRes:FlxPoint, ?size:Int) {
        super();
        canvasRes = canvasRes ?? FlxPoint.get(FlxG.width,FlxG.height);

        textField = new TextField();
        textField.width = Std.int(canvasRes.x);
        textField.height = Std.int(canvasRes.y);
        textFormat = new TextFormat(OpenFlAssets.getFont(Paths.font("vcr")).fontName, 16, 0xffffff);
        textField.defaultTextFormat = textFormat;

        _fillRect = new Rectangle(0,0,cast textField.width,cast textField.height);
        _textMatrix = new FlxMatrix();

        makeGraphic(cast textField.width,cast textField.height,FlxColor.TRANSPARENT,true);
        setPosition(X,Y);
        text = Text;
        if (size != null) {
            this.size = size;
        }
    }

    public var style:TextStyle = NONE;
    inline function sizeMult() {
        return size / 16;
    }

    override function draw() {
        if (alpha == 0) return;
        
        switch (style) {
            case OUTLINE(thicc, quality, col):
                final _offset = offset.clone();
                final _color = color;
                thicc *= sizeMult();

                color = col ?? FlxColor.BLACK;
                quality = quality ?? 8;
                for (i in 0...quality) {
                    final gay = (i / quality) * 2 * Math.PI;
                    offset.copyFrom(_offset);
                    offset.add(Math.cos(gay)*thicc, Math.sin(gay)*thicc);
                    _draw();
                }
                
                offset.copyFrom(_offset);
                color = _color;

            case SHADOW(off, col):
                final _offset = offset.clone();
                final _color = color;
                offset.add(off.x*sizeMult(),off.y*sizeMult());
                color = col ?? FlxColor.BLACK;
                _draw();
                offset.copyFrom(_offset);
                color = _color;

            default:
        }
        super.draw();
    }

    public function _draw():Void {
		if (alpha == 0 || _frame == null || _frame.type == FlxFrameType.EMPTY) return;
		for (cam in cameras) {
			if (!cam.visible || !cam.exists || !isOnScreen(cam)) continue;
            isSimpleRender(cam) ? drawSimple(cam) : drawComplex(cam);
		}
	}
}