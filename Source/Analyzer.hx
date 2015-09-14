package;


class Analyzer {


	public var depthLimit = 0;

	public var totalBytes = 0;
	public var totalObjects = 0;


	var table:ObjectTable;
	var classIDSets = new Map<Int, Map<ObjectNode, Bool>> ();


	public function new () {}


	public function open (path:String) {

		var f = sys.io.File.read (path);
		table = ObjectTable.read (f);
		f.close ();

		{
			var visited = new Map<Int, Int> ();
			totalBytes = 0;
			totalObjects = 0;
			for (i in 0...(table.memberAddrs.length)) {
				var addr = table.memberAddrs[i];
				if (visited.get (addr) != null) {
					continue;
				}
				visited.set (addr, 1);
				totalBytes += table.memberSizes[i];
				totalObjects += 1;
			}
		}
	
		// precompute classIDSets
		for (i in 0...(table.thisAddrs.length)) {

			var set = classIDSets.get (table.memberClassIDs[i]);
			if (set == null) {
				set = new Map<ObjectNode, Bool> ();
				classIDSets.set (table.memberClassIDs[i], set);
			}
			var node = table.addrNodes.get (table.memberAddrs[i]);
			if (node == null) {
				throw 'ObjectNode not found for addr ${table.memberAddrs[i]}';
			}
			set.set (node, true);

		}


	}


	public function lookupNode (addr:Int):ObjectNode {

		return table.addrNodes.get (addr);
		
	}


	public function groupByType ():Array<ObjectGroup> {

		return aggregate ();

	}


	private function aggregate ():Array<ObjectGroup> {

		var groups = new Array<ObjectGroup> ();

		for (classID in classIDSets.keys ()) {
			var set = classIDSets.get (classID);
			var g = new ObjectGroup ();
			g.label = table.classNames[classID];
			g.nodes = new Array<ObjectNode> ();
			for (n in set.keys()) {
				g.nodes.push (n);
			}
			g.compute (depthLimit);
#if 0
			// nothing too interesting with refCounts. doesn't differ too much
			// from instance counts
			g.refCount = 0;
			for (id in memberClassIDs) {
				if (id == classID) {
					g.refCount += 1;
				}
			}
#end
			groups.push (g);
		}

		return groups;

	}


}

