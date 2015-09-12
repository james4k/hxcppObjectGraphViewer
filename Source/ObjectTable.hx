package;


class ObjectTable {


	public var classNameIDs = new Map<String, Int> ();
	public var fieldNameIDs = new Map<String, Int> ();
	public var classNames = new Array<String> ();
	public var fieldNames = new Array<String> ();
	public var lastClassID = 0;
	public var lastFieldID = 0;

	// table
	public var thisAddrs = new Array<Int> ();
	public var memberAddrs = new Array<Int> ();
	public var memberSizes = new Array<Int> ();
	public var memberClassIDs = new Array<Int> ();
	public var memberFieldIDs = new Array<Int> ();

	// graph
	public var addrNodes = new Map<Int, ObjectNode> ();
	//public var roots = new Array<ObjectNode> ();


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

			}	

		} catch (e:haxe.io.Eof) {
		}

		table.buildGraph ();

		return table;

	}


	private function buildGraph () {

		for (i in 0...(thisAddrs.length)) {

			var thisNode = addrNodes.get (thisAddrs[i]);
			var memberNode = addrNodes.get (memberAddrs[i]);
			if (thisNode == null) {
				thisNode = new ObjectNode ();
				thisNode.addr = thisAddrs[i];
				thisNode.className = "<unknown>";
				thisNode.members = new Array<ObjectNode> ();
				thisNode.memberNames = new Array<String> ();
				thisNode.referrers = new Array<ObjectNode> ();
				addrNodes.set (thisAddrs[i], thisNode);
			}
			if (memberNode == null) {
				memberNode = new ObjectNode ();
				memberNode.addr = memberAddrs[i];
				memberNode.className = classNames[memberClassIDs[i]];
				memberNode.fieldName = fieldNames[memberFieldIDs[i]];
				memberNode.size = memberSizes[i];
				memberNode.members = new Array<ObjectNode> ();
				memberNode.memberNames = new Array<String> ();
				memberNode.referrers = new Array<ObjectNode> ();
				addrNodes.set (memberAddrs[i], memberNode);
			} else if (memberNode.className == "<unknown>") {
				memberNode.className = classNames[memberClassIDs[i]];
				memberNode.fieldName = fieldNames[memberFieldIDs[i]];
				memberNode.size = memberSizes[i];
			}

			thisNode.members.push (memberNode);
			thisNode.memberNames.push (fieldNames[memberFieldIDs[i]]); 
			memberNode.referrers.push (thisNode);
			
		}

#if 0
		for (node in addrNodes) {
			if (node.className == "<unknown>") {
				roots.push (node);
			}
		}
#end

	}


}

