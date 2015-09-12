package;


class ObjectGroup {


	public var label:String;
	public var nodes:Array<ObjectNode>;

	public var inclusiveSize:Int;

	public function new () {}


	public static function sortByInstances (groups:Array<ObjectGroup>):Void {

		groups.sort (function (a:ObjectGroup, b:ObjectGroup):Int {
			return b.nodes.length - a.nodes.length;
		});
		
	}


	public static function sortBySize (groups:Array<ObjectGroup>):Void {

		groups.sort (function (a:ObjectGroup, b:ObjectGroup):Int {
			return b.inclusiveSize - a.inclusiveSize;
		});
		
	}


	public function compute (depthLimit:Int):Void {
		inclusiveSize = computeInclusiveSize (depthLimit);
	}


	private function computeInclusiveSize (depthLimit:Int):Int {
		var size = 0;
		var visited = new Map<Int, Bool> ();
		for (n in nodes) {
			size += n.inclusiveSize (visited, depthLimit, 0);
		}
		return size;
	}


}
