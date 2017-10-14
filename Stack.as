package  {
	
	public class Stack {
		
		private var mId:String;
		private var mStack:Array;

		public function Stack(id:String=null) {
			// constructor code
			mId = id;
			mStack = new Array();
		}
		
		public function Insert(pos:int, val:*):void
		{
			mStack.splice(pos, 0, val);
		}
		public function Push(val:*):void
		{
			mStack.push(val);
		}
		public function Pop(val:*=null):*
		{
			if (val == null)
				return mStack.pop();
			for (var i:int = mStack.length-1; i >= 0; i--)
			{
				if (mStack[i] == val)
				{
					mStack.splice(i, 1);
					return val;
				}
			}
		}
		public function Clear():void
		{
			mStack = new Array();
		}
		public function GetTop():*
		{
			var i:int = mStack.length - 1;
			return i >= 0? mStack[i] : null;
		}
		public function GetAt(pos:int):*
		{
			return mStack[pos];
		}
		
		public function get length():uint { return mStack.length; }

	}
	
}
