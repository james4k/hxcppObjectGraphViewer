package;


import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Keyboard;
import openfl.Assets;


class Main extends Sprite {


	var azr = new Analyzer ();
	var groups:Array<ObjectGroup>;

	var splitView:HSplitViewControl;
	var mainView:TableControl;
	var objectListView:TableControl;
	var objectAnalysisView:TableControl;

	var selectedGroup:ObjectGroup;
	var selectedNode:ObjectNode;

	var mainViewTab = OverviewTab;


	public function new () {
		
		super ();

		splitView = new HSplitViewControl (this);

		mainView = new TableControl (this);
		objectListView = new TableControl (this);
		objectAnalysisView = new TableControl (this);
		splitView.addControl (mainView);
		splitView.addControl (objectListView);
		splitView.addControl (objectAnalysisView);
		splitView.firstLayout (0, 0, stage.stageWidth, stage.stageHeight);
		splitView.moveSplitter (0, stage.stageWidth/2);
		splitView.moveSplitter (1, stage.stageWidth/2 + 140);

		mainView.onRowClick = onMainRowClick;
		objectListView.onRowClick = onObjectListRowClick;
		objectListView.onRowHover = onObjectListRowHover;
		objectAnalysisView.onRowClick = onObjectAnalysisRowClick;

		//onResize (null);

		stage.addEventListener (Event.RESIZE, onResize);
		stage.addEventListener (KeyboardEvent.KEY_UP, onKeyUp);

		// TODO(james4k): show a menu of most recent files

		var fd = new lime.ui.FileDialog ();
		fd.onSelect.add (onSelect);
		fd.onCancel.add (function ():Void { Sys.exit (0); });
		fd.browse ();

	}


	private function onSelect (path:String):Void {

		azr.open (path);
		update ();

	}


	private function onResize (event:Event):Void {

		splitView.updateLayout (0, 0, stage.stageWidth, stage.stageHeight);
		
	}


	private function onKeyUp (event:KeyboardEvent):Void {

		if (event.keyCode == Keyboard.UP) {
			azr.depthLimit += 1;
			update ();
		} else if (event.keyCode == Keyboard.DOWN) {
			azr.depthLimit -= 1;
			update ();
		}

	}


	private function onMainRowClick (event:MouseEvent, index:Int):Void {

		if (index == 0) {

			var word = mainView.getWordAt (event.stageX, event.stageY);
			if (word == "overview") {
				updateOverview ();
			} else if (word == "browser") {
				updateObjectBrowser ();
			}

			return;

		}

		if (mainViewTab == OverviewTab) {

			// account for header lines
			if (index >= 6) {
				selectedGroup = groups[index-6];
				updateObjectList ();
			}

		} else if (mainViewTab == BrowserTab) {

			var word = mainView.getWordAt (event.localX, event.localY);
			var addr = Std.parseInt ("0x" + word);
			if (addr != null && addr != 0) {
				var node = azr.lookupNode (addr);
				if (node != null) {
					selectedNode = node;
					updateObjectBrowser ();
					updateObjectAnalysis ();
				}
			}

		}
		
	}


	private function onObjectListRowClick (event:MouseEvent, index:Int):Void {

		// account for header lines
		if (index >= 3) {
			selectedNode = selectedGroup.nodes[index-3];
			updateObjectBrowser ();
		}
		
	}


	private function onObjectListRowHover (index:Int):Void {

		// account for header lines
		if (index >= 3) {
			selectedNode = selectedGroup.nodes[index-3];
			updateObjectAnalysis ();
			if (mainViewTab == BrowserTab) {
				updateObjectBrowser ();
			}
		}
		
	}


	private function onObjectAnalysisRowClick (event:MouseEvent, index:Int):Void {

		var word = objectAnalysisView.getWordAt (event.localX, event.localY);
		var addr = Std.parseInt ("0x" + word);
		if (addr != null && addr != 0) {
			var node = azr.lookupNode (addr);
			if (node != null) {
				selectedNode = node;
				updateObjectBrowser ();
				updateObjectAnalysis ();
			}
		}
		
	}


