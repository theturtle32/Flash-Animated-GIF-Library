package com.worlize.gif
{
	import com.worlize.gif.blocks.ColorTableBlock;
	import com.worlize.gif.blocks.ImageDescriptorBlock;
	import com.worlize.gif.events.AsyncDecodeErrorEvent;
	import com.worlize.gif.events.GIFDecoderEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.utils.ByteArray;
	
	[Event(name="asyncDecodeError",type="com.worlize.gif.events.AsyncDecodeErrorEvent")]
	[Event(name="decodeComplete",type="com.worlize.gif.events.GIFDecoderEvent")]
	public class GIFFrame extends EventDispatcher
	{
		public var bitmapData:BitmapData;
		public var gifData:ByteArray;
		
		public var top:uint;
		public var left:uint;
		public var width:uint;
		public var height:uint;
		public var backgroundColor:uint;
		public var backgroundColorIndex:uint;
		public var hasTransparency:Boolean;
		public var transparencyIndex:uint;
		public var delayMs:uint;
		public var disposalType:uint;
		public var frameNumber:uint;
		
		private var startTime:uint;
		private var loader:Loader;
		
		public function GIFFrame(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function decode():void {
			if (loader) {
				// remove listeners
			}
			bitmapData = null;
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleLoaderComplete);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, handleLoaderIOError);
			startTime = (new Date()).valueOf();
			loader.loadBytes(gifData);
		}
		
		public function abortDecode():void {
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, handleLoaderComplete);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, handleLoaderIOError);
		}
		
		protected function handleLoaderComplete(event:Event):void {
			var endTime:uint = (new Date()).valueOf();
			gifData.clear();
			bitmapData = (loader.content as Bitmap).bitmapData;
			dispatchEvent(new GIFDecoderEvent(GIFDecoderEvent.DECODE_COMPLETE));
		}
		
		protected function handleLoaderIOError(event:IOErrorEvent):void {
			dispatchEvent(new AsyncDecodeErrorEvent(AsyncDecodeErrorEvent.ASYNC_DECODE_ERROR));
		}
	}
}