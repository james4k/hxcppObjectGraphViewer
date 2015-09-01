package;


class ObjectNode {

	public var addr:Int;
	public var className:String;
	public var size:Int;
	public var members:Array<ObjectNode>;
	public var memberNames:Array<String>;
	//public var owners:Array<ObjectNode>;

	public function new () {}

	public function totalCount (visited:Map<Int, Bool>):Int {

		if (visited.get (addr) != null) {
			return 0;	
		}
		visited.set (addr, true);

		var count = 1;

		for (m in members) {
			count += m.totalCount (visited);
		}

		return count;

	}

	public function inclusiveSize (visited:Map<Int, Bool>):Int {

		if (visited.get (addr) != null) {
			return 0;
		}
		visited.set (addr, true);

		var size = this.size;

		for (m in members) {
			size += m.inclusiveSize (visited);
		}

		return size;

	}

}


class ObjectGroup {

	public var label:String;
	public var nodes:Array<ObjectNode>;

	public var inclusiveSize:Int;

	public function new () {}

	public function compute ():Void {
		inclusiveSize = computeInclusiveSize ();
	}

	private function computeInclusiveSize ():Int {
		var size = 0;
		var visited = new Map<Int, Bool> ();
		for (n in nodes) {
			size += n.inclusiveSize (visited);
		}
		return size;
	}

}


class ObjectTable {


	var classNameIDs = new Map<String, Int> ();
	var fieldNameIDs = new Map<String, Int> ();
	var classNames = new Array<String> ();
	var fieldNames = new Array<String> ();
	var lastClassID = 0;
	var lastFieldID = 0;

	// table
	var thisAddrs = new Array<Int> ();
	var memberAddrs = new Array<Int> ();
	var memberSizes = new Array<Int> ();
	var memberClassIDs = new Array<Int> ();
	var memberFieldIDs = new Array<Int> ();

	// graph
	var addrNodes = new Map<Int, ObjectNode> ();
	var roots = new Array<ObjectNode> ();


	public function new () {}


	public static function read (input:haxe.io.Input):ObjectTable {

		var table = new ObjectTable ();

		try {

			var tableHeader = input.readLine ();
			if (tableHeader != "this_addr,member_addr,member_size,member_class_name,member_field_name") {
				throw "unexpected table header";
			}
	
			while (true) {

				var line = input.readLine ();
				if (line.length == 0) {
					continue;
				}

				var cells = line.split (",");
				if (cells.length != 5) {
					throw "unexpected table format";
				}

				table.thisAddrs.push (Std.parseInt ("0x" + cells[0]));
				table.memberAddrs.push (Std.parseInt ("0x" + cells[1]));
				table.memberSizes.push (Std.parseInt (cells[2]));
				{
					var id = table.classNameIDs.get (cells[3]);
					if (id == null) {
						id = table.lastClassID++;
						table.classNameIDs.set(cells[3], id);
						table.classNames.push(cells[3]);
					}
					table.memberClassIDs.push (id);
				}
				{
					var id = table.fieldNameIDs.get (cells[4]);
					if (id == null) {
						id = table.lastFieldID++;
						table.fieldNameIDs.set(cells[4], id);
						table.fieldNames.push(cells[4]);
					}
					table.memberFieldIDs.push (id);
				}

				if (cells[2] == "7875540") {
					trace (cells[0], cells[1], cells[2], cells[3], cells[4]);
				}

			}	

		} catch (e:haxe.io.Eof) {
		}

		table.buildGraph ();

		return table;

	}


	public function aggregate ():Array<ObjectGroup> {

		var classIDSets = new Map<Int, Map<ObjectNode, Bool>> ();

		for (i in 0...(thisAddrs.length)) {

			var set = classIDSets.get (memberClassIDs[i]);
			if (set == null) {
				set = new Map<ObjectNode, Bool> ();
				classIDSets.set (memberClassIDs[i], set);
			}
			var node = addrNodes.get (memberAddrs[i]);
			if (node == null) {
				throw 'ObjectNode not found for addr ${memberAddrs[i]}';
			}
			set.set (node, true);

		}

		var groups = new Array<ObjectGroup> ();

		for (classID in classIDSets.keys ()) {
			var set = classIDSets.get (classID);
			var g = new ObjectGroup ();
			g.label = classNames[classID];
			g.nodes = new Array<ObjectNode> ();
			for (n in set.keys()) {
				g.nodes.push (n);
			}
			g.compute ();
			groups.push (g);
		}

		groups.sort (function (a:ObjectGroup, b:ObjectGroup):Int {
			return b.inclusiveSize - a.inclusiveSize;	
		});

		return groups;

	}


	private function buildGraph () {

		for (i in 0...(thisAddrs.length)) {

			var thisNode = addrNodes.get (thisAddrs[i]);
			var memberNode = addrNodes.get (memberAddrs[i]);
			if (thisNode == null) {
				thisNode = new ObjectNode ();
				thisNode.addr = thisAddrs[i];
				thisNode.className = "<root>";
				thisNode.members = new Array<ObjectNode> ();
				thisNode.memberNames = new Array<String> ();
				addrNodes.set (thisAddrs[i], thisNode);
			}
			if (memberNode == null) {
				memberNode = new ObjectNode ();
				memberNode.addr = memberAddrs[i];
				memberNode.className = classNames[memberClassIDs[i]];
				memberNode.size = memberSizes[i];
				memberNode.members = new Array<ObjectNode> ();
				memberNode.memberNames = new Array<String> ();
				addrNodes.set (memberAddrs[i], memberNode);
			} else if (memberNode.className == "<root>") {
				memberNode.className = classNames[memberClassIDs[i]];
			}

			thisNode.members.push (memberNode);
			thisNode.memberNames.push (fieldNames[memberFieldIDs[i]]); 
			
		}

		for (node in addrNodes) {
			if (node.className == "<root>") {
				roots.push (node);
			}
		}

	}


}

