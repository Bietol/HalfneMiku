package  {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.IExternalizable;
	import flash.utils.IDataOutput;
	import flash.utils.IDataInput;
	import flash.utils.Dictionary;
	import flash.net.registerClassAlias;
	
	// a timeline with stacks
	// time is in ms
	// dispatched Event.CHANGE event whenever the event on top of the stack at the current time changes
	public class Timestack implements IEventDispatcher, IExternalizable {
		
		private var mStacklets:Array;
		private var mLongShots:Vector.<DirectorEvent>;	// indefinite DirectorEvents
		private var mCurrentEvent:DirectorEvent;
		private var mCurrentTime:Number;
		private var mDispatcher:EventDispatcher;
		private var mLSLU:Dictionary;	// (Long Shot Look Up) mLSLU[directorEvents] = is_long_shot;	 need to quickly know where this is registered
		
		registerClassAlias("Timestack", Timestack);
		
		private const INTERVAL:Number = 4096;	// length of time between stacklets

		public function Timestack() {
			// constructor code
			mCurrentTime = 0;
			Clear();			
			mDispatcher = new EventDispatcher(this);
		}
		
		public function Clear():void
		{
			mLSLU = new Dictionary();
			mStacklets = new Array();
			mLongShots = new Vector.<DirectorEvent>;
		}
		
		public function AddEvent(d:DirectorEvent):void
		{
			_AddEvent(d);
			d.addEventListener(Event.CHANGE, OnDirectorEventChange);
			MoveTo(mCurrentTime);
		}
		private function _AddEvent(d:DirectorEvent):void
		{
			if (d.indefinite)
				AddLongShot(d);
			else
			{
				var stacklets:Vector.<Stacklet> = GetStacklets(d.start_ms, d.end_ms, true);
				for each (var stacklet:Stacklet in stacklets)
				{
					stacklet.AddEvent(d);
				}
			}			
		}
		
		public function RemoveEvent(d:DirectorEvent):void
		{
			_RemoveEvent(d);
			d.removeEventListener(Event.CHANGE, OnDirectorEventChange);
			MoveTo(mCurrentTime);
		}
		private function _RemoveEvent(d:DirectorEvent):void
		{
			if (mLSLU[d])
				RemoveLongShot(d);
			else
			{
				var stacklets:Vector.<Stacklet> = GetStacklets(d.start_ms, d.end_ms, true);
				for each (var stacklet:Stacklet in stacklets)
				{
					stacklet.RemoveEvent(d);
				}
			}
		}
		
		public function MoveTo(time:Number):void
		{
			mCurrentTime = time;
			var top:DirectorEvent = GetTopEventAt(time);
			if (top != mCurrentEvent)
			{
				mCurrentEvent = top;
				dispatchEvent(new Event(Event.CHANGE));
			}			
		}
		
		public function GetDirectorEvents(from_time:Number=int.MIN_VALUE, to_time:Number=int.MAX_VALUE):Vector.<DirectorEvent>
		{
			var list:Vector.<DirectorEvent> = new Vector.<DirectorEvent>;
			
			// get all active longshots
			var ls_start:int = GetClosestLongShot(from_time);
			var ls_end:int = GetClosestLongShot(to_time);
			for (var i:int = ls_start; i <= ls_end && i < mLongShots.length; i++)
			{
				list.push(mLongShots[i]);
			}
			
			var dic:Dictionary = new Dictionary();
			var stacklets = (from_time == int.MIN_VALUE || to_time == int.MAX_VALUE)? mStacklets : GetStacklets(from_time, to_time);
			for each (var stacklet:Stacklet in stacklets)
			{
				var stacklet_list:Vector.<DirectorEvent> = new Vector.<DirectorEvent>;
				stacklet.CollectEvents(stacklet_list, from_time, to_time);
				// weed out duplicates via dictionary
				for each (var d:DirectorEvent in stacklet_list)
					dic[d] = d;
			}
			// collect into list
			for each (d in dic)
				list.push(d);
			
			return list;
		}
		
		private function GetStacklets(from_time:Number, to_time:Number, make_if_empty:Boolean=false):Vector.<Stacklet>
		{
			var stacklets:Vector.<Stacklet> = new Vector.<Stacklet>;
			var start_i:int = Math.floor(from_time / INTERVAL);
			var end_i:int = Math.floor(to_time / INTERVAL);
			for (var i:int = start_i; i <= end_i; i++)
			{
				var stacklet = mStacklets[i];
				if (!stacklet)
				{
					if (make_if_empty)
					{
						stacklet = new Stacklet(i * INTERVAL, (i+1) * INTERVAL);
						mStacklets[i] = stacklet;
					}
					else
						continue;
				}
				stacklets.push(stacklet);
			}
			return stacklets;
		}
		
		private function OnDirectorEventChange(e:Event):void
		{
			var d:DirectorEvent = DirectorEvent(e.target);
			_RemoveEvent(d);
			_AddEvent(d);
			MoveTo(mCurrentTime);
		}
		
		public function GetTopEventAt(time:Number):DirectorEvent
		{			
			var stacklet_top;
			for each (var stacklet:Stacklet in GetStacklets(time, time))
			{
				stacklet_top = stacklet.GetTopEvent(time);
			}
			var i:int = GetClosestLongShot(time);
			if (i >= mLongShots.length)
				return stacklet_top;
				
			var long_top:DirectorEvent = mLongShots[i];
				
			if (!stacklet_top)
				return long_top;
			
			return long_top.start_ms < stacklet_top.start_ms? long_top : stacklet_top;
		}
		
		public function get time():Number { return mCurrentTime; }
		
		private function GetClosestLongShot(at_time:Number):int
		{
			if (mLongShots.length == 0)
				return 0;
			
			var i_start:int = 0;	// start should always be safe (begins before at_time)
			var i_end:int = mLongShots.length-1;
			var i:int = Math.ceil((i_start + i_end)/2);
			while(i_end - i_start > 1)
			{
				var d:DirectorEvent = mLongShots[i];
				if (d.start_ms == at_time)
					return i;	// DONE
				
				if (d.start_ms > at_time)	
					i_end = i;	// too late; back it up
				else
					i_start = i;	// start is safe; move it forward
				i = Math.ceil((i_start + i_end)/2);
			}
			return mLongShots[i].start_ms <= at_time? i : i_start;
		}
		private function AddLongShot(d:DirectorEvent):void
		{
			var i:int = GetClosestLongShot(d.start_ms);			
			if (i >= mLongShots.length)
				mLongShots.push(d);
			else
			{
				var other:DirectorEvent = mLongShots[i];
				if (d.start_ms > other.start_ms)
					i++;
				if (i >= mLongShots.length)
					mLongShots.push(d);
				else
					mLongShots.splice(i, 0, d);
			}
			mLSLU[d] = true;
		}
		private function RemoveLongShot(d:DirectorEvent):void
		{
			delete mLSLU[d];
			var i:int = GetClosestLongShot(d.start_ms);
			if (i >= mLongShots.length)
				return;
			for (var j:int = 0; j < mLongShots.length; j++)
			{
				// seek outwards
				var k:int = i;
				if (j % 2 == 0)
					k += Math.ceil(j/2);
				else
					k += mLongShots.length - Math.ceil(j/2);
				k %= mLongShots.length;
				if (mLongShots[k] == d)
				{
					mLongShots.splice(k, 1);
					return;
				}
			}
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
		
		// IExternalizable
		public function writeExternal(output:IDataOutput):void { 
			var event_list:Vector.<DirectorEvent> = new Vector.<DirectorEvent>;
			output.writeObject(event_list);
		}
 
		public function readExternal(input:IDataInput):void {			
			var event_list:Vector.<DirectorEvent> = input.readObject();
			for each (var d:DirectorEvent in event_list)
			{
				AddEvent(d);
			}
		}
	}
	
	
	
}


// a bucket of stacks in the timeline
class Stacklet {
	
	import flash.utils.Dictionary;
	internal var start_ms:Number;
	internal var end_ms:Number;
	private var mDirVents:Dictionary;	// mDirVents[DirectorEvent] = DirectorEvent
	
	public function Stacklet(t_start:Number, t_end:Number)
	{
		start_ms = t_start;
		end_ms = t_end;
		mDirVents = new Dictionary();
	}
	
	public function AddEvent(d:DirectorEvent):void
	{
		if (!mDirVents[d])
		{
			mDirVents[d] = d;
		}
	}
	public function RemoveEvent(d:DirectorEvent):void
	{
		delete mDirVents[d];
	}
	public function GetTopEvent(at_time:Number):DirectorEvent
	{
		var top:DirectorEvent = null;
		for each (var d:DirectorEvent in mDirVents)
		{
			if (d.Contains(at_time))
			{
				if (!top || d.start_ms > top.start_ms)
					top = d;
			}
		}
		return top;
	}
	
	internal function CollectEvents(into:Vector.<DirectorEvent>, start_time:Number, end_time:Number):int
	{
		var count:int = 0;
		for each (var d:DirectorEvent in mDirVents)
		{
			if (d.start_ms <= end_time && (d.indefinite || d.end_ms >= start_time))
			{
				count++;
				into.push(d);
			}
		}
		return count;
	}
	
	internal function MergeDictionary(into:Dictionary):void
	{
		for each (var d:DirectorEvent in mDirVents)
			into[d] = d;
	}
}
	