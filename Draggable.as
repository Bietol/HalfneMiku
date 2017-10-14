package  {
	import flash.geom.Point;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.display.MovieClip;
	
	public class Draggable extends MovieClip {
		
		var mClickTarget:DisplayObject;
		var mMouseClick:Point;	// where the mouse was on click

		public function Draggable() {
			// constructor code
			SetDragTarget(this);
		}
		
		public function SetDragTarget(ct:DisplayObject):void
		{
			if (mClickTarget == ct)
				return;
			
			if (mClickTarget)
			{
				mClickTarget.removeEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
				mClickTarget.removeEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
				if (stage)
					OnRemovedFromStage(null);
			}
			mClickTarget = ct;
			if (mClickTarget)
			{
				mClickTarget.addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
				mClickTarget.addEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
				if (stage)
					OnAddedToStage(null);
			}
		}

		private function OnAddedToStage(e:Event):void
		{
			if (mClickTarget)
				mClickTarget.addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			stage.addEventListener(Event.DEACTIVATE, OnDeactivate);
		}
		
		private function OnRemovedFromStage(e:Event):void
		{
			if (mClickTarget)
				mClickTarget.removeEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			stage.removeEventListener(Event.DEACTIVATE, OnDeactivate);
			StopDrag();
		}
		
		private function OnMouseDown(e:MouseEvent):void
		{			
			mMouseClick = new Point(parent.mouseX, parent.mouseY);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
		}
		
		private function OnMouseMove(e:MouseEvent):void
		{
			x += parent.mouseX - mMouseClick.x;
			y += parent.mouseY - mMouseClick.y;
			mMouseClick = new Point(parent.mouseX, parent.mouseY);
		}
		
		private function OnMouseUp(e:MouseEvent):void
		{			
			StopDrag();
		}
		
		private function OnDeactivate(e:Event):void
		{
			StopDrag();
		}
		
		private function StopDrag():void
		{
			mMouseClick = null;
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
		}

	}
	
}