	public function update ():Void {

		groups = azr.groupByType ();
		ObjectGroup.sortBySize (groups);
		//ObjectGroup.sortByInstances (groups);
		updateOverview ();

	}

	
	private function updateOverview ():Void {

		mainViewTab = OverviewTab;

		var maxRows = 200;

		var str = new StringBuf ();
		str.add ('|<overview>| browser |\n\n');
		str.add ('total_bytes=${azr.totalBytes} total_objects=${azr.totalObjects}\n');
		str.add ('incl_walk_depth=${azr.depthLimit}');
		str.add ("    adjust with up/down keys\n\n");
		str.add (StringTools.lpad ("incl_size", " ", 10));
		str.add (StringTools.lpad ("n_inst", " ", 8));
		str.add ("  " + "class_name" + "\n");
		var nrows = 0;
		for (g in groups) {
			str.add (StringTools.lpad ("" + g.inclusiveSize, " ", 10));
			str.add (StringTools.lpad ("" + g.nodes.length, " ", 8));
			str.add ("  " + g.label + "\n");
			nrows += 1;
			if (nrows > maxRows) {
				break;
			}
		}

		mainView.setText (str.toString ());

	}


	private function updateObjectBrowser ():Void {

		mainViewTab = BrowserTab;

		var maxRows = 200;

		var str = new StringBuf ();
		str.add ('| overview |<browser>|\n\n');

		if (selectedNode == null) {
			mainView.setText (str.toString ());
			return;
		}

		var hexAddr = StringTools.hex (selectedNode.addr, 8);
		str.add (hexAddr);
		str.add (' field_name=${selectedNode.fieldName}');
		str.add (' class_name=${selectedNode.className}');
		str.add (' excl_size=${selectedNode.size}\n\n');

		str.add ('referrers\n');
		for (r in selectedNode.referrers) {
			hexAddr = StringTools.hex (r.addr, 8);
			str.add ('$hexAddr ${r.fieldName}:${r.className}\n');
		}

		str.add ('\nmembers\n');
		for (m in selectedNode.members) {
			hexAddr = StringTools.hex (m.addr, 8);
			str.add ('$hexAddr ${m.fieldName}:${m.className}\n');
		}

		mainView.setText (str.toString ());

	}


	private function updateObjectList ():Void {

		var maxRows = 200;

		var g = selectedGroup;
		if (g == null) {
			return;
		}

		var str = new StringBuf ();
		str.add ('${g.label}\n\n');
		str.add (StringTools.lpad ("incl_size", " ", 9));
		str.add (StringTools.lpad ("addr", " ", 9));
		str.add ("\n");
		//str.add ("  " + "class_name" + "\n");
		var nrows = 0;

		for (node in g.nodes) {
			var visited = new Map<Int, Bool> ();
			node.inclSize = node.inclusiveSize (visited, azr.depthLimit, 0);
		}
		g.nodes.sort (function (a:ObjectNode, b:ObjectNode):Int {
			return b.inclSize - a.inclSize;
		});
		for (node in g.nodes) {
			str.add (StringTools.lpad ("" + node.inclSize, " ", 9));
			str.add (StringTools.lpad ("" + StringTools.hex (node.addr, 8), " ", 9));
			//str.add ("  " + node.className);
			str.add ("\n");
			nrows += 1;
			if (nrows > maxRows) {
				break;
			}
		}

		objectListView.setText (str.toString ());

	}


