package;


class ObjectNode {


	public var addr:Int;
	public var className:String;
	public var fieldName:String;
	public var size:Int;
	public var members:Array<ObjectNode>;
	public var memberNames:Array<String>;
	public var referrers:Array<ObjectNode>;

	// here for convenience. not computed by default.
	public var inclSize:Int;


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


	public function inclusiveSize (visited:Map<Int, Bool>, depthLimit:Int, depth:Int):Int {

		if (visited.get (addr) != null) {
			return 0;
		}
		visited.set (addr, true);

		if (depth > depthLimit) {
			return 0;
		}

		var size = this.size;

		for (m in members) {
			size += m.inclusiveSize (visited, depthLimit, depth + 1);
		}

		return size;

	}


	public function findRoots (
		rootPaths:Array<Array<ObjectNode>>,
		visited:Map<Int, Bool>,
		stack:Array<ObjectNode>
	):Void {

		if (visited.get (addr) != null) {
			return;
		}
		visited.set (addr, true);

		stack.push (this);

		var isRoot = true;
		for (refr in referrers) {
			if (refr.referrers.length > 0) {
				isRoot = false;
			}
			refr.findRoots (rootPaths, visited, stack);
		}
		
		// TODO(james4k): what are these <unknown> guys that we have no names
		// for?? may be rooted by stack, but hard to tell
		//if (isRoot) {
		if (isRoot && className != "<unknown>") {
			rootPaths.push (stack.copy ());
		}

		stack.pop ();

	}


}
