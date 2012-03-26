/************************************************************************
 *  Copyright 2012 Worlize Inc.
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ***********************************************************************/

package com.worlize.gif
{
	import com.worlize.gif.constants.DisposalType;
	import com.worlize.gif.events.AsyncDecodeErrorEvent;
	import com.worlize.gif.events.GIFDecoderEvent;
	import com.worlize.gif.events.GIFPlayerEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	[Event(name="complete",type="com.worlize.gif.events.GIFPlayerEvent")]
	[Event(name="frameRendered",type="com.worlize.gif.events.GIFPlayerEvent")]
	[Event(name="asyncDecodeError",type="com.worlize.gif.events.AsyncDecodeErrorEvent")]
	public class GIFPlayer extends Bitmap
	{
		[Bindable]
		public var autoPlay:Boolean;
		[Bindable]
		public var enableFrameSkipping:Boolean = false;
		
		private var wasPlaying:Boolean = false;
		private var minFrameDelay:Number;
		private var useSmoothing:Boolean = false;
		private var lastQuantizationError:Number = 0;
		private var gifDecoder:GIFDecoder;
		private var timer:Timer = new Timer(0, 0);
		private var currentLoop:uint;
		private var _loopCount:uint;
		private var _currentFrame:int = -1;
		private var _frameCount:uint = 0;
		private var _frames:Vector.<GIFFrame>;
		private var _ready:Boolean = false;
		private var _imageWidth:Number;
		private var _imageHeight:Number;
		
		public function GIFPlayer(autoPlay:Boolean = true) {
			this.autoPlay = autoPlay;
			if (stage) {
				initMinFrameDelay();
			}
			addEventListener(Event.ADDED_TO_STAGE, initMinFrameDelay);
			timer.addEventListener(TimerEvent.TIMER, handleTimer);
			addEventListener(Event.REMOVED_FROM_STAGE, handleRemovedFromStage);
		}
		
		protected function handleRemovedFromStage(event:Event):void {
			wasPlaying = playing;
			stop();
			addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
		}
		
		protected function handleAddedToStage(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
			if (wasPlaying) {
				play();
			}
		}
		
		override public function set smoothing(newValue:Boolean):void {
			if (useSmoothing !== newValue) {
				useSmoothing = newValue;
				super.smoothing = newValue;
			}
		}
				
		private function initMinFrameDelay(event:Event=null):void {
//			stage.frameRate = 60;
			minFrameDelay = 1000 / stage.frameRate;
		}
		
		public function loadBytes(data:ByteArray):void {
			reset();
			gifDecoder.decodeBytes(data);
		}
		
		public function reset():void {
			stop();
			setReady(false);
			unloadDecoder();
			dispose();
			initDecoder();
		}
		
		protected function initDecoder():void {
			gifDecoder = new GIFDecoder();
			gifDecoder.addEventListener(GIFDecoderEvent.DECODE_COMPLETE, handleDecodeComplete);
			gifDecoder.addEventListener(AsyncDecodeErrorEvent.ASYNC_DECODE_ERROR, handleAsyncDecodeError);
		}
		
		protected function unloadDecoder():void {
			if (gifDecoder) {
				gifDecoder.removeEventListener(GIFDecoderEvent.DECODE_COMPLETE, handleDecodeComplete);
				gifDecoder.removeEventListener(AsyncDecodeErrorEvent.ASYNC_DECODE_ERROR, handleAsyncDecodeError);
				gifDecoder = null;
			}
		}
		
		protected function handleDecodeComplete(event:GIFDecoderEvent):void {
//			trace("Decode complete.  Total decoding time: " + gifDecoder.totalDecodeTime + " Blocking decode time: " + gifDecoder.blockingDecodeTime);
			currentLoop = 0;
			_loopCount = gifDecoder.loopCount;
			_frames = gifDecoder.frames;
			_frameCount = _frames.length;
			_currentFrame = -1;
			_imageWidth = gifDecoder.width;
			_imageHeight = gifDecoder.height;
			gifDecoder.cleanup();
			unloadDecoder();
			setReady(true);
			dispatchEvent(new Event('totalFramesChange'));
			dispatchEvent(new GIFPlayerEvent(GIFPlayerEvent.COMPLETE));
			if (stage) {
				if (autoPlay) {
					gotoAndPlay(1);
				}
				else {
					gotoAndStop(1);
				}
			}
		}
		
		private function handleTimer(event:TimerEvent):void {
			step();
		}
		
		public function gotoAndPlay(requestedIndex:uint):void {
			lastQuantizationError = 0;
			goto(requestedIndex-1);
			play();
		}
		
		public function gotoAndStop(requestedIndex:uint):void {
			stop();
			lastQuantizationError = 0;
			goto(requestedIndex-1);
		}
		
		public function play():void {
			if (_frameCount <= 0) {
				throw new Error("Nothing to play");
			}
			// single-frame file, nothing to play but we can
			// render the first frame.
			if (_frameCount === 1) {
				goto(0);
			}
			else {
				timer.start();
				lastQuantizationError = 0;
			}
		}
		
		public function stop():void {
			if (timer.running) {
				timer.stop();
			}
		}
		
		private function quantizeFrameDelay(input:Number, increment:Number):Number {
			var adjustedInput:Number = input + lastQuantizationError;
			var output:Number = Math.round((adjustedInput)/increment)*increment;
			lastQuantizationError = adjustedInput - output;
			return output;
		}
		
		private function step():void {
			if (_currentFrame + 1 >= _frameCount) {
				currentLoop ++;
				if (_loopCount === 0 || currentLoop < _loopCount) {
					goto(0);
				}
				else {
					stop();
				}
			}
			else {
				goto(_currentFrame + 1);
			}
		}
		
		// This private API function uses zero-based indices, while the public
		// facing API uses one-based indices
		private function goto(requestedIndex:uint):void {
			if (requestedIndex >= _frameCount || requestedIndex < 0) {
				throw new RangeError("The requested frame is out of bounds.");
			}
			if (requestedIndex === _currentFrame) {
				return;
			}
			
			// Store current frame index
			_currentFrame = requestedIndex;
			
			var requestedDelay:Number = (currentFrameObject.delayMs < 20) ? 100 : currentFrameObject.delayMs;
			var delay:Number = Math.round(quantizeFrameDelay(requestedDelay, minFrameDelay));
			delay = Math.max(delay - minFrameDelay/2, 0);
			timer.delay = delay;
			
			if (delay === 0 && enableFrameSkipping) {
				// skip the frame
				step();
				return;
			}
			
			// Update the display
			bitmapData = currentFrameObject.bitmapData;
			if (useSmoothing) {
				super.smoothing = true;
			}
			
			var renderedEvent:GIFPlayerEvent = new GIFPlayerEvent(GIFPlayerEvent.FRAME_RENDERED);
			renderedEvent.frameIndex = _currentFrame;
			dispatchEvent(renderedEvent);
		}

		public function dispose():void {
			if (_frames === null) { return; }
			for (var i:int = 0; i < _frames.length; i ++) {
				_frames[i].bitmapData.dispose();
			}
		}
		
		public function get playing():Boolean {
			return timer.running;
		}
		
		[Bindable(event="frameRendered")]
		public function get currentFrame():uint {
			return _currentFrame+1;
		}
		
		[Bindable(event="totalFramesChange")]
		public function get totalFrames():uint {
			return _frameCount;
		}
		
		[Bindable(event="readyChange")]
		public function get ready():Boolean {
			return _ready;
		}
		
		protected function setReady(newValue:Boolean):void {
			if (_ready !== newValue) {
				_ready = newValue;
				dispatchEvent(new Event("readyChange"));
			}
		}
		
		public function get loopCount():uint {
			return _loopCount;
		}
		
		protected function get currentFrameObject():GIFFrame {
			return _frames[_currentFrame];
		}
		
		protected function get previousFrameObject():GIFFrame {
			if (_currentFrame === 0) { return null; }
			return _frames[_currentFrame-1];
		}
		
		protected function handleAsyncDecodeError(event:AsyncDecodeErrorEvent):void {
			dispatchEvent(event.clone());
		}
		
		override public function get width():Number {
			return _imageWidth;
		}
		
		override public function get height():Number {
			return _imageHeight;
		}
	}
}