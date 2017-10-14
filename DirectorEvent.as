package  {
	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.utils.IExternalizable;
	import flash.utils.IDataOutput;
	import flash.utils.IDataInput;
	import flash.net.registerClassAlias;
	
	public class DirectorEvent implements IEventDispatcher, IExternalizable{
		
		private var mStackId:String;
		public var val:*;
		private var mStart_ms:int;
		private var mEnd_ms:int;		
		private var mDispatcher:EventDispatcher;
		public var in_progress:Boolean;	// just a flag for the user
		
		registerClassAlias("DirectorEvent", DirectorEvent);
		
		private const NO_END:int = int.MAX_VALUE;

		public function DirectorEvent(stackId:String=null, _val:*=null, _start_ms:int=0, _end_ms:int=NO_END)
		{
			// constructor code
			in_progress = false;
			
			mStackId = stackId;
			val = _val;
			mStart_ms = _start_ms;
			mEnd_ms = _end_ms;
			
			mDispatcher = new EventDispatcher(this);
		}
		
		public function ShiftTime(ms:int):void
		{
			mStart_ms += ms;
			if (mEnd_ms != NO_END)
				mEnd_ms += ms;
			mDispatcher.dispatchEvent(new Event(Event.CHANGE))
		}
		
		public function Contains(time:Number):Boolean
		{
			return indefinite? (mStart_ms <= time) : (mStart_ms <= time && mEnd_ms >= time);
		}
		
		public function get stack_id():String { return mStackId; }
		public function get dur_ms():int { return mEnd_ms == NO_END? -1 : (mEnd_ms-mStart_ms); }
		public function get indefinite():Boolean { return mEnd_ms == NO_END; }
		
		public function get start_ms():int { return mStart_ms; }
		public function set start_ms(ms:int):void {
			mStart_ms = ms;
			mDispatcher.dispatchEvent(new Event(Event.CHANGE));
		}
		public function get end_ms():int { return mEnd_ms; }		
		public function set end_ms(ms:int):void {
			mEnd_ms = ms;
			mDispatcher.dispatchEvent(new Event(Event.CHANGE));
		}
		
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
		
		
		private const SRL_VERSION:int = 1;
		// IExternalizable
		public function writeExternal(output:IDataOutput):void {
			output.writeShort(SRL_VERSION);
			
			output.writeUTF(mStackId);
			output.writeInt(mStart_ms);
			output.writeInt(mEnd_ms);
			output.writeObject(val);
		}
 
		public function readExternal(input:IDataInput):void {
			var version:int = input.readShort();
			
			mStackId = input.readUTF();
			mStart_ms = input.readInt();
			mEnd_ms = input.readInt();
			val = input.readObject();
		}
	}
	
}
