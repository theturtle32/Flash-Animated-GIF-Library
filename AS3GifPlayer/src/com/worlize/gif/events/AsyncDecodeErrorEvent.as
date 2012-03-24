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