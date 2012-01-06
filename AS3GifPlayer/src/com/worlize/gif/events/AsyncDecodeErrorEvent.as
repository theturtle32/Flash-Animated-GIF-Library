package com.worlize.gif.events
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	
	public class AsyncDecodeErrorEvent extends ErrorEvent
	{
		public static const ASYNC_DECODE_ERROR:String = "asyncDecodeError";
		
		public function AsyncDecodeErrorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, text:String="", id:int=0)
		{
			super(type, bubbles, cancelable, text, id);
		}
		
		override public function clone():Event {
			var event:AsyncDecodeErrorEvent = new AsyncDecodeErrorEvent(type, bubbles, cancelable, text, errorID);
			return event;
		}
	}
}