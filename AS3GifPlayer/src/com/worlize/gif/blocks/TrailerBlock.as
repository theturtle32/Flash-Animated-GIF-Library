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

package com.worlize.gif.blocks
{
	import com.worlize.gif.constants.BlockType;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;
	
	public class TrailerBlock implements IGIFBlockCodec
	{
		public function decode(stream:IDataInput):void {
			// No-op
		}
		
		public function encode(ba:ByteArray=null):ByteArray
		{
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			ba.writeByte(BlockType.TRAILER);
			
			return ba;
		}
		
		public function dispose():void {
		}
	}
}