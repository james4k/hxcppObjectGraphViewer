package;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.Assets;


class Main extends Sprite {


	var text:TextField;

	
	public function new () {
		
		super ();

		var textFormat = new TextFormat ("_typewriter", 12, 0x000000, false, false, false, "", "", TextFormatAlign.LEFT, 0, 0, 0, 0);
		text = new TextField ();
		text.defaultTextFormat = textFormat;
		text.width = 2000;
		text.height = 1200;
		addChild (text);

		var fd = new lime.ui.FileDialog ();
		fd.onSelect.add (onSelect);
		fd.onCancel.add (function ():Void { Sys.exit (0); });
		fd.browse ();

	}


	private function onSelect (path:String):Void {

		var f = sys.io.File.read (path);
		var table = ObjectTable.read (f);
		f.close ();

		var groups = table.aggregate ();
		var str = "";
		str += StringTools.lpad ("inclusive_size", " ", 15);
		str += StringTools.lpad ("num_instances", " ", 15);
		str += "  " + "class_name" + "\n";
		for (g in groups) {
			str += StringTools.lpad ("" + g.inclusiveSize, " ", 15);
			str += StringTools.lpad ("" + g.nodes.length, " ", 15);
			str += "  " + g.label + "\n";
		}

		text.text = str;

	}
	
	
}
