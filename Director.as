package  {
	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.events.Event;

	// plays back (and records) sequences
	public class Director implements IEventDispatcher {
		
		public static var self:Director = new Director();
		public static const ON_DIRECT:String = "OnDirect";
		
		private var mDispatcher:EventDispatcher;
		private var mArgs:*;
		private var mCommand:String;

		public function Director() {
			// constructor code
			mDispatcher = new EventDispatcher(this);
		}
		
		public function Direct(command:String, args:*=null):void
		{
			mArgs = args;
			mCommand = command;
			dispatchEvent(new Event(ON_DIRECT));
			mCommand = null;
			mArgs = null;
		}
		
		public function get command():String	{ return mCommand; }
		public function get args():*			{ return mArgs; }
		
		// IEventDispatcher
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			mDispatcher.addEventListener(type, listener, useCapture, priority);
		}
	
		public function dispatchEvent(evt:Event):Boolean
		{
			return mDispatcher.dispatchEvent(evt);
		}
	
		public function hasEventListener(type:String):Boolean
		{
			return mDispatcher.hasEventListener(type);
		}
	
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			mDispatcher.removeEventListener(type, listener, useCapture);
		}
	
		public function willTrigger(type:String):Boolean
		{
			return mDispatcher.willTrigger(type);
		}

	}
	
}