	private function updateObjectAnalysis ():Void {

		var str = new StringBuf ();
		str.add ("roots\n\n");

		var node = selectedNode;
		if (node == null) {
			return;
		}

		var rootPaths = new Array<Array<ObjectNode>> ();
		{
			var visited = new Map<Int, Bool> ();
			node.findRoots (rootPaths, visited, new Array<ObjectNode> ());
		}
		rootPaths.sort (function (a:Array<ObjectNode>, b:Array<ObjectNode>):Int {
			return a.length - b.length;
		});
		for (i in 0...(rootPaths.length)) {
			var path = rootPaths[i];
			path.reverse ();
			var root = rootPaths[i][0];
			var addr = StringTools.hex (root.addr, 8);
			var prevArray = false;
			for (j in 0...(path.length)) {
				var node = path[j];
				if (node.className == "Array") {
					if (node.fieldName != "") {
						if (j != 0) str.add (".");
						str.add (node.fieldName);
					}
					prevArray = true;
				} else if (prevArray) {
					str.add ("[i]");
					prevArray = false;
				} else {
					if (node.fieldName != "") {
						if (j != 0) str.add (".");
						str.add (node.fieldName);
					}
				}
			}
			str.add ("\n");
			for (j in 0...(path.length)) {
				var node = path[j];
				addr = StringTools.hex (node.addr, 8);
				str.add ('  ${addr} ${node.fieldName}:${node.className}\n');
			}
		}

		objectAnalysisView.setText (str.toString ());

	}


}


enum MainViewTab {

	OverviewTab;
	BrowserTab;

}


class Control {


	public var posX:Float;
	public var posY:Float;
	public var sizeX:Float;
	public var sizeY:Float;


	public function updateLayout (x:Float, y:Float, w:Float, h:Float):Void {

		posX = x;
		posY = y;
		sizeX = w;
		sizeY = h;

	}


}


class HSplitViewControl extends Control {

	static var splitterWidth (default, never) = 6;

	var display:DisplayObjectContainer;

	var controls = new Array<Control> ();
	var splitters = new Array<Sprite> ();
	var leftControls = new Array<Control> ();
	var rightControls = new Array<Control> ();

	var activeSplitter = -1;


	public function new (display:DisplayObjectContainer) {

		this.display = display;

		display.addEventListener (MouseEvent.MOUSE_MOVE, onMouseMove);
		display.addEventListener (MouseEvent.MOUSE_UP, onMouseUp);

	}


	public override function updateLayout (x:Float, y:Float, w:Float, h:Float):Void {

		super.updateLayout (x, y, w, h);

		for (i in 0...(controls.length)) {
			var c = controls[i];	
			if (i < controls.length - 1) {
				c.updateLayout (c.posX, c.posY, c.sizeX, h);
			} else {
				c.updateLayout (c.posX, c.posY, w - c.posX, h);
			}
		}

		for (i in 0...(splitters.length)) {
			splitters[i].x = rightControls[i].posX - splitterWidth;
			splitters[i].height = h;
		}

	}


	public function addControl (c:Control):Void {

		controls.push (c);

		if (controls.length > 1) {
			addSplitter (controls[controls.length-2], controls[controls.length-1]);
		}

	}


	public function firstLayout (x:Float, y:Float, w:Float, h:Float):Void {

		var x:Float = 0;
		var cw = Math.floor ((w - splitterWidth * splitters.length) / controls.length);
		for (c in controls) {
			c.updateLayout (x, c.posY, cw, h);
			x += cw + splitterWidth;
		}

		posX = x;
		posY = y;
		sizeX = w;
		sizeY = h;
		
	}


	private function addSplitter (left:Control, right:Control) {

		var splitter = new Sprite ();
		splitter.graphics.beginFill (0xff333333);
		splitter.graphics.drawRect (0, 0, splitterWidth, splitterWidth);
		display.addChild (splitter);

		var splitterIndex = splitters.length;
		splitters.push (splitter);
		leftControls.push (left);
		rightControls.push (right);

		var hovering = false;
		var sizing = false;
		splitter.addEventListener (MouseEvent.MOUSE_OVER, function (event:MouseEvent):Void {
			hovering = true;
			//lime.ui.Mouse.cursor = RESIZE_WE;
		});

		splitter.addEventListener (MouseEvent.MOUSE_OUT, function (event:MouseEvent):Void {
			hovering = false;
			//lime.ui.Mouse.cursor = RESIZE_WE;
		});

		splitter.addEventListener (MouseEvent.MOUSE_DOWN, function (event:MouseEvent):Void {
			activeSplitter = splitterIndex;
		});

		splitter.addEventListener (MouseEvent.MOUSE_UP, onMouseUp);

	}


