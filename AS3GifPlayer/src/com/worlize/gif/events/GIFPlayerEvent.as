package com.worlize.gif.events
{
	import flash.events.Event;
	
	public class GIFPlayerEvent extends Event
	{
		public static const COMPLETE:String = "complete";
		public static const FRAME_RENDERED:String = "frameRendered";
		
		public var frameIndex:uint;
		
		public function GIFPlayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}