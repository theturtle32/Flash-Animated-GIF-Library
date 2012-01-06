package com.worlize.gif.events
{
	import com.worlize.gif.GIFFrame;
	
	import flash.events.Event;
	
	public class GIFDecoderEvent extends Event
	{
		public static const DECODE_COMPLETE:String = "decodeComplete";
		
		public function GIFDecoderEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}