	private function onMouseMove (event:MouseEvent):Void {

		if (activeSplitter >= 0) {

			moveSplitter (activeSplitter, event.stageX);

		}

	}


	function onMouseUp (event:MouseEvent):Void {

		if (activeSplitter >= 0) {

			moveSplitter (activeSplitter, event.stageX);
			activeSplitter = -1;

		}

	}


	public function moveSplitter (index:Int, mouseX:Float):Void {

		var s = splitters[index];
		var left = leftControls[index];
		var right = rightControls[index];

		var minX = left.posX + 120;
		var maxX = right.posX + right.sizeX - 120;

		var gap = s.width;
		var x = mouseX - gap/2;
		if (x < minX) {
			x = minX;
		}
		if (x > maxX) {
			x = maxX;
		}
		s.x = x;

		left.updateLayout (left.posX, left.posY, x - left.posX, left.sizeY);
		right.updateLayout (x + gap, right.posY, right.sizeX + right.posX - (x+gap), right.sizeY);

	}


}


// TableControl is not really what you expect for a table
// control. It is more of a TextField that sort of acts like
// one.
class TableControl extends Control {


	public var onRowClick:MouseEvent->Int->Void;
	public var onRowHover:Int->Void;


	var tf:TextField;


	public function new (display:DisplayObjectContainer) {

		var textFormat = new TextFormat ("_typewriter", 12, 0x000000, false, false, false, "", "", TextFormatAlign.LEFT, 0, 0, 0, 0);
		tf = new TextField ();
		display.addChild (tf);
		tf.selectable = false;
		tf.defaultTextFormat = textFormat;
		tf.multiline = true;

		tf.addEventListener (MouseEvent.MOUSE_DOWN, onTextClick);
		tf.addEventListener (MouseEvent.MOUSE_OVER, onTextHover);

	}


	public override function updateLayout (x:Float, y:Float, w:Float, h:Float):Void {

		super.updateLayout (x, y, w, h);

		tf.x = x;
		tf.y = y;
		tf.width = (w > 0) ? w : 1;
		tf.height = (h > 0) ? h : 1;

	}


	public function setText (s:String):Void {

		tf.text = s;

	}


	private static function isValidWordChar (charCode:Int):Bool {

		if (charCode >= "0".code && charCode <= "9".code) {
			return true;
		}
		if (charCode >= "a".code && charCode <= "z".code) {
			return true;
		}
		if (charCode >= "A".code && charCode <= "Z".code) {
			return true;
		}
		if (charCode == "_".code) {
			return true;
		}
		return false;
		
	}

	public function getWordAt (x:Float, y:Float):String {

		var s = tf.text;
		var firstChar = tf.getCharIndexAtPoint (x, y);
		var line = tf.getLineIndexOfChar (firstChar);
		var minChar = tf.getLineOffset (line);
		var maxChar = minChar + tf.getLineLength (line);
		var lastChar = firstChar;
		while (true) {
			if (firstChar <= minChar) {
				break;
			}
			if (!isValidWordChar (s.charCodeAt (firstChar-1))) {
				break;
			}
			firstChar--;
		}
		while (true) {
			if (lastChar >= maxChar) {
				break;
			}
			if (!isValidWordChar (s.charCodeAt (lastChar+1))) {
				break;
			}
			lastChar++;
		}
		return s.substring (firstChar, lastChar+1);
	}


	private function onTextClick (event:MouseEvent):Void {

		if (onRowClick != null) {
			var lineIndex = tf.getLineIndexAtPoint (event.localX, event.localY);
			onRowClick (event, lineIndex);
		}

	}


	private function onTextHover (event:MouseEvent):Void {

		if (onRowHover != null) {
			var lineIndex = tf.getLineIndexAtPoint (event.localX, event.localY);
			onRowHover (lineIndex);
		}

	}


}
