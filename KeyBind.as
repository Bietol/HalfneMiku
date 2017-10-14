package  {
	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.events.KeyboardEvent;
	
	public class KeyBind implements IEventDispatcher{
		
		static private var sKeybinds:Vector.<KeyBind> = new Vector.<KeyBind>;		
		
		internal var mId:String;
		internal var mKeyCode:int;
		private var mDisplayName:String;
		private var mDispatcher:EventDispatcher;
		private var mListener:EventDispatcher;
		private var mDown:Boolean;
		
		// static methods
		static public function GetKeyBinds():Vector.<KeyBind>
		{
			return sKeybinds;
		}
		static public function WriteToByteArray(data_out:ByteArray):void
		{
			// count, [id, keycode], [id, keycode], ...
			data_out.writeInt(sKeybinds.length);
			for each (var kb:KeyBind in sKeybinds)
			{
				data_out.writeUTF(kb.mId);
				data_out.writeInt(kb.mKeyCode);
			}
		}
		static public function ReadFromByteArray(data_in:ByteArray):void
		{
			var binds:int = data_in.readInt();
			for (var i:int = 0; i < binds; i++)
			{
				var id:String = data_in.readUTF();
				var kc:int = data_in.readInt();
				// find and rebind the match keybind
				for each (var kb:KeyBind in sKeybinds)
				{
					if (kb.mId == id)
					{
						kb.Rebind(kc);
						break;
					}
				}
			}
		}

		public function KeyBind(id:String, display_name:String, default_keycode:int=0)
		{
			// constructor code
			mId = id;
			mDisplayName = display_name;
			mKeyCode = default_keycode;
			mDown = false;
			mDispatcher = new EventDispatcher(this);
			sKeybinds.push(this);
		}
		
		public function Rebind(keycode:int=0):void
		{
			mKeyCode = keycode;
			dispatchEvent(new Event(Event.CHANGE));
			
			Release();
		}
		
		public function SetListener(listener:EventDispatcher):void
		{
			// typically listener is the stage
			if (mListener)
			{
				mListener.removeEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
				mListener.removeEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
				mListener.removeEventListener(Event.DEACTIVATE, OnDeactivate);
			}
			mListener = listener;
			if (mListener)
			{
				mListener.addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
				mListener.addEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
				mListener.addEventListener(Event.DEACTIVATE, OnDeactivate);
			}
		}
		
		public function Press():void
		{
			if (!mDown)
			{
				mDown = true;
				dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN));
			}
		}
		public function Release():void
		{
			if (mDown)
			{
				mDown = false;
				dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP));
			}
		}
		
		private function OnKeyDown(ke:KeyboardEvent):void
		{
			if (ke.keyCode == mKeyCode)
				Press();
		}
		private function OnKeyUp(ke:KeyboardEvent):void
		{
			if (ke.keyCode == mKeyCode && mDown)
				Release();
		}
		private function OnDeactivate(e:Event):void
		{
			Release();
		}
		
		// getters/setters
		public function get down():Boolean { return mDown; }
		public function get keyCode():int { return mKeyCode; }
		public function get name():String { return mDisplayName; }
		
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
