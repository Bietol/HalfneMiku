package  {
	import flash.utils.Dictionary;
	
	public class Singleton {
		
		static var sSingletons:Dictionary = new Dictionary();
		
		static public function Set(idx:*, obj:Object):void
		{
			sSingletons[idx] = obj;
		}
		
		static public function Get(idx:*):*
		{
			return sSingletons[idx];
		}

		public function Singleton() {
			// constructor code
		}

	}
	
}
