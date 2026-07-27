package openfl.display;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.math.FlxMath;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end

#if openfl
import openfl.system.System;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	// Add this to track the highest recorded memory usage
    private var memoryPeak:Float = 0;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.framerate) currentFPS = ClientPrefs.framerate;

		if (currentCount != cacheCount /*&& visible*/)
        {
            var memoryCurrent:Float = System.totalMemory;
            var memoryMegas:Float = Math.abs(FlxMath.roundDecimal(System.totalMemory / 1000000, 1));

            // Update peak memory if current memory exceeds the previous peak
            if (memoryCurrent > memoryPeak) {
                memoryPeak = memoryCurrent;
            }

            // Fetch setting values (use ClientPrefs.data on 0.7+)
            var fpsEnabled:Bool = ClientPrefs.showFPS;
            var ramEnabled:Bool = ClientPrefs.showRamUsage;
            var peakEnabled:Bool = ClientPrefs.showPeakMemory;

            var textLines:Array<String> = [];

            if (fpsEnabled)
            {
                textLines.push("FPS: " + currentFPS);
            }

            #if openfl
            if (ramEnabled)
            {
                if (peakEnabled) {
                    textLines.push("Memory: " + formatMemory(memoryCurrent) + " / " + formatMemory(memoryPeak));
                } else {
                    textLines.push("Memory: " + formatMemory(memoryCurrent));
                }
            }
            #end

            text = textLines.join("\n");

            textColor = 0xFFFFFFFF;
            if (memoryMegas > 3000 || currentFPS <= ClientPrefs.framerate / 2)
            {
                textColor = 0xFFFF0000;
            }

            #if (gl_stats && !disable_cffi && (!html5 || !canvas))
            text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
            text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
            text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
            #end

            text += "\n";
		}

		cacheCount = currentCount;
	}
	/**
	* Forces an immediate refresh of the text string based on current ClientPrefs.
	*/
	public function updateText():Void
	{
		var memoryCurrent:Float = System.totalMemory;

		// Fetch setting values (use ClientPrefs.data on 0.7+)
		var fpsEnabled:Bool = ClientPrefs.showFPS;
		var ramEnabled:Bool = ClientPrefs.showRamUsage;
		var peakEnabled:Bool = ClientPrefs.showPeakMemory;

		var textLines:Array<String> = [];

		if (fpsEnabled)
		{
			textLines.push("FPS: " + currentFPS);
		}

		#if openfl
		if (ramEnabled)
		{
			if (peakEnabled) {
				textLines.push("Memory: " + formatMemory(memoryCurrent) + " / " + formatMemory(memoryPeak));
			} else {
				textLines.push("Memory: " + formatMemory(memoryCurrent));
			}
		}
		#end

		text = textLines.join("\n");

		#if (gl_stats && !disable_cffi && (!html5 || !canvas))
		text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
		text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
		text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
		#end

		text += "\n";
	}
}
private function formatMemory(bytes:Float):String 
{
    var mb:Float = bytes / (1024 * 1024);
    
    if (mb >= 1024) {
        var gb:Float = mb / 1024;
        // Formats to 2 decimal places (e.g., 1.25 GB)
        return FlxMath.roundDecimal(gb, 2) + " GB";
    }
    
    // Formats to 2 decimal places (e.g., 450.50 MB)
    return FlxMath.roundDecimal(mb, 2) + " MB";
}